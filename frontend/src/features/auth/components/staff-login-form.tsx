"use client"

import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { Eye, EyeOff, Lock, Mail, ArrowRight, LogIn } from "lucide-react"
import Link from "next/link"

import { staffLoginSchema, type StaffLoginFormData } from "../schemas/login-schema"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

export function StaffLoginForm() {
  const [showPassword, setShowPassword] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<StaffLoginFormData>({
    resolver: zodResolver(staffLoginSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  })

  const onSubmit = async (data: StaffLoginFormData) => {
    await new Promise((r) => setTimeout(r, 1500))
    console.log("Staff login:", data)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
      <div className="space-y-2">
        <Label htmlFor="email" className="text-sm font-medium text-gray-700">
          Email Address
        </Label>
        <div className="relative">
          <div className="absolute left-0 top-0 bottom-0 flex items-center pl-3 pointer-events-none">
            <Mail className="h-4 w-4 text-gray-400" />
          </div>
          <Input
            id="email"
            type="email"
            placeholder="doctor@hospital.com"
            className="pl-10 h-11 bg-gray-50 border-gray-200 focus:bg-white focus:border-blue-400 focus:ring-2 focus:ring-blue-100 transition-all rounded-xl"
            {...register("email")}
          />
        </div>
        {errors.email && (
          <p className="text-sm text-red-500 flex items-center gap-1 mt-1">
            <svg className="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" /></svg>
            {errors.email.message}
          </p>
        )}
      </div>

      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <Label htmlFor="password" className="text-sm font-medium text-gray-700">
            Password
          </Label>
          <Link
            href="/forgot-password"
            className="text-xs text-blue-600 hover:text-blue-700 font-medium hover:underline"
          >
            Forgot password?
          </Link>
        </div>
        <div className="relative">
          <div className="absolute left-0 top-0 bottom-0 flex items-center pl-3 pointer-events-none">
            <Lock className="h-4 w-4 text-gray-400" />
          </div>
          <Input
            id="password"
            type={showPassword ? "text" : "password"}
            placeholder="••••••••"
            className="pl-10 pr-10 h-11 bg-gray-50 border-gray-200 focus:bg-white focus:border-blue-400 focus:ring-2 focus:ring-blue-100 transition-all rounded-xl"
            {...register("password")}
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute right-0 top-0 bottom-0 flex items-center pr-3 text-gray-400 hover:text-gray-600 transition-colors"
            tabIndex={-1}
          >
            {showPassword ? (
              <EyeOff className="h-4 w-4" />
            ) : (
              <Eye className="h-4 w-4" />
            )}
          </button>
        </div>
        {errors.password && (
          <p className="text-sm text-red-500 flex items-center gap-1 mt-1">
            <svg className="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" /></svg>
            {errors.password.message}
          </p>
        )}
      </div>

      <Button
        type="submit"
        className="w-full gap-2 h-11 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white shadow-lg shadow-blue-500/25 hover:shadow-blue-500/40 transition-all disabled:opacity-50"
        disabled={isSubmitting}
      >
        {isSubmitting ? (
          <>
            <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
            Signing in...
          </>
        ) : (
          <>
            <LogIn className="h-4 w-4" />
            Sign In
          </>
        )}
      </Button>
    </form>
  )
}
