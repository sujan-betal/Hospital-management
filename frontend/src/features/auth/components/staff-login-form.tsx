"use client"

import { useState } from "react"
import { Eye, EyeOff, Lock, Mail, LogIn } from "lucide-react"
import { useRouter } from "next/navigation"

export function StaffLoginForm() {
  const router = useRouter()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const errs: Record<string, string> = {}
    if (!/^\S+@\S+\.\S+$/.test(email)) errs.email = "Enter a valid email address"
    if (password.length < 6) errs.password = "Password must be at least 6 characters"
    setErrors(errs)
    if (Object.keys(errs).length) return

    setSubmitting(true)
    await new Promise((r) => setTimeout(r, 1400))
    setSubmitting(false)
    router.push("/admin")
  }

  return (
    <form onSubmit={submit} className="space-y-4">
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
        {errors.email && (
          <p className="text-xs text-[#C4392A] flex items-center gap-1.5 pl-0.5">
            <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
            {errors.email}
          </p>
        )}
      </div>

      <div className="space-y-0.5">
        <div className="flex items-center justify-between">
          <label htmlFor="password" className="text-[13px] font-semibold text-[#12463E] tracking-wide">
            Password
          </label>

        </div>
        <div className="relative group">
          <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#6B8078] group-focus-within:text-[#12463E] transition-colors">
            <Lock className="h-4 w-4" strokeWidth={2} />
          </div>
          <input
            id="password"
            type={showPassword ? "text" : "password"}
            placeholder="Enter your password"
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
        <div className="text-right">
          <a
            href="/forgot-password"
            className="text-xs text-[#E85C4A] font-semibold hover:underline"
          >
            Forgot password?
          </a>
        </div>
        {errors.password && (
          <p className="text-xs text-[#C4392A] flex items-center gap-1.5 pl-0.5">
            <span className="w-1 h-1 rounded-full bg-[#C4392A]" />
            {errors.password}
          </p>
        )}
      </div>


      <button
        type="submit"
        disabled={submitting}
        className="w-full h-12 rounded-xl bg-[#12463E] hover:bg-[#0B2B26] text-white font-semibold text-sm shadow-lg shadow-[#12463E]/25 transition-all flex items-center justify-center gap-2 disabled:opacity-70"
      >
        {submitting ? "Signing in..." : (
          <>
            Sign in
            <LogIn className="h-4 w-4" />
          </>
        )}
      </button>

      <p className="text-center text-xs text-[#9CAEA6] pt-1">
        Contact your administrator if you need access
      </p>
    </form>
  )
}