import logging
import os
import re
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import formatdate, make_msgid

import smtplib

from src.config.env import load_env

load_env()

logger = logging.getLogger(__name__)


def _plain_text_from_html(html: str) -> str:
    """Crude HTML→text fallback for the multipart plain-text part."""
    text = re.sub(r"<style.*?</style>", " ", html, flags=re.DOTALL)
    text = re.sub(r"<[^>]+>", " ", text)
    text = text.replace("&nbsp;", " ").replace("&amp;", "&")
    text = re.sub(r"\s+", " ", text).strip()
    return text

SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = (os.getenv("SMTP_USER") or "").strip()
# Gmail app passwords are 16 alphanumeric chars with no spaces; strip any
# whitespace so credentials pasted with formatting still authenticate.
SMTP_PASSWORD = "".join((os.getenv("SMTP_PASSWORD") or "").split())
# Prefer explicit sender config; fall back to the SMTP account itself.
MAIL_FROM = os.getenv("MAIL_FROM") or os.getenv("FROM_EMAIL") or SMTP_USER
MAIL_FROM_NAME = os.getenv("MAIL_FROM_NAME", "AURA Medical")


def email_configured() -> bool:
    return bool(SMTP_HOST and SMTP_USER)


def _domain_can_receive(email: str) -> bool:
    """Check the recipient domain actually has a mail server (MX record).

    Placeholder addresses such as `someone@test.com`, `@example.com` or
    `@auracare.demo` have no MX record, so Gmail accepts the message and then
    silently bounces it — the admin is told "email sent" but nobody receives
    it. Catching this up front gives an honest error instead.
    """
    domain = (email or "").strip().rsplit("@", 1)[-1] if email else ""
    if not domain or "." not in domain or " " in domain:
        return False
    try:
        import dns.resolver

        answers = dns.resolver.resolve(domain, "MX", lifetime=5)
        # A null MX (RFC 7505, empty exchange) explicitly means "no mail here".
        exchanges = [str(r.exchange).strip(".") for r in answers]
        return any(exchanges)
    except dns.resolver.NXDOMAIN:
        return False
    except dns.resolver.NoAnswer:
        return False
    except Exception:
        # Transient DNS failure — don't block a legitimate send on it.
        return True


def _send_html_email(
    to_email: str,
    subject: str,
    html_body: str,
    recipient_name: str | None = None,
) -> tuple[bool, str]:
    """Send an HTML email over SMTP.

    Returns ``(delivered, reason)`` — ``reason`` is empty on success and holds
    a human-readable explanation otherwise.
    """
    if not email_configured():
        # Dev fallback: no SMTP configured, so log the email so the flow
        # can still be exercised locally.
        reason = (
            f"SMTP is not configured (set SMTP_HOST / SMTP_USER in backend/.env). "
            "Email NOT delivered."
        )
        logger.warning(
            "SMTP not configured. Email NOT delivered. [to=%s] [subject=%s]\n%s",
            to_email,
            subject,
            html_body,
        )
        print(f"\n[DEV EMAIL -> {to_email}] Subject: {subject}\n{html_body}\n")
        return False, reason

    if not _domain_can_receive(to_email):
        domain = (to_email or "").rsplit("@", 1)[-1]
        reason = (
            f"'{to_email}' cannot receive mail — the domain '{domain}' has no "
            "mail server (MX record). Check that the staff member's email "
            "address is a real, working inbox."
        )
        logger.warning("Email NOT sent: %s", reason)
        print(f"[EMAIL FAILED -> {to_email}] {reason}")
        return False, reason

    # Multipart with a plain-text alternative reduces spam-folder placement.
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"{MAIL_FROM_NAME} <{MAIL_FROM or SMTP_USER}>"
    msg["To"] = (
        f"{recipient_name} <{to_email}>" if recipient_name else to_email
    )
    msg["Reply-To"] = MAIL_FROM or SMTP_USER
    # Proper Message-ID / Date headers keep the message out of the spam folder.
    msg["Message-ID"] = make_msgid(
        domain=SMTP_USER.split("@")[-1] if "@" in (SMTP_USER or "") else None
    )
    msg["Date"] = formatdate(localtime=True)
    msg.attach(MIMEText(_plain_text_from_html(html_body), "plain", "utf-8"))
    msg.attach(MIMEText(html_body, "html", "utf-8"))

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=30) as server:
            server.ehlo()
            if int(os.getenv("SMTP_TLS", "1")):
                server.starttls()
                server.ehlo()
            if SMTP_PASSWORD:
                server.login(SMTP_USER, SMTP_PASSWORD)
            refused = server.sendmail(MAIL_FROM or SMTP_USER, [to_email], msg.as_string())
        if refused:
            reason = f"Mail server refused delivery to {to_email}: {refused}"
            logger.error("Email delivery refused for %s: %s", to_email, refused)
            print(f"[EMAIL FAILED -> {to_email}] {reason}")
            return False, reason
        logger.info("Email delivered to %s via %s", to_email, SMTP_HOST)
        print(f"[EMAIL SENT -> {to_email}] Subject: {subject}")
        return True, ""
    except Exception as exc:
        reason = f"SMTP error while sending to {to_email}: {exc}"
        logger.error("Failed to send email to %s: %s", to_email, exc)
        print(f"[EMAIL FAILED -> {to_email}] {exc}")
        return False, reason


def send_password_reset_email(
    to_email: str,
    full_name: str,
    reset_link: str,
    reset_minutes: int = 30,
    login_email: str = None,
    login_username: str = None,
) -> tuple[bool, str]:
    """Send a 'set your password' / 'reset password' email.

    Returns ``(delivered, reason)``.
    """
    subject = "AURA Medical - Set Up Your Account Password"
    login_block = ""
    if login_email or login_username:
        login_block = f"""
        <div style="background:#f4f9f7;border:1px solid #d7e6df;border-radius:12px;padding:16px 18px;margin:0 0 18px;">
          <p style="margin:0 0 8px;color:#12463e;font-size:13px;font-weight:bold;">Your Login Details</p>
          <p style="margin:0;color:#405a52;font-size:13px;line-height:1.6;">
            Username: <strong style="color:#0f9d76;">{login_username or "—"}</strong>
          </p>
          <p style="margin:4px 0 0;color:#405a52;font-size:13px;line-height:1.6;">
            Email: <strong style="color:#0f9d76;">{login_email or "—"}</strong>
          </p>
        </div>
        """
    html_body = f"""
    <div style="font-family:Arial,sans-serif;background:#f4f6f5;padding:32px 16px;">
      <div style="max-width:520px;margin:0 auto;background:#ffffff;border-radius:16px;
                  overflow:hidden;border:1px solid #e2e8e4;">
        <div style="background:#12463E;padding:24px 28px;">
          <h2 style="margin:0;color:#ffffff;font-size:20px;">AURA Medical</h2>
          <p style="margin:4px 0 0;color:#9fd8c8;font-size:12px;">Hospital Management System</p>
        </div>
        <div style="padding:28px;">
          <p style="margin:0 0 16px;color:#12463e;font-size:15px;">
            Hi {full_name or "there"},
          </p>
          <p style="margin:0 0 16px;color:#405a52;font-size:14px;line-height:1.6;">
            An administrator has created an account for you. To finish setting it up,
            please create a new password using the link below. The link is valid for
            the next <strong>{reset_minutes} minutes</strong>.
          </p>
          {login_block}
          <a href="{reset_link}"
             style="display:inline-block;background:#0f9d76;color:#ffffff;text-decoration:none;
                    padding:12px 24px;border-radius:10px;font-size:14px;font-weight:bold;">
            Set My Password
          </a>
          <p style="margin:24px 0 0;color:#8aa098;font-size:12px;line-height:1.6;">
            If the button does not work, copy and paste this link into your browser:<br/>
            <a href="{reset_link}" style="color:#12463e;word-break:break-all;">{reset_link}</a>
          </p>
          <p style="margin:20px 0 0;color:#9aaca4;font-size:11px;">
            If you did not request this, you can safely ignore this email.
          </p>
        </div>
      </div>
    </div>
    """
    return _send_html_email(
        to_email, subject, html_body, recipient_name=full_name
    )


def send_account_created_email(
    to_email: str,
    full_name: str,
    login_email: str,
    reset_link: str,
) -> tuple[bool, str]:
    """Send a generic 'account created' email with the login email and reset link.

    Returns ``(delivered, reason)``.
    """
    subject = "AURA Medical - Your Account Has Been Created"
    html_body = f"""
    <div style="font-family:Arial,sans-serif;background:#f4f6f5;padding:32px 16px;">
      <div style="max-width:520px;margin:0 auto;background:#ffffff;border-radius:16px;
                  overflow:hidden;border:1px solid #e2e8e4;">
        <div style="background:#12463E;padding:24px 28px;">
          <h2 style="margin:0;color:#ffffff;font-size:20px;">AURA Medical</h2>
          <p style="margin:4px 0 0;color:#9fd8c8;font-size:12px;">Hospital Management System</p>
        </div>
        <div style="padding:28px;">
          <p style="margin:0 0 16px;color:#12463e;font-size:15px;">Hi {full_name or "there"},</p>
          <p style="margin:0 0 16px;color:#405a52;font-size:14px;line-height:1.6;">
            Your {login_email} account has been created. Use the link below to set your
            password and sign in to your portal.
          </p>
          <a href="{reset_link}"
             style="display:inline-block;background:#0f9d76;color:#ffffff;text-decoration:none;
                    padding:12px 24px;border-radius:10px;font-size:14px;font-weight:bold;">
            Set My Password
          </a>
        </div>
      </div>
    </div>
    """
    return _send_html_email(
        to_email, subject, html_body, recipient_name=full_name
    )
