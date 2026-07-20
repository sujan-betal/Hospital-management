"use client"

import React, { useState } from "react"
import {
  Building,
  CreditCard,
  Clock,
  Save,
  Percent,
  HeartPulse
} from "lucide-react"

export function HospitalSettings() {
  const [hospitalName, setHospitalName] = useState("AURA Medical Center & ICU")
  const [address, setAddress] = useState("456 Care Boulevard, Medical District, SF 94102")
  const [currency, setCurrency] = useState("INR (Rs.)")
  const [copayRate, setCopayRate] = useState(10) // 10% co-pay
  const [emergencyMarkup, setEmergencyMarkup] = useState(25) // +25% Emergency markup
  const [autoTelemetry, setAutoTelemetry] = useState(true)
  const [sanitationInterval, setSanitationInterval] = useState(12) // hours
  const [autoDirty, setAutoDirty] = useState(true)
  const [showToast, setShowToast] = useState(false)

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault()
    setShowToast(true)
    setTimeout(() => {
      setShowToast(false)
    }, 3000)
  }

  return (
    <div className="space-y-6 max-w-3xl animate-fade-in relative">
      <form onSubmit={handleSave} className="space-y-6">
        {/* Profile Card */}
        <div className="bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs">
          <div className="flex items-center gap-3 border-b border-[#E8ECEB] pb-4 mb-4">
            <Building className="h-5 w-5 text-emerald-600" />
            <h3 className="text-base font-bold text-[#0B2B26]">Hospital Facility Profile</h3>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-[#12463E]">Hospital Name</label>
              <input
                type="text"
                value={hospitalName}
                onChange={(e) => setHospitalName(e.target.value)}
                className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-bold text-[#12463E]">Base Currency</label>
              <select
                value={currency}
                onChange={(e) => setCurrency(e.target.value)}
                className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 cursor-not-allowed"
                disabled
              >
                <option value="INR (Rs.)">INR (Rs.) - Indian Rupee</option>
              </select>
            </div>

            <div className="col-span-2 space-y-1.5">
              <label className="text-xs font-bold text-[#12463E]">Facility Address</label>
              <input
                type="text"
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
              />
            </div>
          </div>
        </div>

        {/* Pricing Strategy Card */}
        <div className="bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs">
          <div className="flex items-center gap-3 border-b border-[#E8ECEB] pb-4 mb-4">
            <CreditCard className="h-5 w-5 text-emerald-600" />
            <h3 className="text-base font-bold text-[#0B2B26]">Co-pay &amp; Emergency Markups</h3>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-[#12463E]">Standard Co-pay (%)</label>
              <div className="relative">
                <Percent className="absolute left-3.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[#8AA098]" />
                <input
                  type="number"
                  value={copayRate}
                  onChange={(e) => setCopayRate(Number(e.target.value))}
                  className="w-full h-11 pl-10 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-bold text-[#12463E]">Emergency Bed Markup (%)</label>
              <div className="relative">
                <Percent className="absolute left-3.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[#8AA098]" />
                <input
                  type="number"
                  value={emergencyMarkup}
                  onChange={(e) => setEmergencyMarkup(Number(e.target.value))}
                  className="w-full h-11 pl-10 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                />
              </div>
            </div>

            <div className="col-span-2 flex items-center justify-between p-3.5 bg-[#EEF4F1] rounded-2xl border border-[#D7E2DC] mt-2">
              <div>
                <span className="text-xs font-bold text-[#0B2B26]">Enable Auto ICU Telemetry Monitoring</span>
                <span className="text-[10px] text-[#6B8078] block mt-0.5">Poll vital stats to central dashboard every 3s</span>
              </div>
              <button
                type="button"
                onClick={() => setAutoTelemetry(!autoTelemetry)}
                className={`w-12 h-6 rounded-full p-1 transition-colors duration-200 focus:outline-none ${
                  autoTelemetry ? "bg-emerald-500" : "bg-[#D7E2DC]"
                }`}
              >
                <div
                  className={`w-4 h-4 rounded-full bg-white transition-transform duration-200 ${
                    autoTelemetry ? "translate-x-6" : "translate-x-0"
                  }`}
                />
              </button>
            </div>
          </div>
        </div>

        {/* Operational Config */}
        <div className="bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs">
          <div className="flex items-center gap-3 border-b border-[#E8ECEB] pb-4 mb-4">
            <Clock className="h-5 w-5 text-emerald-600" />
            <h3 className="text-base font-bold text-[#0B2B26]">Ward Operations Settings</h3>
          </div>

          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-[#12463E]">Bed Sanitization Cycle</label>
                <select
                  value={sanitationInterval}
                  onChange={(e) => setSanitationInterval(Number(e.target.value))}
                  className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  <option value={6}>Every 6 Hours</option>
                  <option value={12}>Every 12 Hours (Standard)</option>
                  <option value={24}>Every 24 Hours</option>
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-[#12463E]">Auto-Sanitize Trigger</label>
                <select
                  value={autoDirty ? "on" : "off"}
                  onChange={(e) => setAutoDirty(e.target.value === "on")}
                  className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  <option value="on">Immediately on Inpatient Discharge</option>
                  <option value="off">Manual logs only</option>
                </select>
              </div>
            </div>
          </div>
        </div>

        {/* Save Button */}
        <button
          type="submit"
          className="w-full h-12 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm shadow-lg shadow-emerald-500/20 transition-all flex items-center justify-center gap-2"
        >
          <Save className="h-4.5 w-4.5" />
          Save System Configuration
        </button>
      </form>

      {/* Floating success toast */}
      {showToast && (
        <div className="fixed bottom-6 right-6 z-50 bg-[#12463E] text-white border border-emerald-600 rounded-2xl px-5 py-3.5 shadow-xl shadow-[#0B2B26]/30 flex items-center gap-3 animate-fade-in">
          <HeartPulse className="h-5 w-5 text-emerald-400 animate-bounce" />
          <div>
            <p className="text-xs font-black">Clinical Console Updated</p>
            <p className="text-[10px] text-white/70">Co-pay ratios & dynamic ICU alerts synchronized.</p>
          </div>
        </div>
      )}
    </div>
  )
}
