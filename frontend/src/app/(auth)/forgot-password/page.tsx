"use client"

import { useState } from "react"
import Link from "next/link"
import { Activity, ArrowLeft, Mail, Send, CheckCircle2 } from "lucide-react"
import { forgotPassword } from "@/services/auth.service"

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("")
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState("")
  const [sent, setSent] = useState(false)

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    if (!/^\S+@\S+\.\S+$/.test(email)) {
      setError("Enter a valid email address")
      return
    }

    setSubmitting(true)
    try {
      await forgotPassword(email)
      setSent(true)
    } catch (err: any) {
      setError(err.message || "Something went wrong. Please try again.")
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-[#F8FAF9] relative overflow-hidden p-6">
      <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-emerald-100/40 rounded-full blur-[120px] -translate-y-1/2 translate-x-1/4" />
      <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-teal-50/60 rounded-full blur-[100px] translate-y-1/3 -translate-x-1/4" />

      <div className="relative z-10 w-full max-w-[420px]">
        {/* Brand */}
        <div className="flex flex-col items-center mb-8">
          <div className="relative">
            <div className="absolute inset-0 rounded-2xl bg-emerald-500/20 blur-xl scale-150" />
            <div className="relative w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-500 to-emerald-700 flex items-center justify-center shadow-xl">
              <Activity className="h-7 w-7 text-white" strokeWidth={2.5} />
            </div>
          </div>
          <h2 className="text-lg font-black text-[#0B2B26] mt-3 tracking-tight">AURA Medical</h2>
          <p className="text-xs text-[#8AA098] font-medium">Hospital Management System</p>
        </div>

        <div className="rounded-[28px] bg-white/80 backdrop-blur-xl shadow-[0_8px_60px_rgba(11,43,38,0.08)] border border-white/60 overflow-hidden">
          <div className="px-8 pt-8 pb-6">
            {sent ? (
              <div className="text-center py-4">
                <div className="mx-auto w-16 h-16 rounded-full bg-emerald-50 border border-emerald-200 flex items-center justify-center mb-4">
                  <CheckCircle2 className="h-8 w-8 text-emerald-600" />
                </div>
                <h1 className="text-xl font-extrabold text-[#0B2B26] tracking-tight">Check your inbox</h1>
                <p className="text-sm text-[#6B8078] mt-2 leading-relaxed">
                  If an account exists for{" "}
                  <span className="font-semibold text-[#12463E]">{email}</span>, we&apos;ve sent a
                  password-set link. It expires in 30 minutes.
                </p>
                <Link
                  href="/login"
                  className="mt-6 inline-flex items-center gap-2 text-xs font-bold text-[#12463E] hover:text-[#0B2B26]"
                >
                  <ArrowLeft className="h-3.5 w-3.5" />
                  Back to sign in
                </Link>
              </div>
            ) : (
              <>
                <h1 className="text-[22px] font-extrabold text-[#0B2B26] tracking-tight">
                  Reset your password
                </h1>
                <p className="text-sm text-[#6B8078] mt-1">
                  Enter your account email and we&apos;ll send you a secure link to create a new password.
                </p>

                <form onSubmit={submit} className="space-y-4 mt-6">
                  <div className="space-y-1.5">
                    <label htmlFor="email" className="text-[13px] font-semibold text-[#12463E] tracking-wide">
                      Email address
                    </label>
                    <div className="relative group">
                      <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#6B8078] group-focus-within:text-[#12463E] transition-colors">
                        <Mail className="h-4 w-4" strokeWidth={2} />
                      </div>
                      <input
                        id="email"
                        type="email"
                        placeholder="doctor@hospital.com"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        className="w-full h-12 pl-10 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-[#12463E]/20 focus:border-[#12463E] transition-all"
                      />
                    </div>
                    {error && (
                      <p className="text-xs text-[#C4392A] flex items-center gap-1.5 pl-0.5">
                        <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
                        {error}
                      </p>
                    )}
                  </div>

                  <button
                    type="submit"
                    disabled={submitting}
                    className="w-full h-12 rounded-xl bg-[#12463E] hover:bg-[#0B2B26] text-white font-semibold text-sm shadow-lg shadow-[#12463E]/25 transition-all flex items-center justify-center gap-2 disabled:opacity-70"
                  >
                    {submitting ? "Sending..." : (
                      <>
                        Send reset link
                        <Send className="h-4 w-4" />
                      </>
                    )}
                  </button>
                </form>
              </>
            )}
          </div>
        </div>

        <p className="text-center mt-6">
          <Link href="/login" className="text-xs font-bold text-[#12463E] hover:underline inline-flex items-center gap-1.5">
            <ArrowLeft className="h-3.5 w-3.5" />
            Back to sign in
          </Link>
        </p>
      </div>
    </div>
  )
}
