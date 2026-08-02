"use client"

import { Suspense, useState } from "react"
import Link from "next/link"
import { useRouter, useSearchParams } from "next/navigation"
import { Activity, Eye, EyeOff, Lock, CheckCircle2, AlertTriangle, ArrowLeft, ShieldCheck } from "lucide-react"
import { resetPassword } from "@/services/auth.service"

function ResetPasswordForm() {
  const router = useRouter()
  const params = useSearchParams()
  const token = params.get("token") || ""

  const [password, setPassword] = useState("")
  const [confirm, setConfirm] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [done, setDone] = useState(false)

  if (!token) {
    return (
      <div className="text-center py-6">
        <div className="mx-auto w-16 h-16 rounded-full bg-amber-50 border border-amber-200 flex items-center justify-center mb-4">
          <AlertTriangle className="h-8 w-8 text-amber-600" />
        </div>
        <h1 className="text-xl font-extrabold text-[#0B2B26] tracking-tight">Invalid reset link</h1>
        <p className="text-sm text-[#6B8078] mt-2 leading-relaxed">
          This link is missing or malformed. Please request a new one.
        </p>
        <Link href="/forgot-password" className="mt-6 inline-flex items-center gap-2 text-xs font-bold text-[#12463E] hover:text-[#0B2B26]">
          <ArrowLeft className="h-3.5 w-3.5" />
          Request a new link
        </Link>
      </div>
    )
  }

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const errs: Record<string, string> = {}
    if (password.length < 6) errs.password = "Password must be at least 6 characters"
    if (password !== confirm) errs.confirm = "Passwords do not match"
    setErrors(errs)
    if (Object.keys(errs).length) return

    setSubmitting(true)
    try {
      await resetPassword(token, password)
      setDone(true)
      setTimeout(() => router.push("/login"), 2500)
    } catch (err: any) {
      setErrors({ form: err.message || "Failed to reset password. Please request a new link." })
    } finally {
      setSubmitting(false)
    }
  }

  if (done) {
    return (
      <div className="text-center py-4">
        <div className="mx-auto w-16 h-16 rounded-full bg-emerald-50 border border-emerald-200 flex items-center justify-center mb-4">
          <CheckCircle2 className="h-8 w-8 text-emerald-600" />
        </div>
        <h1 className="text-xl font-extrabold text-[#0B2B26] tracking-tight">Password updated!</h1>
        <p className="text-sm text-[#6B8078] mt-2 leading-relaxed">
          You can now sign in with your new password. Redirecting to login...
        </p>
      </div>
    )
  }

  return (
    <>
      <h1 className="text-[22px] font-extrabold text-[#0B2B26] tracking-tight">Create a new password</h1>
      <p className="text-sm text-[#6B8078] mt-1">
        Set the password you&apos;ll use to sign in to your portal.
      </p>

      <form onSubmit={submit} className="space-y-4 mt-6">
        {errors.form && (
          <p className="text-xs text-[#C4392A] flex items-center gap-1.5 bg-red-50 border border-red-100 rounded-xl px-3 py-2">
            <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
            {errors.form}
          </p>
        )}

        <div className="space-y-1.5">
          <label htmlFor="password" className="text-[13px] font-semibold text-[#12463E] tracking-wide">
            New password
          </label>
          <div className="relative group">
            <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#6B8078] group-focus-within:text-[#12463E] transition-colors">
              <Lock className="h-4 w-4" strokeWidth={2} />
            </div>
            <input
              id="password"
              type={showPassword ? "text" : "password"}
              placeholder="At least 6 characters"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full h-12 pl-10 pr-10 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-[#12463E]/20 focus:border-[#12463E] transition-all"
            />
            <button
              type="button"
              tabIndex={-1}
              onClick={() => setShowPassword((v) => !v)}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#9CAEA6] hover:text-[#12463E] transition-colors"
            >
              {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
            </button>
          </div>
          {errors.password && (
            <p className="text-xs text-[#C4392A] flex items-center gap-1.5 pl-0.5">
              <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
              {errors.password}
            </p>
          )}
        </div>

        <div className="space-y-1.5">
          <label htmlFor="confirm" className="text-[13px] font-semibold text-[#12463E] tracking-wide">
            Confirm password
          </label>
          <div className="relative group">
            <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#6B8078] group-focus-within:text-[#12463E] transition-colors">
              <Lock className="h-4 w-4" strokeWidth={2} />
            </div>
            <input
              id="confirm"
              type={showPassword ? "text" : "password"}
              placeholder="Re-enter your password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              className="w-full h-12 pl-10 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-[#12463E]/20 focus:border-[#12463E] transition-all"
            />
          </div>
          {errors.confirm && (
            <p className="text-xs text-[#C4392A] flex items-center gap-1.5 pl-0.5">
              <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
              {errors.confirm}
            </p>
          )}
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full h-12 rounded-xl bg-[#12463E] hover:bg-[#0B2B26] text-white font-semibold text-sm shadow-lg shadow-[#12463E]/25 transition-all flex items-center justify-center gap-2 disabled:opacity-70"
        >
          {submitting ? "Saving..." : (
            <>
              Set password
              <ShieldCheck className="h-4 w-4" />
            </>
          )}
        </button>
      </form>
    </>
  )
}

export default function ResetPasswordPage() {
  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-[#F8FAF9] relative overflow-hidden p-6">
      <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-emerald-100/40 rounded-full blur-[120px] -translate-y-1/2 translate-x-1/4" />
      <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-teal-50/60 rounded-full blur-[100px] translate-y-1/3 -translate-x-1/4" />

      <div className="relative z-10 w-full max-w-[420px]">
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
          <div className="px-8 pt-8 pb-8">
            <Suspense fallback={<p className="text-sm text-[#6B8078] text-center py-8">Loading...</p>}>
              <ResetPasswordForm />
            </Suspense>
          </div>
        </div>
      </div>
    </div>
  )
}
