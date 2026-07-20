"use client"

import React from "react"
import {
  TrendingUp,
  TrendingDown,
  CreditCard,
  Users,
  Bed,
  Activity,
  ArrowUpRight,
  Plus,
  Compass,
  Heart,
  Stethoscope
} from "lucide-react"
import { Bed as HospitalBed, Admission, MedicalTask } from "../mockData"

interface OverviewProps {
  beds: HospitalBed[]
  admissions: Admission[]
  tasks: MedicalTask[]
  onNavigate: (tab: string) => void
  onAddAdmissionClick: () => void
  onAddTaskClick: () => void
}

export function Overview({
  beds,
  admissions,
  tasks,
  onNavigate,
  onAddAdmissionClick,
  onAddTaskClick
}: OverviewProps) {
  // Compute analytics
  const occupiedCount = beds.filter(b => b.status === "occupied").length
  const availableCount = beds.filter(b => b.status === "available").length
  const sanitizingCount = beds.filter(b => b.status === "sanitizing").length
  const reservedCount = beds.filter(b => b.status === "reserved").length
  const totalBeds = beds.length
  const occupancyRate = Math.round((occupiedCount / totalBeds) * 100)

  const activeAdmissionsCount = admissions.filter(adm => adm.status === "admitted" || adm.status === "scheduled").length
  
  // Calculate daily care billing charges based on occupied beds
  const dailyBilling = beds.reduce((acc, curr) => {
    if (curr.status === "occupied") {
      return acc + curr.price
    }
    return acc
  }, 0)

  // Pending care tasks
  const pendingTasksCount = tasks.filter(t => t.status !== "completed").length

  // Quick Stats
  const stats = [
    {
      label: "Bed Occupancy",
      value: `${occupancyRate}%`,
      sub: `${occupiedCount} of ${totalBeds} Beds occupied`,
      icon: Bed,
      color: "bg-emerald-50 text-emerald-700 border-emerald-100",
      trend: "+1.8% from yesterday",
      trendUp: true
    },
    {
      label: "Daily Ward Yield",
      value: `Rs. ${dailyBilling.toLocaleString()}`,
      sub: "Active inpatient care rates",
      icon: CreditCard,
      color: "bg-[#E8BA60]/10 text-[#7C5A14] border-[#E8BA60]/20",
      trend: "Adjusted for ICU charges",
      trendUp: true
    },
    {
      label: "Admitted Inpatients",
      value: `${activeAdmissionsCount}`,
      sub: "Receiving inpatient therapies",
      icon: Users,
      color: "bg-blue-50 text-blue-700 border-blue-100",
      trend: "3 discharges expected today",
      trendUp: true
    },
    {
      label: "Clinical Task Backlog",
      value: `${pendingTasksCount} Orders`,
      sub: "Nursing, lab tests, pharmacy",
      icon: Activity,
      color: "bg-rose-50 text-rose-700 border-rose-100",
      trend: "1 emergency lab order",
      trendUp: false
    }
  ]

  // Weekly admissions chart data (mock admissions count per day)
  const weeklyData = [
    { day: "Mon", rate: 45 },
    { day: "Tue", rate: 58 },
    { day: "Wed", rate: 70 },
    { day: "Thu", rate: 64 },
    { day: "Fri", rate: 82 },
    { day: "Sat", rate: 90 },
    { day: "Sun", rate: 52 }
  ]

  // Recent logs
  const recentActivities = [
    { id: 1, type: "admission", patient: "Robert Downey Jr.", detail: "Checked into Bed ICU-101 (Critical Telemetry)", time: "Just now" },
    { id: 2, type: "task", patient: "Staff (Nurse Maria)", detail: "Completed blood drawing for Emma Watson (GEN-301)", time: "15 mins ago" },
    { id: 3, type: "scheduled", patient: "Leonardo DiCaprio", detail: "Scheduled for elective care admission tomorrow (ICU-102)", time: "1 hr ago" },
    { id: 4, type: "discharge", patient: "Brad Pitt", detail: "Discharged from Bed GEN-302 (General Ward)", time: "2 hrs ago" },
    { id: 5, type: "emergency", patient: "Staff (ER Team)", detail: "Dispatched Nurse Sarah to ICU-101 for telemetry BP check", time: "4 hrs ago" },
  ]

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Welcome Banner */}
      <div className="relative rounded-3xl overflow-hidden bg-gradient-to-br from-[#0B2B26] via-[#0D3831] to-[#12463E] p-8 text-white shadow-xl shadow-[#0B2B26]/10">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_90%_20%,rgba(16,185,129,0.15),transparent_40%)]" />
        <div className="absolute inset-0 bg-[linear-gradient(110deg,transparent_60%,rgba(255,255,255,0.02)_70%,transparent_80%)]" />
        
        <div className="relative z-10 flex flex-col md:flex-row md:items-center md:justify-between gap-6">
          <div>
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-semibold mb-3">
              <Heart className="h-3 w-3 animate-pulse" /> Clinic Status: Fully Operational
            </div>
            <h2 className="text-3xl font-extrabold tracking-tight">Chief Officer Console</h2>
            <p className="text-white/70 text-sm mt-1.5 max-w-xl">
              ICU telemetry links are active. Total bed occupancy is at {occupancyRate}%. Outpatient scheduling is operating at normal latency, and attending staff directories are fully synchronized.
            </p>
          </div>
          
          <div className="flex gap-3 shrink-0">
            <button
              onClick={onAddAdmissionClick}
              className="px-5 py-3 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs shadow-lg shadow-emerald-500/25 transition-all flex items-center gap-2 group"
            >
              <Plus className="h-4 w-4" />
              Admit Patient
            </button>
            <button
              onClick={onAddTaskClick}
              className="px-5 py-3 rounded-xl bg-white/10 hover:bg-white/15 text-white font-bold text-xs border border-white/15 transition-all flex items-center gap-2"
            >
              <Activity className="h-4 w-4 text-emerald-400" />
              Order Lab/Rx
            </button>
          </div>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, i) => {
          const Icon = stat.icon
          return (
            <div
              key={i}
              className="bg-white rounded-2xl border border-[#E8ECEB] p-6 shadow-xs hover:shadow-md hover:border-[#D7E2DC] transition-all flex flex-col justify-between"
            >
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-xs font-semibold text-[#8AA098] tracking-wider uppercase">{stat.label}</p>
                  <h3 className="text-2xl font-black text-[#0B2B26] tracking-tight mt-1.5">{stat.value}</h3>
                  <p className="text-xs text-[#6B8078] mt-1">{stat.sub}</p>
                </div>
                <div className={`p-3 rounded-xl border ${stat.color} shrink-0`}>
                  <Icon className="h-5 w-5" strokeWidth={2.2} />
                </div>
              </div>
              <div className="mt-4 pt-4 border-t border-[#F6F8F7] flex items-center justify-between text-[11px] text-[#6B8078] font-medium">
                <span>{stat.trend}</span>
                {stat.trendUp ? (
                  <TrendingUp className="h-3.5 w-3.5 text-emerald-600 shrink-0" />
                ) : (
                  <TrendingDown className="h-3.5 w-3.5 text-rose-500 shrink-0" />
                )}
              </div>
            </div>
          )
        })}
      </div>

      {/* Analytics Charts & Status Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* CSS Chart: Weekly Admissions */}
        <div className="lg:col-span-2 bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-[#0B2B26]">Weekly Patient Admissions</h3>
                <p className="text-xs text-[#8AA098]">Total inpatient check-ins recorded daily</p>
              </div>
              <button
                onClick={() => onNavigate("admissions")}
                className="text-xs text-emerald-600 font-bold hover:underline flex items-center gap-1"
              >
                Admissions Log <ArrowUpRight className="h-3 w-3" />
              </button>
            </div>
            
            {/* Chart Area */}
            <div className="h-64 flex items-end gap-5 mt-8 px-2">
              {weeklyData.map((d, index) => (
                <div key={index} className="flex-1 flex flex-col items-center gap-3 group h-full justify-end">
                  <div className="w-full relative flex flex-col justify-end h-full">
                    {/* Tooltip */}
                    <div className="absolute -top-8 left-1/2 -translate-x-1/2 bg-[#0B2B26] text-white text-[10px] font-bold px-2 py-0.5 rounded-md opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap shadow-md">
                      {d.rate} admitted
                    </div>
                    {/* Bar background */}
                    <div className="absolute inset-0 bg-[#F6F8F7] rounded-xl w-full -z-10" />
                    {/* Filled Bar */}
                    <div
                      className="w-full rounded-xl bg-gradient-to-t from-emerald-600 to-emerald-500 group-hover:to-[#E8BA60] transition-all duration-500 relative cursor-pointer"
                      style={{ height: `${d.rate}%` }}
                    />
                  </div>
                  <span className="text-xs text-[#8AA098] font-semibold">{d.day}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-[#F6F8F7] flex items-center justify-between text-xs text-[#6B8078]">
            <span className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-600" /> General/Pediatric Care
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#E8BA60]" /> ICU / Critical Surges
            </span>
          </div>
        </div>

        {/* Bed Status Gauge & Wards */}
        <div className="bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs flex flex-col justify-between">
          <div>
            <h3 className="text-base font-bold text-[#0B2B26]">Real-time Bed Allocations</h3>
            <p className="text-xs text-[#8AA098] mb-6">Attended ward beds and room sanitation logs</p>
            
            {/* Big segmented progress gauge */}
            <div className="flex gap-1.5 h-3 rounded-full overflow-hidden bg-[#EEF4F1] w-full">
              <div style={{ width: `${(occupiedCount/totalBeds)*100}%` }} className="bg-emerald-600 hover:opacity-95 transition-all" title="Occupied" />
              <div style={{ width: `${(availableCount/totalBeds)*100}%` }} className="bg-blue-400 hover:opacity-95 transition-all" title="Available" />
              <div style={{ width: `${(sanitizingCount/totalBeds)*100}%` }} className="bg-amber-400 hover:opacity-95 transition-all" title="Sanitizing" />
              <div style={{ width: `${(reservedCount/totalBeds)*100}%` }} className="bg-rose-500 hover:opacity-95 transition-all" title="Reserved" />
            </div>

            {/* List breakdown */}
            <div className="space-y-4 mt-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="w-3 h-3 rounded-full bg-emerald-600" />
                  <span className="text-xs font-semibold text-[#4B5F58]">Beds Occupied</span>
                </div>
                <span className="text-xs font-bold text-[#0B2B26]">{occupiedCount} ({Math.round(occupiedCount/totalBeds*100)}%)</span>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="w-3 h-3 rounded-full bg-blue-400" />
                  <span className="text-xs font-semibold text-[#4B5F58]">Beds Available (Ready)</span>
                </div>
                <span className="text-xs font-bold text-[#0B2B26]">{availableCount} ({Math.round(availableCount/totalBeds*100)}%)</span>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="w-3 h-3 rounded-full bg-amber-400" />
                  <span className="text-xs font-semibold text-[#4B5F58]">Under Sanitization</span>
                </div>
                <span className="text-xs font-bold text-[#0B2B26]">{sanitizingCount} ({Math.round(sanitizingCount/totalBeds*100)}%)</span>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="w-3 h-3 rounded-full bg-rose-500" />
                  <span className="text-xs font-semibold text-[#4B5F58]">Out of Service / Reserved</span>
                </div>
                <span className="text-xs font-bold text-[#0B2B26]">{reservedCount} ({Math.round(reservedCount/totalBeds*100)}%)</span>
              </div>
            </div>
          </div>

          <button
            onClick={() => onNavigate("beds")}
            className="w-full mt-6 py-3 rounded-xl border border-[#D7E2DC] text-emerald-600 hover:bg-[#EEF4F1] text-xs font-bold transition-all text-center block"
          >
            Manage Ward Allocations
          </button>
        </div>
      </div>

      {/* Recent Activity Feed & Task Summary */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Activity Feed */}
        <div className="lg:col-span-2 bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs">
          <h3 className="text-base font-bold text-[#0B2B26]">Live Clinical Activity Feed</h3>
          <p className="text-xs text-[#8AA098] mb-6">Patient status logs, admissions, and telemetry triggers</p>
          
          <div className="flow-root">
            <ul className="-mb-8">
              {recentActivities.map((activity, activityIdx) => (
                <li key={activity.id}>
                  <div className="relative pb-8">
                    {activityIdx !== recentActivities.length - 1 ? (
                      <span className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-[#E8ECEB]" aria-hidden="true" />
                    ) : null}
                    <div className="relative flex space-x-3.5">
                      <div>
                        <span className={`h-8 w-8 rounded-lg flex items-center justify-center ring-4 ring-white ${
                          activity.type === "admission" ? "bg-emerald-50 text-emerald-600" :
                          activity.type === "discharge" ? "bg-blue-50 text-blue-600" :
                          activity.type === "scheduled" ? "bg-purple-50 text-purple-600" :
                          activity.type === "emergency" ? "bg-rose-50 text-rose-600" : "bg-amber-50 text-amber-600"
                        }`}>
                          <Activity className="h-4 w-4" />
                        </span>
                      </div>
                      <div className="flex-1 min-w-0 pt-1.5 flex justify-between space-x-4">
                        <div>
                          <p className="text-xs font-bold text-[#0B2B26]">
                            {activity.patient}{" "}
                            <span className="font-normal text-[#6B8078]">{activity.detail}</span>
                          </p>
                        </div>
                        <div className="text-right text-[10px] whitespace-nowrap text-[#9CAEA6] font-medium">
                          {activity.time}
                        </div>
                      </div>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Attending Doctors Overview */}
        <div className="bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-bold text-[#0B2B26]">Pending Lab & Rx Orders</h3>
              <span className="px-2.5 py-0.5 rounded-full bg-rose-50 text-rose-700 text-[10px] font-bold border border-rose-100">
                {pendingTasksCount} Pending
              </span>
            </div>
            
            <div className="space-y-3.5">
              {tasks.slice(0, 3).map((task) => (
                <div key={task.id} className="p-3 bg-[#F6F8F7] rounded-xl border border-[#E8ECEB] flex items-center justify-between">
                  <div>
                    <span className="text-[10px] font-bold text-emerald-600 uppercase tracking-wider block">
                      Bed {task.bedId} · {task.type}
                    </span>
                    <p className="text-xs font-semibold text-[#0B2B26] mt-0.5 truncate max-w-[150px]">{task.task}</p>
                    <span className="text-[9px] text-[#8AA098] mt-0.5 block">Attendant: {task.assignedTo}</span>
                  </div>
                  <span className={`text-[10px] px-2 py-0.5 font-bold rounded-lg ${
                    task.priority === "emergency" ? "bg-rose-50 text-rose-600 border border-rose-100 animate-pulse" :
                    task.priority === "high" ? "bg-amber-50 text-amber-600 border border-amber-100" :
                    "bg-blue-50 text-blue-600 border border-blue-100"
                  }`}>
                    {task.priority}
                  </span>
                </div>
              ))}
            </div>
          </div>

          <button
            onClick={() => onNavigate("tasks")}
            className="w-full mt-6 py-3 rounded-xl border border-[#D7E2DC] text-emerald-600 hover:bg-[#EEF4F1] text-xs font-bold transition-all text-center block"
          >
            Review Medical Orders
          </button>
        </div>
      </div>
    </div>
  )
}
