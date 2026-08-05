"use client"

import React, { useState, useEffect } from "react"
import {
  Calendar,
  Clock,
  User,
  FileText,
  FlaskConical,
  Video,
  Plus,
  Search,
  CheckCircle,
  AlertCircle,
  FileMinus,
  Briefcase,
  Activity,
  HeartPulse,
  Send,
  Check,
  ChevronRight,
  LogOut,
  Stethoscope,
  ChevronDown,
  Landmark,
  Wallet,
  IndianRupee,
  Loader2,
  Save
} from "lucide-react"
import {
  getDoctorEarnings,
  updateDoctorBankDetails,
  type DoctorEarnings
} from "@/services/doctor.service"

// Types & Mock Data for Doctor Panel
interface Appointment {
  id: string
  patientName: string
  age: number
  gender: string
  time: string
  type: "Consultation" | "Follow-up" | "Emergency"
  symptoms: string
  status: "waiting" | "in-consultation" | "completed"
}

interface Prescription {
  id: string
  patientName: string
  date: string
  medicines: { name: string; dosage: string; duration: string }[]
  notes: string
}

interface LabOrder {
  id: string
  patientName: string
  testType: string
  status: "pending" | "processing" | "completed"
  priority: "routine" | "urgent" | "stat"
  results?: string
  abnormalFlag?: boolean
}

interface ConsultationHistory {
  id: string
  patientName: string
  date: string
  diagnosis: string
  treatmentPlan: string
  notes: string
}

export default function DoctorDashboard() {
  const [activeTab, setActiveTab] = useState<"schedule" | "prescriptions" | "lab-orders" | "consultations" | "earnings">("schedule")
  const [currentTime, setCurrentTime] = useState("")
  const [authed, setAuthed] = useState(false)
  const [earnings, setEarnings] = useState<DoctorEarnings | null>(null)
  const [bankForm, setBankForm] = useState({
    account_holder: "",
    account_number: "",
    ifsc: "",
    bank_name: "",
    upi_id: ""
  })
  const [loadingEarnings, setLoadingEarnings] = useState(true)
  const [savingBank, setSavingBank] = useState(false)
  const [bankMsg, setBankMsg] = useState("")

  const loadEarnings = async () => {
    setLoadingEarnings(true)
    try {
      const res = await getDoctorEarnings()
      setEarnings(res.data)
      const bank = res.data.bank
      setBankForm({
        account_holder: bank.account_holder || "",
        account_number: bank.account_number || "",
        ifsc: bank.ifsc || "",
        bank_name: bank.bank_name || "",
        upi_id: bank.upi_id || ""
      })
    } catch {
      setEarnings(null)
    } finally {
      setLoadingEarnings(false)
    }
  }

  useEffect(() => {
    if (!localStorage.getItem("access_token")) {
      window.location.href = "/login"
    } else {
      setAuthed(true)
      loadEarnings()
    }
  }, [])

  const handleSaveBank = async (e: React.FormEvent) => {
    e.preventDefault()
    setSavingBank(true)
    setBankMsg("")
    try {
      const res = await updateDoctorBankDetails({
        ...bankForm,
        bank_name: bankForm.bank_name || undefined,
        upi_id: bankForm.upi_id || undefined
      })
      setBankMsg(res.message)
      loadEarnings()
    } catch (err: any) {
      setBankMsg(err?.message || "Failed to save bank details")
    } finally {
      setSavingBank(false)
    }
  }

  // State lists
  const [appointments, setAppointments] = useState<Appointment[]>([
    { id: "APT-101", patientName: "Robert Downey Jr.", age: 55, gender: "Male", time: "09:30 AM", type: "Follow-up", symptoms: "Recovering from hypertension, BP follow-up", status: "waiting" },
    { id: "APT-102", patientName: "Emma Watson", age: 32, gender: "Female", time: "10:15 AM", type: "Consultation", symptoms: "Chronic headaches, fatigue", status: "in-consultation" },
    { id: "APT-103", patientName: "Liam Neeson", age: 68, gender: "Male", time: "11:00 AM", type: "Emergency", symptoms: "Shortness of breath, chest pressure", status: "waiting" },
    { id: "APT-104", patientName: "Scarlett Johansson", age: 36, gender: "Female", time: "11:45 AM", type: "Consultation", symptoms: "Routine antenatal check-up", status: "waiting" },
    { id: "APT-105", patientName: "Tommy Watson", age: 8, gender: "Male", time: "12:30 PM", type: "Follow-up", symptoms: "Allergic bronchitis review", status: "completed" },
  ])

  const [prescriptions, setPrescriptions] = useState<Prescription[]>([
    {
      id: "PRX-501",
      patientName: "Tommy Watson",
      date: "2026-07-20",
      medicines: [
        { name: "Montelukast 5mg", dosage: "1 tablet daily at night", duration: "10 Days" },
        { name: "Levosalbutamol Inhaler", dosage: "2 puffs twice daily", duration: "1 Month" }
      ],
      notes: "Avoid cold items and potential allergen triggers."
    },
    {
      id: "PRX-502",
      patientName: "Robert Downey Jr.",
      date: "2026-07-19",
      medicines: [
        { name: "Amlodipine 5mg", dosage: "1 tablet in morning", duration: "3 Months" },
        { name: "Atorvastatin 10mg", dosage: "1 tablet after dinner", duration: "3 Months" }
      ],
      notes: "Strict low-sodium diet recommended. Track daily BP."
    }
  ])

  const [labOrders, setLabOrders] = useState<LabOrder[]>([
    { id: "LAB-801", patientName: "Emma Watson", testType: "Complete Blood Count (CBC) & Serum Glucose", status: "completed", priority: "urgent", results: "Hb 12.8 g/dL (Normal), RBC 4.2 M/uL, Glucose 98 mg/dL", abnormalFlag: false },
    { id: "LAB-802", patientName: "Liam Neeson", testType: "Cardiac Troponin & ECG Telemetry Review", status: "processing", priority: "stat" },
    { id: "LAB-803", patientName: "Robert Downey Jr.", testType: "Lipid Profile & Kidney Function Test", status: "pending", priority: "routine" },
  ])

  const [consultations, setConsultations] = useState<ConsultationHistory[]>([
    { id: "CON-301", patientName: "Robert Downey Jr.", date: "2026-07-17", diagnosis: "Essential Hypertension", treatmentPlan: "Statins & Vasodilators initiation", notes: "Patient reported mild vertigo when starting dosage. Adjusted Amlodipine timing." },
    { id: "CON-302", patientName: "Tommy Watson", date: "2026-07-16", diagnosis: "Allergic Bronchitis", treatmentPlan: "Inhaled bronchodilator therapy", notes: "Nebulizer administered in clinic. Pulse ox 97% post therapy." },
  ])

  // Modals / Input states
  const [isPrescriptionModalOpen, setIsPrescriptionModalOpen] = useState(false)
  const [newPresc, setNewPresc] = useState({
    patientName: "",
    medicines: [{ name: "", dosage: "", duration: "" }],
    notes: ""
  })

  const [isLabModalOpen, setIsLabModalOpen] = useState(false)
  const [newLab, setNewLab] = useState({
    patientName: "",
    testType: "",
    priority: "routine" as "routine" | "urgent" | "stat"
  })

  const [isConsultationModalOpen, setIsConsultationModalOpen] = useState(false)
  const [newConsultation, setNewConsultation] = useState({
    patientName: "",
    diagnosis: "",
    treatmentPlan: "",
    notes: ""
  })

  useEffect(() => {
    const updateTime = () => {
      const now = new Date()
      setCurrentTime(now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit", hour12: true }))
    }
    updateTime()
    const timer = setInterval(updateTime, 1000)
    return () => clearInterval(timer)
  }, [])

  // Action handlers
  const handleUpdateStatus = (id: string, newStatus: "waiting" | "in-consultation" | "completed") => {
    setAppointments(appointments.map(a => a.id === id ? { ...a, status: newStatus } : a))
  }

  const handleAddMedicineRow = () => {
    setNewPresc({
      ...newPresc,
      medicines: [...newPresc.medicines, { name: "", dosage: "", duration: "" }]
    })
  }

  const handleMedicineChange = (index: number, field: string, value: string) => {
    const updated = [...newPresc.medicines]
    updated[index] = { ...updated[index], [field]: value }
    setNewPresc({ ...newPresc, medicines: updated })
  }

  const handleSavePrescription = (e: React.FormEvent) => {
    e.preventDefault()
    if (!newPresc.patientName || !newPresc.medicines[0].name) return

    const created: Prescription = {
      id: `PRX-${Math.floor(500 + Math.random() * 500)}`,
      patientName: newPresc.patientName,
      date: new Date().toISOString().split("T")[0],
      medicines: newPresc.medicines.filter(m => m.name !== ""),
      notes: newPresc.notes
    }

    setPrescriptions([created, ...prescriptions])
    setNewPresc({ patientName: "", medicines: [{ name: "", dosage: "", duration: "" }], notes: "" })
    setIsPrescriptionModalOpen(false)
  }

  const handleSaveLabOrder = (e: React.FormEvent) => {
    e.preventDefault()
    if (!newLab.patientName || !newLab.testType) return

    const created: LabOrder = {
      id: `LAB-${Math.floor(800 + Math.random() * 200)}`,
      patientName: newLab.patientName,
      testType: newLab.testType,
      status: "pending",
      priority: newLab.priority
    }

    setLabOrders([created, ...labOrders])
    setNewLab({ patientName: "", testType: "", priority: "routine" })
    setIsLabModalOpen(false)
  }

  const handleSaveConsultation = (e: React.FormEvent) => {
    e.preventDefault()
    if (!newConsultation.patientName || !newConsultation.diagnosis) return

    const created: ConsultationHistory = {
      id: `CON-${Math.floor(300 + Math.random() * 200)}`,
      patientName: newConsultation.patientName,
      date: new Date().toISOString().split("T")[0],
      diagnosis: newConsultation.diagnosis,
      treatmentPlan: newConsultation.treatmentPlan,
      notes: newConsultation.notes
    }

    setConsultations([created, ...consultations])
    setNewConsultation({ patientName: "", diagnosis: "", treatmentPlan: "", notes: "" })
    setIsConsultationModalOpen(false)
  }

  if (!authed) return null

  return (
    <div className="flex min-h-screen bg-[#050E0C] text-[#E5ECE9]">
      {/* ─── SIDEBAR ─── */}
      <aside className="w-72 bg-[#0C1E1A] border-r border-[#1B352E] flex flex-col justify-between h-screen sticky top-0 shrink-0">
        <div>
          {/* Brand */}
          <div className="p-6">
            <div className="flex items-center gap-3 bg-gradient-to-r from-[#12463E] to-[#0A2622] p-4 rounded-2xl border border-[#1E5D52] shadow-lg">
              <div className="w-10 h-10 rounded-xl bg-emerald-500 flex items-center justify-center text-white shadow-md shadow-emerald-500/20">
                <HeartPulse className="h-5.5 w-5.5" strokeWidth={2.5} />
              </div>
              <div>
                <h2 className="font-bold text-sm tracking-wide text-white">AURA Medical</h2>
                <p className="text-[10px] text-emerald-400 font-semibold tracking-widest uppercase mt-0.5">Doctor Portal</p>
              </div>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="px-4 space-y-1.5 py-2">
            <p className="px-3 text-[10px] font-bold text-[#8AA098] tracking-widest uppercase mb-3">Clinical Console</p>

            <button
              onClick={() => setActiveTab("schedule")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "schedule" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "schedule" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <Calendar className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>My Schedule</span>
            </button>

            <button
              onClick={() => setActiveTab("prescriptions")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "prescriptions" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "prescriptions" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <FileText className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Prescriptions</span>
            </button>

            <button
              onClick={() => setActiveTab("lab-orders")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "lab-orders" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "lab-orders" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <FlaskConical className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Lab Orders</span>
            </button>

            <button
              onClick={() => setActiveTab("consultations")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "consultations" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "consultations" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <Video className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Consultations</span>
            </button>

            <button
              onClick={() => setActiveTab("earnings")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "earnings" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "earnings" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <Landmark className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Earnings & Payout</span>
            </button>
          </nav>
        </div>

        {/* Doctor Info */}
        <div className="p-4 border-t border-[#1B352E] bg-[#071310]">
          <div className="flex items-center gap-3 p-2 rounded-xl">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-[#12463E] flex items-center justify-center font-bold text-white border border-[#1E5D52]">
              GH
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-white truncate">Dr. Gregory House</p>
              <p className="text-[10px] text-emerald-400 truncate">General Medicine Specialist</p>
            </div>
          </div>
          <button
            onClick={() => window.location.href = "/login"}
            className="w-full mt-3 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl border border-rose-500/30 text-rose-400 hover:bg-rose-500/10 text-xs font-semibold transition-all"
          >
            <LogOut className="h-3.5 w-3.5" />
            Exit Dashboard
          </button>
        </div>
      </aside>

      {/* ─── MAIN WORKSPACE ─── */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Navbar */}
        <header className="h-20 bg-[#0C1E1A] border-b border-[#1B352E] flex items-center justify-between px-8 sticky top-0 z-30 shadow-md">
          <div>
            <h1 className="text-lg font-bold text-white tracking-tight uppercase">
              {activeTab === "schedule" && "Clinical Appointments"}
              {activeTab === "prescriptions" && "Prescription Pad"}
              {activeTab === "lab-orders" && "Laboratory Orders & Diagnostics"}
              {activeTab === "consultations" && "Specialist Consultations"}
              {activeTab === "earnings" && "Earnings & Payout"}
            </h1>
            <p className="text-xs text-[#8AA098] mt-0.5">Welcome back, Dr. House. Medical console fully sync'd.</p>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#12463E]/40 border border-[#1B352E] text-emerald-400 font-medium text-xs tabular-nums">
              <Clock className="h-3.5 w-3.5" />
              <span>{currentTime || "Loading clock..."}</span>
            </div>
            <div className="flex items-center gap-2 text-xs text-emerald-400 bg-emerald-500/10 px-3.5 py-2 rounded-xl border border-emerald-500/20 font-semibold">
              <span className="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-ping" />
              <span>On Duty</span>
            </div>
          </div>
        </header>

        {/* Content Wrapper */}
        <main className="flex-1 p-8 overflow-y-auto max-w-[1400px] w-full mx-auto space-y-6">
          {/* ─── TAB 1: SCHEDULE ─── */}
          {activeTab === "schedule" && (
            <div className="space-y-6">
              {/* Daily Stats Banner */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-[#0C1E1A] p-5 rounded-2xl border border-[#1B352E] flex items-center gap-4">
                  <div className="p-3 bg-blue-500/10 rounded-xl text-blue-400">
                    <Calendar className="h-6 w-6" />
                  </div>
                  <div>
                    <h3 className="text-xs text-[#8AA098] uppercase tracking-wider font-semibold">Total Scheduled</h3>
                    <p className="text-2xl font-bold text-white mt-1">{appointments.length}</p>
                  </div>
                </div>

                <div className="bg-[#0C1E1A] p-5 rounded-2xl border border-[#1B352E] flex items-center gap-4">
                  <div className="p-3 bg-amber-500/10 rounded-xl text-amber-400">
                    <Clock className="h-6 w-6 animate-pulse" />
                  </div>
                  <div>
                    <h3 className="text-xs text-[#8AA098] uppercase tracking-wider font-semibold">Waiting List</h3>
                    <p className="text-2xl font-bold text-white mt-1">
                      {appointments.filter(a => a.status === "waiting").length}
                    </p>
                  </div>
                </div>

                <div className="bg-[#0C1E1A] p-5 rounded-2xl border border-[#1B352E] flex items-center gap-4">
                  <div className="p-3 bg-emerald-500/10 rounded-xl text-emerald-400">
                    <Activity className="h-6 w-6" />
                  </div>
                  <div>
                    <h3 className="text-xs text-[#8AA098] uppercase tracking-wider font-semibold">In Consultation</h3>
                    <p className="text-2xl font-bold text-white mt-1">
                      {appointments.filter(a => a.status === "in-consultation").length}
                    </p>
                  </div>
                </div>

                <div className="bg-[#0C1E1A] p-5 rounded-2xl border border-[#1B352E] flex items-center gap-4">
                  <div className="p-3 bg-[#12463E] rounded-xl text-emerald-300">
                    <CheckCircle className="h-6 w-6" />
                  </div>
                  <div>
                    <h3 className="text-xs text-[#8AA098] uppercase tracking-wider font-semibold">Completed Visits</h3>
                    <p className="text-2xl font-bold text-white mt-1">
                      {appointments.filter(a => a.status === "completed").length}
                    </p>
                  </div>
                </div>
              </div>

              {/* Appointments List */}
              <div className="bg-[#0C1E1A] border border-[#1B352E] rounded-3xl overflow-hidden">
                <div className="p-6 border-b border-[#1B352E] flex justify-between items-center bg-[#071310]/50">
                  <div>
                    <h2 className="text-lg font-bold text-white">Daily Queue & Triaging</h2>
                    <p className="text-xs text-[#8AA098] mt-1">Real-time status updates from Front Desk OPD registry</p>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => setIsConsultationModalOpen(true)}
                      className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-lg shadow-emerald-500/10"
                    >
                      <Plus className="h-4 w-4" /> Log Consultation
                    </button>
                  </div>
                </div>

                <div className="divide-y divide-[#1B352E]">
                  {appointments.map((a) => (
                    <div key={a.id} className="p-6 flex flex-col lg:flex-row lg:items-center justify-between gap-6 hover:bg-[#12463E]/10 transition-all">
                      <div className="flex items-start gap-4">
                        <div className="w-12 h-12 rounded-2xl bg-[#12463E]/40 flex items-center justify-center font-bold text-emerald-400 shrink-0 text-sm border border-[#1E5D52]">
                          {a.patientName.split(" ").map(n => n[0]).join("")}
                        </div>
                        <div>
                          <div className="flex items-center gap-3">
                            <h3 className="font-bold text-white text-base">{a.patientName}</h3>
                            <span className="text-xs text-[#8AA098]">{a.age} Y/O · {a.gender}</span>
                            <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase ${
                              a.type === "Emergency" ? "bg-rose-500/10 text-rose-400 border border-rose-500/20 animate-pulse" :
                              a.type === "Follow-up" ? "bg-blue-500/10 text-blue-400 border border-blue-500/20" :
                              "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                            }`}>
                              {a.type}
                            </span>
                          </div>
                          <p className="text-xs text-[#8AA098] mt-1.5 flex items-center gap-1">
                            <span className="font-semibold text-emerald-400">Chief complaint:</span> {a.symptoms}
                          </p>
                          <div className="flex items-center gap-4 mt-3">
                            <span className="text-xs text-[#5C7D73] flex items-center gap-1 font-mono">
                              <Clock className="h-3.5 w-3.5" /> Slot: {a.time}
                            </span>
                            <span className="text-xs text-[#5C7D73] font-mono">
                              ID: {a.id}
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* Status and Action flow */}
                      <div className="flex items-center gap-3 self-end lg:self-auto">
                        <span className={`px-3 py-1.5 rounded-xl text-xs font-bold ${
                          a.status === "waiting" ? "bg-amber-500/10 text-amber-400 border border-amber-500/20" :
                          a.status === "in-consultation" ? "bg-blue-500/10 text-blue-400 border border-blue-500/20 animate-pulse" :
                          "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                        }`}>
                          {a.status === "waiting" ? "Waiting Check-in" :
                           a.status === "in-consultation" ? "Active Care" : "Checked Out"}
                        </span>

                        <div className="flex gap-1.5">
                          {a.status === "waiting" && (
                            <button
                              onClick={() => handleUpdateStatus(a.id, "in-consultation")}
                              className="px-3.5 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-bold transition-all"
                            >
                              Call In
                            </button>
                          )}
                          {a.status === "in-consultation" && (
                            <>
                              <button
                                onClick={() => {
                                  setNewPresc({ ...newPresc, patientName: a.patientName })
                                  setIsPrescriptionModalOpen(true)
                                }}
                                className="px-3 py-2 bg-[#12463E] border border-[#1E5D52] hover:bg-[#1B564C] text-emerald-300 rounded-xl text-xs font-bold transition-all"
                              >
                                Rx
                              </button>
                              <button
                                onClick={() => {
                                  setNewLab({ ...newLab, patientName: a.patientName })
                                  setIsLabModalOpen(true)
                                }}
                                className="px-3 py-2 bg-[#12463E] border border-[#1E5D52] hover:bg-[#1B564C] text-emerald-300 rounded-xl text-xs font-bold transition-all"
                              >
                                Lab
                              </button>
                              <button
                                onClick={() => handleUpdateStatus(a.id, "completed")}
                                className="px-3.5 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-bold transition-all"
                              >
                                Finalize
                              </button>
                            </>
                          )}
                          {a.status === "completed" && (
                            <div className="p-2 bg-emerald-500/10 rounded-full text-emerald-400 border border-emerald-500/20">
                              <Check className="h-4 w-4" strokeWidth={3} />
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ─── TAB 2: PRESCRIPTIONS ─── */}
          {activeTab === "prescriptions" && (
            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <div>
                  <h2 className="text-xl font-bold text-white">Active Patient Prescriptions</h2>
                  <p className="text-xs text-[#8AA098] mt-1">Write digital prescriptions directly dispatchable to the hospital pharmacy</p>
                </div>
                <button
                  onClick={() => setIsPrescriptionModalOpen(true)}
                  className="px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-lg shadow-emerald-500/10"
                >
                  <Plus className="h-4 w-4" /> New Prescription
                </button>
              </div>

              {/* Prescriptions Grid */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {prescriptions.map((p) => (
                  <div key={p.id} className="bg-[#0C1E1A] border border-[#1B352E] rounded-3xl p-6 relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-24 h-24 bg-emerald-500/5 rounded-full blur-xl" />
                    <div className="flex justify-between items-start border-b border-[#1B352E] pb-4">
                      <div>
                        <h3 className="font-bold text-white text-lg">{p.patientName}</h3>
                        <p className="text-xs text-[#8AA098] mt-1">Prescribed on: {p.date}</p>
                      </div>
                      <span className="text-[10px] font-mono text-[#5C7D73] bg-[#071310] px-2.5 py-1.5 rounded-lg border border-[#1B352E]">
                        ID: {p.id}
                      </span>
                    </div>

                    <div className="mt-4 space-y-3">
                      <p className="text-xs text-[#8AA098] font-bold uppercase tracking-wider">Medicines & Schedule</p>
                      <div className="space-y-2">
                        {p.medicines.map((med, i) => (
                          <div key={i} className="bg-[#071310]/40 p-3 rounded-xl border border-[#1B352E]/50 flex justify-between items-center">
                            <div>
                              <p className="text-sm font-bold text-emerald-400">{med.name}</p>
                              <p className="text-xs text-[#8AA098] mt-0.5">{med.dosage}</p>
                            </div>
                            <span className="text-xs text-[#5C7D73] font-semibold">{med.duration}</span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {p.notes && (
                      <div className="mt-4 bg-emerald-500/5 border border-emerald-500/10 rounded-xl p-3">
                        <p className="text-xs text-emerald-400/90 leading-relaxed font-medium">
                          <span className="font-bold block text-emerald-400 text-[10px] uppercase tracking-wider mb-0.5">Special Advice:</span>
                          {p.notes}
                        </p>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ─── TAB 3: LAB ORDERS ─── */}
          {activeTab === "lab-orders" && (
            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <div>
                  <h2 className="text-xl font-bold text-white">Clinical Pathology & Diagnostic Orders</h2>
                  <p className="text-xs text-[#8AA098] mt-1">Telemetry status, labs, imaging and diagnostic requests</p>
                </div>
                <button
                  onClick={() => setIsLabModalOpen(true)}
                  className="px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-lg shadow-emerald-500/10"
                >
                  <Plus className="h-4 w-4" /> Request Diagnostics
                </button>
              </div>

              {/* Lab Orders Table */}
              <div className="bg-[#0C1E1A] border border-[#1B352E] rounded-3xl overflow-hidden">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-[#071310]/50 border-b border-[#1B352E] text-xs font-bold text-[#8AA098] uppercase">
                      <th className="p-4">Order ID</th>
                      <th className="p-4">Patient Name</th>
                      <th className="p-4">Required Diagnostics</th>
                      <th className="p-4">Priority</th>
                      <th className="p-4">Status</th>
                      <th className="p-4">Results Reference</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#1B352E]">
                    {labOrders.map((order) => (
                      <tr key={order.id} className="text-sm hover:bg-[#12463E]/10 transition-all">
                        <td className="p-4 font-mono text-emerald-400 font-semibold">{order.id}</td>
                        <td className="p-4 font-bold text-white">{order.patientName}</td>
                        <td className="p-4 text-[#8AA098] font-medium">{order.testType}</td>
                        <td className="p-4">
                          <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                            order.priority === "stat" ? "bg-rose-500/10 text-rose-400 border border-rose-500/20 animate-pulse" :
                            order.priority === "urgent" ? "bg-amber-500/10 text-amber-400 border border-amber-500/20" :
                            "bg-blue-500/10 text-blue-400 border border-blue-500/20"
                          }`}>
                            {order.priority}
                          </span>
                        </td>
                        <td className="p-4">
                          <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                            order.status === "completed" ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20" :
                            order.status === "processing" ? "bg-blue-500/10 text-blue-400 border border-blue-500/20" :
                            "bg-[#071310] text-[#5C7D73] border border-[#1B352E]"
                          }`}>
                            {order.status}
                          </span>
                        </td>
                        <td className="p-4">
                          {order.results ? (
                            <div className="text-xs max-w-xs">
                              <p className="text-white font-medium italic truncate" title={order.results}>{order.results}</p>
                              {order.abnormalFlag && (
                                <span className="inline-flex items-center gap-1.5 mt-1 text-[10px] text-rose-400 font-bold bg-rose-500/10 px-2 py-0.5 rounded-full border border-rose-500/20">
                                  <AlertCircle className="h-3 w-3" /> CRITICAL VALUE
                                </span>
                              )}
                            </div>
                          ) : (
                            <span className="text-xs text-[#5C7D73] italic">Results pending processing...</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* ─── TAB 4: CONSULTATIONS ─── */}
          {activeTab === "consultations" && (
            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <div>
                  <h2 className="text-xl font-bold text-white">Consultation Room & History</h2>
                  <p className="text-xs text-[#8AA098] mt-1">Review diagnostic history, patient records, and activate remote consultation calls</p>
                </div>
                <button
                  onClick={() => setIsConsultationModalOpen(true)}
                  className="px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-lg shadow-emerald-500/10"
                >
                  <Plus className="h-4 w-4" /> Start Diagnosis Notes
                </button>
              </div>

              {/* Consultation Workspace Split */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Simulated Telemedicine Panel */}
                <div className="lg:col-span-1 bg-[#0C1E1A] border border-[#1B352E] rounded-3xl p-6 flex flex-col justify-between h-[500px]">
                  <div>
                    <div className="flex items-center justify-between border-b border-[#1B352E] pb-4">
                      <h3 className="font-bold text-white text-base">Telehealth Interface</h3>
                      <span className="flex items-center gap-1.5 text-[10px] text-[#8AA098] font-bold bg-[#071310] px-2 py-1 rounded-full border border-[#1B352E]">
                        <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-ping" /> Live Feed
                      </span>
                    </div>

                    <div className="mt-6 bg-[#050E0C] rounded-2xl h-60 relative overflow-hidden flex items-center justify-center border border-[#1B352E]">
                      <div className="absolute top-3 left-3 bg-[#0C1E1A]/80 backdrop-blur-md text-[10px] text-white px-2 py-1 rounded-md border border-[#1B352E] font-medium">
                        Patient: Robert Downey Jr.
                      </div>
                      <div className="absolute bottom-3 right-3 bg-[#0C1E1A]/80 backdrop-blur-md text-[10px] text-emerald-400 px-2 py-1 rounded-md border border-[#1B352E] font-bold">
                        Dr. House (You)
                      </div>
                      {/* Virtual Video Mock */}
                      <div className="text-center p-4">
                        <Video className="h-12 w-12 text-[#1E5D52] mx-auto animate-pulse" />
                        <p className="text-xs text-[#8AA098] mt-3">Virtual telehealth room initialized.</p>
                        <p className="text-[10px] text-[#5C7D73] mt-1 font-mono">Channel: TLS-256 AES Sec</p>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2 mt-4">
                    <button className="w-full py-3 bg-[#12463E] hover:bg-[#1E5D52] text-white rounded-xl text-xs font-semibold transition-all border border-[#1E5D52] flex items-center justify-center gap-2">
                      <Video className="h-4 w-4" /> Start Video Consultation
                    </button>
                    <button className="w-full py-3 bg-[#071310] hover:bg-[#071310]/80 text-[#8AA098] rounded-xl text-xs font-semibold transition-all border border-[#1B352E]">
                      Mute Audio / Standby
                    </button>
                  </div>
                </div>

                {/* Consultation Records */}
                <div className="lg:col-span-2 space-y-4">
                  <h3 className="font-bold text-white text-base">Historical Patient Diagnoses</h3>
                  <div className="space-y-4 max-h-[440px] overflow-y-auto pr-2">
                    {consultations.map((c) => (
                      <div key={c.id} className="bg-[#0C1E1A] border border-[#1B352E] rounded-2xl p-5 hover:border-emerald-500/20 transition-all">
                        <div className="flex justify-between items-start border-b border-[#1B352E]/60 pb-3">
                          <div>
                            <h4 className="font-bold text-emerald-400 text-sm">{c.patientName}</h4>
                            <p className="text-[10px] text-[#8AA098] mt-0.5">Date of session: {c.date}</p>
                          </div>
                          <span className="text-[10px] font-mono text-[#5C7D73] bg-[#071310] px-2 py-1 rounded border border-[#1B352E]">
                            Reference: {c.id}
                          </span>
                        </div>

                        <div className="mt-4 space-y-3">
                          <div>
                            <span className="text-[10px] font-bold text-emerald-500 tracking-wider uppercase block">Diagnosis / Symptoms Summary:</span>
                            <p className="text-xs text-white mt-1 leading-relaxed">{c.diagnosis}</p>
                          </div>
                          <div>
                            <span className="text-[10px] font-bold text-[#8AA098] tracking-wider uppercase block">Treatment & Intervention Plan:</span>
                            <p className="text-xs text-white/90 mt-1 leading-relaxed">{c.treatmentPlan}</p>
                          </div>
                          {c.notes && (
                            <div className="bg-[#050E0C] p-3 rounded-xl border border-[#1B352E] mt-2">
                              <span className="text-[9px] font-bold text-[#5C7D73] tracking-wider uppercase block">Session Transcript Notes:</span>
                              <p className="text-xs text-[#8AA098] italic mt-1 leading-relaxed">{c.notes}</p>
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ─── TAB 5: EARNINGS & PAYOUT ─── */}
          {activeTab === "earnings" && (
            <div className="space-y-6">
              {bankMsg && (
                <div className={`px-4 py-3 rounded-2xl text-xs font-bold border ${
                  bankMsg.includes("Failed") || bankMsg.includes("failed")
                    ? "bg-rose-500/10 text-rose-400 border-rose-500/20"
                    : "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
                }`}>
                  {bankMsg}
                </div>
              )}

              <div className="flex justify-between items-center">
                <div>
                  <h2 className="text-xl font-bold text-white">Consultation Earnings</h2>
                  <p className="text-xs text-[#8AA098] mt-1">
                    Your share of every confirmed OPD payment. Disbursed automatically to your bank when RazorpayX payouts are enabled.
                  </p>
                </div>
              </div>

              {/* Earnings summary */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="bg-[#0C1E1A] p-5 rounded-2xl border border-[#1B352E] flex items-center gap-4">
                  <div className="p-3 bg-emerald-500/10 rounded-xl text-emerald-400">
                    <Wallet className="h-6 w-6" />
                  </div>
                  <div>
                    <h3 className="text-xs text-[#8AA098] uppercase tracking-wider font-semibold">Total Earned</h3>
                    <p className="text-2xl font-bold text-white mt-1">
                      Rs. {(earnings?.summary.total_earned ?? 0).toLocaleString()}
                    </p>
                  </div>
                </div>

                <div className="bg-[#0C1E1A] p-5 rounded-2xl border border-[#1B352E] flex items-center gap-4">
                  <div className="p-3 bg-blue-500/10 rounded-xl text-blue-400">
                    <CheckCircle className="h-6 w-6" />
                  </div>
                  <div>
                    <h3 className="text-xs text-[#8AA098] uppercase tracking-wider font-semibold">Paid Out</h3>
                    <p className="text-2xl font-bold text-white mt-1">
                      Rs. {(earnings?.summary.paid_out ?? 0).toLocaleString()}
                    </p>
                  </div>
                </div>

                <div className="bg-[#0C1E1A] p-5 rounded-2xl border border-[#1B352E] flex items-center gap-4">
                  <div className="p-3 bg-amber-500/10 rounded-xl text-amber-400">
                    <Clock className="h-6 w-6" />
                  </div>
                  <div>
                    <h3 className="text-xs text-[#8AA098] uppercase tracking-wider font-semibold">Pending Payout</h3>
                    <p className="text-2xl font-bold text-white mt-1">
                      Rs. {(earnings?.summary.pending ?? 0).toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>

              {/* Bank details form */}
              <div className="bg-[#0C1E1A] border border-[#1B352E] rounded-3xl p-6">
                <div className="flex items-center gap-3 border-b border-[#1B352E] pb-4 mb-5">
                  <Landmark className="h-5 w-5 text-emerald-400" />
                  <div>
                    <h3 className="text-base font-bold text-white">Payout Bank Account</h3>
                    <p className="text-[11px] text-[#8AA098]">
                      {earnings?.bank.has_bank_details
                        ? "Details saved — payouts will be sent to this account."
                        : "Add your bank details to receive your consultation share."}
                    </p>
                  </div>
                </div>

                {loadingEarnings ? (
                  <div className="flex items-center justify-center py-10 text-[#8AA098]">
                    <Loader2 className="h-5 w-5 animate-spin mr-3 text-emerald-500" />
                    <span className="text-sm font-semibold">Loading earnings...</span>
                  </div>
                ) : (
                  <form onSubmit={handleSaveBank} className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="space-y-1.5">
                        <label className="text-xs font-semibold text-emerald-400 block">Account Holder Name</label>
                        <input
                          required
                          value={bankForm.account_holder}
                          onChange={(e) => setBankForm({ ...bankForm, account_holder: e.target.value })}
                          className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                          placeholder="Full name as on bank account"
                        />
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-xs font-semibold text-emerald-400 block">Account Number</label>
                        <input
                          required
                          value={bankForm.account_number}
                          onChange={(e) => setBankForm({ ...bankForm, account_number: e.target.value })}
                          className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                          placeholder="9–18 digit account number"
                        />
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-xs font-semibold text-emerald-400 block">IFSC Code</label>
                        <input
                          required
                          value={bankForm.ifsc}
                          onChange={(e) => setBankForm({ ...bankForm, ifsc: e.target.value.toUpperCase() })}
                          className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                          placeholder="11 chars, e.g. HDFC0001234"
                        />
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-xs font-semibold text-emerald-400 block">Bank Name</label>
                        <input
                          value={bankForm.bank_name}
                          onChange={(e) => setBankForm({ ...bankForm, bank_name: e.target.value })}
                          className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                          placeholder="e.g. HDFC Bank"
                        />
                      </div>
                      <div className="space-y-1.5 md:col-span-2">
                        <label className="text-xs font-semibold text-emerald-400 block">UPI ID (optional)</label>
                        <input
                          value={bankForm.upi_id}
                          onChange={(e) => setBankForm({ ...bankForm, upi_id: e.target.value })}
                          className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                          placeholder="name@bank"
                        />
                      </div>
                    </div>
                    <div className="flex justify-end">
                      <button
                        type="submit"
                        disabled={savingBank}
                        className="px-5 py-2.5 bg-emerald-500 hover:bg-emerald-600 disabled:opacity-60 text-white rounded-xl text-xs font-bold transition-all flex items-center gap-2 shadow-lg shadow-emerald-500/10"
                      >
                        {savingBank ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        Save Bank Details
                      </button>
                    </div>
                  </form>
                )}
              </div>

              {/* Earnings history */}
              <div className="bg-[#0C1E1A] border border-[#1B352E] rounded-3xl overflow-hidden">
                <div className="p-6 border-b border-[#1B352E] flex justify-between items-center bg-[#071310]/50">
                  <div>
                    <h2 className="text-lg font-bold text-white">Payment History</h2>
                    <p className="text-xs text-[#8AA098] mt-1">
                      {earnings?.summary.payments_count ?? 0} confirmed consultation{earnings?.summary.payments_count === 1 ? "" : "s"}
                    </p>
                  </div>
                </div>
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-[#071310]/50 border-b border-[#1B352E] text-xs font-bold text-[#8AA098] uppercase">
                      <th className="p-4">Appointment</th>
                      <th className="p-4">Patient</th>
                      <th className="p-4">Date</th>
                      <th className="p-4">Fee</th>
                      <th className="p-4">Split</th>
                      <th className="p-4">Your Share</th>
                      <th className="p-4">Payout</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#1B352E]">
                    {(earnings?.payments ?? []).length === 0 && (
                      <tr>
                        <td colSpan={7} className="p-8 text-center text-xs text-[#5C7D73]">
                          No confirmed payments yet — your share appears here after patients pay.
                        </td>
                      </tr>
                    )}
                    {(earnings?.payments ?? []).map((p) => (
                      <tr key={p.appointment_id} className="text-sm hover:bg-[#12463E]/10 transition-all">
                        <td className="p-4 font-mono text-emerald-400 font-semibold">{p.appointment_id}</td>
                        <td className="p-4 font-bold text-white">{p.patient_name}</td>
                        <td className="p-4 text-[#8AA098]">{p.date}</td>
                        <td className="p-4 text-white font-semibold">Rs. {p.fee.toLocaleString()}</td>
                        <td className="p-4 text-[#8AA098]">{p.doctor_share_percent}%</td>
                        <td className="p-4 text-emerald-400 font-bold">Rs. {p.doctor_share.toLocaleString()}</td>
                        <td className="p-4">
                          {p.payout_status === "PAID" ? (
                            <span className="inline-flex items-center gap-1.5 text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2.5 py-1 rounded-full">
                              <CheckCircle className="h-3 w-3" /> Paid {p.payout_date ? new Date(p.payout_date).toLocaleDateString() : ""}
                            </span>
                          ) : p.payout_status === "FAILED" ? (
                            <span className="inline-flex items-center gap-1.5 text-[10px] font-bold bg-rose-500/10 text-rose-400 border border-rose-500/20 px-2.5 py-1 rounded-full">
                              <AlertCircle className="h-3 w-3" /> Failed
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1.5 text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20 px-2.5 py-1 rounded-full">
                              <Clock className="h-3 w-3" /> Pending
                            </span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </main>
      </div>

      {/* ─── MODAL: WRITE PRESCRIPTION ─── */}
      {isPrescriptionModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center z-50 p-4">
          <div className="bg-[#0C1E1A] border border-[#1E5D52] rounded-3xl w-full max-w-lg p-6 overflow-hidden max-h-[90vh] flex flex-col">
            <div className="flex justify-between items-center border-b border-[#1B352E] pb-4 shrink-0">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <FileText className="h-5 w-5 text-emerald-400" /> Write Medical Prescription
              </h3>
              <button
                onClick={() => setIsPrescriptionModalOpen(false)}
                className="text-[#8AA098] hover:text-white transition-colors"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSavePrescription} className="space-y-4 py-4 overflow-y-auto flex-1 pr-1">
              <div>
                <label className="text-xs font-semibold text-emerald-400 block mb-1">Select Patient</label>
                <select
                  value={newPresc.patientName}
                  onChange={(e) => setNewPresc({ ...newPresc, patientName: e.target.value })}
                  className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  required
                >
                  <option value="">-- Choose attending patient --</option>
                  {appointments.map(a => (
                    <option key={a.id} value={a.patientName}>{a.patientName}</option>
                  ))}
                </select>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <label className="text-xs font-semibold text-emerald-400 block">Medication Details</label>
                  <button
                    type="button"
                    onClick={handleAddMedicineRow}
                    className="text-[10px] text-emerald-400 font-bold hover:underline flex items-center gap-0.5"
                  >
                    + Add Medication
                  </button>
                </div>

                <div className="space-y-3">
                  {newPresc.medicines.map((med, i) => (
                    <div key={i} className="grid grid-cols-12 gap-2 bg-[#050E0C]/60 p-3 rounded-xl border border-[#1B352E]">
                      <div className="col-span-6">
                        <input
                          type="text"
                          placeholder="Medicine name (e.g. Paracetamol)"
                          value={med.name}
                          onChange={(e) => handleMedicineChange(i, "name", e.target.value)}
                          className="w-full bg-[#050E0C] border border-[#1B352E] rounded-lg px-2.5 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                          required
                        />
                      </div>
                      <div className="col-span-4">
                        <input
                          type="text"
                          placeholder="Dosage (e.g. 1-0-1)"
                          value={med.dosage}
                          onChange={(e) => handleMedicineChange(i, "dosage", e.target.value)}
                          className="w-full bg-[#050E0C] border border-[#1B352E] rounded-lg px-2.5 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                        />
                      </div>
                      <div className="col-span-2">
                        <input
                          type="text"
                          placeholder="10 Days"
                          value={med.duration}
                          onChange={(e) => handleMedicineChange(i, "duration", e.target.value)}
                          className="w-full bg-[#050E0C] border border-[#1B352E] rounded-lg px-2 py-2 text-xs text-white focus:outline-none focus:border-emerald-500"
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-emerald-400 block mb-1">Additional Advice / Notes</label>
                <textarea
                  placeholder="E.g. Drink plenty of water, avoid strenuous physical activities for a week."
                  value={newPresc.notes}
                  onChange={(e) => setNewPresc({ ...newPresc, notes: e.target.value })}
                  className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 h-20"
                />
              </div>

              <div className="flex justify-end gap-2 border-t border-[#1B352E] pt-4 shrink-0">
                <button
                  type="button"
                  onClick={() => setIsPrescriptionModalOpen(false)}
                  className="px-4 py-2 bg-transparent hover:bg-[#12463E]/30 text-[#8AA098] rounded-xl text-xs font-semibold transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-emerald-500/10"
                >
                  Dispatch Prescription
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ─── MODAL: REQUEST DIAGNOSTICS ─── */}
      {isLabModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center z-50 p-4">
          <div className="bg-[#0C1E1A] border border-[#1E5D52] rounded-3xl w-full max-w-md p-6">
            <div className="flex justify-between items-center border-b border-[#1B352E] pb-4">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <FlaskConical className="h-5 w-5 text-emerald-400" /> Request Lab & Diagnostics
              </h3>
              <button
                onClick={() => setIsLabModalOpen(false)}
                className="text-[#8AA098] hover:text-white transition-colors"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSaveLabOrder} className="space-y-4 mt-4">
              <div>
                <label className="text-xs font-semibold text-emerald-400 block mb-1">Select Patient</label>
                <select
                  value={newLab.patientName}
                  onChange={(e) => setNewLab({ ...newLab, patientName: e.target.value })}
                  className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  required
                >
                  <option value="">-- Choose patient --</option>
                  {appointments.map(a => (
                    <option key={a.id} value={a.patientName}>{a.patientName}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs font-semibold text-emerald-400 block mb-1">Requested Diagnostics / Panels</label>
                <input
                  type="text"
                  placeholder="E.g. HbA1c, Liver Function Panel, MRI Head"
                  value={newLab.testType}
                  onChange={(e) => setNewLab({ ...newLab, testType: e.target.value })}
                  className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-emerald-500"
                  required
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-emerald-400 block mb-1">Triage Priority</label>
                <div className="grid grid-cols-3 gap-2">
                  {(["routine", "urgent", "stat"] as const).map((p) => (
                    <button
                      key={p}
                      type="button"
                      onClick={() => setNewLab({ ...newLab, priority: p })}
                      className={`py-2 rounded-xl text-xs font-bold border capitalize transition-all ${
                        newLab.priority === p
                          ? "bg-emerald-500 border-emerald-500 text-white"
                          : "bg-[#050E0C] border-[#1B352E] text-[#8AA098] hover:border-[#1E5D52]"
                      }`}
                    >
                      {p}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex justify-end gap-2 border-t border-[#1B352E] pt-4 mt-6">
                <button
                  type="button"
                  onClick={() => setIsLabModalOpen(false)}
                  className="px-4 py-2 bg-transparent hover:bg-[#12463E]/30 text-[#8AA098] rounded-xl text-xs font-semibold transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-emerald-500/10"
                >
                  Dispatch Lab Order
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ─── MODAL: LOG CONSULTATION ─── */}
      {isConsultationModalOpen && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center z-50 p-4">
          <div className="bg-[#0C1E1A] border border-[#1E5D52] rounded-3xl w-full max-w-md p-6">
            <div className="flex justify-between items-center border-b border-[#1B352E] pb-4">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Stethoscope className="h-5 w-5 text-emerald-400" /> Start Diagnosis Notes
              </h3>
              <button
                onClick={() => setIsConsultationModalOpen(false)}
                className="text-[#8AA098] hover:text-white transition-colors"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSaveConsultation} className="space-y-4 mt-4">
              <div>
                <label className="text-xs font-semibold text-emerald-400 block mb-1">Patient</label>
                <select
                  value={newConsultation.patientName}
                  onChange={(e) => setNewConsultation({ ...newConsultation, patientName: e.target.value })}
                  className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  required
                >
                  <option value="">-- Choose patient --</option>
                  {appointments.map(a => (
                    <option key={a.id} value={a.patientName}>{a.patientName}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs font-semibold text-emerald-400 block mb-1">Diagnosis & Assessment</label>
                <input
                  type="text"
                  placeholder="E.g. Mild gastric irritation, early stage influenza"
                  value={newConsultation.diagnosis}
                  onChange={(e) => setNewConsultation({ ...newConsultation, diagnosis: e.target.value })}
                  className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-emerald-500"
                  required
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-emerald-400 block mb-1">Treatment / Intervention Plan</label>
                <textarea
                  placeholder="E.g. Bed rest, daily temperature tracking, follow-up in 3 days."
                  value={newConsultation.treatmentPlan}
                  onChange={(e) => setNewConsultation({ ...newConsultation, treatmentPlan: e.target.value })}
                  className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 h-20"
                  required
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-emerald-400 block mb-1">Clinical Notes (Confidential)</label>
                <textarea
                  placeholder="E.g. Patient showed anxiety during assessment. Recommend soft diet."
                  value={newConsultation.notes}
                  onChange={(e) => setNewConsultation({ ...newConsultation, notes: e.target.value })}
                  className="w-full bg-[#050E0C] border border-[#1B352E] rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 h-20"
                />
              </div>

              <div className="flex justify-end gap-2 border-t border-[#1B352E] pt-4 mt-6">
                <button
                  type="button"
                  onClick={() => setIsConsultationModalOpen(false)}
                  className="px-4 py-2 bg-transparent hover:bg-[#12463E]/30 text-[#8AA098] rounded-xl text-xs font-semibold transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-emerald-500/10"
                >
                  Save Diagnostics Notes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
