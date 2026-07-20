"use client"

import React from "react"
import {
  LayoutDashboard,
  Bed,
  CalendarRange,
  Users,
  Activity,
  Settings,
  LogOut,
  Stethoscope,
  KeyRound
} from "lucide-react"

interface SidebarProps {
  activeTab: string
  setActiveTab: (tab: string) => void
}

export function Sidebar({ activeTab, setActiveTab }: SidebarProps) {
  const menuItems = [
    { id: "overview", label: "Overview Dashboard", icon: LayoutDashboard },
    { id: "beds", label: "Wards & Bed Status", icon: Bed },
    { id: "admissions", label: "Patient Admissions", icon: CalendarRange },
    { id: "doctors", label: "Attending Doctors", icon: Stethoscope },
    { id: "tasks", label: "Nursing & Medical Tasks", icon: Activity },
    { id: "credentials", label: "Staff Credentials", icon: KeyRound },
    { id: "settings", label: "Hospital Configs", icon: Settings },
  ]

  return (
    <aside className="w-72 bg-[#0C1E1A] border-r border-[#1B352E] flex flex-col justify-between h-screen sticky top-0 shrink-0 text-[#E5ECE9]">
      {/* Brand Section */}
      <div className="p-6">
        <div className="flex items-center gap-3 bg-gradient-to-r from-[#12463E] to-[#0A2622] p-4 rounded-2xl border border-[#1E5D52] shadow-lg">
          <div className="w-10 h-10 rounded-xl bg-emerald-500 flex items-center justify-center text-white shadow-md shadow-emerald-500/25 animate-pulse-slow">
            <Activity className="h-5.5 w-5.5" strokeWidth={2.5} />
          </div>
          <div>
            <h2 className="font-bold text-sm tracking-wide text-white leading-tight">AURA Medical</h2>
            <p className="text-[10px] text-emerald-400 font-semibold tracking-widest mt-0.5">ADMIN PORTAL</p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-4 space-y-1.5 overflow-y-auto py-2">
        <p className="px-3 text-[10px] font-bold text-[#8AA098] tracking-widest uppercase mb-3">Core Modules</p>
        
        {menuItems.map((item) => {
          const Icon = item.icon
          const isActive = activeTab === item.id

          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                isActive
                  ? "bg-emerald-500 text-white font-bold shadow-lg shadow-emerald-500/20"
                  : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {/* Active Accent Bar */}
              {isActive && (
                <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />
              )}
              
              <Icon
                className={`h-5 w-5 shrink-0 transition-transform group-hover:scale-105 ${
                  isActive ? "text-white" : "text-[#5C7D73] group-hover:text-white"
                }`}
                strokeWidth={isActive ? 2.5 : 2}
              />
              <span>{item.label}</span>
            </button>
          )
        })}
      </nav>

      {/* Footer / Account */}
      <div className="p-4 border-t border-[#1B352E] bg-[#071310]">
        <div className="flex items-center gap-3 p-2.5 rounded-xl hover:bg-[#12463E]/20 transition-all">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#12463E] to-[#1E5D52] flex items-center justify-center font-bold text-emerald-400 border border-[#1E5D52]">
            H
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold text-white truncate">Chief Administrator</p>
            <p className="text-[10px] text-[#5C7D73] truncate">admin@auramedical.org</p>
          </div>
        </div>

        <button 
          onClick={() => window.location.href = "/login"}
          className="w-full mt-3 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl border border-[#C4392A]/30 text-[#C4392A] hover:bg-[#C4392A]/10 text-xs font-semibold transition-all"
        >
          <LogOut className="h-3.5 w-3.5" />
          Sign Out
        </button>
      </div>
    </aside>
  )
}
