"use client"

import React, { useState, useEffect } from "react"
import {
  Search,
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
  AlertCircle,
  Pencil,
  Trash2,
  UserCog,
  UserCheck,
  KeySquare,
} from "lucide-react"
import { StaffCredential } from "../mockData"
import {
  createDoctor,
  createSubAdmin,
  deleteStaff,
  listStaff,
  registerAdmin,
  updateStaff,
} from "@/services/auth.service"

interface StaffCredentialsProps {
  credentials: StaffCredential[]
  onAddCredential: (cred: StaffCredential) => void
  onUpdateCredential: (cred: StaffCredential) => void
  onDeleteCredential?: (id: string) => void
}

type Notice = { type: "success" | "error"; text: string }

/* ─── Password generator ────────────────────────────────── */
function generatePassword(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#$!"
  let pass = ""
  for (let i = 0; i < 12; i++) {
    pass += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return pass
}

const ROLE_MAP: Record<string, StaffCredential["role"]> = {
  DOCTOR: "doctor",
  RECEPTIONIST: "receptionist",
  SUBADMIN: "subadmin",
  ADMIN: "admin",
}

function convertStaffRow(row: any): StaffCredential {
  const role = ROLE_MAP[row.role] || "receptionist"
  const rawStatus = (row.status || "").toLowerCase()
  return {
    id: `CRED-${row.user_id}`,
    user_id: row.user_id,
    fullName:
      role === "doctor"
        ? String(row.user_name || "").startsWith("Dr.")
          ? row.user_name
          : `Dr. ${row.user_name}`
        : row.user_name || "—",
    role,
    email: row.email || "—",
    phone: row.phone || "—",
    department:
      row.department ||
      (role === "doctor"
        ? "General Medicine"
        : role === "receptionist"
        ? "Front Desk - OPD"
        : "Administration"),
    employeeId: `EMP-${role.slice(0, 1).toUpperCase()}${(row.user_id || "").slice(0, 4).toUpperCase()}`,
    status:
      rawStatus === "active"
        ? "active"
        : rawStatus === "suspended"
        ? "suspended"
        : "inactive",
    createdAt: row.created_at ? String(row.created_at).slice(0, 10) : new Date().toISOString().slice(0, 10),
    lastLogin: null,
  }
}

/* ═══════════════════════════════════════════════════════════ */
export function StaffCredentials({
  credentials,
  onAddCredential,
  onUpdateCredential,
  onDeleteCredential,
}: StaffCredentialsProps) {
  const [staff, setStaff] = useState<StaffCredential[]>(credentials)
  const [searchQuery, setSearchQuery] = useState("")
  const [roleFilter, setRoleFilter] = useState("all")
  const [isCreateOpen, setIsCreateOpen] = useState(false)
  const [viewCredId, setViewCredId] = useState<string | null>(null)
  const [notice, setNotice] = useState<Notice | null>(null)

  // Create form state
  const [newFullName, setNewFullName] = useState("")
  const [newRole, setNewRole] = useState<StaffCredential["role"]>("doctor")
  const [newEmail, setNewEmail] = useState("")
  const [newPhone, setNewPhone] = useState("")
  const [newDepartment, setNewDepartment] = useState("")
  const [newPermissions, setNewPermissions] = useState("")
  const [newUserName, setNewUserName] = useState("")
  const [generatedPassword, setGeneratedPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [copied, setCopied] = useState(false)
  const [createError, setCreateError] = useState("")
  const [creating, setCreating] = useState(false)

  // Edit form state
  const [isEditOpen, setIsEditOpen] = useState(false)
  const [editCred, setEditCred] = useState<StaffCredential | null>(null)
  const [editFullName, setEditFullName] = useState("")
  const [editEmail, setEditEmail] = useState("")
  const [editPhone, setEditPhone] = useState("")
  const [editDepartment, setEditDepartment] = useState("")
  const [editStatus, setEditStatus] = useState<StaffCredential["status"]>("active")
  const [editError, setEditError] = useState("")
  const [editSaving, setEditSaving] = useState(false)

  // Delete state
  const [isDeleteOpen, setIsDeleteOpen] = useState(false)
  const [deletingCred, setDeletingCred] = useState<StaffCredential | null>(null)
  const [deleteError, setDeleteError] = useState("")
  const [deleting, setDeleting] = useState(false)

  // Load real staff from the backend on mount (fall back to mock data).
  useEffect(() => {
    let active = true
    listStaff()
      .then((res) => {
        if (!active) return
        const rows = res.data
        if (Array.isArray(rows) && rows.length > 0) {
          setStaff(rows.map(convertStaffRow))
        }
      })
      .catch(() => {})
    return () => {
      active = false
    }
  }, [])

  // Analytics
  const totalStaff = staff.length
  const doctorCount = staff.filter((c) => c.role === "doctor").length
  const receptionistCount = staff.filter((c) => c.role === "receptionist").length
  const activeCount = staff.filter((c) => c.status === "active").length
  const suspendedCount = staff.filter((c) => c.status === "suspended").length

  // Filter
  const filtered = staff.filter((c) => {
    const matchesSearch =
      c.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.employeeId.toLowerCase().includes(searchQuery.toLowerCase())

    const matchesRole = roleFilter === "all" || c.role === roleFilter

    return matchesSearch && matchesRole
  })

  const dismissNotice = () => setNotice(null)

  const handleOpenCreate = () => {
    setNewFullName("")
    setNewRole("doctor")
    setNewEmail("")
    setNewPhone("")
    setNewDepartment("")
    setNewPermissions("")
    setNewUserName("")
    setGeneratedPassword(generatePassword())
    setShowPassword(false)
    setCopied(false)
    setCreateError("")
    setIsCreateOpen(true)
  }

  const deriveUserName = (name: string) =>
    name.toLowerCase().replace(/\s+/g, "_").replace(/[^a-z0-9_.-]/g, "")

  const handleFullNameChange = (value: string) => {
    setNewFullName(value)
    setNewUserName(deriveUserName(value))
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
      const userName = newUserName || deriveUserName(newFullName)
      let createdUserId: string | undefined

      if (newRole === "doctor") {
        const res = await createDoctor({
          user_name: userName,
          email: newEmail,
          phone: newPhone || undefined,
          department: newDepartment || undefined,
        })
        createdUserId = res.data?.user_id
      } else if (newRole === "subadmin") {
        const permissions = newPermissions
          .split(",")
          .map((p) => p.trim().toUpperCase())
          .filter(Boolean)
        const res = await createSubAdmin({
          user_name: userName,
          email: newEmail,
          password: generatedPassword,
          permissions: permissions.length ? permissions : ["ALL"],
        })
        createdUserId = res.data?.user_id
      } else {
        const res = await registerAdmin({
          user_name: userName,
          email: newEmail,
          password: generatedPassword,
        })
        createdUserId = res.data?.user_id
      }

      const now = new Date()
      const dateStr = now.toISOString().split("T")[0]
      const prefix = newRole === "doctor" ? "D" : newRole === "subadmin" ? "S" : "R"
      const empNum = Math.floor(100 + Math.random() * 900)

      const newCred: StaffCredential = {
        id: `CRED-${createdUserId || Math.floor(100 + Math.random() * 900)}`,
        user_id: createdUserId,
        fullName: newRole === "doctor" ? `Dr. ${newFullName}` : newFullName,
        role: newRole,
        email: newEmail,
        phone: newPhone || "+91 00000 00000",
        department:
          newDepartment ||
          (newRole === "doctor"
            ? "General Medicine"
            : newRole === "receptionist"
            ? "Front Desk - OPD"
            : "Administration"),
        employeeId: `EMP-${prefix}${empNum}`,
        status: "active",
        createdAt: dateStr,
        lastLogin: null,
      }

      setStaff([newCred, ...staff])
      onAddCredential(newCred)
      setIsCreateOpen(false)

      if (newRole === "doctor") {
        setNotice({
          type: "success",
          text: `Doctor account created. Password-set email sent to ${newEmail}.`,
        })
      } else {
        setNotice({
          type: "success",
          text: `${newRole === "subadmin" ? "Sub-admin" : "Receptionist"} credential created successfully.`,
        })
      }
    } catch (err: any) {
      setCreateError(err.message || "Failed to create credential")
    } finally {
      setCreating(false)
    }
  }

  const handleToggleStatus = async (cred: StaffCredential) => {
    const nextStatus: StaffCredential["status"] =
      cred.status === "active" ? "suspended" : "active"

    if (cred.user_id) {
      try {
        await updateStaff(cred.user_id, { status: nextStatus.toUpperCase() })
      } catch (err: any) {
        setNotice({ type: "error", text: err.message || "Failed to update status" })
        return
      }
    }

    const updated = { ...cred, status: nextStatus }
    setStaff(staff.map((c) => (c.id === cred.id ? updated : c)))
    onUpdateCredential(updated)
  }

  const openEdit = (cred: StaffCredential) => {
    setEditCred(cred)
    setEditFullName(cred.fullName.replace(/^Dr\.\s*/i, ""))
    setEditEmail(cred.email === "—" ? "" : cred.email)
    setEditPhone(cred.phone === "—" ? "" : cred.phone)
    setEditDepartment(cred.department)
    setEditStatus(cred.status)
    setEditError("")
    setIsEditOpen(true)
  }

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editCred) return
    setEditError("")

    if (!editCred.user_id) {
      setEditError("This record is not linked to a backend account, so it can only be edited after it is saved to the database.")
      return
    }

    setEditSaving(true)
    try {
      await updateStaff(editCred.user_id, {
        user_name: editFullName.toLowerCase().replace(/\s+/g, "_"),
        email: editEmail,
        phone: editCred.role === "doctor" ? editPhone : undefined,
        department: editCred.role === "doctor" ? editDepartment : undefined,
        status: editStatus.toUpperCase(),
      })

      const updated: StaffCredential = {
        ...editCred,
        fullName: editCred.role === "doctor" ? `Dr. ${editFullName}` : editFullName,
        email: editEmail,
        phone: editPhone || "—",
        department: editDepartment,
        status: editStatus,
      }
      setStaff(staff.map((c) => (c.id === editCred.id ? updated : c)))
      onUpdateCredential(updated)
      setIsEditOpen(false)
      setNotice({ type: "success", text: "Credential updated successfully." })
    } catch (err: any) {
      setEditError(err.message || "Failed to update credential")
    } finally {
      setEditSaving(false)
    }
  }

  const openDelete = (cred: StaffCredential) => {
    setDeletingCred(cred)
    setDeleteError("")
    setIsDeleteOpen(true)
  }

  const handleDelete = async () => {
    if (!deletingCred) return
    setDeleteError("")

    if (!deletingCred.user_id) {
      setDeleteError("This record is not linked to a backend account, so it cannot be permanently deleted.")
      return
    }

    setDeleting(true)
    try {
      await deleteStaff(deletingCred.user_id)
      setStaff(staff.filter((c) => c.id !== deletingCred.id))
      onDeleteCredential?.(deletingCred.id)
      setIsDeleteOpen(false)
      setNotice({
        type: "success",
        text: `${deletingCred.fullName} (${deletingCred.role}) has been permanently deleted.`,
      })
    } catch (err: any) {
      setDeleteError(err.message || "Failed to delete credential")
    } finally {
      setDeleting(false)
    }
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
    switch (role) {
      case "doctor":
        return <Stethoscope className="h-4 w-4" />
      case "receptionist":
        return <ClipboardList className="h-4 w-4" />
      case "subadmin":
        return <UserCog className="h-4 w-4" />
      case "admin":
        return <Shield className="h-4 w-4" />
    }
  }

  const getRoleBadge = (role: StaffCredential["role"]) => {
    switch (role) {
      case "doctor":
        return { cls: "bg-blue-50 text-blue-700 border-blue-100", Icon: Stethoscope }
      case "receptionist":
        return { cls: "bg-purple-50 text-purple-700 border-purple-100", Icon: ClipboardList }
      case "subadmin":
        return { cls: "bg-teal-50 text-teal-700 border-teal-100", Icon: UserCog }
      case "admin":
        return { cls: "bg-[#EEF4F1] text-[#12463E] border-[#D7E2DC]", Icon: Shield }
    }
  }

  const getAvatarCls = (role: StaffCredential["role"]) => {
    switch (role) {
      case "doctor":
        return "bg-blue-50 text-blue-600 border border-blue-100"
      case "receptionist":
        return "bg-purple-50 text-purple-600 border border-purple-100"
      case "subadmin":
        return "bg-teal-50 text-teal-600 border border-teal-100"
      case "admin":
        return "bg-[#EEF4F1] text-[#12463E] border border-[#D7E2DC]"
    }
  }

  const departmentOptions: Record<string, string[]> = {
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
      "Psychiatry",
    ],
    receptionist: [
      "Front Desk - OPD",
      "Front Desk - Emergency",
      "Front Desk - Maternity",
      "Front Desk - Pediatrics",
      "Billing Counter",
      "Insurance & Claims",
    ],
  }

  const FILTER_OPTIONS: { value: string; label: string }[] = [
    { value: "all", label: "All Staff" },
    { value: "doctor", label: "Doctors" },
    { value: "receptionist", label: "Receptionists" },
    { value: "subadmin", label: "Sub-admins" },
    { value: "admin", label: "Admins" },
  ]

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
            {FILTER_OPTIONS.map((opt) => (
              <button
                key={opt.value}
                onClick={() => setRoleFilter(opt.value)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold capitalize transition-all ${
                  roleFilter === opt.value
                    ? "bg-emerald-600 text-white shadow-xs"
                    : "text-[#6B8078] hover:text-[#12463E]"
                }`}
              >
                {opt.label}
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

      {/* ─── Notice ───────────────────────────────────── */}
      {notice && (
        <div
          className={`flex items-center gap-3 border text-xs font-medium rounded-2xl px-4 py-3 ${
            notice.type === "success"
              ? "bg-emerald-50 border-emerald-200 text-emerald-800"
              : "bg-red-50 border-red-200 text-red-700"
          }`}
        >
          <Mail className={`h-4 w-4 shrink-0 ${notice.type === "success" ? "text-emerald-600" : "text-red-600"}`} />
          <span className="flex-1">{notice.text}</span>
          <button
            onClick={dismissNotice}
            className="w-6 h-6 rounded-full bg-white/70 hover:bg-white flex items-center justify-center transition-all"
            aria-label="Dismiss"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      )}

      {/* ─── Credentials Table ────────────────────────── */}
      <div className="bg-white rounded-3xl border border-[#E8ECEB] shadow-xs overflow-x-auto">
        {/* Table Header */}
        <div className="grid grid-cols-[1.1fr_110px_1.3fr_140px_90px_275px] gap-3 px-6 py-3.5 border-b border-[#E8ECEB] bg-[#F6F8F7]">
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Staff Member</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Role</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Contact</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Department</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Status</span>
          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider text-right">Actions</span>
        </div>

        {/* Table Rows */}
        {filtered.map((cred) => {
          const badge = getRoleBadge(cred.role)
          return (
            <div
              key={cred.id}
              className={`grid grid-cols-[1.1fr_110px_1.3fr_140px_90px_275px] gap-3 px-6 py-4 border-b border-[#F6F8F7] hover:bg-[#FAFBFA] transition-colors items-center ${
                cred.status === "inactive" ? "opacity-50" : ""
              }`}
            >
              {/* Name & ID */}
              <div className="flex items-center gap-3 min-w-0">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${getAvatarCls(cred.role)}`}>
                  {getRoleIcon(cred.role)}
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-bold text-[#0B2B26] truncate">{cred.fullName}</p>
                  <p className="text-[10px] text-[#8AA098] font-medium mt-0.5">{cred.employeeId}</p>
                </div>
              </div>

              {/* Role Badge */}
              <div>
                <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wider border ${badge.cls}`}>
                  <badge.Icon className="h-3 w-3" />
                  {cred.role === "subadmin" ? "Sub-admin" : cred.role}
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
                    title={cred.status === "active" ? "Suspend account" : "Activate account"}
                    className={`px-2.5 py-1.5 rounded-lg text-[10px] font-bold transition-all border ${
                      cred.status === "active"
                        ? "text-amber-700 bg-amber-50 border-amber-200 hover:bg-amber-100"
                        : "text-emerald-700 bg-emerald-50 border-emerald-200 hover:bg-emerald-100"
                    }`}
                  >
                    {cred.status === "active" ? "Suspend" : "Activate"}
                  </button>
                )}
                <button
                  onClick={() => openEdit(cred)}
                  title="Edit credential"
                  className="px-2.5 py-1.5 rounded-lg text-[10px] font-bold text-[#12463E] bg-[#EEF4F1] border border-[#D7E2DC] hover:bg-[#E0EBE5] transition-all flex items-center gap-1"
                >
                  <Pencil className="h-3 w-3" />
                  Edit
                </button>
                <button
                  onClick={() => openDelete(cred)}
                  title="Delete credential permanently"
                  className="px-2.5 py-1.5 rounded-lg text-[10px] font-bold text-red-700 bg-red-50 border border-red-200 hover:bg-red-100 transition-all flex items-center gap-1"
                >
                  <Trash2 className="h-3 w-3" />
                  Delete
                </button>
                <button
                  onClick={() => setViewCredId(viewCredId === cred.id ? null : cred.id)}
                  className="px-2.5 py-1.5 rounded-lg text-[10px] font-bold text-[#12463E] bg-[#EEF4F1] border border-[#D7E2DC] hover:bg-[#E0EBE5] transition-all"
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
                        {cred.role === "doctor"
                          ? "Doctor Portal"
                          : cred.role === "receptionist"
                          ? "Reception Desk"
                          : "Admin Console"}
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )
        })}

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
                <p className="text-xs text-[#8AA098] mt-0.5">Generate login access for a doctor, sub-admin or receptionist</p>
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
                <div className="grid grid-cols-3 gap-3">
                  <button
                    type="button"
                    onClick={() => { setNewRole("doctor"); setNewDepartment("") }}
                    className={`p-3.5 rounded-2xl border-2 transition-all flex flex-col items-center gap-2 ${
                      newRole === "doctor"
                        ? "border-blue-400 bg-blue-50 shadow-sm"
                        : "border-[#E8ECEB] bg-white hover:border-[#D7E2DC]"
                    }`}
                  >
                    <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${
                      newRole === "doctor" ? "bg-blue-100 text-blue-600" : "bg-[#F6F8F7] text-[#8AA098]"
                    }`}>
                      <Stethoscope className="h-5 w-5" />
                    </div>
                    <div className="text-center">
                      <p className={`text-xs font-bold ${newRole === "doctor" ? "text-blue-700" : "text-[#6B8078]"}`}>Doctor</p>
                      <p className="text-[9px] text-[#8AA098] mt-0.5">Email invite</p>
                    </div>
                  </button>

                  <button
                    type="button"
                    onClick={() => { setNewRole("subadmin"); setNewDepartment("") }}
                    className={`p-3.5 rounded-2xl border-2 transition-all flex flex-col items-center gap-2 ${
                      newRole === "subadmin"
                        ? "border-teal-400 bg-teal-50 shadow-sm"
                        : "border-[#E8ECEB] bg-white hover:border-[#D7E2DC]"
                    }`}
                  >
                    <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${
                      newRole === "subadmin" ? "bg-teal-100 text-teal-600" : "bg-[#F6F8F7] text-[#8AA098]"
                    }`}>
                      <UserCog className="h-5 w-5" />
                    </div>
                    <div className="text-center">
                      <p className={`text-xs font-bold ${newRole === "subadmin" ? "text-teal-700" : "text-[#6B8078]"}`}>Sub-admin</p>
                      <p className="text-[9px] text-[#8AA098] mt-0.5">Permissions</p>
                    </div>
                  </button>

                  <button
                    type="button"
                    onClick={() => { setNewRole("receptionist"); setNewDepartment("") }}
                    className={`p-3.5 rounded-2xl border-2 transition-all flex flex-col items-center gap-2 ${
                      newRole === "receptionist"
                        ? "border-purple-400 bg-purple-50 shadow-sm"
                        : "border-[#E8ECEB] bg-white hover:border-[#D7E2DC]"
                    }`}
                  >
                    <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${
                      newRole === "receptionist" ? "bg-purple-100 text-purple-600" : "bg-[#F6F8F7] text-[#8AA098]"
                    }`}>
                      <ClipboardList className="h-5 w-5" />
                    </div>
                    <div className="text-center">
                      <p className={`text-xs font-bold ${newRole === "receptionist" ? "text-purple-700" : "text-[#6B8078]"}`}>Receptionist</p>
                      <p className="text-[9px] text-[#8AA098] mt-0.5">Generated password</p>
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
                    onChange={(e) => handleFullNameChange(e.target.value)}
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

              {/* Username (auto-generated, editable) */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-[#12463E] flex items-center gap-1.5">
                  Login Username
                  <span className="text-[10px] font-normal text-[#8AA098]">(auto-generated from full name, editable)</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. rajesh_kumar"
                  value={newUserName}
                  onChange={(e) => setNewUserName(e.target.value.toLowerCase().replace(/\s+/g, "_"))}
                  className="w-full h-11 px-3.5 rounded-xl border border-emerald-200 bg-emerald-50/50 text-xs font-mono text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                />
                <p className="text-[10px] text-[#8AA098]">
                  The staff member signs in with this username (or their email) and the password they set via the emailed link.
                </p>
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

                {newRole !== "subadmin" && (
                  <div className="space-y-1.5">
                    <label className="text-xs font-bold text-[#12463E]">Department</label>
                    <select
                      value={newDepartment}
                      onChange={(e) => setNewDepartment(e.target.value)}
                      className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                    >
                      <option value="">Select department</option>
                      {departmentOptions[newRole === "receptionist" ? "receptionist" : "doctor"].map((dept) => (
                        <option key={dept} value={dept}>{dept}</option>
                      ))}
                    </select>
                  </div>
                )}
              </div>

              {/* Role-specific auth setup */}
              {newRole === "doctor" ? (
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E] flex items-center gap-1.5">
                    <Mail className="h-3.5 w-3.5 text-emerald-600" />
                    Password Set-Up (Email Invite)
                  </label>
                  <div className="rounded-xl border border-emerald-200 bg-emerald-50/50 px-4 py-3.5">
                    <p className="text-[11px] text-[#3E6B5C] leading-relaxed">
                      A secure password-set link will be emailed to{" "}
                      <span className="font-bold text-emerald-800">{newEmail || "this doctor"}</span>.
                      The doctor uses the link to create their own password, then signs in to the
                      Doctor Portal. Only this doctor&apos;s account will have access.
                    </p>
                  </div>
                </div>
              ) : newRole === "subadmin" ? (
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E] flex items-center gap-1.5">
                    <KeySquare className="h-3.5 w-3.5 text-teal-600" />
                    Permissions
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. ALL  (or comma-separated: DOCTOR_MANAGE, PATIENT_VIEW)"
                    value={newPermissions}
                    onChange={(e) => setNewPermissions(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                  <p className="text-[10px] text-[#8AA098]">
                    Leave blank to grant ALL permissions. The sub-admin logs in with the password below.
                  </p>
                </div>
              ) : null}

              {/* Generated password (sub-admin & receptionist) */}
              {newRole !== "doctor" && (
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
                    Share this password securely with the staff member.
                  </p>
                </div>
              )}

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

      {/* ═══════════════════════════════════════════════════ */}
      {/*  EDIT CREDENTIAL MODAL                             */}
      {/* ═══════════════════════════════════════════════════ */}
      {isEditOpen && editCred && (
        <>
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity" onClick={() => setIsEditOpen(false)} />

          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in max-h-[90vh] overflow-y-auto">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-[#E8ECEB] pb-4">
              <div>
                <h3 className="text-lg font-bold text-[#0B2B26] flex items-center gap-2">
                  <UserCheck className="h-5 w-5 text-emerald-600" />
                  Edit Credential
                </h3>
                <p className="text-xs text-[#8AA098] mt-0.5">
                  Update {editCred.fullName} ({editCred.role === "subadmin" ? "sub-admin" : editCred.role})
                </p>
              </div>
              <button
                onClick={() => setIsEditOpen(false)}
                className="w-8 h-8 rounded-full bg-[#F6F8F7] hover:bg-[#EEF4F1] flex items-center justify-center transition-all text-[#6B8078]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <form onSubmit={handleEditSubmit} className="space-y-4 py-4">
              {editError && (
                <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 text-xs font-medium rounded-xl px-4 py-2.5">
                  <AlertCircle className="h-4 w-4 shrink-0" />
                  {editError}
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">
                    Full Name {editCred.role === "doctor" && <span className="text-[#8AA098] font-normal">(without Dr.)</span>}
                  </label>
                  <input
                    type="text"
                    required
                    value={editFullName}
                    onChange={(e) => setEditFullName(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Email Address</label>
                  <input
                    type="email"
                    required
                    value={editEmail}
                    onChange={(e) => setEditEmail(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Phone Number</label>
                  <input
                    type="tel"
                    value={editPhone}
                    onChange={(e) => setEditPhone(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Status</label>
                  <select
                    value={editStatus}
                    onChange={(e) => setEditStatus(e.target.value as StaffCredential["status"])}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="active">Active</option>
                    <option value="suspended">Suspended</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
              </div>

              {(editCred.role === "doctor" || editCred.role === "receptionist") && (
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Department</label>
                  <select
                    value={editDepartment}
                    onChange={(e) => setEditDepartment(e.target.value)}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="">Select department</option>
                    {departmentOptions[editCred.role].map((dept) => (
                      <option key={dept} value={dept}>{dept}</option>
                    ))}
                  </select>
                </div>
              )}

              {!editCred.user_id && (
                <p className="text-[10px] text-amber-700 bg-amber-50 border border-amber-200 rounded-xl px-3 py-2">
                  This record is from demo data and is not saved in the database yet.
                </p>
              )}

              <div className="flex gap-3 border-t border-[#E8ECEB] pt-4 mt-2">
                <button
                  type="button"
                  onClick={() => setIsEditOpen(false)}
                  className="flex-1 h-11 rounded-xl border border-[#D7E2DC] text-xs font-bold text-[#6B8078] hover:bg-[#F6F8F7] transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={editSaving}
                  className="flex-1 h-11 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 shadow-md shadow-emerald-600/10 transition-all flex items-center justify-center gap-2 disabled:opacity-60"
                >
                  {editSaving ? (
                    <>Saving...</>
                  ) : (
                    <><BadgeCheck className="h-4 w-4" /> Save Changes</>
                  )}
                </button>
              </div>
            </form>
          </div>
        </>
      )}

      {/* ═══════════════════════════════════════════════════ */}
      {/*  DELETE CONFIRMATION MODAL                         */}
      {/* ═══════════════════════════════════════════════════ */}
      {isDeleteOpen && deletingCred && (
        <>
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity" onClick={() => setIsDeleteOpen(false)} />

          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 rounded-2xl bg-red-50 border border-red-200 flex items-center justify-center text-red-600 shrink-0">
                <Trash2 className="h-6 w-6" />
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-bold text-[#0B2B26]">Delete credential?</h3>
                <p className="text-xs text-[#6B8078] mt-1 leading-relaxed">
                  This will <span className="font-bold text-red-600">permanently delete</span> the
                  account for <span className="font-bold text-[#12463E]">{deletingCred.fullName}</span>{" "}
                  ({deletingCred.role === "subadmin" ? "sub-admin" : deletingCred.role} — {deletingCred.email}).
                  The user will immediately lose access and this cannot be undone.
                </p>
              </div>
            </div>

            {deleteError && (
              <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 text-xs font-medium rounded-xl px-4 py-2.5 mt-4">
                <AlertCircle className="h-4 w-4 shrink-0" />
                {deleteError}
              </div>
            )}

            <div className="flex gap-3 border-t border-[#E8ECEB] pt-4 mt-5">
              <button
                onClick={() => setIsDeleteOpen(false)}
                className="flex-1 h-11 rounded-xl border border-[#D7E2DC] text-xs font-bold text-[#6B8078] hover:bg-[#F6F8F7] transition-all"
              >
                Cancel
              </button>
              <button
                onClick={handleDelete}
                disabled={deleting}
                className="flex-1 h-11 rounded-xl bg-red-600 text-white text-xs font-bold hover:bg-red-700 shadow-md shadow-red-600/10 transition-all flex items-center justify-center gap-2 disabled:opacity-60"
              >
                {deleting ? (
                  <>Deleting...</>
                ) : (
                  <><Trash2 className="h-4 w-4" /> Delete Permanently</>
                )}
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
