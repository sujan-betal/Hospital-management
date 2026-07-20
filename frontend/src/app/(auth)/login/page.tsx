"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import {
  Activity,
  Smartphone,
  ShieldCheck,
  HeartPulse,
  Stethoscope,
  Pill,
  Syringe,
  Cross,
  Thermometer,
  CircleDot,
  Sparkles
} from "lucide-react"
import { PatientLoginForm } from "@/features/auth/components/patient-login-form"
import { StaffLoginForm } from "@/features/auth/components/staff-login-form"

/* ─── Animated heartbeat SVG line ────────────────────────── */
function HeartbeatLine() {
  return (
    <svg viewBox="0 0 400 60" className="w-full h-10" preserveAspectRatio="none">
      <defs>
        <linearGradient id="pulse-grad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="#10b981" stopOpacity="0" />
          <stop offset="40%" stopColor="#10b981" stopOpacity="1" />
          <stop offset="60%" stopColor="#34d399" stopOpacity="1" />
          <stop offset="100%" stopColor="#10b981" stopOpacity="0" />
        </linearGradient>
      </defs>
      <polyline
        points="0,30 80,30 100,30 115,30 125,8 135,52 145,30 160,30 180,30 195,30 205,12 215,48 225,30 240,30 400,30"
        fill="none"
        stroke="url(#pulse-grad)"
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="heartbeat-line"
      />
      {/* Faint shadow line */}
      <polyline
        points="0,30 80,30 100,30 115,30 125,8 135,52 145,30 160,30 180,30 195,30 205,12 215,48 225,30 240,30 400,30"
        fill="none"
        stroke="#10b981"
        strokeWidth="6"
        strokeLinecap="round"
        strokeLinejoin="round"
        opacity="0.15"
        className="heartbeat-line"
      />
    </svg>
  )
}

/* ─── Floating medical icon particles on left panel ──────── */
function FloatingParticles() {
  const particles = [
    { Icon: HeartPulse, x: "12%", y: "18%", delay: "0s", size: "h-5 w-5", opacity: "0.15" },
    { Icon: Stethoscope, x: "75%", y: "12%", delay: "1.2s", size: "h-6 w-6", opacity: "0.12" },
    { Icon: Pill, x: "25%", y: "72%", delay: "2.5s", size: "h-4 w-4", opacity: "0.18" },
    { Icon: Syringe, x: "80%", y: "65%", delay: "0.8s", size: "h-5 w-5", opacity: "0.10" },
    { Icon: Cross, x: "55%", y: "85%", delay: "3.2s", size: "h-6 w-6", opacity: "0.12" },
    { Icon: Thermometer, x: "40%", y: "25%", delay: "1.8s", size: "h-4 w-4", opacity: "0.15" },
    { Icon: CircleDot, x: "65%", y: "42%", delay: "2.2s", size: "h-3 w-3", opacity: "0.20" },
    { Icon: HeartPulse, x: "88%", y: "35%", delay: "0.5s", size: "h-4 w-4", opacity: "0.14" },
    { Icon: Cross, x: "18%", y: "50%", delay: "3.8s", size: "h-3 w-3", opacity: "0.16" },
    { Icon: Pill, x: "50%", y: "55%", delay: "1.5s", size: "h-5 w-5", opacity: "0.10" },
  ]

  return (
    <>
      {particles.map((p, i) => (
        <div
          key={i}
          className="absolute text-white animate-float-particle"
          style={{
            left: p.x,
            top: p.y,
            animationDelay: p.delay,
            opacity: p.opacity,
          }}
        >
          <p.Icon className={p.size} />
        </div>
      ))}
    </>
  )
}

/* ─── Live clock ─────────────────────────────────────────── */
function LiveClock() {
  const [time, setTime] = useState("")
  const [date, setDate] = useState("")

  useEffect(() => {
    const tick = () => {
      const now = new Date()
      setTime(now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: true }))
      setDate(now.toLocaleDateString("en-IN", { weekday: "long", year: "numeric", month: "long", day: "numeric" }))
    }
    tick()
    const id = setInterval(tick, 1000)
    return () => clearInterval(id)
  }, [])

  return (
    <div className="text-center">
      <p className="text-3xl font-black text-white tracking-tight tabular-nums">{time}</p>
      <p className="text-sm text-white/50 mt-1 font-medium">{date}</p>
    </div>
  )
}

/* ─── Stats pill ─────────────────────────────────────────── */
function StatPill({ label, value, pulse }: { label: string; value: string; pulse?: boolean }) {
  return (
    <div className="flex items-center gap-3 bg-white/[0.07] backdrop-blur-sm border border-white/[0.08] rounded-2xl px-4 py-3">
      <div className={`w-2.5 h-2.5 rounded-full ${pulse ? "bg-emerald-400 animate-pulse" : "bg-white/30"}`} />
      <div>
        <p className="text-[11px] text-white/40 font-medium uppercase tracking-wider">{label}</p>
        <p className="text-sm font-bold text-white/90 mt-0.5">{value}</p>
      </div>
    </div>
  )
}

/* ═══════════════════════════════════════════════════════════ */
/*  MAIN LOGIN PAGE                                          */
/* ═══════════════════════════════════════════════════════════ */
export default function LoginPage() {
  const [tab, setTab] = useState<"patient" | "staff">("patient")
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  return (
    <div className="min-h-screen w-full flex bg-[#050E0C]">
      {/* ─── INLINE STYLES for complex animations ─── */}
      <style jsx global>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap');

        @keyframes heartbeat-flow {
          0% { stroke-dashoffset: 800; }
          100% { stroke-dashoffset: 0; }
        }
        .heartbeat-line {
          stroke-dasharray: 800;
          animation: heartbeat-flow 3s linear infinite;
        }

        @keyframes float-particle {
          0%, 100% { transform: translateY(0) rotate(0deg); }
          25% { transform: translateY(-18px) rotate(5deg); }
          50% { transform: translateY(-8px) rotate(-3deg); }
          75% { transform: translateY(-22px) rotate(2deg); }
        }
        .animate-float-particle {
          animation: float-particle 8s ease-in-out infinite;
        }

        @keyframes shimmer {
          0% { background-position: -200% 0; }
          100% { background-position: 200% 0; }
        }

        @keyframes glow-ring {
          0%, 100% { box-shadow: 0 0 20px rgba(16,185,129,0.15), 0 0 60px rgba(16,185,129,0.05); }
          50% { box-shadow: 0 0 30px rgba(16,185,129,0.25), 0 0 80px rgba(16,185,129,0.10); }
        }

        @keyframes slide-up {
          from { opacity: 0; transform: translateY(30px); }
          to { opacity: 1; transform: translateY(0); }
        }

        @keyframes slide-right {
          from { opacity: 0; transform: translateX(-40px); }
          to { opacity: 1; transform: translateX(0); }
        }

        @keyframes scale-in {
          from { opacity: 0; transform: scale(0.9); }
          to { opacity: 1; transform: scale(1); }
        }

        .anim-slide-up { animation: slide-up 0.7s cubic-bezier(0.16,1,0.3,1) both; }
        .anim-slide-up-d1 { animation: slide-up 0.7s cubic-bezier(0.16,1,0.3,1) 0.1s both; }
        .anim-slide-up-d2 { animation: slide-up 0.7s cubic-bezier(0.16,1,0.3,1) 0.2s both; }
        .anim-slide-up-d3 { animation: slide-up 0.7s cubic-bezier(0.16,1,0.3,1) 0.3s both; }
        .anim-slide-up-d4 { animation: slide-up 0.7s cubic-bezier(0.16,1,0.3,1) 0.4s both; }
        .anim-slide-up-d5 { animation: slide-up 0.7s cubic-bezier(0.16,1,0.3,1) 0.5s both; }
        .anim-slide-right { animation: slide-right 0.8s cubic-bezier(0.16,1,0.3,1) both; }
        .anim-scale-in { animation: scale-in 0.6s cubic-bezier(0.16,1,0.3,1) 0.15s both; }

        .login-card {
          font-family: 'Inter', system-ui, -apple-system, sans-serif;
        }

        .tab-slider {
          transition: transform 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
        }

        .gradient-border {
          background: linear-gradient(135deg, rgba(16,185,129,0.3), rgba(52,211,153,0.1), rgba(16,185,129,0.3));
          background-size: 200% 200%;
          animation: shimmer 4s ease-in-out infinite;
        }
      `}</style>

      {/* ═══════════════════════════════════════════════════ */}
      {/*  LEFT PANEL — Branding & Ambient Visuals           */}
      {/* ═══════════════════════════════════════════════════ */}
      <div className="hidden lg:flex flex-col w-[55%] relative overflow-hidden bg-gradient-to-br from-[#0B2B26] via-[#0F3D35] to-[#0B2B26]">
        {/* Deep layered gradient orbs */}
        <div className="absolute -top-40 -left-40 w-[700px] h-[700px] bg-emerald-600/[0.08] rounded-full blur-[150px]" />
        <div className="absolute -bottom-60 -right-40 w-[600px] h-[600px] bg-teal-500/[0.06] rounded-full blur-[140px]" />
        <div className="absolute top-1/3 right-1/4 w-[400px] h-[400px] bg-emerald-400/[0.04] rounded-full blur-[120px] animate-pulse-slow" />

        {/* Dot-grid pattern overlay */}
        <div className="absolute inset-0 bg-[radial-gradient(circle,rgba(255,255,255,0.03)_1px,transparent_1px)] bg-[size:32px_32px]" />

        {/* Floating medical particles */}
        <FloatingParticles />

        {/* Content */}
        <div className="relative z-10 flex flex-col justify-between h-full p-12">
          {/* Top — Brand */}
          <div className={mounted ? "anim-slide-right" : "opacity-0"}>
            <div className="flex items-center gap-4">
              <div className="relative">
                <div className="absolute inset-0 rounded-2xl bg-emerald-500/20 blur-xl scale-150" />
                <div className="relative w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-500 to-emerald-700 flex items-center justify-center shadow-xl shadow-emerald-900/30" style={{ animation: "glow-ring 3s ease-in-out infinite" }}>
                  <Activity className="h-7 w-7 text-white" strokeWidth={2.5} />
                </div>
              </div>
              <div>
                <h2 className="text-xl font-black text-white tracking-tight">AURA Medical</h2>
                <p className="text-xs text-emerald-400/70 font-semibold tracking-widest uppercase">Hospital Management System</p>
              </div>
            </div>
          </div>

          {/* Center — Hero messaging */}
          <div className="flex-1 flex flex-col justify-center max-w-lg">
            <div className={mounted ? "anim-slide-up" : "opacity-0"}>
              <div className="inline-flex items-center gap-2 bg-emerald-500/10 border border-emerald-500/20 rounded-full px-4 py-1.5 mb-6">
                <Sparkles className="h-3.5 w-3.5 text-emerald-400" />
                <span className="text-[11px] text-emerald-400 font-bold uppercase tracking-wider">Trusted by 200+ Hospitals</span>
              </div>
            </div>

            <h1 className={`text-5xl font-black text-white leading-[1.1] tracking-tight ${mounted ? "anim-slide-up-d1" : "opacity-0"}`}>
              Smart Healthcare,{" "}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 via-teal-300 to-emerald-400">
                Simplified.
              </span>
            </h1>

            <p className={`text-base text-white/40 leading-relaxed mt-5 max-w-md ${mounted ? "anim-slide-up-d2" : "opacity-0"}`}>
              Streamline patient care, manage clinical workflows, and monitor real-time hospital operations — all from one intelligent dashboard.
            </p>

            {/* Heartbeat line */}
            <div className={`mt-8 ${mounted ? "anim-slide-up-d3" : "opacity-0"}`}>
              <HeartbeatLine />
            </div>

            {/* Stats row */}
            <div className={`grid grid-cols-3 gap-3 mt-6 ${mounted ? "anim-slide-up-d4" : "opacity-0"}`}>
              <StatPill label="Uptime" value="99.97%" pulse />
              <StatPill label="Response" value="< 200ms" />
              <StatPill label="Data" value="AES-256" />
            </div>
          </div>

          {/* Bottom — Live clock */}
          <div className={mounted ? "anim-slide-up-d5" : "opacity-0"}>
            <LiveClock />
          </div>
        </div>

        {/* Vertical emerald accent strip on right edge */}
        <div className="absolute right-0 top-0 bottom-0 w-[2px] gradient-border" />
      </div>

      {/* ═══════════════════════════════════════════════════ */}
      {/*  RIGHT PANEL — Login Form                          */}
      {/* ═══════════════════════════════════════════════════ */}
      <div className="flex-1 flex items-center justify-center relative overflow-hidden p-6 bg-gradient-to-br from-[#F8FAF9] via-white to-[#F0F5F3]">
        {/* Subtle background decoration */}
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-emerald-100/40 rounded-full blur-[120px] -translate-y-1/2 translate-x-1/4" />
        <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-teal-50/60 rounded-full blur-[100px] translate-y-1/3 -translate-x-1/4" />

        {/* Faint grid */}
        <div className="absolute inset-0 bg-[linear-gradient(rgba(16,185,129,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(16,185,129,0.03)_1px,transparent_1px)] bg-[size:48px_48px]" />

        <div className={`relative z-10 w-full max-w-[420px] login-card ${mounted ? "anim-scale-in" : "opacity-0"}`}>
          {/* Mobile-only brand header (hidden on desktop since left panel shows it) */}
          <div className="lg:hidden flex flex-col items-center mb-8">
            <div className="relative">
              <div className="absolute inset-0 rounded-2xl bg-emerald-500/20 blur-xl scale-150" />
              <div className="relative w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-500 to-emerald-700 flex items-center justify-center shadow-xl">
                <Activity className="h-7 w-7 text-white" strokeWidth={2.5} />
              </div>
            </div>
            <h2 className="text-lg font-black text-[#0B2B26] mt-3 tracking-tight">AURA Medical</h2>
            <p className="text-xs text-[#8AA098] font-medium">Hospital Management System</p>
          </div>

          {/* Card container */}
          <div className="rounded-[28px] bg-white/80 backdrop-blur-xl shadow-[0_8px_60px_rgba(11,43,38,0.08)] border border-white/60 overflow-hidden">
            {/* Card header */}
            <div className="px-8 pt-9 pb-5">
              <h1 className="text-[22px] font-extrabold text-[#0B2B26] tracking-tight">Welcome back</h1>
              <p className="text-sm text-[#6B8078] mt-1">Sign in to access your medical portal</p>
            </div>

            {/* Heartbeat divider */}
            <div className="px-6 -my-1">
              <HeartbeatLine />
            </div>

            {/* Form body */}
            <div className="px-8 pb-8 pt-2">
              {/* Tab switcher */}
              <div className="relative grid grid-cols-2 mb-7 bg-[#EEF4F1] p-1.5 rounded-2xl h-12">
                <div
                  className="absolute top-1.5 bottom-1.5 w-[calc(50%-6px)] rounded-xl bg-white shadow-md shadow-emerald-900/5 tab-slider"
                  style={{ transform: tab === "staff" ? "translateX(calc(100% + 12px))" : "translateX(0)" }}
                />
                <button
                  onClick={() => setTab("patient")}
                  className={`relative z-10 flex items-center justify-center gap-2.5 text-sm font-semibold transition-colors duration-200 rounded-xl ${
                    tab === "patient" ? "text-[#12463E]" : "text-[#8AA098] hover:text-[#6B8078]"
                  }`}
                >
                  <Smartphone className="h-4 w-4" />
                  Patient
                </button>
                <button
                  onClick={() => setTab("staff")}
                  className={`relative z-10 flex items-center justify-center gap-2.5 text-sm font-semibold transition-colors duration-200 rounded-xl ${
                    tab === "staff" ? "text-[#12463E]" : "text-[#8AA098] hover:text-[#6B8078]"
                  }`}
                >
                  <ShieldCheck className="h-4 w-4" />
                  Staff
                </button>
              </div>

              {/* Form views */}
              <div key={tab} className="animate-fade-in">
                {tab === "patient" ? <PatientLoginForm /> : <StaffLoginForm />}
              </div>
            </div>
          </div>

          {/* Bottom links */}
          <div className="mt-6 space-y-4">
            <div className="border-t border-[#EEF4F1] pt-4">
              <p className="text-center text-[11px] font-bold text-[#8AA098] uppercase tracking-wider mb-2.5">
                Quick Demo Access Portals
              </p>
              <div className="grid grid-cols-2 gap-2">
                <Link
                  href="/patient"
                  className="flex items-center justify-center gap-2 text-xs text-emerald-800 font-bold bg-emerald-50/50 hover:bg-emerald-100/80 px-3 py-2 rounded-xl transition-all border border-emerald-100 hover:border-emerald-200 shadow-xs"
                >
                  <Smartphone className="h-3.5 w-3.5" />
                  Patient Panel
                </Link>
                <Link
                  href="/doctor"
                  className="flex items-center justify-center gap-2 text-xs text-emerald-800 font-bold bg-emerald-50/50 hover:bg-emerald-100/80 px-3 py-2 rounded-xl transition-all border border-emerald-100 hover:border-emerald-200 shadow-xs"
                >
                  <Stethoscope className="h-3.5 w-3.5" />
                  Doctor Panel
                </Link>
                <Link
                  href="/receptionist"
                  className="flex items-center justify-center gap-2 text-xs text-emerald-800 font-bold bg-emerald-50/50 hover:bg-emerald-100/80 px-3 py-2 rounded-xl transition-all border border-emerald-100 hover:border-emerald-200 shadow-xs"
                >
                  <ShieldCheck className="h-3.5 w-3.5" />
                  Receptionist
                </Link>
                <Link
                  href="/admin"
                  className="flex items-center justify-center gap-2 text-xs text-white font-bold bg-[#12463E] hover:bg-[#0B2B26] px-3 py-2 rounded-xl transition-all border border-[#1E5D52] shadow-xs"
                >
                  <Activity className="h-3.5 w-3.5" />
                  Admin Console
                </Link>
              </div>
            </div>

            <p className="text-center text-[10px] text-[#8AA098] flex items-center justify-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Protected by end-to-end encryption · HIPAA Compliant
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}