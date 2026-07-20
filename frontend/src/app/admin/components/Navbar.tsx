"use client"

import React, { useState, useEffect } from "react"
import { Bell, Search, Clock, Activity, AlertCircle, ChevronDown, Check, ShieldAlert } from "lucide-react"

interface NavbarProps {
  activeTab: string
}

interface ClinicalAlert {
  id: string
  title: string
  description: string
  time: string
  read: boolean
  type: "info" | "success" | "critical"
}

export function Navbar({ activeTab }: NavbarProps) {
  const [currentTime, setCurrentTime] = useState("")
  const [showNotifications, setShowNotifications] = useState(false)
  
  const [alerts, setAlerts] = useState<ClinicalAlert[]>([
    {
      id: "1",
      title: "ICU Telemetry Alert",
      description: "Robert Downey Jr. (Bed ICU-101) blood pressure spike.",
      time: "Just now",
      read: false,
      type: "critical"
    },
    {
      id: "2",
      title: "ER Patient Admitted",
      description: "Liam Neeson admitted to Bed ER-201 with cardiac concerns.",
      time: "12 mins ago",
      read: false,
      type: "info"
    },
    {
      id: "3",
      title: "Lab Results Prepared",
      description: "Emma Watson's blood sample CBC results are ready in the system.",
      time: "30 mins ago",
      read: false,
      type: "success"
    }
  ])

  useEffect(() => {
    const updateTime = () => {
      const now = new Date()
      setCurrentTime(
        now.toLocaleTimeString("en-US", {
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
          hour12: true
        })
      )
    }
    updateTime()
    const timer = setInterval(updateTime, 1000)
    return () => clearInterval(timer)
  }, [])

  const markAllRead = () => {
    setAlerts(alerts.map(a => ({ ...a, read: true })))
  }

  const unreadCount = alerts.filter(a => !a.read).length

  const getTitle = () => {
    switch (activeTab) {
      case "overview": return "Clinical Overview"
      case "beds": return "Ward Bed Management"
      case "admissions": return "Admissions Registry"
      case "doctors": return "Medical Staff Ledger"
      case "tasks": return "Nursing Orders & Telemetry"
      case "settings": return "Medical Console Configs"
      default: return "Dashboard"
    }
  }

  return (
    <header className="h-20 bg-white border-b border-[#E8ECEB] flex items-center justify-between px-8 sticky top-0 z-30 shadow-xs">
      {/* Title */}
      <div>
        <h1 className="text-xl font-bold text-[#0B2B26] tracking-tight">{getTitle()}</h1>
        <p className="text-xs text-[#6B8078] mt-0.5">Aura Medical Center Administration Console</p>
      </div>

      {/* Right controls */}
      <div className="flex items-center gap-6">
        {/* Search */}
        <div className="relative w-64 max-lg:hidden">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-[#8AA098]" />
          <input
            type="text"
            placeholder="Search patients, wards, doctors..."
            className="w-full h-10 pl-10 pr-4 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
          />
        </div>

        {/* Live Clock */}
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#EEF4F1] border border-[#D7E2DC] text-[#12463E] font-medium text-xs tabular-nums">
          <Clock className="h-3.5 w-3.5 text-[#12463E]" />
          <span>{currentTime || "Loading..."}</span>
        </div>

        {/* Notifications Icon with Dropdown */}
        <div className="relative">
          <button
            onClick={() => setShowNotifications(!showNotifications)}
            className="relative w-10 h-10 rounded-xl hover:bg-[#EEF4F1] border border-[#E8ECEB] flex items-center justify-center transition-all text-[#4B5F58] hover:text-[#12463E]"
          >
            <Bell className="h-5 w-5" />
            {unreadCount > 0 && (
              <span className="absolute top-1 right-1 w-4 h-4 bg-rose-500 border-2 border-white rounded-full text-[9px] font-bold text-white flex items-center justify-center animate-pulse">
                {unreadCount}
              </span>
            )}
          </button>

          {/* Notifications Dropdown */}
          {showNotifications && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setShowNotifications(false)} />
              <div className="absolute right-0 mt-2.5 w-80 bg-white rounded-2xl border border-[#E8ECEB] shadow-xl z-50 overflow-hidden animate-fade-in">
                <div className="p-4 bg-[#EEF4F1] border-b border-[#D7E2DC] flex items-center justify-between">
                  <span className="text-xs font-bold text-[#0B2B26]">Medical System Alerts</span>
                  {unreadCount > 0 && (
                    <button
                      onClick={markAllRead}
                      className="text-[10px] text-[#12463E] font-bold hover:underline flex items-center gap-1"
                    >
                      <Check className="h-3 w-3" /> Mark all read
                    </button>
                  )}
                </div>

                <div className="divide-y divide-[#E8ECEB] max-h-80 overflow-y-auto">
                  {alerts.map((a) => (
                    <div
                      key={a.id}
                      className={`p-4 hover:bg-[#F6F8F7] transition-all flex gap-3 ${
                        !a.read ? "bg-[#EEF4F1]/30 font-medium" : ""
                      }`}
                    >
                      <div className="mt-0.5">
                        {a.type === "critical" && (
                          <div className="p-1 rounded-md bg-rose-50 text-rose-600 animate-pulse">
                            <ShieldAlert className="h-4 w-4" />
                          </div>
                        )}
                        {a.type === "info" && (
                          <div className="p-1 rounded-md bg-blue-50 text-blue-600">
                            <Activity className="h-4 w-4" />
                          </div>
                        )}
                        {a.type === "success" && (
                          <div className="p-1 rounded-md bg-emerald-50 text-emerald-600">
                            <Check className="h-4 w-4" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-bold text-[#0B2B26]">{a.title}</p>
                        <p className="text-[11px] text-[#6B8078] mt-0.5 leading-relaxed">{a.description}</p>
                        <span className="text-[9px] text-[#9CAEA6] block mt-1">{a.time}</span>
                      </div>
                    </div>
                  ))}
                </div>

                <div className="p-3 text-center bg-[#F6F8F7] border-t border-[#E8ECEB]">
                  <p className="text-[10px] text-[#8AA098] font-medium">ER & ICU Telemetry Status: Connected</p>
                </div>
              </div>
            </>
          )}
        </div>

        {/* ER status */}
        <div className="flex items-center gap-2 max-sm:hidden text-xs text-rose-700 bg-rose-50 px-3.5 py-2 rounded-xl border border-rose-100 font-bold">
          <span className="w-2 h-2 bg-rose-500 rounded-full animate-ping" />
          <span>ER Capacity: 80%</span>
        </div>
      </div>
    </header>
  )
}
