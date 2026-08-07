"use client"

import React, { useState, useEffect, useMemo } from "react"
import {
  Users,
  Calendar,
  CreditCard,
  BarChart3,
  Plus,
  Search,
  CheckCircle,
  Clock,
  UserPlus,
  Activity,
  LogOut,
  TrendingUp,
  TrendingDown,
  Phone,
  Mail,
  Shield,
  BedDouble,
} from "lucide-react"
import {
  listPatients,
  registerPatient,
  listDoctors,
  listAppointments,
  bookAppointment,
  updateAppointment,
  listInvoices,
  createInvoice,
  updateInvoice,
  getDashboard,
  listBeds,
  updateBedStatus,
  type Bed,
  type DoctorOption,
  type DashboardStats,
} from "@/services/receptionist.service"
import { useToast } from "@/components/ui/toast"

// Types & Mock Data for Receptionist Panel
interface Patient {
  id: string
  name: string
  age: number
  gender: "Male" | "Female" | "Other"
  phone: string
  email: string
  insuranceProvider: string
  registeredAt: string
}

interface Appointment {
  id: string
  patientName: string
  patientPhone: string
  doctorName: string
  specialty: string
  date: string
  time: string
  fee: number
  paymentStatus: "paid" | "unpaid"
  status: "scheduled" | "checked-in" | "completed" | "cancelled"
}

interface Invoice {
  id: string
  patientName: string
  date: string
  amount: number
  items: { description: string; cost: number }[]
  insuranceStatus: "covered" | "uninsured" | "pending"
  paymentStatus: "paid" | "unpaid"
}

// Fallback dummy data so every panel renders even when the API is unreachable/empty
const mockPatients: Patient[] = [
  { id: "PAT-001", name: "Emma Watson", age: 32, gender: "Female", phone: "+1 (555) 019-2834", email: "emma.watson@gmail.com", insuranceProvider: "BlueCross Health", registeredAt: "2026-07-20" },
  { id: "PAT-002", name: "Liam Neeson", age: 68, gender: "Male", phone: "+44 7911 123456", email: "liam@taken.com", insuranceProvider: "Aetna Premium", registeredAt: "2026-07-19" },
  { id: "PAT-003", name: "Robert Downey Jr.", age: 55, gender: "Male", phone: "+1 (555) 300-3000", email: "rdj@stark.com", insuranceProvider: "Star Health Assurance", registeredAt: "2026-07-18" },
  { id: "PAT-004", name: "Scarlett Johansson", age: 36, gender: "Female", phone: "+1 (555) 102-8822", email: "scarlett@avengers.org", insuranceProvider: "MetLife Shield", registeredAt: "2026-07-17" },
  { id: "PAT-005", name: "Leonardo DiCaprio", age: 47, gender: "Male", phone: "+1 (555) 987-6543", email: "leo@di-caprio.com", insuranceProvider: "Self-Pay (Uninsured)", registeredAt: "2026-07-16" },
]

const mockAppointments: Appointment[] = [
  { id: "APT-901", patientName: "Robert Downey Jr.", patientPhone: "+1 (555) 300-3000", doctorName: "Dr. Gregory House", specialty: "General Medicine", date: "2026-07-20", time: "09:30 AM", fee: 150, paymentStatus: "paid", status: "checked-in" },
  { id: "APT-902", patientName: "Emma Watson", patientPhone: "+1 (555) 019-2834", doctorName: "Dr. Gregory House", specialty: "General Medicine", date: "2026-07-20", time: "10:15 AM", fee: 150, paymentStatus: "unpaid", status: "checked-in" },
  { id: "APT-903", patientName: "Liam Neeson", patientPhone: "+44 7911 123456", doctorName: "Dr. Stephen Strange", specialty: "Cardiology", date: "2026-07-20", time: "11:00 AM", fee: 200, paymentStatus: "unpaid", status: "scheduled" },
  { id: "APT-904", patientName: "Scarlett Johansson", patientPhone: "+1 (555) 102-8822", doctorName: "Dr. Allison Cameron", specialty: "Pediatrics", date: "2026-07-20", time: "11:45 AM", fee: 150, paymentStatus: "unpaid", status: "scheduled" },
  { id: "APT-905", patientName: "Leonardo DiCaprio", patientPhone: "+1 (555) 987-6543", doctorName: "Dr. Meredith Grey", specialty: "Neurology", date: "2026-07-21", time: "02:15 PM", fee: 250, paymentStatus: "unpaid", status: "scheduled" },
]

const mockInvoices: Invoice[] = [
  { id: "INV-401", patientName: "Robert Downey Jr.", date: "2026-07-20", amount: 850, items: [{ description: "General Consultation (OPD)", cost: 150 }, { description: "ECG Diagnostic Scan", cost: 300 }, { description: "Cardiology Telemetry Hookup", cost: 400 }], insuranceStatus: "covered", paymentStatus: "paid" },
  { id: "INV-402", patientName: "Emma Watson", date: "2026-07-20", amount: 450, items: [{ description: "General Consultation (OPD)", cost: 150 }, { description: "CBC Blood Panel", cost: 300 }], insuranceStatus: "pending", paymentStatus: "unpaid" },
  { id: "INV-403", patientName: "Liam Neeson", date: "2026-07-21", amount: 300, items: [{ description: "Cardiology Consultation", cost: 200 }, { description: "Lipid Profile Panel", cost: 100 }], insuranceStatus: "uninsured", paymentStatus: "unpaid" },
]

const mockDoctors: DoctorOption[] = [
  { user_id: "DOC-001", name: "Dr. Gregory House", specialty: "General Medicine", department: "OPD - General", email: "house@aura-med.org", phone: "+1 (555) 123-9081" },
  { user_id: "DOC-002", name: "Dr. Meredith Grey", specialty: "Neurology", department: "Neuro Sciences", email: "grey@aura-med.org", phone: "+1 (555) 345-1234" },
  { user_id: "DOC-003", name: "Dr. Shaun Murphy", specialty: "Orthopedics", department: "Ortho & Trauma", email: "murphy@aura-med.org", phone: "+1 (555) 890-4321" },
  { user_id: "DOC-004", name: "Dr. Stephen Strange", specialty: "Cardiology", department: "Cardio Thoracic", email: "strange@aura-med.org", phone: "+1 (555) 456-7890" },
  { user_id: "DOC-005", name: "Dr. Allison Cameron", specialty: "Pediatrics", department: "Pediatric Care", email: "cameron@aura-med.org", phone: "+1 (555) 789-0123" },
]

const mockDashboard: DashboardStats = {
  today_visits: 12,
  checked_in_today: 8,
  total_patients: 342,
  paid_billings: 25400,
  unpaid_billings: 8850,
  unpaid_invoices: 4,
  total_beds: 10,
  occupied_beds: 6,
  occupancy_rate: 60,
  pending_tasks: 3,
  admitted: 4,
}

export default function ReceptionistDashboard() {
  const toast = useToast()
  const [activeTab, setActiveTab] = useState<"registration" | "appointments" | "beds" | "billing" | "reports">("registration")
  const [currentTime, setCurrentTime] = useState("")
  const [authed, setAuthed] = useState(false)

  useEffect(() => {
    if (!localStorage.getItem("access_token")) {
      window.location.href = "/login"
    } else {
      setAuthed(true)
    }
  }, [])

  // State variables (fetched from the receptionist API; falls back to dummy data)
  const [loading, setLoading] = useState(true)
  const [patients, setPatients] = useState<Patient[]>(mockPatients)
  const [appointments, setAppointments] = useState<Appointment[]>(mockAppointments)
  const [invoices, setInvoices] = useState<Invoice[]>(mockInvoices)
  const [doctors, setDoctors] = useState<DoctorOption[]>(mockDoctors)
  const [dashboard, setDashboard] = useState<DashboardStats | null>(mockDashboard)
  const [beds, setBeds] = useState<Bed[]>([])

  useEffect(() => {
    let active = true
    async function load() {
      try {
        const [pRes, aRes, iRes, dRes, dashRes, bedRes] = await Promise.all([
          listPatients(),
          listAppointments(),
          listInvoices(),
          listDoctors(),
          getDashboard(),
          listBeds(),
        ])
        if (!active) return

        if (pRes.data.length) {
          setPatients(pRes.data.map((p) => ({
            id: `PAT-${String(p.id).padStart(3, "0")}`,
            name: p.name,
            age: p.age ?? 30,
            gender: (p.gender || "Male") as Patient["gender"],
            phone: p.phone,
            email: p.email || "no-email@aura.org",
            insuranceProvider: p.insurance_provider,
            registeredAt: p.created_at ? p.created_at.split("T")[0] : new Date().toISOString().split("T")[0],
          })))
        }

        if (aRes.data.length) {
          setAppointments(aRes.data.map((a) => ({
            id: a.appointment_id,
            patientName: a.patient_name,
            patientPhone: a.patient_phone || "",
          doctorName: a.doctor_name,
            specialty: a.specialty,
            date: a.date,
            time: a.time,
            fee: a.fee ?? 150,
          paymentStatus: (a.payment_status || "UNPAID").toLowerCase() as Appointment["paymentStatus"],
          status: a.status.toLowerCase() as Appointment["status"],
          })))
        }

        if (iRes.data.length) {
          setInvoices(iRes.data.map((inv) => ({
            id: inv.invoice_id,
            patientName: inv.patient_name,
            date: inv.date,
            amount: inv.amount,
            items: inv.items,
            insuranceStatus: inv.insurance_status.toLowerCase() as Invoice["insuranceStatus"],
            paymentStatus: inv.payment_status.toLowerCase() as Invoice["paymentStatus"],
          })))
        }

        if (dRes.data.length) setDoctors(dRes.data)
        setDashboard(dashRes.data)
        setBeds(bedRes.data)
      } catch (err: any) {
        console.error("Failed to load receptionist data", err)
      } finally {
        if (active) setLoading(false)
      }
    }
    load()
    return () => { active = false }
  }, [])

  // Modals & form submissions states
  const [isRegisterOpen, setIsRegisterOpen] = useState(false)
  const [newPatient, setNewPatient] = useState({
    name: "",
    age: "",
    gender: "Male" as "Male" | "Female" | "Other",
    phone: "",
    email: "",
    insuranceProvider: ""
  })

  const [isBookOpen, setIsBookOpen] = useState(false)
  const [newAppt, setNewAppt] = useState({
    patientName: "",
    doctorName: "",
    specialty: "General Medicine",
    time: "",
    date: ""
  })

  const [isInvoiceOpen, setIsInvoiceOpen] = useState(false)
  const [newInvoice, setNewInvoice] = useState({
    patientName: "",
    insuranceStatus: "uninsured" as "covered" | "uninsured" | "pending",
    items: [{ description: "", cost: 0 }]
  })

  const [isBedBookOpen, setIsBedBookOpen] = useState(false)
  const [bedBooking, setBedBooking] = useState({ bedId: "", patientName: "", status: "OCCUPIED" as "OCCUPIED" | "RESERVED" })
  const [bedStatusFilter, setBedStatusFilter] = useState<string>("all")
  const [bedWardFilter, setBedWardFilter] = useState<string>("all")

  const [searchTerm, setSearchTerm] = useState("")

  useEffect(() => {
    const updateTime = () => {
      const now = new Date()
      setCurrentTime(now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit", hour12: true }))
    }
    updateTime()
    const timer = setInterval(updateTime, 1000)
    return () => clearInterval(timer)
  }, [])

  // Handlers
  const handleRegisterPatient = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newPatient.name || !newPatient.phone) return

    try {
      const res = await registerPatient({
        user_name: newPatient.name,
        phone: newPatient.phone,
        email: newPatient.email || undefined,
        age: Number(newPatient.age) || null,
        gender: newPatient.gender,
        insurance_provider: newPatient.insuranceProvider || null,
      })

      const created: Patient = {
        id: `PAT-${String(res.data.id).padStart(3, "0")}`,
        name: res.data.name,
        age: res.data.age ?? 30,
        gender: (res.data.gender || "Male") as Patient["gender"],
        phone: res.data.phone,
        email: res.data.email || "no-email@aura.org",
        insuranceProvider: res.data.insurance_provider,
        registeredAt: new Date().toISOString().split("T")[0]
      }

      setPatients([created, ...patients])
      setNewPatient({ name: "", age: "", gender: "Male", phone: "", email: "", insuranceProvider: "" })
      setIsRegisterOpen(false)
      toast.success("Patient registered", `${created.name} was added to the system.`)
    } catch (err: any) {
      toast.error("Failed to register patient", err.message || "")
    }
  }

  const handleBookAppointment = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newAppt.patientName || !newAppt.doctorName || !newAppt.time) return

    try {
      const selectedPatient = patients.find(p => p.name === newAppt.patientName)
      const res = await bookAppointment({
        patient_name: newAppt.patientName,
        patient_phone: selectedPatient?.phone,
        doctor_name: newAppt.doctorName,
        specialty: newAppt.specialty,
        date: newAppt.date || new Date().toISOString().split("T")[0],
        time: newAppt.time,
        status: "SCHEDULED",
      })

      const created: Appointment = {
        id: res.data.appointment_id,
        patientName: res.data.patient_name,
        patientPhone: res.data.patient_phone || selectedPatient?.phone || "",
        doctorName: res.data.doctor_name,
        specialty: res.data.specialty,
        date: res.data.date,
        time: res.data.time,
        fee: res.data.fee ?? 150,
        paymentStatus: (res.data.payment_status || "UNPAID").toLowerCase() as Appointment["paymentStatus"],
        status: "scheduled"
      }

      setAppointments([created, ...appointments])
      setNewAppt({ patientName: "", doctorName: "", specialty: "General Medicine", time: "", date: "" })
      setIsBookOpen(false)
      toast.success("Appointment booked", `${created.patientName} scheduled with ${created.doctorName} at ${created.time}.`)
    } catch (err: any) {
      toast.error("Failed to book appointment", err.message || "")
    }
  }

  const handleAddInvoiceItem = () => {
    setNewInvoice({
      ...newInvoice,
      items: [...newInvoice.items, { description: "", cost: 0 }]
    })
  }

  const handleInvoiceItemChange = (index: number, field: string, value: string | number) => {
    const updated = [...newInvoice.items]
    updated[index] = { ...updated[index], [field]: value }
    setNewInvoice({ ...newInvoice, items: updated })
  }

  const handleCreateInvoice = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newInvoice.patientName || !newInvoice.items[0].description) return

    const items = newInvoice.items
      .filter(item => item.description !== "")
      .map(item => ({ description: item.description, cost: Number(item.cost) || 0 }))

    try {
      const res = await createInvoice({
        patient_name: newInvoice.patientName,
        date: new Date().toISOString().split("T")[0],
        items,
        insurance_status: newInvoice.insuranceStatus.toUpperCase(),
      })

      const created: Invoice = {
        id: res.data.invoice_id,
        patientName: res.data.patient_name,
        date: res.data.date,
        amount: res.data.amount,
        items: res.data.items,
        insuranceStatus: res.data.insurance_status.toLowerCase() as Invoice["insuranceStatus"],
        paymentStatus: "unpaid"
      }

      setInvoices([created, ...invoices])
      setNewInvoice({ patientName: "", insuranceStatus: "uninsured", items: [{ description: "", cost: 0 }] })
      setIsInvoiceOpen(false)
      toast.success("Invoice created", `Invoice ${created.id} for ${created.patientName} recorded.`)
    } catch (err: any) {
      toast.error("Failed to create invoice", err.message || "")
    }
  }

  const handleMarkAsPaid = async (id: string) => {
    try {
      await updateInvoice(id, { payment_status: "PAID" })
      setInvoices(invoices.map(inv => inv.id === id ? { ...inv, paymentStatus: "paid" as const } : inv))
      toast.success("Invoice marked as paid", `Invoice ${id} settled.`)
    } catch (err: any) {
      toast.error("Failed to mark invoice as paid", err.message || "")
    }
  }

  const handleCheckIn = async (id: string) => {
    try {
      await updateAppointment(id, { status: "CHECKED-IN" })
      setAppointments(appointments.map(a => a.id === id ? { ...a, status: "checked-in" as const } : a))
      toast.success("Patient checked in", `Appointment ${id} marked as checked-in.`)
    } catch (err: any) {
      toast.error("Failed to check in patient", err.message || "")
    }
  }

  const handleCompleteVisit = async (id: string) => {
    try {
      await updateAppointment(id, { status: "COMPLETED" })
      setAppointments(appointments.map(a => a.id === id ? { ...a, status: "completed" as const } : a))
      toast.success("Visit completed", `Appointment ${id} marked as completed.`)
    } catch (err: any) {
      toast.error("Failed to mark visit completed", err.message || "")
    }
  }

  const handleConfirmBookBed = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!bedBooking.bedId) return

    try {
      const selectedPatient = patients.find(p => p.name === bedBooking.patientName)
      const res = await updateBedStatus(bedBooking.bedId, {
        status: bedBooking.status,
        patient: selectedPatient?.name || bedBooking.patientName || null,
      })
      setBeds(beds.map(b => b.bed_id === bedBooking.bedId ? res.data : b))
      setBedBooking({ bedId: "", patientName: "", status: "OCCUPIED" })
      setIsBedBookOpen(false)
      toast.success("Bed booked", `Bed ${bedBooking.bedId} assigned successfully.`)
    } catch (err: any) {
      toast.error("Failed to book bed", err.message || "")
    }
  }

  const handleReleaseBed = async (bedId: string) => {
    if (!window.confirm(`Release bed ${bedId}? The bed will be marked AVAILABLE.`)) return
    try {
      const res = await updateBedStatus(bedId, { status: "AVAILABLE" })
      setBeds(beds.map(b => b.bed_id === bedId ? res.data : b))
      toast.success("Bed released", `Bed ${bedId} is now available.`)
    } catch (err: any) {
      toast.error("Failed to release bed", err.message || "")
    }
  }

  // Beds filtering (ward + status) for the front-desk bed console
  const filteredBeds = useMemo(() => {
    return beds.filter(b =>
      (bedStatusFilter === "all" || b.status === bedStatusFilter) &&
      (bedWardFilter === "all" || b.ward === bedWardFilter)
    )
  }, [beds, bedStatusFilter, bedWardFilter])

  const bedWards = useMemo(() => Array.from(new Set(beds.map(b => b.ward))).sort(), [beds])
  const bedCounts = useMemo(() => ({
    total: beds.length,
    available: beds.filter(b => b.status === "AVAILABLE").length,
    occupied: beds.filter(b => b.status === "OCCUPIED").length,
    sanitizing: beds.filter(b => b.status === "SANITIZING").length,
    reserved: beds.filter(b => b.status === "RESERVED").length,
  }), [beds])

  // Filtered patients search
  const filteredPatients = patients.filter(p =>
    (p.name || "").toLowerCase().includes(searchTerm.toLowerCase()) ||
    (p.phone || "").includes(searchTerm) ||
    p.id.toLowerCase().includes(searchTerm.toLowerCase())
  )

  // OPD specialty distribution for the analytics tab
  const specialtyBreakdown = useMemo(() => {
    const counts: Record<string, number> = {}
    appointments.forEach(a => {
      counts[a.specialty] = (counts[a.specialty] || 0) + 1
    })
    const entries = Object.entries(counts).map(([name, count]) => ({ name, count }))
    entries.sort((a, b) => b.count - a.count)
    return entries
  }, [appointments])

  const maxSpecialty = specialtyBreakdown.length
    ? Math.max(...specialtyBreakdown.map(s => s.count))
    : 0

  if (!authed) return null

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#F6F8F7] text-[#0B2B26]">
        <div className="text-sm font-semibold text-[#12463E] animate-pulse">Loading desk console...</div>
      </div>
    )
  }

  return (
    <div className="flex min-h-screen bg-[#F6F8F7] text-[#0B2B26]">
      {/* ─── SIDEBAR ─── */}
      <aside className="w-72 bg-[#0C1E1A] border-r border-[#1B352E] flex flex-col justify-between h-screen sticky top-0 shrink-0 text-[#E5ECE9]">
        <div>
          {/* Brand */}
          <div className="p-6">
            <div className="flex items-center gap-3 bg-gradient-to-r from-[#12463E] to-[#0A2622] p-4 rounded-2xl border border-[#1E5D52] shadow-lg">
              <div className="w-10 h-10 rounded-xl bg-emerald-500 flex items-center justify-center text-white shadow-md shadow-emerald-500/20">
                <Users className="h-5.5 w-5.5" strokeWidth={2.5} />
              </div>
              <div>
                <h2 className="font-bold text-sm tracking-wide text-white">AURA Medical</h2>
                <p className="text-[10px] text-emerald-400 font-semibold tracking-widest uppercase mt-0.5">Reception Desk</p>
              </div>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="px-4 space-y-1.5 py-2">
            <p className="px-3 text-[10px] font-bold text-[#8AA098] tracking-widest uppercase mb-3">Front Desk Console</p>

            <button
              onClick={() => setActiveTab("registration")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "registration" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "registration" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <UserPlus className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Patient Admissions</span>
            </button>

            <button
              onClick={() => setActiveTab("appointments")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "appointments" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "appointments" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <Calendar className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>OPD Scheduler</span>
            </button>

            <button
              onClick={() => setActiveTab("beds")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "beds" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "beds" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <BedDouble className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Ward & Bed Console</span>
            </button>

            <button
              onClick={() => setActiveTab("billing")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "billing" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "billing" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <CreditCard className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Billing & Invoices</span>
            </button>

            <button
              onClick={() => setActiveTab("reports")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "reports" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "reports" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <BarChart3 className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Clinic Analytics</span>
            </button>
          </nav>
        </div>

        {/* Receptionist Info */}
        <div className="p-4 border-t border-[#1B352E] bg-[#071310]">
          <div className="flex items-center gap-3 p-2 rounded-xl">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-[#12463E] flex items-center justify-center font-bold text-white border border-[#1E5D52]">
              PS
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-white truncate font-sans">Priya Sharma</p>
              <p className="text-[10px] text-emerald-400 truncate">Front Desk supervisor</p>
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
        <header className="h-20 bg-white border-b border-[#E8ECEB] flex items-center justify-between px-8 sticky top-0 z-30 shadow-sm">
          <div>
            <h1 className="text-lg font-bold text-[#0B2B26] tracking-tight uppercase">
              {activeTab === "registration" && "Patient Registry"}
              {activeTab === "appointments" && "Doctor Scheduling & Appointments"}
              {activeTab === "beds" && "Ward & Bed Availability"}
              {activeTab === "billing" && "Billing Entry & Ledger"}
              {activeTab === "reports" && "Operational Reports & KPI Telemetry"}
            </h1>
            <p className="text-xs text-[#6B8078] mt-0.5">Welcome back, Priya. Desk Console fully operational.</p>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#EEF4F1] border border-[#D7E2DC] text-[#12463E] font-medium text-xs tabular-nums">
              <Clock className="h-3.5 w-3.5" />
              <span>{currentTime || "Loading clock..."}</span>
            </div>
            <div className="flex items-center gap-2 text-xs text-emerald-700 bg-emerald-50 px-3.5 py-2 rounded-xl border border-emerald-200 font-bold">
              <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-ping" />
              <span>Online Desk</span>
            </div>
          </div>
        </header>

        {/* Content Wrapper */}
        <main className="flex-1 p-8 overflow-y-auto max-w-[1400px] w-full mx-auto space-y-6">
          {/* ─── TAB 1: PATIENT REGISTRATION ─── */}
          {activeTab === "registration" && (
            <div className="space-y-6">
              {/* Operations row */}
              <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div className="relative w-full md:w-80">
                  <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-[#8AA098]" />
                  <input
                    type="text"
                    placeholder="Search name, phone, patient ID..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full h-11 pl-10 pr-4 rounded-xl border border-[#D7E2DC] bg-white text-xs text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all shadow-sm"
                  />
                </div>

                <button
                  onClick={() => setIsRegisterOpen(true)}
                  className="px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-lg shadow-emerald-500/10"
                >
                  <Plus className="h-4 w-4" /> Register New Patient
                </button>
              </div>

              {/* Patient Table */}
              <div className="bg-white border border-[#E8ECEB] rounded-3xl overflow-hidden shadow-sm">
                <div className="p-6 border-b border-[#E8ECEB] bg-[#EEF4F1]/30">
                  <h3 className="font-bold text-[#0B2B26] text-base">Registered Patient Database</h3>
                  <p className="text-xs text-[#6B8078] mt-1">Review demographics, contact credentials and health insurance coverage providers</p>
                </div>
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-[#EEF4F1]/40 border-b border-[#E8ECEB] text-xs font-bold text-[#6B8078] uppercase">
                      <th className="p-4">Patient ID</th>
                      <th className="p-4">Full Name</th>
                      <th className="p-4">Age / Gender</th>
                      <th className="p-4">Contact info</th>
                      <th className="p-4">Insurance policy</th>
                      <th className="p-4">Registered On</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#E8ECEB]">
                    {filteredPatients.map((p) => (
                      <tr key={p.id} className="text-sm hover:bg-[#EEF4F1]/30 transition-all">
                        <td className="p-4 font-mono text-emerald-700 font-bold">{p.id}</td>
                        <td className="p-4 font-bold text-[#0B2B26]">{p.name}</td>
                        <td className="p-4 text-[#4B5F58]">
                          {p.age} Y/O <span className="text-[#8AA098] font-bold">/</span> {p.gender}
                        </td>
                        <td className="p-4 text-[#4B5F58] space-y-1 text-xs">
                          <p className="flex items-center gap-1"><Phone className="h-3 w-3 text-[#8AA098]" /> {p.phone}</p>
                          <p className="flex items-center gap-1"><Mail className="h-3 w-3 text-[#8AA098]" /> {p.email}</p>
                        </td>
                        <td className="p-4 text-xs font-semibold">
                          <span className="inline-flex items-center gap-1 bg-[#EEF4F1] border border-[#D7E2DC] px-2.5 py-1 rounded-full text-[#12463E]">
                            <Shield className="h-3 w-3 text-[#12463E]" /> {p.insuranceProvider}
                          </span>
                        </td>
                        <td className="p-4 text-xs font-mono text-[#6B8078]">{p.registeredAt}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* ─── TAB 2: OPD SCHEDULER ─── */}
          {activeTab === "appointments" && (
            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <div>
                  <h2 className="text-lg font-bold text-[#0B2B26]">Outpatient Department (OPD) Scheduling</h2>
                  <p className="text-xs text-[#6B8078] mt-1">Book consultations, followups, and check-in patients as they arrive</p>
                </div>
                <button
                  onClick={() => setIsBookOpen(true)}
                  className="px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-lg shadow-emerald-500/10"
                >
                  <Plus className="h-4 w-4" /> Book Appointment slot
                </button>
              </div>

              {/* Appointments grid */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {appointments.map((appt) => (
                  <div key={appt.id} className="bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm hover:shadow-md transition-all">
                    <div className="flex justify-between items-start border-b border-[#E8ECEB] pb-4">
                      <div>
                        <h3 className="font-bold text-[#0B2B26] text-base">{appt.patientName}</h3>
                        <p className="text-xs text-[#8AA098] mt-1 font-mono">{appt.id}</p>
                        {appt.patientPhone && (
                          <p className="text-xs text-[#8AA098] mt-0.5 font-mono">📞 {appt.patientPhone}</p>
                        )}
                      </div>
                      <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                        appt.status === "checked-in" ? "bg-sky-50 text-sky-700 border border-sky-200" :
                        appt.status === "completed" ? "bg-emerald-50 text-emerald-700 border border-emerald-200" :
                        appt.status === "cancelled" ? "bg-rose-50 text-rose-700 border border-rose-200" :
                        "bg-amber-50 text-amber-700 border border-amber-200"
                      }`}>
                        {appt.status}
                      </span>
                    </div>

                    <div className="mt-4 space-y-2.5 text-xs text-[#4B5F58]">
                      <div className="flex justify-between">
                        <span className="font-semibold">Specialist:</span>
                        <span className="font-bold text-[#0B2B26]">{appt.doctorName}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-semibold">Specialty:</span>
                        <span className="bg-emerald-50 text-emerald-800 px-2 py-0.5 rounded font-medium">{appt.specialty}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-semibold">Scheduled Date:</span>
                        <span className="font-mono">{appt.date}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-semibold">Consultation Slot:</span>
                        <span className="font-bold text-emerald-700">{appt.time}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="font-semibold">Fee / Payment:</span>
                        <span className="flex items-center gap-1.5">
                          <span className="font-mono">₹{appt.fee}</span>
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                            appt.paymentStatus === "paid" ? "bg-emerald-100 text-emerald-800" : "bg-rose-100 text-rose-800"
                          }`}>
                            {appt.paymentStatus}
                          </span>
                        </span>
                      </div>
                    </div>

                    {appt.status === "scheduled" && (
                      <button
                        onClick={() => handleCheckIn(appt.id)}
                        className="w-full mt-5 py-2.5 bg-[#12463E] hover:bg-[#0B2B26] text-white text-xs font-semibold rounded-xl transition-all shadow-sm flex items-center justify-center gap-1"
                      >
                        <CheckCircle className="h-4 w-4" /> Check In Patient
                      </button>
                    )}
                    {appt.status === "checked-in" && (
                      <button
                        onClick={() => handleCompleteVisit(appt.id)}
                        className="w-full mt-5 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-white text-xs font-semibold rounded-xl transition-all shadow-sm flex items-center justify-center gap-1"
                      >
                        <CheckCircle className="h-4 w-4" /> Mark Visit Completed
                      </button>
                    )}
                    {appt.status === "completed" && (
                      <p className="w-full mt-5 py-2.5 text-center text-xs font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-xl">
                        Consultation completed — patient can now rate the doctor
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ─── TAB 3: WARD & BED CONSOLE ─── */}
          {activeTab === "beds" && (
            <div className="space-y-6">
              {/* Bed occupancy summary */}
              <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                <div className="bg-white p-5 rounded-3xl border border-[#E8ECEB] shadow-xs">
                  <h4 className="text-[11px] font-semibold text-[#8AA098] uppercase tracking-wider">Total Beds</h4>
                  <p className="text-3xl font-black text-[#0B2B26] mt-1.5">{bedCounts.total}</p>
                </div>
                <div className="bg-white p-5 rounded-3xl border border-[#E8ECEB] shadow-xs">
                  <h4 className="text-[11px] font-semibold text-[#8AA098] uppercase tracking-wider">Available</h4>
                  <p className="text-3xl font-black text-emerald-600 mt-1.5">{bedCounts.available}</p>
                </div>
                <div className="bg-white p-5 rounded-3xl border border-[#E8ECEB] shadow-xs">
                  <h4 className="text-[11px] font-semibold text-[#8AA098] uppercase tracking-wider">Occupied</h4>
                  <p className="text-3xl font-black text-sky-600 mt-1.5">{bedCounts.occupied}</p>
                </div>
                <div className="bg-white p-5 rounded-3xl border border-[#E8ECEB] shadow-xs">
                  <h4 className="text-[11px] font-semibold text-[#8AA098] uppercase tracking-wider">Reserved</h4>
                  <p className="text-3xl font-black text-rose-600 mt-1.5">{bedCounts.reserved}</p>
                </div>
                <div className="bg-white p-5 rounded-3xl border border-[#E8ECEB] shadow-xs">
                  <h4 className="text-[11px] font-semibold text-[#8AA098] uppercase tracking-wider">Sanitizing</h4>
                  <p className="text-3xl font-black text-amber-600 mt-1.5">{bedCounts.sanitizing}</p>
                </div>
              </div>

              {/* Filters */}
              <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-5 rounded-3xl border border-[#E8ECEB] shadow-xs">
                <div>
                  <h3 className="font-bold text-[#0B2B26] text-base">Bed Availability Board</h3>
                  <p className="text-xs text-[#6B8078] mt-1">View ward-wise availability and book or release beds from the front desk</p>
                </div>
                <div className="flex flex-wrap items-center gap-3">
                  <select
                    value={bedWardFilter}
                    onChange={(e) => setBedWardFilter(e.target.value)}
                    className="h-10 px-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs font-semibold text-[#12463E] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="all">All Wards</option>
                    {bedWards.map(w => <option key={w} value={w}>{w}</option>)}
                  </select>
                  <div className="flex bg-[#F6F8F7] border border-[#D7E2DC] p-1 rounded-xl">
                    {["all", "AVAILABLE", "OCCUPIED", "RESERVED", "SANITIZING"].map((s) => (
                      <button
                        key={s}
                        onClick={() => setBedStatusFilter(s)}
                        className={`px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase tracking-wide transition-all ${
                          bedStatusFilter === s ? "bg-emerald-500 text-white shadow-sm" : "text-[#6B8078] hover:text-[#12463E]"
                        }`}
                      >
                        {s === "all" ? "All" : s}
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              {/* Beds grid */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
                {filteredBeds.map((bed) => (
                  <div key={bed.bed_id} className="bg-white border border-[#E8ECEB] rounded-3xl p-5 shadow-sm hover:shadow-md transition-all flex flex-col">
                    <div className="flex items-start justify-between border-b border-[#E8ECEB] pb-4">
                      <div className="flex items-center gap-3">
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                          bed.status === "AVAILABLE" ? "bg-emerald-50 text-emerald-600" :
                          bed.status === "OCCUPIED" ? "bg-sky-50 text-sky-600" :
                          bed.status === "RESERVED" ? "bg-rose-50 text-rose-600" :
                          "bg-amber-50 text-amber-600"
                        }`}>
                          <BedDouble className="h-5 w-5" />
                        </div>
                        <div>
                          <h3 className="font-bold text-[#0B2B26] text-base font-mono">{bed.bed_id}</h3>
                          <p className="text-[11px] text-[#8AA098] font-medium">{bed.ward} · Floor {bed.floor}</p>
                        </div>
                      </div>
                      <span className={`px-2.5 py-1 rounded-full text-[9px] font-bold uppercase tracking-wider border ${
                        bed.status === "AVAILABLE" ? "bg-emerald-50 text-emerald-700 border-emerald-200" :
                        bed.status === "OCCUPIED" ? "bg-sky-50 text-sky-700 border-sky-200" :
                        bed.status === "RESERVED" ? "bg-rose-50 text-rose-700 border-rose-200" :
                        "bg-amber-50 text-amber-700 border-amber-200"
                      }`}>
                        {bed.status}
                      </span>
                    </div>

                    <div className="mt-4 space-y-2 text-xs text-[#4B5F58] flex-1">
                      <div className="flex justify-between">
                        <span className="font-semibold text-[#8AA098]">Patient:</span>
                        <span className={`font-bold ${bed.patient ? "text-[#0B2B26]" : "text-[#9CAEA6]"}`}>
                          {bed.patient || "— vacant —"}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-semibold text-[#8AA098]">Rate:</span>
                        <span className="font-mono font-bold">₹{bed.price}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="font-semibold text-[#8AA098]">Assigned Nurse:</span>
                        <span>{bed.assigned_nurse || "—"}</span>
                      </div>
                    </div>

                    <div className="mt-4 pt-4 border-t border-[#E8ECEB]">
                      {bed.status === "AVAILABLE" || bed.status === "SANITIZING" ? (
                        <button
                          onClick={() => { setBedBooking({ bedId: bed.bed_id, patientName: "", status: "OCCUPIED" }); setIsBedBookOpen(true) }}
                          className="w-full py-2.5 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all shadow-sm flex items-center justify-center gap-1"
                        >
                          <Plus className="h-4 w-4" /> Book Bed
                        </button>
                      ) : (
                        <button
                          onClick={() => handleReleaseBed(bed.bed_id)}
                          className="w-full py-2.5 bg-[#12463E] hover:bg-[#0B2B26] text-white rounded-xl text-xs font-semibold transition-all shadow-sm flex items-center justify-center gap-1"
                        >
                          <CheckCircle className="h-4 w-4" /> Release Bed
                        </button>
                      )}
                    </div>
                  </div>
                ))}

                {filteredBeds.length === 0 && (
                  <div className="col-span-full bg-white border border-dashed border-[#D7E2DC] rounded-3xl p-10 text-center">
                    <p className="text-sm font-semibold text-[#6B8078]">No beds match the selected filters.</p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ─── TAB 4: BILLING & INVOICES ─── */}
          {activeTab === "billing" && (
            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <div>
                  <h2 className="text-lg font-bold text-[#0B2B26]">Hospital Revenue Ledger</h2>
                  <p className="text-xs text-[#6B8078] mt-1">Generate invoices for consultation fees, lab diagnostic tests, ward stays, and pharmacy bills</p>
                </div>
                <button
                  onClick={() => setIsInvoiceOpen(true)}
                  className="px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-lg shadow-emerald-500/10"
                >
                  <Plus className="h-4 w-4" /> Create Invoice
                </button>
              </div>

              {/* Invoices List */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {invoices.map((inv) => (
                  <div key={inv.id} className="bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm flex flex-col justify-between">
                    <div>
                      <div className="flex justify-between items-start border-b border-[#E8ECEB] pb-4">
                        <div>
                          <h3 className="font-bold text-[#0B2B26] text-base">{inv.patientName}</h3>
                          <p className="text-xs text-[#8AA098] mt-0.5">Date: {inv.date} · <span className="font-mono font-bold text-[#12463E]">{inv.id}</span></p>
                        </div>
                        <div className="flex flex-col items-end gap-1.5">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${
                            inv.paymentStatus === "paid" ? "bg-emerald-100 text-emerald-800" : "bg-rose-100 text-rose-800"
                          }`}>
                            {inv.paymentStatus}
                          </span>
                          <span className="text-xs font-semibold text-[#8AA098]">Insurance: {inv.insuranceStatus}</span>
                        </div>
                      </div>

                      <div className="mt-4 space-y-2">
                        <p className="text-xs text-[#8AA098] uppercase font-bold tracking-wider">Itemized charges</p>
                        <div className="space-y-1">
                          {inv.items.map((item, idx) => (
                            <div key={idx} className="flex justify-between text-xs text-[#4B5F58] py-1 border-b border-dotted border-[#E8ECEB]">
                              <span>{item.description}</span>
                              <span className="font-mono font-semibold">Rs. {item.cost}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>

                    <div className="mt-6 pt-4 border-t border-[#E8ECEB] flex items-center justify-between">
                      <div>
                        <span className="text-[11px] text-[#8AA098] font-semibold block uppercase">Total Balance</span>
                        <span className="text-xl font-black text-[#0B2B26]">Rs. {inv.amount}</span>
                      </div>

                      {inv.paymentStatus === "unpaid" && (
                        <button
                          onClick={() => handleMarkAsPaid(inv.id)}
                          className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-emerald-500/10"
                        >
                          Mark as Paid
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ─── TAB 4: OPERATIONAL REPORTS ─── */}
          {activeTab === "reports" && (
            <div className="space-y-6">
              {/* Daily KPI Metrics grid */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <div className="bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs flex items-center justify-between">
                  <div>
                    <h4 className="text-xs font-semibold text-[#8AA098] uppercase tracking-wider">Today's Visits</h4>
                    <p className="text-3xl font-black text-[#0B2B26] mt-2">{dashboard?.today_visits ?? "—"}</p>
                    <span className="text-[10px] text-emerald-600 font-bold flex items-center gap-0.5 mt-1">
                      <TrendingUp className="h-3 w-3" /> {dashboard?.checked_in_today ?? 0} checked in today
                    </span>
                  </div>
                  <div className="p-4 bg-emerald-50 text-emerald-600 rounded-2xl">
                    <Users className="h-6 w-6" />
                  </div>
                </div>

                <div className="bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs flex items-center justify-between">
                  <div>
                    <h4 className="text-xs font-semibold text-[#8AA098] uppercase tracking-wider">Net Billings</h4>
                    <p className="text-3xl font-black text-[#0B2B26] mt-2">Rs. {(dashboard?.paid_billings ?? 0).toLocaleString()}</p>
                    <span className="text-[10px] text-emerald-600 font-bold flex items-center gap-0.5 mt-1">
                      <TrendingUp className="h-3 w-3" /> {dashboard?.unpaid_invoices ?? 0} unpaid invoices
                    </span>
                  </div>
                  <div className="p-4 bg-emerald-50 text-emerald-600 rounded-2xl">
                    <CreditCard className="h-6 w-6" />
                  </div>
                </div>

                <div className="bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs flex items-center justify-between">
                  <div>
                    <h4 className="text-xs font-semibold text-[#8AA098] uppercase tracking-wider">Unpaid Billings</h4>
                    <p className="text-3xl font-black text-[#0B2B26] mt-2">Rs. {(dashboard?.unpaid_billings ?? 0).toLocaleString()}</p>
                    <span className="text-[10px] text-rose-600 font-bold flex items-center gap-0.5 mt-1">
                      <TrendingDown className="h-3 w-3" /> Pending collections
                    </span>
                  </div>
                  <div className="p-4 bg-rose-50 text-rose-600 rounded-2xl">
                    <Clock className="h-6 w-6" />
                  </div>
                </div>

                <div className="bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs flex items-center justify-between">
                  <div>
                    <h4 className="text-xs font-semibold text-[#8AA098] uppercase tracking-wider">Ward Occupancy</h4>
                    <p className="text-3xl font-black text-[#0B2B26] mt-2">{dashboard?.occupancy_rate ?? 0}%</p>
                    <span className="text-[10px] text-emerald-600 font-bold flex items-center gap-0.5 mt-1">
                      <CheckCircle className="h-3 w-3" /> {dashboard?.occupied_beds ?? 0}/{dashboard?.total_beds ?? 0} beds
                    </span>
                  </div>
                  <div className="p-4 bg-emerald-50 text-emerald-600 rounded-2xl">
                    <Activity className="h-6 w-6" />
                  </div>
                </div>
              </div>

              {/* Detailed Analytics mock panels */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-2 bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm">
                  <h3 className="font-bold text-[#0B2B26] text-base">OPD Specialty Visit Breakdown</h3>
                  <p className="text-xs text-[#8AA098] mt-1">Total distribution of OPD schedules across departments today</p>

                  <div className="space-y-4 mt-6">
                    {specialtyBreakdown.length === 0 && (
                      <p className="text-xs text-[#8AA098]">No OPD appointments booked yet.</p>
                    )}
                    {specialtyBreakdown.map((s) => {
                      const pct = maxSpecialty ? Math.round((s.count / maxSpecialty) * 100) : 0
                      return (
                        <div key={s.name}>
                          <div className="flex justify-between text-xs font-semibold mb-1.5">
                            <span>{s.name}</span>
                            <span className="font-mono">{s.count} / {maxSpecialty} Slots</span>
                          </div>
                          <div className="h-2.5 bg-[#EEF4F1] rounded-full overflow-hidden">
                            <div className="h-full bg-emerald-500 rounded-full" style={{ width: `${pct}%` }} />
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </div>

                <div className="lg:col-span-1 bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm flex flex-col justify-between">
                  <div>
                    <h3 className="font-bold text-[#0B2B26] text-base">Critical System Alerts</h3>
                    <p className="text-xs text-[#8AA098] mt-1">Realtime logs of bed occupancy and ICU capacity warnings</p>

                    <div className="space-y-3 mt-6">
                      <div className="bg-rose-50 border border-rose-100 p-3.5 rounded-2xl text-xs text-rose-800 flex items-start gap-2.5">
                        <span className="w-1.5 h-1.5 bg-rose-500 rounded-full shrink-0 mt-1.5" />
                        <div>
                          <p className="font-bold">ICU Capacity Warning</p>
                          <p className="text-[10px] text-rose-700/80 mt-0.5">8 out of 10 ICU telemetry beds occupied. Urgent sanitization required for Bed ICU-102.</p>
                        </div>
                      </div>

                      <div className="bg-amber-50 border border-amber-100 p-3.5 rounded-2xl text-xs text-amber-800 flex items-start gap-2.5">
                        <span className="w-1.5 h-1.5 bg-amber-500 rounded-full shrink-0 mt-1.5" />
                        <div>
                          <p className="font-bold">Unpaid Billing Backlog</p>
                          <p className="text-[10px] text-amber-700/80 mt-0.5">3 patients pending invoice clearance prior to hospital checkout.</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="bg-[#EEF4F1] p-4 rounded-2xl mt-4">
                    <p className="text-[10px] text-[#6B8078] font-bold uppercase tracking-wider">Telephony Queue</p>
                    <p className="text-xs text-[#12463E] mt-1 font-medium">OPD Hotlines: Connected (3 Agents Active)</p>
                  </div>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>

      {/* ─── MODAL: REGISTER PATIENT ─── */}
      {isRegisterOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white border border-[#E8ECEB] rounded-3xl w-full max-w-md p-6 shadow-2xl">
            <div className="flex justify-between items-center border-b border-[#E8ECEB] pb-4">
              <h3 className="text-lg font-bold text-[#0B2B26] flex items-center gap-2">
                <UserPlus className="h-5 w-5 text-emerald-500" /> Patient Registration Form
              </h3>
              <button
                onClick={() => setIsRegisterOpen(false)}
                className="text-[#8AA098] hover:text-[#0B2B26] transition-colors"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleRegisterPatient} className="space-y-4 mt-4">
              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Full Name</label>
                <input
                  type="text"
                  placeholder="E.g. Emma Watson"
                  value={newPatient.name}
                  onChange={(e) => setNewPatient({ ...newPatient, name: e.target.value })}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-[#12463E] block mb-1">Age</label>
                  <input
                    type="number"
                    placeholder="32"
                    value={newPatient.age}
                    onChange={(e) => setNewPatient({ ...newPatient, age: e.target.value })}
                    className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                    required
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-[#12463E] block mb-1">Gender</label>
                  <select
                    value={newPatient.gender}
                    onChange={(e) => setNewPatient({ ...newPatient, gender: e.target.value as "Male" | "Female" | "Other" })}
                    className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  >
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Phone Number</label>
                <input
                  type="tel"
                  placeholder="+1 (555) 019-2834"
                  value={newPatient.phone}
                  onChange={(e) => setNewPatient({ ...newPatient, phone: e.target.value })}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  required
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Email address</label>
                <input
                  type="email"
                  placeholder="emma@example.com"
                  value={newPatient.email}
                  onChange={(e) => setNewPatient({ ...newPatient, email: e.target.value })}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Insurance Provider</label>
                <input
                  type="text"
                  placeholder="E.g. BlueCross Health, Aetna"
                  value={newPatient.insuranceProvider}
                  onChange={(e) => setNewPatient({ ...newPatient, insuranceProvider: e.target.value })}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                />
              </div>

              <div className="flex justify-end gap-2 border-t border-[#E8ECEB] pt-4 mt-6">
                <button
                  type="button"
                  onClick={() => setIsRegisterOpen(false)}
                  className="px-4 py-2 bg-transparent hover:bg-[#EEF4F1] text-[#6B8078] rounded-xl text-xs font-semibold transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-emerald-500/10"
                >
                  Save Registration
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ─── MODAL: BOOK APPOINTMENT ─── */}
      {isBookOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white border border-[#E8ECEB] rounded-3xl w-full max-w-md p-6 shadow-2xl">
            <div className="flex justify-between items-center border-b border-[#E8ECEB] pb-4">
              <h3 className="text-lg font-bold text-[#0B2B26] flex items-center gap-2">
                <Calendar className="h-5 w-5 text-emerald-500" /> Book OPD Slot
              </h3>
              <button
                onClick={() => setIsBookOpen(false)}
                className="text-[#8AA098] hover:text-[#0B2B26] transition-colors"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleBookAppointment} className="space-y-4 mt-4">
              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Select Patient</label>
                <select
                  value={newAppt.patientName}
                  onChange={(e) => setNewAppt({ ...newAppt, patientName: e.target.value })}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  required
                >
                  <option value="">-- Choose patient --</option>
                  {patients.map(p => (
                    <option key={p.id} value={p.name}>{p.name} ({p.id})</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Attending Doctor</label>
                <select
                  value={newAppt.doctorName}
                  onChange={(e) => {
                    const selected = doctors.find(d => d.name === e.target.value)
                    setNewAppt({
                      ...newAppt,
                      doctorName: e.target.value,
                      specialty: selected?.specialty || "General Medicine"
                    })
                  }}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  required
                >
                  <option value="">-- Choose practitioner --</option>
                  {doctors.map(doc => (
                    <option key={doc.user_id} value={doc.name}>{doc.name} ({doc.specialty})</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-[#12463E] block mb-1">Booking Date</label>
                  <input
                    type="date"
                    value={newAppt.date}
                    onChange={(e) => setNewAppt({ ...newAppt, date: e.target.value })}
                    className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-[#12463E] block mb-1">OPD Slot Time</label>
                  <input
                    type="text"
                    placeholder="E.g. 10:15 AM"
                    value={newAppt.time}
                    onChange={(e) => setNewAppt({ ...newAppt, time: e.target.value })}
                    className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] placeholder:text-[#9CAEA6] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                    required
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 border-t border-[#E8ECEB] pt-4 mt-6">
                <button
                  type="button"
                  onClick={() => setIsBookOpen(false)}
                  className="px-4 py-2 bg-transparent hover:bg-[#EEF4F1] text-[#6B8078] rounded-xl text-xs font-semibold transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-emerald-500/10"
                >
                  Book OPD Slot
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ─── MODAL: CREATE INVOICE ─── */}
      {isInvoiceOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white border border-[#E8ECEB] rounded-3xl w-full max-w-md p-6 shadow-2xl max-h-[90vh] flex flex-col">
            <div className="flex justify-between items-center border-b border-[#E8ECEB] pb-4 shrink-0">
              <h3 className="text-lg font-bold text-[#0B2B26] flex items-center gap-2">
                <CreditCard className="h-5 w-5 text-emerald-500" /> Create Billing Entry
              </h3>
              <button
                onClick={() => setIsInvoiceOpen(false)}
                className="text-[#8AA098] hover:text-[#0B2B26] transition-colors"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateInvoice} className="space-y-4 py-4 overflow-y-auto flex-1 pr-1">
              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Select Patient</label>
                <select
                  value={newInvoice.patientName}
                  onChange={(e) => setNewInvoice({ ...newInvoice, patientName: e.target.value })}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  required
                >
                  <option value="">-- Choose patient --</option>
                  {patients.map(p => (
                    <option key={p.id} value={p.name}>{p.name} ({p.id})</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Insurance Triage Status</label>
                <select
                  value={newInvoice.insuranceStatus}
                  onChange={(e) => setNewInvoice({ ...newInvoice, insuranceStatus: e.target.value as "covered" | "uninsured" | "pending" })}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  <option value="covered">Policy Coverage (Fully Covered)</option>
                  <option value="pending">Claim Pending</option>
                  <option value="uninsured">Self-Pay (Uninsured)</option>
                </select>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <label className="text-xs font-semibold text-[#12463E] block">Billing Line Items</label>
                  <button
                    type="button"
                    onClick={handleAddInvoiceItem}
                    className="text-[10px] text-emerald-500 font-bold hover:underline flex items-center gap-0.5"
                  >
                    + Add Charge Item
                  </button>
                </div>

                <div className="space-y-3">
                  {newInvoice.items.map((item, idx) => (
                    <div key={idx} className="grid grid-cols-12 gap-2 bg-[#F6F8F7] p-3 rounded-xl border border-[#D7E2DC]">
                      <div className="col-span-8">
                        <input
                          type="text"
                          placeholder="Charge description (e.g. ECG Scan)"
                          value={item.description}
                          onChange={(e) => handleInvoiceItemChange(idx, "description", e.target.value)}
                          className="w-full bg-white border border-[#D7E2DC] rounded-lg px-2.5 py-2 text-xs text-[#0B2B26] focus:outline-none focus:border-emerald-500"
                          required
                        />
                      </div>
                      <div className="col-span-4">
                        <input
                          type="number"
                          placeholder="Cost (Rs.)"
                          value={item.cost || ""}
                          onChange={(e) => handleInvoiceItemChange(idx, "cost", Number(e.target.value))}
                          className="w-full bg-white border border-[#D7E2DC] rounded-lg px-2.5 py-2 text-xs text-[#0B2B26] focus:outline-none focus:border-emerald-500"
                          required
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="flex justify-end gap-2 border-t border-[#E8ECEB] pt-4 shrink-0">
                <button
                  type="button"
                  onClick={() => setIsInvoiceOpen(false)}
                  className="px-4 py-2 bg-transparent hover:bg-[#EEF4F1] text-[#6B8078] rounded-xl text-xs font-semibold transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-emerald-500/10"
                >
                  Dispatch Invoice
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ─── MODAL: BOOK BED ─── */}
      {isBedBookOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white border border-[#E8ECEB] rounded-3xl w-full max-w-md p-6 shadow-2xl">
            <div className="flex justify-between items-center border-b border-[#E8ECEB] pb-4">
              <h3 className="text-lg font-bold text-[#0B2B26] flex items-center gap-2">
                <BedDouble className="h-5 w-5 text-emerald-500" /> Book Bed {bedBooking.bedId}
              </h3>
              <button
                onClick={() => setIsBedBookOpen(false)}
                className="text-[#8AA098] hover:text-[#0B2B26] transition-colors"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleConfirmBookBed} className="space-y-4 mt-4">
              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Assign Patient</label>
                <select
                  value={bedBooking.patientName}
                  onChange={(e) => setBedBooking({ ...bedBooking, patientName: e.target.value })}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  <option value="">-- Choose registered patient --</option>
                  {patients.map(p => (
                    <option key={p.id} value={p.name}>{p.name} ({p.id})</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1">Booking Type</label>
                <select
                  value={bedBooking.status}
                  onChange={(e) => setBedBooking({ ...bedBooking, status: e.target.value as "OCCUPIED" | "RESERVED" })}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  <option value="OCCUPIED">Occupied (patient admitted)</option>
                  <option value="RESERVED">Reserved (bed blocked)</option>
                </select>
              </div>

              <div className="bg-[#EEF4F1] border border-[#D7E2DC] rounded-xl p-3 text-xs text-[#12463E]">
                This update is instantly reflected on the Admin dashboard — ward managers can see the bed as
                <strong> {bedBooking.status}</strong>.
              </div>

              <div className="flex justify-end gap-2 border-t border-[#E8ECEB] pt-4 mt-6">
                <button
                  type="button"
                  onClick={() => setIsBedBookOpen(false)}
                  className="px-4 py-2 bg-transparent hover:bg-[#EEF4F1] text-[#6B8078] rounded-xl text-xs font-semibold transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-emerald-500/10"
                >
                  Book Bed
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
