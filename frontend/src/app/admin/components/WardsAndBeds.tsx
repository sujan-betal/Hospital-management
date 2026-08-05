"use client"

import React, { useState } from "react"
import {
  Search,
  Filter,
  CreditCard,
  User,
  Activity,
  CheckCircle,
  HelpCircle,
  X,
  Edit,
  Wrench,
  Sparkles,
  ShieldAlert,
  Plus,
  Trash2,
  Loader
} from "lucide-react"
import { Bed } from "../mockData"

interface BedsProps {
  beds: Bed[]
  loading?: boolean
  onAddBed: (bed: Bed) => boolean | Promise<boolean>
  onUpdateBed: (bed: Bed) => void | boolean | Promise<boolean | void>
  onDeleteBed: (bedId: string) => boolean | Promise<boolean>
}

const COMMON_WARDS = ["ICU", "Emergency", "General Ward", "Pediatrics", "Maternity"]

export function WardsAndBeds({ beds, loading = false, onAddBed, onUpdateBed, onDeleteBed }: BedsProps) {
  const [statusFilter, setStatusFilter] = useState<string>("all")
  const [wardFilter, setWardFilter] = useState<string>("all")
  const [searchQuery, setSearchQuery] = useState<string>("")
  
  // State for active edit modal
  const [editingBed, setEditingBed] = useState<Bed | null>(null)
  const [editPrice, setEditPrice] = useState<number>(0)
  const [editStatus, setEditStatus] = useState<Bed["status"]>("available")
  const [editNurse, setEditNurse] = useState<string>("")

  // State for add-bed modal
  const [isAddOpen, setIsAddOpen] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [newBedId, setNewBedId] = useState("")
  const [newWard, setNewWard] = useState("General Ward")
  const [newFloor, setNewFloor] = useState(1)
  const [newPrice, setNewPrice] = useState(150)
  const [newNurse, setNewNurse] = useState("Nurse Sarah Jenkins")
  const [newEquipment, setNewEquipment] = useState("")
  const [newStatus, setNewStatus] = useState<Bed["status"]>("available")

  const nursesList = ["Nurse Sarah Jenkins", "Nurse David Vance", "Nurse Maria Gomez", "Nurse John Doe", "Nurse Chloe Adams"]
  const knownWards = Array.from(new Set([...COMMON_WARDS, ...beds.map((b) => b.ward)])).sort()

  const handleOpenEdit = (bed: Bed) => {
    setEditingBed(bed)
    setEditPrice(bed.price)
    setEditStatus(bed.status)
    setEditNurse(bed.assignedNurse)
  }

  const handleSaveEdit = () => {
    if (!editingBed) return
    const updated: Bed = {
      ...editingBed,
      price: editPrice,
      status: editStatus,
      assignedNurse: editNurse,
      patient: editStatus !== "occupied" ? null : editingBed.patient // clear patient if not occupied
    }
    onUpdateBed(updated)
    setEditingBed(null)
  }

  const handleSubmitAdd = async () => {
    if (!newBedId.trim() || !newWard.trim()) return
    setIsSubmitting(true)
    const ok = await onAddBed({
      id: newBedId.trim().toUpperCase(),
      ward: newWard.trim(),
      status: newStatus,
      price: newPrice,
      floor: newFloor,
      assignedNurse: newNurse,
      equipment: newEquipment.split(",").map((e) => e.trim()).filter(Boolean),
      patient: newStatus === "occupied" ? "Pending" : null,
    })
    setIsSubmitting(false)
    if (ok) {
      setNewBedId("")
      setNewWard("General Ward")
      setNewFloor(1)
      setNewPrice(150)
      setNewNurse("Nurse Sarah Jenkins")
      setNewEquipment("")
      setNewStatus("available")
      setIsAddOpen(false)
    }
  }

  const handleDelete = async (bedId: string) => {
    if (!window.confirm(`Delete bed ${bedId}? This cannot be undone.`)) return
    await onDeleteBed(bedId)
  }

  // Filter logic
  const filteredBeds = beds.filter((bed) => {
    const matchesStatus = statusFilter === "all" || bed.status === statusFilter
    const matchesWard = wardFilter === "all" || bed.ward === wardFilter
    const matchesSearch =
      bed.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (bed.patient && bed.patient.toLowerCase().includes(searchQuery.toLowerCase())) ||
      bed.assignedNurse.toLowerCase().includes(searchQuery.toLowerCase())

    return matchesStatus && matchesWard && matchesSearch
  })

  const getStatusColor = (status: Bed["status"]) => {
    switch (status) {
      case "available":
        return "bg-blue-50 text-blue-700 border-blue-100"
      case "occupied":
        return "bg-emerald-50 text-emerald-700 border-emerald-100"
      case "sanitizing":
        return "bg-amber-50 text-amber-700 border-amber-100"
      case "reserved":
        return "bg-rose-50 text-rose-700 border-rose-100"
      default:
        return "bg-gray-50 text-gray-700 border-gray-100"
    }
  }

  const getStatusIcon = (status: Bed["status"]) => {
    switch (status) {
      case "available":
        return <CheckCircle className="h-3.5 w-3.5" />
      case "occupied":
        return <User className="h-3.5 w-3.5" />
      case "sanitizing":
        return <Sparkles className="h-3.5 w-3.5 animate-spin-slow" />
      case "reserved":
        return <ShieldAlert className="h-3.5 w-3.5" />
      default:
        return <HelpCircle className="h-3.5 w-3.5" />
    }
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header and filters */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs">
        <div className="flex items-center gap-2 bg-[#F6F8F7] border border-[#D7E2DC] px-3.5 py-2 rounded-xl w-full md:w-80">
          <Search className="h-4 w-4 text-[#8AA098]" />
          <input
            type="text"
            placeholder="Search by Bed ID, Patient, Nurse..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="bg-transparent border-0 outline-none text-xs text-[#0B2B26] w-full placeholder:text-[#9CAEA6] focus:ring-0"
          />
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Add Bed button */}
          <button
            onClick={() => setIsAddOpen(true)}
            className="flex items-center gap-2 h-10 px-4 rounded-xl bg-emerald-600 text-white text-xs font-bold shadow-md shadow-emerald-600/10 hover:bg-emerald-700 transition-all"
          >
            <Plus className="h-4 w-4" />
            Add Bed
          </button>

          {/* Status filter tabs */}
          <div className="flex bg-[#F6F8F7] border border-[#D7E2DC] p-1 rounded-xl">
            {["all", "available", "occupied", "sanitizing", "reserved"].map((status) => (
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

          {/* Ward Selector */}
          <div className="relative">
            <select
              value={wardFilter}
              onChange={(e) => setWardFilter(e.target.value)}
              className="appearance-none h-10 px-4 pr-10 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs font-semibold text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 cursor-pointer"
            >
              <option value="all">All Wards</option>
              {knownWards.map((ward) => (
                <option key={ward} value={ward}>
                  {ward}
                </option>
              ))}
            </select>
            <Filter className="absolute right-3.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[#8AA098] pointer-events-none" />
          </div>
        </div>
      </div>

      {/* Bed Cards Grid */}
      {loading ? (
        <div className="bg-white p-16 rounded-3xl border border-[#E8ECEB] text-center max-w-lg mx-auto flex items-center justify-center gap-3">
          <Loader className="h-5 w-5 text-emerald-600 animate-spin" />
          <p className="text-sm text-[#8AA098]">Loading beds...</p>
        </div>
      ) : filteredBeds.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          {filteredBeds.map((bed) => (
            <div
              key={bed.id}
              onClick={() => handleOpenEdit(bed)}
              className="bg-white rounded-3xl border border-[#E8ECEB] hover:border-emerald-600 p-5 shadow-xs hover:shadow-lg transition-all duration-300 cursor-pointer group flex flex-col justify-between relative overflow-hidden"
            >
              {/* Top Details */}
              <div>
                <div className="flex items-start justify-between">
                  <div>
                    <span className="text-[10px] text-[#8AA098] font-bold uppercase tracking-wider">Floor {bed.floor}</span>
                    <h3 className="text-lg font-black text-[#0B2B26] mt-0.5 group-hover:text-emerald-600 transition-colors">
                      {bed.id}
                    </h3>
                  </div>
                  
                  <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full border text-[10px] font-bold capitalize ${getStatusColor(bed.status)}`}>
                    {getStatusIcon(bed.status)}
                    {bed.status}
                  </span>
                </div>

                <p className="text-xs font-bold text-[#4B5F58] mt-3.5">{bed.ward} Ward</p>

                {/* Patient details */}
                {bed.status === "occupied" && bed.patient && (
                  <div className="mt-3 p-2.5 bg-emerald-50/50 rounded-xl border border-emerald-100/50 text-[11px] text-[#12463E] flex items-center gap-2">
                    <User className="h-3.5 w-3.5 text-emerald-500 shrink-0" />
                    <span className="font-semibold truncate">Patient: {bed.patient}</span>
                  </div>
                )}
                
                {bed.status === "sanitizing" && (
                  <div className="mt-3 p-2.5 bg-amber-50/50 rounded-xl border border-amber-100/50 text-[11px] text-amber-800 flex items-center gap-2">
                    <Sparkles className="h-3.5 w-3.5 text-amber-500 shrink-0" />
                    <span className="font-semibold truncate">Cleaner: {bed.assignedNurse}</span>
                  </div>
                )}

                {/* Equipment list */}
                <div className="mt-4">
                  <span className="text-[9px] text-[#8AA098] font-bold block mb-1">EQUIPMENT</span>
                  <div className="flex flex-wrap gap-1">
                    {bed.equipment.map((eq, i) => (
                      <span key={i} className="text-[9px] bg-[#EEF4F1] text-[#6B8078] px-2 py-0.5 rounded-md font-medium">
                        {eq}
                      </span>
                    ))}
                  </div>
                </div>
              </div>

              {/* Bottom Price & Edit CTA */}
              <div className="mt-6 pt-4 border-t border-[#F6F8F7] flex items-center justify-between">
                <div>
                  <span className="text-[10px] text-[#8AA098] block font-medium">Daily Rate</span>
                  <span className="text-sm font-black text-[#12463E]">Rs. {bed.price}</span>
                </div>
                
                <div className="flex items-center gap-2">
                  <span
                    onClick={(e) => {
                      e.stopPropagation()
                      handleDelete(bed.id)
                    }}
                    title="Delete bed"
                    className="w-8 h-8 rounded-lg bg-[#FDF1F1] text-rose-500 hover:bg-rose-500 hover:text-white flex items-center justify-center transition-all"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </span>
                  <span className="w-8 h-8 rounded-lg bg-[#EEF4F1] text-[#12463E] hover:bg-emerald-600 hover:text-white flex items-center justify-center transition-all">
                    <Edit className="h-3.5 w-3.5" />
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white p-16 rounded-3xl border border-[#E8ECEB] text-center max-w-lg mx-auto">
          <p className="text-sm text-[#8AA098]">No beds match your filter settings. Try adjusting your parameters.</p>
        </div>
      )}

      {/* Edit Bed Modal Dialog */}
      {editingBed && (
        <>
          {/* Backdrop */}
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity" onClick={() => setEditingBed(null)} />
          
          {/* Modal Container */}
          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in">
            <div className="flex items-center justify-between border-b border-[#E8ECEB] pb-4">
              <div>
                <h3 className="text-lg font-bold text-[#0B2B26]">Update Bed {editingBed.id}</h3>
                <p className="text-xs text-[#8AA098]">{editingBed.ward} Ward</p>
              </div>
              <button
                onClick={() => setEditingBed(null)}
                className="w-8 h-8 rounded-full bg-[#F6F8F7] hover:bg-[#EEF4F1] flex items-center justify-center transition-all text-[#6B8078]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="space-y-4 py-4">
              {/* Bed Status */}
              <div className="space-y-2">
                <label className="text-xs font-bold text-[#12463E]">Bed Occupancy Status</label>
                <div className="grid grid-cols-2 gap-2">
                  {(["available", "occupied", "sanitizing", "reserved"] as const).map((status) => (
                    <button
                      key={status}
                      type="button"
                      onClick={() => setEditStatus(status)}
                      className={`h-11 rounded-xl border text-xs font-bold flex items-center justify-center gap-2 transition-all capitalize ${
                        editStatus === status
                          ? "border-emerald-600 bg-emerald-50 text-emerald-700 font-black"
                          : "border-[#D7E2DC] text-[#6B8078] hover:bg-[#F6F8F7]"
                      }`}
                    >
                      {getStatusIcon(status)}
                      {status}
                    </button>
                  ))}
                </div>
              </div>

              {/* Bed Daily Charge */}
              <div className="space-y-2">
                <label className="text-xs font-bold text-[#12463E]">Daily Charge (Rs.)</label>
                <div className="relative">
                  <CreditCard className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[#8AA098]" />
                  <input
                    type="number"
                    value={editPrice}
                    onChange={(e) => setEditPrice(Number(e.target.value))}
                    className="w-full h-11 pl-9 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>
              </div>

              {/* Nurse Assignment */}
              <div className="space-y-2">
                <label className="text-xs font-bold text-[#12463E]">Assigned Nurse</label>
                <select
                  value={editNurse}
                  onChange={(e) => setEditNurse(e.target.value)}
                  className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  {nursesList.map((n, i) => (
                    <option key={i} value={n}>
                      {n}
                    </option>
                  ))}
                </select>
              </div>

              {/* Patient allocation */}
              {editingBed.status === "occupied" && editingBed.patient && (
                <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-100 text-xs text-emerald-800">
                  <span className="font-bold block">Attended Inpatient</span>
                  <span className="mt-0.5 block">{editingBed.patient} (Under clinical observations)</span>
                </div>
              )}
            </div>

            {/* Modal Actions */}
            <div className="flex gap-3 border-t border-[#E8ECEB] pt-4 mt-2">
              <button
                type="button"
                onClick={() => setEditingBed(null)}
                className="flex-1 h-11 rounded-xl border border-[#D7E2DC] text-xs font-bold text-[#6B8078] hover:bg-[#F6F8F7] transition-all"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleSaveEdit}
                className="flex-1 h-11 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 shadow-md shadow-emerald-600/10 transition-all"
              >
                Save Changes
              </button>
            </div>
          </div>
        </>
      )}

      {/* Add Bed Modal Dialog */}
      {isAddOpen && (
        <>
          {/* Backdrop */}
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 transition-opacity" onClick={() => setIsAddOpen(false)} />
          
          {/* Modal Container */}
          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-[#E8ECEB] pb-4">
              <div>
                <h3 className="text-lg font-bold text-[#0B2B26]">Add New Bed</h3>
                <p className="text-xs text-[#8AA098]">Register a bed and assign it to a ward</p>
              </div>
              <button
                onClick={() => setIsAddOpen(false)}
                className="w-8 h-8 rounded-full bg-[#F6F8F7] hover:bg-[#EEF4F1] flex items-center justify-center transition-all text-[#6B8078]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="space-y-4 py-4">
              {/* Bed ID */}
              <div className="space-y-2">
                <label className="text-xs font-bold text-[#12463E]">Bed ID</label>
                <input
                  type="text"
                  value={newBedId}
                  onChange={(e) => setNewBedId(e.target.value)}
                  placeholder="e.g. ICU-103"
                  className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                />
              </div>

              {/* Ward */}
              <div className="space-y-2">
                <label className="text-xs font-bold text-[#12463E]">Ward</label>
                <input
                  type="text"
                  list="ward-options"
                  value={newWard}
                  onChange={(e) => setNewWard(e.target.value)}
                  placeholder="Select or type a new ward name"
                  className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                />
                <datalist id="ward-options">
                  {knownWards.map((ward) => (
                    <option key={ward} value={ward} />
                  ))}
                </datalist>
                <p className="text-[10px] text-[#9CAEA6]">Pick an existing ward or type a new one to create it.</p>
              </div>

              {/* Floor & Price */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2">
                  <label className="text-xs font-bold text-[#12463E]">Floor</label>
                  <input
                    type="number"
                    value={newFloor}
                    onChange={(e) => setNewFloor(Number(e.target.value))}
                    className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-xs font-bold text-[#12463E]">Daily Charge (Rs.)</label>
                  <div className="relative">
                    <CreditCard className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[#8AA098]" />
                    <input
                      type="number"
                      value={newPrice}
                      onChange={(e) => setNewPrice(Number(e.target.value))}
                      className="w-full h-11 pl-9 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                    />
                  </div>
                </div>
              </div>

              {/* Status */}
              <div className="space-y-2">
                <label className="text-xs font-bold text-[#12463E]">Bed Occupancy Status</label>
                <div className="grid grid-cols-2 gap-2">
                  {(["available", "occupied", "sanitizing", "reserved"] as const).map((status) => (
                    <button
                      key={status}
                      type="button"
                      onClick={() => setNewStatus(status)}
                      className={`h-11 rounded-xl border text-xs font-bold flex items-center justify-center gap-2 transition-all capitalize ${
                        newStatus === status
                          ? "border-emerald-600 bg-emerald-50 text-emerald-700 font-black"
                          : "border-[#D7E2DC] text-[#6B8078] hover:bg-[#F6F8F7]"
                      }`}
                    >
                      {getStatusIcon(status)}
                      {status}
                    </button>
                  ))}
                </div>
              </div>

              {/* Nurse Assignment */}
              <div className="space-y-2">
                <label className="text-xs font-bold text-[#12463E]">Assigned Nurse</label>
                <select
                  value={newNurse}
                  onChange={(e) => setNewNurse(e.target.value)}
                  className="w-full h-11 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  {nursesList.map((n, i) => (
                    <option key={i} value={n}>
                      {n}
                    </option>
                  ))}
                </select>
              </div>

              {/* Equipment */}
              <div className="space-y-2">
                <label className="text-xs font-bold text-[#12463E]">Equipment (comma separated)</label>
                <div className="relative">
                  <Wrench className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[#8AA098]" />
                  <input
                    type="text"
                    value={newEquipment}
                    onChange={(e) => setNewEquipment(e.target.value)}
                    placeholder="Ventilator, Cardiac Monitor"
                    className="w-full h-11 pl-9 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  />
                </div>
              </div>
            </div>

            {/* Modal Actions */}
            <div className="flex gap-3 border-t border-[#E8ECEB] pt-4 mt-2">
              <button
                type="button"
                onClick={() => setIsAddOpen(false)}
                className="flex-1 h-11 rounded-xl border border-[#D7E2DC] text-xs font-bold text-[#6B8078] hover:bg-[#F6F8F7] transition-all"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleSubmitAdd}
                disabled={isSubmitting || !newBedId.trim() || !newWard.trim()}
                className="flex-1 h-11 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 shadow-md shadow-emerald-600/10 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {isSubmitting && <Loader className="h-3.5 w-3.5 animate-spin" />}
                Add Bed
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
