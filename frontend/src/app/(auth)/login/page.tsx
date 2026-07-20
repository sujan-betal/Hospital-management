"use client"

import { useState } from "react"
import Link from "next/link"
import { Activity, Smartphone, ShieldCheck } from "lucide-react"
import { PatientLoginForm } from "@/features/auth/components/patient-login-form"
import { StaffLoginForm } from "@/features/auth/components/staff-login-form"

function PulseDivider() {
  return (
    <svg viewBox="0 0 300 40" className="w-full h-8" preserveAspectRatio="none">
      <polyline
        points="0,20 60,20 75,20 85,4 95,36 105,20 120,20 300,20"
        fill="none"
        stroke="#E85C4A"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="pulse-line"
      />
    </svg>
  )
}

export default function LoginPage() {
  const [tab, setTab] = useState<"patient" | "staff">("patient")

  return (
    <div className="min-h-screen w-full relative flex items-center justify-center p-6 overflow-hidden bg-[#0B2B26]">
      <style jsx global>{`
        @keyframes pulseFlow { 0% { stroke-dashoffset: 300; } 100% { stroke-dashoffset: 0; } }
        .pulse-line { stroke-dasharray: 300; animation: pulseFlow 2.4s linear infinite; }
      `}</style>

      <div className="absolute inset-0">
        <img
          src="https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=1600&q=80"
          alt=""
          className="w-full h-full object-cover opacity-40"
        />
        <div className="absolute inset-0 bg-gradient-to-br from-[#0B2B26] via-[#0B2B26]/90 to-[#12463E]/80" />
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(232,92,74,0.10),transparent_45%)]" />
      </div>

      <div className="relative w-full max-w-md">
        <div className="rounded-3xl bg-white/[0.97] backdrop-blur-xl shadow-2xl shadow-black/40 overflow-hidden">
          <div className="px-8 pt-10 pb-6 text-center bg-gradient-to-b from-[#EEF4F1] to-transparent">
            <div className="flex justify-center mb-5">
              <div className="relative">
                <div className="absolute inset-0 bg-[#12463E] rounded-2xl blur-lg opacity-30 scale-110" />
                <div className="relative flex items-center justify-center w-16 h-16 rounded-2xl bg-[#12463E] shadow-lg shadow-[#12463E]/30 ring-1 ring-white/20">
                  <Activity className="h-8 w-8 text-white" strokeWidth={2.5} />
                </div>
              </div>
            </div>
            <h1 className="text-2xl font-bold text-[#0B2B26] tracking-tight">Medical Hospital</h1>
            <p className="text-[#6B8078] text-sm mt-1.5">Sign in to access your account</p>
          </div>

          <div className="px-3">
            <PulseDivider />
          </div>

          <div className="px-8 pb-8 pt-2">
            <div className="relative grid grid-cols-2 mb-6 bg-[#EEF4F1] p-1 rounded-xl h-11">
              <div
                className="absolute top-1 bottom-1 w-[calc(50%-4px)] rounded-lg bg-white shadow-sm transition-transform duration-300 ease-out"
                style={{ transform: tab === "staff" ? "translateX(calc(100% + 8px))" : "translateX(0)" }}
              />
              <button
                onClick={() => setTab("patient")}
                className={`relative z-10 flex items-center justify-center gap-2 text-sm font-medium transition-colors ${
                  tab === "patient" ? "text-[#12463E] font-semibold" : "text-[#8AA098]"
                }`}
              >
                <Smartphone className="h-4 w-4" />
                Patient
              </button>
              <button
                onClick={() => setTab("staff")}
                className={`relative z-10 flex items-center justify-center gap-2 text-sm font-medium transition-colors ${
                  tab === "staff" ? "text-[#12463E] font-semibold" : "text-[#8AA098]"
                }`}
              >
                <ShieldCheck className="h-4 w-4" />
                Staff
              </button>
            </div>

            {tab === "patient" ? <PatientLoginForm /> : <StaffLoginForm />}
          </div>
        </div>

        <p className="text-center text-white/50 text-xs mt-6">
          Protected by end-to-end encryption · Medical Health Systems
        </p>

        <div className="text-center mt-4">
          <Link
            href="/admin"
            className="inline-flex items-center gap-1.5 text-xs text-[#E8BA60] hover:text-[#E8BA60]/80 font-bold bg-white/5 hover:bg-white/10 px-4 py-2 rounded-xl transition-all border border-white/10"
          >
            Bypass to Admin Dashboard Demo →
          </Link>
        </div>
      </div>
    </div>
  )
}