"use client"

import { useState, useEffect, useRef } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { Send, ShieldCheck, Smartphone, Check, ArrowRight } from "lucide-react"

import { patientLoginSchema, type PatientLoginFormData } from "../schemas/login-schema"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

export function PatientLoginForm() {
  const [otpSent, setOtpSent] = useState(false)
  const [countdown, setCountdown] = useState(0)
  const [captchaVerified, setCaptchaVerified] = useState(false)
  const otpInputRef = useRef<HTMLInputElement>(null)

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<PatientLoginFormData>({
    resolver: zodResolver(patientLoginSchema),
    defaultValues: {
      phone: "",
      otp: "",
    },
  })

  const phoneValue = watch("phone")
  const otpValue = watch("otp")
  const isPhoneValid = (phoneValue || "").length >= 10

  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000)
      return () => clearTimeout(timer)
    }
  }, [countdown])

  useEffect(() => {
    if (otpSent && otpInputRef.current) {
      otpInputRef.current.focus()
    }
  }, [otpSent])

  const onSubmit = async (data: PatientLoginFormData) => {
    await new Promise((r) => setTimeout(r, 1500))
    console.log("Patient login:", data)
  }

  const handleSendOtp = () => {
    setOtpSent(true)
    setCountdown(30)
  }

  const handleResendOtp = () => {
    setCountdown(30)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
      <div className="space-y-2">
        <Label htmlFor="phone" className="text-sm font-medium text-gray-700">
          Phone Number
        </Label>
        <div className="relative">
          <div className="absolute left-0 top-0 bottom-0 flex items-center pl-3 pointer-events-none">
            <Smartphone className="h-4 w-4 text-gray-400" />
          </div>
          <Input
            id="phone"
            type="tel"
            placeholder="+1 (555) 123-4567"
            className="pl-10 h-11 bg-gray-50 border-gray-200 focus:bg-white focus:border-blue-400 focus:ring-2 focus:ring-blue-100 transition-all rounded-xl"
            {...register("phone")}
          />
        </div>
        {errors.phone && (
          <p className="text-sm text-red-500 flex items-center gap-1 mt-1">
            <svg className="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" /></svg>
            {errors.phone.message}
          </p>
        )}
      </div>

      {!otpSent ? (
        <Button
          type="button"
          variant="outline"
          className="w-full gap-2 h-11 rounded-xl border-blue-200 text-blue-700 hover:bg-blue-50 hover:border-blue-300 transition-all"
          disabled={!isPhoneValid}
          onClick={handleSendOtp}
        >
          <Send className="h-4 w-4" />
          Send OTP
        </Button>
      ) : (
        <div className="animate-slide-down space-y-2">
          <Label htmlFor="otp" className="text-sm font-medium text-gray-700">
            One-Time Password
          </Label>
          <div className="relative">
            <Input
              ref={otpInputRef}
              id="otp"
              type="text"
              inputMode="numeric"
              maxLength={6}
              placeholder="Enter 6-digit OTP"
              className="h-11 bg-gray-50 border-gray-200 focus:bg-white focus:border-blue-400 focus:ring-2 focus:ring-blue-100 transition-all rounded-xl text-center text-lg font-mono tracking-[0.5em]"
              {...register("otp")}
            />
          </div>
          {errors.otp && (
            <p className="text-sm text-red-500 flex items-center gap-1 mt-1">
              <svg className="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" /></svg>
              {errors.otp.message}
            </p>
          )}
          <div className="flex items-center justify-between">
            <p className="text-xs text-gray-500">
              Didn&apos;t receive code?
            </p>
            {countdown > 0 ? (
              <span className="text-xs text-gray-400 font-medium">
                Resend in {countdown}s
              </span>
            ) : (
              <button
                type="button"
                onClick={handleResendOtp}
                className="text-xs text-blue-600 hover:text-blue-700 font-medium hover:underline"
              >
                Resend OTP
              </button>
            )}
          </div>
        </div>
      )}

      <div
        className={`rounded-xl border p-4 flex items-center gap-3 cursor-pointer transition-all ${
          captchaVerified
            ? "border-green-300 bg-green-50"
            : "border-gray-200 bg-gray-50 hover:bg-gray-100"
        }`}
        onClick={() => setCaptchaVerified(!captchaVerified)}
        role="checkbox"
        aria-checked={captchaVerified}
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === " " || e.key === "Enter") {
            e.preventDefault()
            setCaptchaVerified(!captchaVerified)
          }
        }}
      >
        <div
          className={`flex items-center justify-center w-9 h-9 rounded-lg border-2 transition-all shrink-0 ${
            captchaVerified
              ? "bg-blue-600 border-blue-600"
              : "bg-white border-gray-300"
          }`}
        >
          {captchaVerified && (
            <Check className="h-5 w-5 text-white" />
          )}
        </div>
        <div className="flex-1">
          <p className={`text-sm font-medium ${captchaVerified ? "text-green-700" : "text-gray-600"}`}>
            I&apos;m not a robot
          </p>
          <p className="text-xs text-gray-400">
            reCAPTCHA verification
          </p>
        </div>
        <div className="flex items-center gap-1">
          <ShieldCheck className={`h-5 w-5 ${captchaVerified ? "text-green-500" : "text-gray-300"}`} />
        </div>
      </div>

      <Button
        type="submit"
        className="w-full gap-2 h-11 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white shadow-lg shadow-blue-500/25 hover:shadow-blue-500/40 transition-all disabled:opacity-50"
        disabled={isSubmitting || !captchaVerified || (otpSent && !otpValue)}
      >
        {isSubmitting ? (
          <>
            <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
            Verifying...
          </>
        ) : (
          <>
            <ArrowRight className="h-4 w-4" />
            Verify & Login
          </>
        )}
      </Button>
    </form>
  )
}
