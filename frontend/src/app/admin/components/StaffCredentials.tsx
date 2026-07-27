"use client"

import React, { useState } from "react"
import {
  Search,
  Plus,
  X,
  Stethoscope,
  ClipboardList,
  Mail,
  Phone,
  Building2,
  BadgeCheck,
  Shield,
  ShieldOff,
  Eye,
  EyeOff,
  Copy,
  Check,
  KeyRound,
  UserPlus,
  Clock,
  CircleDot,
  Lock,
  AlertCircle
} from "lucide-react"
import { StaffCredential } from "../mockData"
import { registerAdmin } from "@/services/auth.service"

interface StaffCredentialsProps {
  credentials: StaffCredential[]
  onAddCredential: (cred: StaffCredential) => void
  onUpdateCredential: (cred: StaffCredential) => void
}

/* ─── Password generator ────────────────────────────────── */
function generatePassword(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#$!"
  let pass = ""
  for (let i = 0; i < 12; i++) {
    pass += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return pass
}

/* ═══════════════════════════════════════════════════════════ */
export function StaffCredentials({
  credentials,
  onAddCredential,
  onUpdateCredential
}: StaffCredentialsProps) {
  const [searchQuery, setSearchQuery] = useState("")
  const [roleFilter, setRoleFilter] = useState("all")
  const [isCreateOpen, setIsCreateOpen] = useState(false)
  const [viewCredId, setViewCredId] = useState<string | null>(null)

  // Create form state
  const [newFullName, setNewFullName] = useState("")
  const [newRole, setNewRole] = useState<StaffCredential["role"]>("doctor")
  const [newEmail, setNewEmail] = useState("")
  const [newPhone, setNewPhone] = useState("")
  const [newDepartment, setNewDepartment] = useState("")
  const [generatedPassword, setGeneratedPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [copied, setCopied] = useState(false)
  const [createError, setCreateError] = useState("")
  const [creating, setCreating] = useState(false)

  // Analytics
  const totalStaff = credentials.length
  const doctorCount = credentials.filter(c => c.role === "doctor").length
  const receptionistCount = credentials.filter(c => c.role === "receptionist").length
  const activeCount = credentials.filter(c => c.status === "active").length
  const suspendedCount = credentials.filter(c => c.status === "suspended").length

  // Filter
  const filtered = credentials.filter((c) => {
    const matchesSearch =
      c.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.employeeId.toLowerCase().includes(searchQuery.toLowerCase())

    const matchesRole = roleFilter === "all" || c.role === roleFilter

    return matchesSearch && matchesRole
  })

  const handleOpenCreate = () => {
    setNewFullName("")
    setNewRole("doctor")
    setNewEmail("")
    setNewPhone("")
    setNewDepartment("")
    setGeneratedPassword(generatePassword())
    setShowPassword(false)
    setCopied(false)
    setCreateError("")
    setIsCreateOpen(true)
  }

  const handleCopyPassword = () => {
    navigator.clipboard.writeText(generatedPassword)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault()
    setCreateError("")
    if (!newFullName || !newEmail) return

    setCreating(true)
    try {
      const userName = newFullName.toLowerCase().replace(/\s+/g, "_")
      await registerAdmin({
        user_name: userName,
        email: newEmail,
        password: generatedPassword,
      })

      const now = new Date()
      const dateStr = now.toISOString().split("T")[0]
      const prefix = newRole === "doctor" ? "D" : "R"
      const empNum = Math.floor(100 + Math.random() * 900)

      const newCred: StaffCredential = {
        id: `CRED-${Math.floor(100 + Math.random() * 900)}`,
        fullName: newRole === "doctor" ? `Dr. ${newFullName}` : newFullName,
        role: newRole,
        email: newEmail,
        phone: newPhone || "+91 00000 00000",
        department: newDepartment || (newRole === "doctor" ? "General Medicine" : "Front Desk - OPD"),
        employeeId: `EMP-${prefix}${empNum}`,
        status: "active",
        createdAt: dateStr,
        lastLogin: null
      }

      onAddCredential(newCred)
      setIsCreateOpen(false)
    } catch (err: any) {
      setCreateError(err.message || "Failed to create credential")
    } finally {
      setCreating(false)
    }
  }

  const handleToggleStatus = (cred: StaffCredential) => {
    const nextStatus: StaffCredential["status"] =
      cred.status === "active" ? "suspended" :
      cred.status === "suspended" ? "active" : "active"

    onUpdateCredential({ ...cred, status: nextStatus })
  }

  const getStatusStyles = (status: StaffCredential["status"]) => {
    switch (status) {
      case "active":
        return "bg-emerald-50 text-emerald-700 border-emerald-200"
      case "suspended":
        return "bg-amber-50 text-amber-700 border-amber-200"
      case "inactive":
        return "bg-gray-100 text-gray-500 border-gray-200"
    }
  }

  const getRoleIcon = (role: StaffCredential["role"]) => {
    return role === "doctor"
      ? <Stethoscope className="h-4 w-4" />
      : <ClipboardList className="h-4 w-4" />
  }

  const departmentOptions = {
    doctor: [
      "General Medicine",
      "Cardiology",
      "Neurology",
      "Orthopedics",
      "Pediatrics",
      "Maternity",
      "Dermatology",
      "ENT",
      "Ophthalmology",
      "Psychiatry"
    ],
    receptionist: [
      "Front Desk - OPD",
      "Front Desk - Emergency",
      "Front Desk - Maternity",
      "Front Desk - Pediatrics",
      "Billing Counter",
      "Insurance & Claims"
    ]
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* ─── KPI Stats ────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-5">
        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 flex items-center justify-between shadow-xs">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Total Staff Accounts</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{totalStaff}</h3>
            <span className="text-[10px] text-emerald-600 font-semibold block mt-1">{activeCount} active credentials</span>
          </div>
          <div className="p-3 bg-[#EEF4F1] border border-[#D7E2DC] rounded-xl text-[#12463E]">
            <KeyRound className="h-5 w-5" />
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 flex items-center justify-between shadow-xs">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Doctor Logins</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{doctorCount}</h3>
            <span className="text-[10px] text-blue-600 font-semibold block mt-1">Physician portal access</span>
          </div>
          <div className="p-3 bg-blue-50 border border-blue-100 rounded-xl text-blue-700">
            <Stethoscope className="h-5 w-5" />
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 flex items-center justify-between shadow-xs">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Receptionist Logins</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{receptionistCount}</h3>
            <span className="text-[10px] text-purple-600 font-semibold block mt-1">Front desk access</span>
          </div>
          <div className="p-3 bg-purple-50 border border-purple-100 rounded-xl text-purple-700">
            <ClipboardList className="h-5 w-5" />
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-[#E8ECEB] p-5 flex items-center justify-between shadow-xs">
          <div>
            <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Suspended</span>
            <h3 className="text-2xl font-black text-[#0B2B26] mt-1">{suspendedCount}</h3>
            <span className="text-[10px] text-amber-600 font-semibold block mt-1">Credentials on hold</span>
          </div>
          <div className="p-3 bg-amber-50 border border-amber-100 rounded-xl text-amber-700">
            <ShieldOff className="h-5 w-5" />
          </div>
        </div>
      </div>

      {/* ─── Filter Bar ───────────────────────────────── */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs">
        <div className="flex items-center gap-2 bg-[#F6F8F7] border border-[#D7E2DC] px-3.5 py-2 rounded-xl w-full md:w-80">
          <Search className="h-4 w-4 text-[#8AA098]" />
          <input
            type="text"
            placeholder="Search by name, email, employee ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="bg-transparent border-0 outline-none text-xs text-[#0B2B26] w-full placeholder:text-[#9CAEA6] focus:ring-0"
          />
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <div className="flex bg-[#F6F8F7] border border-[#D7E2DC] p-1 rounded-xl">
            {["all", "doctor", "receptionist"].map((role) => (
              <button
                key={role}
                onClick={() => setRoleFilter(role)}
                className={`px-4 py-1.5 rounded-lg text-xs font-bold capitalize transition-all ${
                  roleFilter === role
                    ? "bg-emerald-600 text-white shadow-xs"
                    : "text-[#6B8078] hover:text-[#12463E]"
                }`}
              >
                {role === "all" ? "All Staff" : role === "doctor" ? "Doctors" : "Receptionists"}
              </button>
            ))}
          </div>

          <button
            onClick={handleOpenCreate}
            className="h-10 px-4 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs shadow-md shadow-emerald-500/10 transition-all flex items-center gap-2"
          >
            <UserPlus className="h-4 w-4" />
            Create Credential
          </button>
        </div>
      </div>

      {/* ─── Credentials Table ────────────────────────── */}
      <div className="bg-white rounded-3xl border border-[#E8ECEB] shadow-xs overflow-hidden">
        {/* Table Header */}
        <div className="grid grid-cols-[1fr_120px_1.2fr_140px_100px_120px] gap-4 px-6 py-3.5 border-b border-[#E8ECEB] bg-[#F6F8F7]">
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Staff Member</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Role</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Contact</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Department</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Status</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider text-right">Actions</span>
        </div>

        {/* Table Rows */}
        {filtered.map((cred) => (
          <div
            key={cred.id}
            className={`grid grid-cols-[1fr_120px_1.2fr_140px_100px_120px] gap-4 px-6 py-4 border-b border-[#F6F8F7] hover:bg-[#FAFBFA] transition-colors items-center ${
              cred.status === "inactive" ? "opacity-50" : ""
            }`}
          >
            {/* Name & ID */}
            <div className="flex items-center gap-3 min-w-0">
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                cred.role === "doctor"
                  ? "bg-blue-50 text-blue-600 border border-blue-100"
                  : "bg-purple-50 text-purple-600 border border-purple-100"
              }`}>
                {getRoleIcon(cred.role)}
              </div>
              <div className="min-w-0">
                <p className="text-sm font-bold text-[#0B2B26] truncate">{cred.fullName}</p>
                <p className="text-[10px] text-[#8AA098] font-medium mt-0.5">{cred.employeeId}</p>
              </div>
            </div>

            {/* Role Badge */}
            <div>
              <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wider border ${
                cred.role === "doctor"
                  ? "bg-blue-50 text-blue-700 border-blue-100"
                  : "bg-purple-50 text-purple-700 border-purple-100"
              }`}>
                {cred.role === "doctor" ? <Stethoscope className="h-3 w-3" /> : <ClipboardList className="h-3 w-3" />}
                {cred.role}
              </span>
            </div>

            {/* Contact */}
            <div className="space-y-0.5 min-w-0">
              <div className="flex items-center gap-1.5 text-[11px] text-[#4B5F58]">
                <Mail className="h-3 w-3 text-[#8AA098] shrink-0" />
                <span className="truncate">{cred.email}</span>
              </div>
              <div className="flex items-center gap-1.5 text-[11px] text-[#6B8078]">
                <Phone className="h-3 w-3 text-[#8AA098] shrink-0" />
                <span>{cred.phone}</span>
              </div>
            </div>

            {/* Department */}
            <div className="flex items-center gap-1.5 text-[11px] text-[#4B5F58]">
              <Building2 className="h-3 w-3 text-[#8AA098] shrink-0" />
              <span className="truncate">{cred.department}</span>
            </div>

            {/* Status */}
            <div>
              <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg border text-[10px] font-bold capitalize ${getStatusStyles(cred.status)}`}>
                <CircleDot className="h-3 w-3" />
                {cred.status}
              </span>
            </div>

            {/* Actions */}
            <div className="flex items-center justify-end gap-2">
              {cred.status !== "inactive" && (
                <button
                  onClick={() => handleToggleStatus(cred)}
                  className={`px-3 py-1.5 rounded-lg text-[10px] font-bold transition-all border ${
                    cred.status === "active"
                      ? "text-amber-700 bg-amber-50 border-amber-200 hover:bg-amber-100"
                      : "text-emerald-700 bg-emerald-50 border-emerald-200 hover:bg-emerald-100"
                  }`}
                >
                  {cred.status === "active" ? "Suspend" : "Activate"}
                </button>
              )}
              <button
                onClick={() => setViewCredId(viewCredId === cred.id ? null : cred.id)}
                className="px-3 py-1.5 rounded-lg text-[10px] font-bold text-[#12463E] bg-[#EEF4F1] border border-[#D7E2DC] hover:bg-[#E0EBE5] transition-all"
              >
                Details
              </button>
            </div>

            {/* Expanded Details Row */}
            {viewCredId === cred.id && (
              <div className="col-span-6 bg-[#F6F8F7] rounded-2xl p-5 border border-[#E8ECEB] -mt-2 mb-2 animate-fade-in">
                <div className="grid grid-cols-4 gap-4">
                  <div>
                    <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Employee ID</span>
                    <span className="text-sm font-bold text-[#0B2B26] mt-1 block">{cred.employeeId}</span>
                  </div>
                  <div>
                    <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Account Created</span>
                    <span className="text-sm font-bold text-[#0B2B26] mt-1 block">{cred.createdAt}</span>
                  </div>
                  <div>
                    <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Last Login</span>
                    <span className="text-sm font-bold text-[#0B2B26] mt-1 block flex items-center gap-1.5">
                      <Clock className="h-3.5 w-3.5 text-[#8AA098]" />
                      {cred.lastLogin || "Never logged in"}
                    </span>
                  </div>
                  <div>
                    <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider block">Login Portal</span>
                    <span className="text-sm font-bold text-emerald-600 mt-1 block flex items-center gap-1.5">
                      <Lock className="h-3.5 w-3.5" />
                      {cred.role === "doctor" ? "Doctor Portal" : "Reception Desk"}
                    </span>
                  </div>
                </div>
              </div>
            )}
          </div>
        ))}

        {filtered.length === 0 && (
          <div className="py-16 text-center">
            <KeyRound className="h-8 w-8 text-[#D7E2DC] mx-auto mb-3" />
            <p className="text-sm text-[#8AA098] font-medium">No staff credentials found</p>
          </div>
        )}
      </div>

      {/* ═══════════════════════════════════════════════════ */}
      {/*  CREATE CREDENTIAL MODAL                           */}
      {/* ═══════════════════════════════════════════════════ */}
      {isCreateOpen && (
        <>
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity" onClick={() => setIsCreateOpen(false)} />

          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in max-h-[90vh] overflow-y-auto">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-[#E8ECEB] pb-4">
              <div>
                <h3 className="text-lg font-bold text-[#0B2B26] flex items-center gap-2">
                  <UserPlus className="h-5 w-5 text-emerald-600" />
                  Create Staff Credential
                </h3>
                <p className="text-xs text-[#8AA098] mt-0.5">Generate login access for a doctor or receptionist</p>
              </div>
              <button
                onClick={() => setIsCreateOpen(false)}
                className="w-8 h-8 rounded-full bg-[#F6F8F7] hover:bg-[#EEF4F1] flex items-center justify-center transition-all text-[#6B8078]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <form onSubmit={handleCreate} className="space-y-4 py-4">
              {createError && (
                <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 text-xs font-medium rounded-xl px-4 py-2.5">
                  <AlertCircle className="h-4 w-4 shrink-0" />
                  {createError}
                </div>
              )}
              {/* Role Selector */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-[#12463E]">Staff Role</label>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    type="button"
                    onClick={() => { setNewRole("doctor"); setNewDepartment("") }}
                    className={`p-4 rounded-2xl border-2 transition-all flex flex-col items-center gap-2 ${
                      newRole === "doctor"
                        ? "border-blue-400 bg-blue-50 shadow-sm"
                        : "border-[#E8ECEB] bg-white hover:border-[#D7E2DC]"
                    }`}
                  >
                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                      newRole === "doctor" ? "bg-blue-100 text-blue-600" : "bg-[#F6F8F7] text-[#8AA098]"
                    }`}>
                      <Stethoscope className="h-6 w-6" />
                    </div>
                    <div className="text-center">
                      <p className={`text-sm font-bold ${newRole === "doctor" ? "text-blue-700" : "text-[#6B8078]"}`}>Doctor</p>
                      <p className="text-[10px] text-[#8AA098] mt-0.5">Physician portal access</p>
                    </div>
                  </button>

                  <button
                    type="button"
                    onClick={() => { setNewRole("receptionist"); setNewDepartment("") }}
                    className={`p-4 rounded-2xl border-2 transition-all flex flex-col items-center gap-2 ${
                      newRole === "receptionist"
                        ? "border-purple-400 bg-purple-50 shadow-sm"
                        : "border-[#E8ECEB] bg-white hover:border-[#D7E2DC]"
                    }`}
                  >
                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                      newRole === "receptionist" ? "bg-purple-100 text-purple-600" : "bg-[#F6F8F7] text-[#8AA098]"
                    }`}>
                      <ClipboardList className="h-6 w-6" />
                    </div>
                    <div className="text-center">
                      <p className={`text-sm font-bold ${newRole === "receptionist" ? "text-purple-700" : "text-[#6B8078]"}`}>Receptionist</p>
                      <p className="text-[10px] text-[#8AA098] mt-0.5">Front desk access</p>
                    </div>
                  </button>
                </div>
              </div>

              {/* Name & Email */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">
                    Full Name {newRole === "doctor" && <span className="text-[#8AA098] font-normal">(without Dr.)</span>}
                  </label>
                  <input
                    type="text"
                    required
                    placeholder={newRole === "doctor" ? "e.g. Rajesh Kumar" : "e.g. Priya Patel"}
                    value={newFullName}
                    onChange={(e) => setNewFullName(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Email Address</label>
                  <input
                    type="email"
                    required
                    placeholder="name@auramedical.org"
                    value={newEmail}
                    onChange={(e) => setNewEmail(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>
              </div>

              {/* Phone & Department */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Phone Number</label>
                  <input
                    type="tel"
                    placeholder="+91 98765 43210"
                    value={newPhone}
                    onChange={(e) => setNewPhone(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Department</label>
                  <select
                    value={newDepartment}
                    onChange={(e) => setNewDepartment(e.target.value)}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="">Select department</option>
                    {departmentOptions[newRole].map((dept) => (
                      <option key={dept} value={dept}>{dept}</option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Generated Password Block */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-[#12463E] flex items-center gap-1.5">
                  <KeyRound className="h-3.5 w-3.5 text-emerald-600" />
                  Auto-Generated Password
                </label>
                <div className="flex items-center gap-2">
                  <div className="flex-1 relative">
                    <input
                      type={showPassword ? "text" : "password"}
                      value={generatedPassword}
                      readOnly
                      className="w-full h-11 px-3.5 pr-10 rounded-xl border border-emerald-200 bg-emerald-50/50 text-sm font-mono text-[#0B2B26] focus:outline-none tracking-wider"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-[#8AA098] hover:text-[#12463E] transition-colors"
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  <button
                    type="button"
                    onClick={handleCopyPassword}
                    className={`h-11 px-4 rounded-xl border font-bold text-xs transition-all flex items-center gap-1.5 ${
                      copied
                        ? "bg-emerald-600 text-white border-emerald-600"
                        : "bg-[#F6F8F7] text-[#12463E] border-[#D7E2DC] hover:bg-[#EEF4F1]"
                    }`}
                  >
                    {copied ? <><Check className="h-3.5 w-3.5" /> Copied!</> : <><Copy className="h-3.5 w-3.5" /> Copy</>}
                  </button>
                  <button
                    type="button"
                    onClick={() => setGeneratedPassword(generatePassword())}
                    className="h-11 px-4 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-[#12463E] font-bold text-xs hover:bg-[#EEF4F1] transition-all"
                  >
                    Regenerate
                  </button>
                </div>
                <p className="text-[10px] text-[#8AA098] flex items-center gap-1.5 mt-1">
                  <Shield className="h-3 w-3" />
                  Share this password securely with the staff member. They can change it after first login.
                </p>
              </div>

              {/* Action Buttons */}
              <div className="flex gap-3 border-t border-[#E8ECEB] pt-4 mt-2">
                <button
                  type="button"
                  onClick={() => setIsCreateOpen(false)}
                  className="flex-1 h-11 rounded-xl border border-[#D7E2DC] text-xs font-bold text-[#6B8078] hover:bg-[#F6F8F7] transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={creating}
                  className="flex-1 h-11 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 shadow-md shadow-emerald-600/10 transition-all flex items-center justify-center gap-2 disabled:opacity-60"
                >
                  {creating ? (
                    <>Creating...</>
                  ) : (
                    <><BadgeCheck className="h-4 w-4" /> Create & Activate</>
                  )}
                </button>
              </div>
            </form>
          </div>
        </>
      )}
    </div>
  )
}
