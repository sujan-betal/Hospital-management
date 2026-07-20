"use client"

import React, { useState } from "react"
import {
  Search,
  Filter,
  Users,
  Award,
  Phone,
  Mail,
  Stethoscope,
  Clock,
  Heart,
  Briefcase
} from "lucide-react"
import { Doctor } from "../mockData"

interface DoctorsProps {
  guests: Doctor[] // mapped from page.tsx state
}

export function AttendingDoctors({ guests }: DoctorsProps) {
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")

  // Analytics
  const totalDoctors = guests.length
  const onDutyCount = guests.filter(d => d.status === "On Duty").length
  const onCallCount = guests.filter(d => d.status === "On Call").length
  const totalPatientLoad = guests.reduce((acc, d) => acc + d.activePatients, 0)
  const averageLoad = Math.round((totalPatientLoad / totalDoctors) * 10) / 10

  const filteredDoctors = guests.filter((d) => {
    const matchesSearch =
      d.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      d.specialty.toLowerCase().includes(searchQuery.toLowerCase())
    
    const matchesStatus = statusFilter === "all" || d.status === statusFilter

    return matchesSearch && matchesStatus
  })

  return (
    <div className="space-y-6 animate-fade-in">
      {/* KPI stats for doctors */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 flex items-center justify-between shadow-xs">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Medical Staff Directory</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{totalDoctors} Physicians</h3>
            <span className="text-[10px] text-emerald-600 font-semibold block mt-1">Credentials verified</span>
          </div>
          <div className="p-3 bg-[#EEF4F1] border border-[#D7E2DC] rounded-xl text-[#12463E]">
            <Stethoscope className="h-5 w-5" />
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 flex items-center justify-between shadow-xs">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Currently On Shift</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{onDutyCount} On Duty</h3>
            <span className="text-[10px] text-blue-600 font-semibold block mt-1">{onCallCount} on backup call</span>
          </div>
          <div className="p-3 bg-blue-50 border border-blue-100 rounded-xl text-blue-700">
            <Clock className="h-5 w-5" />
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 flex items-center justify-between shadow-xs">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Active Clinical Load</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{totalPatientLoad} Patients</h3>
            <span className="text-[10px] text-rose-600 font-semibold block mt-1">Avg {averageLoad} patients per physician</span>
          </div>
          <div className="p-3 bg-rose-50 border border-rose-100 rounded-xl text-rose-700">
            <Users className="h-5 w-5" />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs">
        <div className="flex items-center gap-2 bg-[#F6F8F7] border border-[#D7E2DC] px-3.5 py-2 rounded-xl w-full md:w-80">
          <Search className="h-4 w-4 text-[#8AA098]" />
          <input
            type="text"
            placeholder="Search doctors by Name, Specialty..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="bg-transparent border-0 outline-none text-xs text-[#0B2B26] w-full placeholder:text-[#9CAEA6] focus:ring-0"
          />
        </div>

        <div className="flex bg-[#F6F8F7] border border-[#D7E2DC] p-1 rounded-xl">
          {["all", "On Duty", "On Call", "Off Duty"].map((status) => (
            <button
              key={status}
              onClick={() => setStatusFilter(status)}
              className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                statusFilter === status
                  ? "bg-emerald-600 text-white shadow-xs"
                  : "text-[#6B8078] hover:text-[#12463E]"
              }`}
            >
              {status}
            </button>
          ))}
        </div>
      </div>

      {/* Doctor Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredDoctors.map((doc) => (
          <div
            key={doc.id}
            className="bg-white rounded-3xl border border-[#E8ECEB] p-5 shadow-xs hover:shadow-md hover:border-[#D7E2DC] transition-all flex flex-col justify-between"
          >
            {/* Doctor Header */}
            <div>
              <div className="flex items-start justify-between">
                <div>
                  <span className="text-[9px] text-[#8AA098] font-bold tracking-widest">{doc.id}</span>
                  <h4 className="text-base font-bold text-[#0B2B26] mt-0.5">{doc.name}</h4>
                </div>
                
                <span className={`px-2.5 py-0.5 rounded-md border text-[9px] font-bold ${
                  doc.status === "On Duty" ? "bg-emerald-50 text-emerald-700 border-emerald-200" :
                  doc.status === "On Call" ? "bg-amber-50 text-amber-700 border-amber-200" :
                  "bg-gray-100 text-gray-700 border-gray-200"
                }`}>
                  {doc.status}
                </span>
              </div>

              {/* Contacts */}
              <div className="space-y-1.5 mt-4 text-[11px] text-[#6B8078]">
                <div className="flex items-center gap-2">
                  <Mail className="h-3.5 w-3.5 text-[#8AA098]" />
                  <span>{doc.email}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="h-3.5 w-3.5 text-[#8AA098]" />
                  <span>{doc.phone}</span>
                </div>
              </div>

              {/* Specialty */}
              <div className="mt-4 p-3 bg-[#F6F8F7] rounded-xl border border-[#E8ECEB] flex items-center justify-between text-[11px]">
                <div className="flex items-center gap-1.5 text-[#4B5F58]">
                  <Briefcase className="h-3.5 w-3.5 text-emerald-600" />
                  <span>Attendant:</span>
                </div>
                <span className="font-bold text-[#0B2B26]">{doc.specialty}</span>
              </div>
            </div>

            {/* Patients load info */}
            <div className="mt-6 pt-4 border-t border-[#F6F8F7] flex items-center justify-between">
              <div>
                <span className="text-[10px] text-[#8AA098] font-medium block">Patient Load</span>
                <span className="text-sm font-black text-[#0B2B26] mt-0.5 block">{doc.activePatients} Active</span>
              </div>
              <span className="text-[10px] text-emerald-600 font-bold bg-[#EEF4F1] px-2.5 py-1 rounded-md border border-[#D7E2DC]">
                Shift active
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
