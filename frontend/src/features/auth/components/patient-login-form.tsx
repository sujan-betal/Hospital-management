"use client"

import { useState, useEffect, useRef } from "react"
import { Send, ShieldCheck, Smartphone, Check, ArrowRight, KeyRound, Sparkles } from "lucide-react"
import { useRouter } from "next/navigation"
import { sendPatientOtp, verifyPatientOtp } from "@/services/patient.service"


function Field({ icon: Icon, error, children }) {
  return (
    <div className="space-y-1.5">
      <div className="relative group">
        <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#6B8078] group-focus-within:text-[#12463E] transition-colors">
          <Icon className="h-4 w-4" strokeWidth={2} />
        </div>
        {children}
      </div>
      {error && (
        <p className="text-xs text-[#C4392A] flex items-center gap-1.5 pl-0.5">
          <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
          {error}
        </p>
      )}
    </div>
  )
}

export function PatientLoginForm() {
  const router = useRouter()
  const [phone, setPhone] = useState("")
  const [otp, setOtp] = useState("")
  const [otpSent, setOtpSent] = useState(false)
  const [countdown, setCountdown] = useState(0)
  const [captchaVerified, setCaptchaVerified] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [sending, setSending] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [demoOtp, setDemoOtp] = useState("")
  const [serverMessage, setServerMessage] = useState("")
  const otpRef = useRef<HTMLInputElement>(null)

  const isPhoneValid = /^[+]?[\d\s()-]{6,20}$/.test(phone.trim())

  useEffect(() => {
    if (countdown <= 0) return
    const t = setTimeout(() => setCountdown((c) => c - 1), 1000)
    return () => clearTimeout(t)
  }, [countdown])

  useEffect(() => {
    if (otpSent) otpRef.current?.focus()
  }, [otpSent])

  const handleSendOtp = async () => {
    if (!isPhoneValid) {
      setErrors({ phone: "Enter a valid phone number" })
      return
    }
    setErrors({})
    setServerMessage("")
    setDemoOtp("")
    setSending(true)
    try {
      const res = await sendPatientOtp(phone.trim())
      setOtpSent(true)
      setCountdown(30)
      setDemoOtp(res.data?.otp || "")
      setServerMessage(res.message || `OTP sent to ${res.data?.phone}`)
    } catch (err: any) {
      setErrors({ phone: err?.message || "Could not send OTP. Please try again." })
    } finally {
      setSending(false)
    }
  }

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const errs: Record<string, string> = {}
    if (!isPhoneValid) errs.phone = "Enter a valid phone number"
    if (otpSent && !/^\d{4,8}$/.test(otp)) errs.otp = "Enter the OTP code"
    if (!captchaVerified) errs.captcha = "Please verify you're not a robot"
    setErrors(errs)
    if (Object.keys(errs).length) return

    setSubmitting(true)
    try {
      const res = await verifyPatientOtp(phone.trim(), otp)
      const { access_token, ...userData } = res.data
      if (access_token) {
        localStorage.setItem("access_token", access_token)
        localStorage.setItem("user", JSON.stringify(userData))
      }
      router.push("/patient")
    } catch (err: any) {
      setErrors({ otp: err?.message || "Invalid OTP. Please try again." })
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <div className="space-y-1.5">
        <label htmlFor="phone" className="text-[13px] font-semibold text-[#12463E] tracking-wide">
          Registered phone number
        </label>
        <Field icon={Smartphone} error={errors.phone}>
          <input
            id="phone"
            type="tel"
            inputMode="tel"
            placeholder="+1 (555) 019-2834"
            value={phone}
            disabled={otpSent}
            onChange={(e) => setPhone(e.target.value.slice(0, 20))}
            className="w-full h-12 pl-10 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-[#12463E]/20 focus:border-[#12463E] disabled:opacity-60 transition-all"
          />
        </Field>
        {!otpSent && (
          <p className="text-[11px] text-[#9CAEA6] flex items-center gap-1.5 pl-0.5">
            <Sparkles className="h-3 w-3 text-emerald-500" />
            Demo: try <span className="font-mono font-semibold text-[#12463E]">+1 (555) 019-2834</span>
          </p>
        )}
      </div>

      {!otpSent ? (
        <button
          type="button"
          onClick={handleSendOtp}
          disabled={!isPhoneValid || sending}
          className="w-full h-11 rounded-xl border border-[#12463E]/30 text-[#12463E] font-semibold text-sm flex items-center justify-center gap-2 hover:bg-[#12463E]/5 disabled:opacity-40 disabled:cursor-not-allowed transition-all"
        >
          {sending ? (
            <>
              <span className="w-4 h-4 border-2 border-[#12463E]/30 border-t-[#12463E] rounded-full animate-spin" />
              Sending OTP...
            </>
          ) : (
            <>
              <Send className="h-4 w-4" />
              Send OTP
            </>
          )}
        </button>
      ) : (
        <div className="space-y-1.5">
          <label htmlFor="otp" className="text-[13px] font-semibold text-[#12463E] tracking-wide">
            One-time code
          </label>
          <input
            ref={otpRef}
            id="otp"
            type="text"
            inputMode="numeric"
            maxLength={8}
            placeholder="······"
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 8))}
            className="w-full h-12 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-center text-lg font-mono tracking-[0.6em] text-[#0B2B26] placeholder:text-[#C3CFC9] focus:outline-none focus:ring-2 focus:ring-[#12463E]/20 focus:border-[#12463E] transition-all"
          />
          {errors.otp && (
            <p className="text-xs text-[#C4392A] flex items-center gap-1.5 pl-0.5">
              <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
              {errors.otp}
            </p>
          )}
          {serverMessage && (
            <p className="text-xs text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-xl px-3 py-2 flex items-center gap-1.5">
              <Check className="h-3.5 w-3.5 shrink-0" />
              {serverMessage}
            </p>
          )}
          {demoOtp && (
            <div className="flex items-center justify-between gap-2 rounded-xl border border-amber-200 bg-amber-50 px-3 py-2.5">
              <p className="text-xs text-amber-800 font-semibold">
                Demo mode OTP: <span className="font-mono text-sm tracking-widest">{demoOtp}</span>
              </p>
              <button
                type="button"
                onClick={() => setOtp(demoOtp)}
                className="shrink-0 flex items-center gap-1 text-[11px] font-bold text-amber-800 bg-white border border-amber-200 hover:bg-amber-100 px-2.5 py-1 rounded-lg transition-all"
              >
                <KeyRound className="h-3 w-3" />
                Use code
              </button>
            </div>
          )}
          <div className="flex items-center justify-between pt-0.5">
            <p className="text-xs text-[#6B8078]">
              Sent to {phone.trim() || "your number"}
            </p>
            {countdown > 0 ? (
              <span className="text-xs text-[#9CAEA6] font-medium tabular-nums">
                Resend in {countdown}s
              </span>
            ) : (
              <button type="button" onClick={handleSendOtp} disabled={sending} className="text-xs text-[#E85C4A] font-semibold hover:underline disabled:opacity-50">
                {sending ? "Sending..." : "Resend OTP"}
              </button>
            )}
          </div>
        </div>
      )}

      <div
        onClick={() => setCaptchaVerified((v) => !v)}
        role="checkbox"
        aria-checked={captchaVerified}
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === " " || e.key === "Enter") {
            e.preventDefault()
            setCaptchaVerified((v) => !v)
          }
        }}
        className={`rounded-xl border p-3.5 flex items-center gap-3 cursor-pointer transition-all ${
          captchaVerified ? "border-[#12463E]/40 bg-[#12463E]/[0.06]" : "border-[#D7E2DC] bg-[#F6F8F7] hover:border-[#B9C7C2]"
        }`}
      >
        <div
          className={`flex items-center justify-center w-7 h-7 rounded-lg border-2 shrink-0 transition-all ${
            captchaVerified ? "bg-[#12463E] border-[#12463E]" : "bg-white border-[#C3CFC9]"
          }`}
        >
          {captchaVerified && <Check className="h-4 w-4 text-white" strokeWidth={3} />}
        </div>
        <div className="flex-1 min-w-0">
          <p className={`text-sm font-medium ${captchaVerified ? "text-[#12463E]" : "text-[#4B5F58]"}`}>
            I&apos;m not a robot
          </p>
          <p className="text-[11px] text-[#9CAEA6] mt-0.5">reCAPTCHA verification</p>
        </div>
        <ShieldCheck className={`h-5 w-5 shrink-0 ${captchaVerified ? "text-[#12463E]" : "text-[#C3CFC9]"}`} />
      </div>
      {errors.captcha && (
        <p className="text-xs text-[#C4392A] flex items-center gap-1.5 -mt-2 pl-0.5">
          <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
          {errors.captcha}
        </p>
      )}

      <button
        type="submit"
        disabled={submitting || !otpSent}
        className="w-full h-12 rounded-xl bg-[#12463E] hover:bg-[#0B2B26] text-white font-semibold text-sm shadow-lg shadow-[#12463E]/25 transition-all flex items-center justify-center gap-2 disabled:opacity-70"
      >
        {submitting ? "Verifying..." : (
          <>
            Verify &amp; login
            <ArrowRight className="h-4 w-4" />
          </>
        )}
      </button>
    </form>
  )
}
