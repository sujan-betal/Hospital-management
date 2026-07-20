"use client"

import React, { useState } from "react"
import {
  Search,
  Filter,
  Plus,
  X,
  CheckCircle,
  XCircle,
  Clock,
  ArrowRight,
  Calendar,
  AlertCircle,
  Heart
} from "lucide-react"
import { Admission, Bed } from "../mockData"

interface AdmissionsProps {
  reservations: Admission[]
  rooms: Bed[]
  onAddReservation: (adm: Admission) => void
  onUpdateReservation: (adm: Admission) => void
  isCreateOpen: boolean
  setIsCreateOpen: (open: boolean) => void
}

export function PatientAdmissions({
  reservations,
  rooms,
  onAddReservation,
  onUpdateReservation,
  isCreateOpen,
  setIsCreateOpen
}: AdmissionsProps) {
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")

  // Form State for New Admission
  const [newPatientName, setNewPatientName] = useState("")
  const [newPatientAge, setNewPatientAge] = useState<number>(30)
  const [newPatientGender, setNewPatientGender] = useState<Admission["patientGender"]>("Male")
  const [newWardType, setNewWardType] = useState<Bed["ward"]>("General Ward")
  const [newAdmitDate, setNewAdmitDate] = useState("")
  const [newDischargeDate, setNewDischargeDate] = useState("")
  const [newBedId, setNewBedId] = useState("Pending")
  const [newInsurance, setNewInsurance] = useState<Admission["insuranceStatus"]>("covered")
  const [newEmail, setNewEmail] = useState("")
  const [newPhone, setNewPhone] = useState("")

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault()
    if (!newPatientName || !newAdmitDate || !newDischargeDate) return

    // Calculate billing amount based on nights and ward type daily charges
    const start = new Date(newAdmitDate)
    const end = new Date(newDischargeDate)
    const days = Math.max(1, Math.round((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)))
    
    const wardRates: Record<Bed["ward"], number> = {
      "ICU": 850,
      "Emergency": 400,
      "General Ward": 150,
      "Pediatrics": 200,
      "Maternity": 300
    }
    const rate = wardRates[newWardType]
    const billingAmount = rate * days

    const newAdm: Admission = {
      id: `ADM-${Math.floor(1000 + Math.random() * 9000)}`,
      patientName: newPatientName,
      patientAge: Number(newPatientAge),
      patientGender: newPatientGender,
      wardType: newWardType,
      bedId: newBedId,
      admitDate: newAdmitDate,
      dischargeDate: newDischargeDate,
      billingAmount,
      status: "admitted",
      insuranceStatus: newInsurance,
      patientEmail: newEmail || `${newPatientName.toLowerCase().replace(/\s+/g, "")}@hospital.com`,
      patientPhone: newPhone || "+1 (555) 000-0000"
    }

    onAddReservation(newAdm)
    
    // Reset Form
    setNewPatientName("")
    setNewPatientAge(30)
    setNewPatientGender("Male")
    setNewAdmitDate("")
    setNewDischargeDate("")
    setNewBedId("Pending")
    setNewInsurance("covered")
    setNewEmail("")
    setNewPhone("")
    setIsCreateOpen(false)
  }

  // Filter admissions
  const filteredAdmissions = reservations.filter((adm) => {
    const matchesSearch =
      adm.patientName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      adm.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      adm.bedId.toLowerCase().includes(searchQuery.toLowerCase())
    
    const matchesStatus = statusFilter === "all" || adm.status === statusFilter

    return matchesSearch && matchesStatus
  })

  const getStatusColor = (status: Admission["status"]) => {
    switch (status) {
      case "admitted":
        return "bg-emerald-50 text-emerald-700 border-emerald-100 font-extrabold"
      case "scheduled":
        return "bg-blue-50 text-blue-700 border-blue-100"
      case "discharged":
        return "bg-gray-100 text-gray-700 border-gray-200"
      case "cancelled":
        return "bg-rose-50 text-rose-700 border-rose-100"
      default:
        return "bg-gray-50 text-gray-700 border-gray-100"
    }
  }

  const getInsuranceStatusColor = (status: Admission["insuranceStatus"]) => {
    switch (status) {
      case "covered":
        return "bg-emerald-50 text-emerald-600 border-emerald-100"
      case "pending":
        return "bg-amber-50 text-amber-600 border-amber-100"
      case "uninsured":
        return "bg-rose-50 text-rose-600 border-rose-100"
      default:
        return "bg-gray-50 text-gray-600"
    }
  }

  const handleAction = (adm: Admission, action: "admit" | "discharge" | "cancel") => {
    if (action === "admit") {
      // Find an available bed of the same ward type to assign
      const matchingAvailableBed = rooms.find(
        (r) => r.ward === adm.wardType && r.status === "available"
      )
      
      const assignedBedNo = matchingAvailableBed ? matchingAvailableBed.id : "GEN-302" // fallback
      onUpdateReservation({
        ...adm,
        status: "admitted",
        bedId: assignedBedNo
      })
    } else if (action === "discharge") {
      onUpdateReservation({
        ...adm,
        status: "discharged"
      })
    } else if (action === "cancel") {
      onUpdateReservation({
        ...adm,
        status: "cancelled"
      })
    }
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Search & Actions Bar */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs">
        <div className="flex items-center gap-2 bg-[#F6F8F7] border border-[#D7E2DC] px-3.5 py-2 rounded-xl w-full md:w-80">
          <Search className="h-4 w-4 text-[#8AA098]" />
          <input
            type="text"
            placeholder="Search admissions by Patient, ADM ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="bg-transparent border-0 outline-none text-xs text-[#0B2B26] w-full placeholder:text-[#9CAEA6] focus:ring-0"
          />
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Status filtering */}
          <div className="flex bg-[#F6F8F7] border border-[#D7E2DC] p-1 rounded-xl">
            {["all", "admitted", "scheduled", "discharged", "cancelled"].map((status) => (
              <button
                key={status}
                onClick={() => setStatusFilter(status)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold capitalize transition-all ${
                  statusFilter === status
                    ? "bg-emerald-600 text-white shadow-xs"
                    : "text-[#6B8078] hover:text-[#12463E]"
                }`}
              >
                {status}
              </button>
            ))}
          </div>

          <button
            onClick={() => setIsCreateOpen(true)}
            className="h-10 px-4 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs shadow-md shadow-emerald-500/10 transition-all flex items-center gap-2"
          >
            <Plus className="h-4 w-4" />
            Admit Patient
          </button>
        </div>
      </div>

      {/* Admissions Table */}
      <div className="bg-white rounded-3xl border border-[#E8ECEB] shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-[#F6F8F7] border-b border-[#E8ECEB] text-[10px] font-bold text-[#8AA098] tracking-widest uppercase">
                <th className="p-5">Admission ID</th>
                <th className="p-5">Patient Details</th>
                <th className="p-5">Ward Category</th>
                <th className="p-5">Bed #</th>
                <th className="p-5">Hospitalization Dates</th>
                <th className="p-5">Treatment Bill</th>
                <th className="p-5">Status</th>
                <th className="p-5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8ECEB] text-xs text-[#0B2B26]">
              {filteredAdmissions.length > 0 ? (
                filteredAdmissions.map((adm) => (
                  <tr key={adm.id} className="hover:bg-[#F6F8F7]/40 transition-colors">
                    <td className="p-5 font-bold text-emerald-600">{adm.id}</td>
                    <td className="p-5">
                      <div>
                        <p className="font-bold text-[#0B2B26]">{adm.patientName}</p>
                        <p className="text-[10px] text-[#6B8078] mt-0.5">
                          {adm.patientAge} yrs · {adm.patientGender} · {adm.patientPhone}
                        </p>
                      </div>
                    </td>
                    <td className="p-5 font-semibold text-[#4B5F58]">{adm.wardType}</td>
                    <td className="p-5">
                      <span className={`px-2.5 py-1 rounded-lg text-xs font-bold ${
                        adm.bedId === "Pending" ? "bg-amber-50 text-amber-800" : "bg-[#EEF4F1] text-[#12463E]"
                      }`}>
                        {adm.bedId}
                      </span>
                    </td>
                    <td className="p-5">
                      <div className="flex items-center gap-1.5">
                        <span className="font-medium text-[#0B2B26]">{adm.admitDate}</span>
                        <ArrowRight className="h-3 w-3 text-[#8AA098]" />
                        <span className="font-medium text-[#0B2B26]">{adm.dischargeDate}</span>
                      </div>
                    </td>
                    <td className="p-5 font-bold text-[#0B2B26]">
                      <div>
                        <span>Rs. {adm.billingAmount}</span>
                        <span className={`ml-2 inline-flex items-center px-1.5 py-0.5 rounded-md border text-[9px] font-semibold uppercase ${getInsuranceStatusColor(adm.insuranceStatus)}`}>
                          {adm.insuranceStatus}
                        </span>
                      </div>
                    </td>
                    <td className="p-5">
                      <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full border text-[10px] font-bold capitalize ${getStatusColor(adm.status)}`}>
                        {adm.status}
                      </span>
                    </td>
                    <td className="p-5 text-right space-x-1.5">
                      {adm.status === "scheduled" && (
                        <button
                          onClick={() => handleAction(adm, "admit")}
                          className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-[10px] font-bold transition-all"
                        >
                          Admit Inpatient
                        </button>
                      )}
                      {adm.status === "admitted" && (
                        <button
                          onClick={() => handleAction(adm, "discharge")}
                          className="px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-700 text-white text-[10px] font-bold transition-all"
                        >
                          Discharge
                        </button>
                      )}
                      {adm.status !== "cancelled" && adm.status !== "discharged" && (
                        <button
                          onClick={() => handleAction(adm, "cancel")}
                          className="px-3 py-1.5 rounded-lg border border-[#C4392A]/20 hover:bg-rose-50 text-[#C4392A] text-[10px] font-bold transition-all"
                        >
                          Cancel
                        </button>
                      )}
                      {(adm.status === "cancelled" || adm.status === "discharged") && (
                        <span className="text-[10px] text-[#8AA098] font-bold italic pr-2">Archived</span>
                      )}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={8} className="p-10 text-center text-[#8AA098]">
                    No patient admission records match your query.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Admit Patient Modal */}
      {isCreateOpen && (
        <>
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity" onClick={() => setIsCreateOpen(false)} />
          
          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in">
            <div className="flex items-center justify-between border-b border-[#E8ECEB] pb-4">
              <div>
                <h3 className="text-lg font-bold text-[#0B2B26]">Create Inpatient Admission</h3>
                <p className="text-xs text-[#8AA098]">Register new clinical intake and allocate ward space</p>
              </div>
              <button
                onClick={() => setIsCreateOpen(false)}
                className="w-8 h-8 rounded-full bg-[#F6F8F7] hover:bg-[#EEF4F1] flex items-center justify-center transition-all text-[#6B8078]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <form onSubmit={handleCreate} className="space-y-4 py-4">
              <div className="grid grid-cols-3 gap-4">
                {/* Patient Name */}
                <div className="col-span-2 space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Patient Full Name</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. John Miller"
                    value={newPatientName}
                    onChange={(e) => setNewPatientName(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>

                {/* Age */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Age</label>
                  <input
                    type="number"
                    required
                    min={0}
                    max={120}
                    value={newPatientAge}
                    onChange={(e) => setNewPatientAge(Number(e.target.value))}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                {/* Gender */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Gender</label>
                  <select
                    value={newPatientGender}
                    onChange={(e) => setNewPatientGender(e.target.value as Admission["patientGender"])}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    <option value="Other">Other</option>
                  </select>
                </div>

                {/* Ward Type */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Ward Category</label>
                  <select
                    value={newWardType}
                    onChange={(e) => setNewWardType(e.target.value as Bed["ward"])}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="General Ward">General Ward (Rs. 150/day)</option>
                    <option value="ICU">ICU Ward (Rs. 850/day)</option>
                    <option value="Emergency">Emergency Room (Rs. 400/day)</option>
                    <option value="Pediatrics">Pediatrics (Rs. 200/day)</option>
                    <option value="Maternity">Maternity (Rs. 300/day)</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                {/* Email */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Email Address</label>
                  <input
                    type="email"
                    placeholder="patient@mail.com"
                    value={newEmail}
                    onChange={(e) => setNewEmail(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>

                {/* Phone */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Contact Number</label>
                  <input
                    type="tel"
                    placeholder="+1 (555) 012-3456"
                    value={newPhone}
                    onChange={(e) => setNewPhone(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                {/* Admit Date */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Admission Date</label>
                  <input
                    type="date"
                    required
                    value={newAdmitDate}
                    onChange={(e) => setNewAdmitDate(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>

                {/* Discharge Date */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Expected Discharge</label>
                  <input
                    type="date"
                    required
                    value={newDischargeDate}
                    onChange={(e) => setNewDischargeDate(e.target.value)}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                {/* Bed Assignment Options */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Bed Allocation</label>
                  <select
                    value={newBedId}
                    onChange={(e) => setNewBedId(e.target.value)}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="Pending">Keep Pending (Auto-assign on arrival)</option>
                    {rooms
                      .filter((r) => r.ward === newWardType && r.status === "available")
                      .map((r) => (
                        <option key={r.id} value={r.id}>
                          {r.id} (Floor {r.floor} - Ready)
                        </option>
                      ))}
                  </select>
                </div>

                {/* Insurance status */}
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Insurance Status</label>
                  <select
                    value={newInsurance}
                    onChange={(e) => setNewInsurance(e.target.value as Admission["insuranceStatus"])}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="covered">Insured (Full Coverage)</option>
                    <option value="pending">Pre-authorization Pending</option>
                    <option value="uninsured">Uninsured (Self Pay)</option>
                  </select>
                </div>
              </div>

              {/* Live Cost calculation summary */}
              {newAdmitDate && newDischargeDate && (
                <div className="p-3 bg-emerald-50 rounded-2xl border border-emerald-100 flex items-center justify-between text-xs text-[#12463E]">
                  <div>
                    <span className="font-bold block">Estimated Hospitalization Charges</span>
                    <span className="text-[10px] text-emerald-800">
                      Standard daily ward calculations apply.
                    </span>
                  </div>
                  <div className="text-right">
                    <span className="text-base font-black text-[#12463E]">
                      Rs. {(() => {
                        const start = new Date(newAdmitDate)
                        const end = new Date(newDischargeDate)
                        const days = Math.max(1, Math.round((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)))
                        const rates = { "General Ward": 150, "ICU": 850, "Emergency": 400, "Pediatrics": 200, "Maternity": 300 }
                        return (rates[newWardType] * days).toLocaleString()
                      })()}
                    </span>
                    <span className="text-[9px] text-emerald-800 block">estimated co-pay</span>
                  </div>
                </div>
              )}

              {/* Modal Actions */}
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
                  className="flex-1 h-11 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 shadow-md shadow-emerald-600/10 transition-all"
                >
                  Confirm intake
                </button>
              </div>
            </form>
          </div>
        </>
      )}
    </div>
  )
}
