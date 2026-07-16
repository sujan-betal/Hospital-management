"use client"

import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { Send, ShieldCheck, Smartphone } from "lucide-react"

import { patientLoginSchema, type PatientLoginFormData } from "../schemas/login-schema"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

export function PatientLoginForm() {
  const [otpSent, setOtpSent] = useState(false)

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
  const isPhoneValid = phoneValue.length >= 10

  const onSubmit = async (data: PatientLoginFormData) => {
    await new Promise((r) => setTimeout(r, 1000))
    console.log("Patient login:", data)
  }

  const handleSendOtp = () => {
    setOtpSent(true)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
      <div className="space-y-2">
        <Label htmlFor="phone">Phone Number</Label>
        <div className="relative">
          <Smartphone className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            id="phone"
            type="tel"
            placeholder="+1 (555) 123-4567"
            className="pl-10"
            {...register("phone")}
          />
        </div>
        {errors.phone && (
          <p className="text-sm text-destructive">{errors.phone.message}</p>
        )}
      </div>

      <Button
        type="button"
        variant="outline"
        className="w-full gap-2"
        disabled={!isPhoneValid || otpSent}
        onClick={handleSendOtp}
      >
        <Send className="h-4 w-4" />
        {otpSent ? "OTP Sent" : "Send OTP"}
      </Button>

      {otpSent && (
        <div className="space-y-2">
          <Label htmlFor="otp">One-Time Password</Label>
          <Input
            id="otp"
            type="text"
            inputMode="numeric"
            maxLength={6}
            placeholder="000000"
            className="tracking-[0.5em] text-center text-lg font-mono"
            {...register("otp")}
          />
          {errors.otp && (
            <p className="text-sm text-destructive">{errors.otp.message}</p>
          )}
        </div>
      )}

      <div className="rounded-lg border bg-muted/40 p-3 flex items-center gap-3">
        <div className="flex items-center justify-center w-8 h-8 rounded border bg-background shrink-0">
          <ShieldCheck className="h-4 w-4 text-primary" />
        </div>
        <div className="flex-1">
          <p className="text-xs font-medium text-muted-foreground">
            I&apos;m not a robot
          </p>
          <p className="text-[10px] text-muted-foreground/60">
            CAPTCHA verification
          </p>
        </div>
      </div>

      <Button type="submit" className="w-full gap-2" disabled={isSubmitting || (otpSent && !watch("otp"))}>
        <ShieldCheck className="h-4 w-4" />
        {isSubmitting ? "Verifying..." : "Verify & Login"}
      </Button>
    </form>
  )
}
