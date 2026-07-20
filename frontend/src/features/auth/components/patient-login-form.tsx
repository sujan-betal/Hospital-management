"use client"

import { useState, useEffect, useRef } from "react"
import { Send, ShieldCheck, Smartphone, Check, ArrowRight } from "lucide-react"
import { useRouter } from "next/navigation"


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
  const [errors, setErrors] = useState<Record<string, string>>({})
  const otpRef = useRef<HTMLInputElement>(null)

  const isPhoneValid = /^\d{10}$/.test(phone)

  useEffect(() => {
    if (countdown <= 0) return
    const t = setTimeout(() => setCountdown((c) => c - 1), 1000)
    return () => clearTimeout(t)
  }, [countdown])

  useEffect(() => {
    if (otpSent) otpRef.current?.focus()
  }, [otpSent])

  const sendOtp = () => {
    if (!isPhoneValid) {
      setErrors({ phone: "Enter a valid 10-digit phone number" })
      return
    }
    setErrors({})
    setOtpSent(true)
    setCountdown(30)
  }

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const errs: Record<string, string> = {}
    if (!isPhoneValid) errs.phone = "Enter a valid 10-digit phone number"
    if (otpSent && !/^\d{6}$/.test(otp)) errs.otp = "Enter the 6-digit code"
    if (!captchaVerified) errs.captcha = "Please verify you're not a robot"
    setErrors(errs)
    if (Object.keys(errs).length) return

    setSubmitting(true)
    await new Promise((r) => setTimeout(r, 1400))
    setSubmitting(false)
    console.log("Patient login:", { phone, otp })
    router.push("/patient")
  }

  return (
    <form onSubmit={submit} className="space-y-4">
      <div className="space-y-1.5">
        <label htmlFor="phone" className="text-[13px] font-semibold text-[#12463E] tracking-wide">
          Phone number
        </label>
        <Field icon={Smartphone} error={errors.phone}>
          <input
            id="phone"
            type="tel"
            inputMode="numeric"
            placeholder="98765 43210"
            value={phone}
            disabled={otpSent}
            onChange={(e) => setPhone(e.target.value.replace(/\D/g, "").slice(0, 10))}
            className="w-full h-12 pl-10 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-[#12463E]/20 focus:border-[#12463E] disabled:opacity-60 transition-all"
          />
        </Field>
      </div>

      {!otpSent ? (
        <button
          type="button"
          onClick={sendOtp}
          disabled={!isPhoneValid}
          className="w-full h-11 rounded-xl border border-[#12463E]/30 text-[#12463E] font-semibold text-sm flex items-center justify-center gap-2 hover:bg-[#12463E]/5 disabled:opacity-40 disabled:cursor-not-allowed transition-all"
        >
          <Send className="h-4 w-4" />
          Send OTP
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
            maxLength={6}
            placeholder="······"
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))}
            className="w-full h-12 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-center text-lg font-mono tracking-[0.6em] text-[#0B2B26] placeholder:text-[#C3CFC9] focus:outline-none focus:ring-2 focus:ring-[#12463E]/20 focus:border-[#12463E] transition-all"
          />
          {errors.otp && (
            <p className="text-xs text-[#C4392A] flex items-center gap-1.5 pl-0.5">
              <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
              {errors.otp}
            </p>
          )}
          <div className="flex items-center justify-between pt-0.5">
            <p className="text-xs text-[#6B8078]">
              Sent to +91 {phone.slice(0, 5)} {phone.slice(5)}
            </p>
            {countdown > 0 ? (
              <span className="text-xs text-[#9CAEA6] font-medium tabular-nums">
                Resend in {countdown}s
              </span>
            ) : (
              <button type="button" onClick={() => setCountdown(30)} className="text-xs text-[#E85C4A] font-semibold hover:underline">
                Resend OTP
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
        disabled={submitting}
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