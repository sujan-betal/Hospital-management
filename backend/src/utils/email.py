import logging
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import smtplib

from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
# Prefer explicit sender config; fall back to the SMTP account itself.
MAIL_FROM = os.getenv("MAIL_FROM") or os.getenv("FROM_EMAIL") or SMTP_USER
MAIL_FROM_NAME = os.getenv("MAIL_FROM_NAME", "AURA Medical")


def email_configured() -> bool:
    return bool(SMTP_HOST and SMTP_USER)


def _send_html_email(to_email: str, subject: str, html_body: str) -> bool:
    """Send an HTML email over SMTP. Returns True if delivered."""
    if not email_configured():
        # Dev fallback: no SMTP configured, so log the email so the flow
        # can still be exercised locally.
        logger.warning(
            "SMTP not configured. Email NOT delivered. [to=%s] [subject=%s]\n%s",
            to_email,
            subject,
            html_body,
        )
        print(
            f"\n[DEV EMAIL -> {to_email}] Subject: {subject}\n{html_body}\n"
        )
        return False

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"{MAIL_FROM_NAME} <{MAIL_FROM or SMTP_USER}>"
    msg["To"] = to_email
    msg.attach(MIMEText(html_body, "html", "utf-8"))

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=30) as server:
            server.ehlo()
            if int(os.getenv("SMTP_TLS", "1")):
                server.starttls()
                server.ehlo()
            if SMTP_PASSWORD:
                server.login(SMTP_USER, SMTP_PASSWORD)
            server.sendmail(MAIL_FROM or SMTP_USER, [to_email], msg.as_string())
        logger.info("Email delivered to %s via %s", to_email, SMTP_HOST)
        print(f"[EMAIL SENT -> {to_email}] Subject: {subject}")
        return True
    except Exception as exc:
        logger.error("Failed to send email to %s: %s", to_email, exc)
        print(f"[EMAIL FAILED -> {to_email}] {exc}")
        return False


def send_password_reset_email(
    to_email: str,
    full_name: str,
    reset_link: str,
    reset_minutes: int = 30,
) -> bool:
    """Send a 'set your password' / 'reset password' email."""
    subject = "AURA Medical - Set Up Your Account Password"
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
    return _send_html_email(to_email, subject, html_body)


def send_account_created_email(
    to_email: str,
    full_name: str,
    login_email: str,
    reset_link: str,
) -> bool:
    """Send a generic 'account created' email with the login email and reset link."""
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
    return _send_html_email(to_email, subject, html_body)
