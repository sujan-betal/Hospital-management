"use client"

import React, { useState, useEffect } from "react"
import {
  Calendar,
  Clock,
  User,
  FileText,
  FlaskConical,
  CreditCard,
  Plus,
  ShieldAlert,
  Search,
  CheckCircle,
  HelpCircle,
  Activity,
  HeartPulse,
  LogOut,
  Stethoscope,
  Info,
  Sliders,
  DollarSign,
  Download,
  AlertCircle,
  Shield,
  Smartphone
} from "lucide-react"
import { getPatientProfile, updatePatientProfile } from "@/services/patient.service"

// Types & Mock Data for Patient Panel
interface DoctorReview {
  id: string
  name: string
  specialty: string
  rating: number
  reviewsCount: number
  availableSlots: string[]
}

interface PatientAppointment {
  id: string
  doctorName: string
  specialty: string
  date: string
  time: string
  status: "scheduled" | "checked-in" | "completed" | "cancelled"
}

interface PatientRecord {
  id: string
  type: "prescription" | "lab-result" | "invoice"
  title: string
  doctorName: string
  date: string
  status: "active" | "completed" | "paid" | "unpaid" | "pending"
  details: string
}

export default function PatientDashboard() {
  const [activeTab, setActiveTab] = useState<"records" | "book" | "profile">("records")
  const [currentTime, setCurrentTime] = useState("")

  // Patient Info state (fetched from the patient API, falls back to demo data)
  const [profile, setProfile] = useState({
    fullName: "Emma Watson",
    age: 32,
    gender: "Female",
    phone: "+91 98765 43210",
    email: "emma.watson@gmail.com",
    address: "Baker Street 221B, London",
    insuranceProvider: "BlueCross Health",
    insuranceNumber: "POL-8839-2026",
    bloodGroup: "O-Positive",
    emergencyContact: "John Watson (+91 98765 11111)"
  })

  // Simulated booking choices
  const [doctorsList] = useState<DoctorReview[]>([
    { id: "DOC-001", name: "Dr. Gregory House", specialty: "General Medicine", rating: 4.8, reviewsCount: 312, availableSlots: ["09:30 AM", "10:15 AM", "03:30 PM"] },
    { id: "DOC-002", name: "Dr. Meredith Grey", specialty: "Neurology", rating: 4.9, reviewsCount: 245, availableSlots: ["11:30 AM", "02:15 PM", "04:00 PM"] },
    { id: "DOC-003", name: "Dr. Shaun Murphy", specialty: "Orthopedics", rating: 4.7, reviewsCount: 198, availableSlots: ["10:30 AM", "01:15 PM", "03:00 PM"] },
    { id: "DOC-004", name: "Dr. Stephen Strange", specialty: "Cardiology", rating: 5.0, reviewsCount: 520, availableSlots: ["09:00 AM", "11:00 AM", "04:30 PM"] },
  ])

  const [appointments, setAppointments] = useState<PatientAppointment[]>([
    { id: "APT-882", doctorName: "Dr. Gregory House", specialty: "General Medicine", date: "2026-07-20", time: "10:15 AM", status: "scheduled" },
    { id: "APT-712", doctorName: "Dr. Stephen Strange", specialty: "Cardiology", date: "2026-06-15", time: "09:00 AM", status: "completed" }
  ])

  const [records, setRecords] = useState<PatientRecord[]>([
    { id: "PRX-501", type: "prescription", title: "Montelukast & Levosalbutamol Bronchial Inhaler", doctorName: "Dr. Allison Cameron", date: "2026-07-20", status: "active", details: "Montelukast 5mg (1 tab daily at night), Levosalbutamol (2 puffs daily)" },
    { id: "LAB-801", type: "lab-result", title: "Complete Blood Count (CBC) Panel", doctorName: "Dr. Gregory House", date: "2026-07-15", status: "completed", details: "Hemoglobin: 12.8 g/dL (Normal Range: 12.0 - 15.5 g/dL), WBC: 6.5 k/uL, RBC: 4.2 M/uL" },
    { id: "INV-402", type: "invoice", title: "OPD Consultation & Pathology Lab Fee", doctorName: "Front Desk Billing", date: "2026-07-20", status: "unpaid", details: "General Consultation OPD (Rs. 150) + CBC Diagnostic Blood Panel (Rs. 300) = Total Balance Due: Rs. 450" }
  ])

  // Form states
  const [selectedSpecialty, setSelectedSpecialty] = useState("All Specialties")
  const [bookingSuccess, setBookingSuccess] = useState("")

  useEffect(() => {
    const updateTime = () => {
      const now = new Date()
      setCurrentTime(now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit", hour12: true }))
    }
    updateTime()
    const timer = setInterval(updateTime, 1000)
    return () => clearInterval(timer)
  }, [])

  // Fetch the logged-in patient profile from the patient API.
  // Falls back to the demo profile when not authenticated / offline.
  useEffect(() => {
    let active = true
    async function load() {
      try {
        const res = await getPatientProfile()
        if (!active || !res?.data) return
        const p = res.data
        setProfile((prev) => ({
          ...prev,
          fullName: p.user_name || prev.fullName,
          age: p.age ?? prev.age,
          gender: p.gender || prev.gender,
          phone: p.phone || prev.phone,
          email: p.email || prev.email,
          insuranceProvider: p.insurance_provider && p.insurance_provider !== "Self-Pay / None"
            ? p.insurance_provider
            : prev.insuranceProvider,
        }))
      } catch {
        // No token or API offline: keep the demo profile so the UI never breaks.
      }
    }
    load()
    return () => { active = false }
  }, [])

  // Action: Book appointment
  const handleBookSlot = (doc: DoctorReview, slot: string) => {
    const created: PatientAppointment = {
      id: `APT-${Math.floor(100 + Math.random() * 900)}`,
      doctorName: doc.name,
      specialty: doc.specialty,
      date: new Date().toISOString().split("T")[0],
      time: slot,
      status: "scheduled"
    }

    setAppointments([created, ...appointments])
    setBookingSuccess(`Your consultation with ${doc.name} has been scheduled for ${slot} today!`)
    
    // Auto clear warning banner
    setTimeout(() => setBookingSuccess(""), 5000)
  }

  // Action: Pay invoice
  const handlePayInvoice = (id: string) => {
    setRecords(records.map(rec => rec.id === id ? { ...rec, status: "paid" as const } : rec))
  }

  // Action: Save updated profile to the patient API
  const handleSaveProfile = async () => {
    try {
      await updatePatientProfile({
        user_name: profile.fullName,
        email: profile.email || undefined,
        phone: profile.phone,
        age: profile.age,
        gender: profile.gender,
        insurance_provider: profile.insuranceProvider || undefined,
      })
      alert("Registration profile successfully updated in the hospital database!")
    } catch {
      alert("Could not save changes. Please check your connection and try again.")
    }
  }

  // Filter doctors list
  const filteredDoctors = selectedSpecialty === "All Specialties"
    ? doctorsList
    : doctorsList.filter(doc => doc.specialty === selectedSpecialty)

  return (
    <div className="flex min-h-screen bg-[#F0F5F3] text-[#0B2B26]">
      {/* ─── SIDEBAR ─── */}
      <aside className="w-72 bg-[#0C1E1A] border-r border-[#1B352E] flex flex-col justify-between h-screen sticky top-0 shrink-0 text-[#E5ECE9]">
        <div>
          {/* Brand */}
          <div className="p-6">
            <div className="flex items-center gap-3 bg-gradient-to-r from-[#12463E] to-[#0A2622] p-4 rounded-2xl border border-[#1E5D52] shadow-lg">
              <div className="w-10 h-10 rounded-xl bg-emerald-500 flex items-center justify-center text-white shadow-md shadow-emerald-500/20 animate-pulse-slow">
                <HeartPulse className="h-5.5 w-5.5" strokeWidth={2.5} />
              </div>
              <div>
                <h2 className="font-bold text-sm tracking-wide text-white">AURA Care</h2>
                <p className="text-[10px] text-emerald-400 font-semibold tracking-widest uppercase mt-0.5">Patient Portal</p>
              </div>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="px-4 space-y-1.5 py-2">
            <p className="px-3 text-[10px] font-bold text-[#8AA098] tracking-widest uppercase mb-3">My Health Dashboard</p>

            <button
              onClick={() => setActiveTab("records")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "records" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "records" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <FileText className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Medical Records</span>
            </button>

            <button
              onClick={() => setActiveTab("book")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "book" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "book" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <Stethoscope className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Book Appointment</span>
            </button>

            <button
              onClick={() => setActiveTab("profile")}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                activeTab === "profile" ? "bg-emerald-500 text-white font-semibold" : "text-[#8AA098] hover:text-white hover:bg-[#12463E]/30"
              }`}
            >
              {activeTab === "profile" && <span className="absolute left-0 top-3 bottom-3 w-1 bg-white rounded-r-md" />}
              <User className="h-5 w-5 text-[#5C7D73] group-hover:text-white" />
              <span>Profile & Insurance</span>
            </button>
          </nav>
        </div>

        {/* Patient Profile footer */}
        <div className="p-4 border-t border-[#1B352E] bg-[#071310]">
          <div className="flex items-center gap-3 p-2 rounded-xl">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-[#12463E] flex items-center justify-center font-bold text-white border border-[#1E5D52]">
              {profile.fullName.split(" ").map(n => n[0]).join("").slice(0, 2).toUpperCase() || "PT"}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-white truncate font-sans">{profile.fullName}</p>
              <p className="text-[10px] text-emerald-400 truncate">Patient Account Active</p>
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
        <header className="h-20 bg-white border-b border-[#E8ECEB] flex items-center justify-between px-8 sticky top-0 z-30 shadow-xs">
          <div>
            <h1 className="text-lg font-bold text-[#0B2B26] tracking-tight uppercase">
              {activeTab === "records" && "My Medical Records Ledger"}
              {activeTab === "book" && "Schedule Care Appointment"}
              {activeTab === "profile" && "Patient Registration details"}
            </h1>
            <p className="text-xs text-[#6B8078] mt-0.5">Aura Medical Center patient portal console.</p>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#EEF4F1] border border-[#D7E2DC] text-[#12463E] font-medium text-xs tabular-nums">
              <Clock className="h-3.5 w-3.5" />
              <span>{currentTime || "Loading clock..."}</span>
            </div>
            <div className="flex items-center gap-2 text-xs text-[#12463E] bg-[#EEF4F1] px-3.5 py-2 rounded-xl border border-[#D7E2DC] font-bold">
              <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse" />
              <span>MRN: AURA-993821</span>
            </div>
          </div>
        </header>

        {/* Content Wrapper */}
        <main className="flex-1 p-8 overflow-y-auto max-w-[1400px] w-full mx-auto space-y-6">
          {/* Booking notification alert */}
          {bookingSuccess && (
            <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-4 text-emerald-800 text-sm font-semibold flex items-center gap-2 animate-fade-in shadow-xs">
              <CheckCircle className="h-5 w-5 text-emerald-600" />
              <span>{bookingSuccess}</span>
            </div>
          )}

          {/* ─── TAB 1: MEDICAL RECORDS ─── */}
          {activeTab === "records" && (
            <div className="space-y-6 animate-fade-in">
              {/* Core Active Care Metrics */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs flex items-center gap-4">
                  <div className="p-3.5 bg-emerald-50 rounded-2xl text-emerald-600">
                    <FileText className="h-6 w-6" />
                  </div>
                  <div>
                    <h4 className="text-xs font-semibold text-[#8AA098] uppercase tracking-wider">Active Prescriptions</h4>
                    <p className="text-2xl font-bold text-[#0B2B26] mt-1">
                      {records.filter(r => r.type === "prescription" && r.status === "active").length}
                    </p>
                  </div>
                </div>

                <div className="bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs flex items-center gap-4">
                  <div className="p-3.5 bg-blue-50 rounded-2xl text-blue-600">
                    <FlaskConical className="h-6 w-6" />
                  </div>
                  <div>
                    <h4 className="text-xs font-semibold text-[#8AA098] uppercase tracking-wider">Diagnostic Results</h4>
                    <p className="text-2xl font-bold text-[#0B2B26] mt-1">
                      {records.filter(r => r.type === "lab-result").length}
                    </p>
                  </div>
                </div>

                <div className="bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs flex items-center gap-4">
                  <div className="p-3.5 bg-rose-50 rounded-2xl text-rose-600">
                    <CreditCard className="h-6 w-6" />
                  </div>
                  <div>
                    <h4 className="text-xs font-semibold text-[#8AA098] uppercase tracking-wider">Outstanding Balance</h4>
                    <p className="text-2xl font-bold text-[#0B2B26] mt-1">
                      Rs. 450
                    </p>
                  </div>
                </div>
              </div>

              {/* Records feed */}
              <div className="bg-white border border-[#E8ECEB] rounded-3xl overflow-hidden shadow-sm">
                <div className="p-6 border-b border-[#E8ECEB] bg-[#EEF4F1]/30 flex justify-between items-center">
                  <div>
                    <h3 className="font-bold text-[#0B2B26] text-base">Clinics Prescriptions & Diagnostics</h3>
                    <p className="text-xs text-[#6B8078] mt-1">Download lab reports, review medication instructions and clear invoices</p>
                  </div>
                </div>

                <div className="divide-y divide-[#E8ECEB]">
                  {records.map((rec) => (
                    <div key={rec.id} className="p-6 flex flex-col md:flex-row md:items-center justify-between gap-6 hover:bg-[#EEF4F1]/20 transition-all">
                      <div className="flex items-start gap-4">
                        <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 border ${
                          rec.type === "prescription" ? "bg-emerald-50 text-emerald-600 border-emerald-100" :
                          rec.type === "lab-result" ? "bg-blue-50 text-blue-600 border-blue-100" :
                          "bg-rose-50 text-rose-600 border-rose-100"
                        }`}>
                          {rec.type === "prescription" && <FileText className="h-5 w-5" />}
                          {rec.type === "lab-result" && <FlaskConical className="h-5 w-5" />}
                          {rec.type === "invoice" && <CreditCard className="h-5 w-5" />}
                        </div>

                        <div>
                          <div className="flex items-center gap-3">
                            <h4 className="font-bold text-[#0B2B26] text-base">{rec.title}</h4>
                            <span className="text-[10px] font-mono text-[#8AA098] bg-[#EEF4F1] border border-[#D7E2DC] px-2 py-0.5 rounded">
                              ID: {rec.id}
                            </span>
                          </div>
                          <p className="text-xs text-[#6B8078] mt-1.5">
                            Author: <span className="font-bold text-[#12463E]">{rec.doctorName}</span> · Date of Registry: {rec.date}
                          </p>
                          <p className="text-xs text-[#4B5F58] mt-2.5 leading-relaxed bg-[#F6F8F7] p-3.5 rounded-2xl border border-[#E8ECEB]">
                            {rec.details}
                          </p>
                        </div>
                      </div>

                      {/* Record action buttons */}
                      <div className="flex items-center gap-2 self-end md:self-auto">
                        <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                          rec.status === "active" ? "bg-emerald-50 text-emerald-700 border border-emerald-200 animate-pulse" :
                          rec.status === "completed" ? "bg-blue-50 text-blue-700 border border-blue-200" :
                          rec.status === "paid" ? "bg-emerald-50 text-emerald-700 border border-emerald-200" :
                          "bg-rose-50 text-rose-700 border border-rose-200"
                        }`}>
                          {rec.status}
                        </span>

                        {rec.type === "invoice" && rec.status === "unpaid" ? (
                          <button
                            onClick={() => handlePayInvoice(rec.id)}
                            className="px-3.5 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold shadow-md shadow-emerald-500/10 transition-all flex items-center gap-1"
                          >
                            <DollarSign className="h-3.5 w-3.5" /> Pay Now
                          </button>
                        ) : (
                          <button className="p-2 bg-[#EEF4F1] hover:bg-[#D7E2DC] border border-[#D7E2DC] rounded-xl text-[#12463E] transition-all">
                            <Download className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ─── TAB 2: BOOK APPOINTMENT ─── */}
          {activeTab === "book" && (
            <div className="space-y-6 animate-fade-in">
              <div className="bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                  <h2 className="text-lg font-bold text-[#0B2B26]">Book Consultation / Doctor Slot</h2>
                  <p className="text-xs text-[#6B8078] mt-1">Select specialized clinical department to filter accredited doctors</p>
                </div>

                {/* Filters */}
                <div className="flex gap-2">
                  {["All Specialties", "General Medicine", "Cardiology", "Neurology", "Orthopedics"].map((sp) => (
                    <button
                      key={sp}
                      onClick={() => setSelectedSpecialty(sp)}
                      className={`px-3.5 py-2 rounded-xl text-xs font-semibold border transition-all ${
                        selectedSpecialty === sp
                          ? "bg-emerald-500 border-emerald-500 text-white shadow-md shadow-emerald-500/10"
                          : "bg-white border-[#D7E2DC] text-[#4B5F58] hover:border-[#12463E]"
                      }`}
                    >
                      {sp}
                    </button>
                  ))}
                </div>
              </div>

              {/* Doctors listing */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {filteredDoctors.map((doc) => (
                  <div key={doc.id} className="bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm hover:shadow-md transition-all flex flex-col justify-between">
                    <div>
                      <div className="flex items-start gap-4">
                        <div className="w-14 h-14 rounded-2xl bg-[#EEF4F1] border border-[#D7E2DC] flex items-center justify-center font-bold text-emerald-800 text-base shrink-0">
                          {doc.name.split(" ").slice(1).map(n => n[0]).join("")}
                        </div>
                        <div>
                          <h3 className="font-bold text-[#0B2B26] text-base">{doc.name}</h3>
                          <span className="text-xs bg-emerald-50 text-emerald-800 px-2 py-0.5 rounded font-medium mt-1 inline-block">
                            {doc.specialty}
                          </span>
                          <div className="flex items-center gap-1.5 mt-2.5 text-xs text-[#6B8078]">
                            <span className="font-bold text-amber-500">★ {doc.rating}</span>
                            <span>({doc.reviewsCount} reviews)</span>
                          </div>
                        </div>
                      </div>

                      {/* Available slots */}
                      <div className="mt-5 space-y-2">
                        <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider block">Available Slots today</span>
                        <div className="flex flex-wrap gap-2">
                          {doc.availableSlots.map((slot) => (
                            <button
                              key={slot}
                              onClick={() => handleBookSlot(doc, slot)}
                              className="px-3.5 py-2 bg-[#F6F8F7] hover:bg-[#12463E] hover:text-white border border-[#D7E2DC] text-xs font-semibold rounded-xl transition-all font-mono"
                            >
                              {slot}
                            </button>
                          ))}
                        </div>
                      </div>
                    </div>

                    <div className="border-t border-[#E8ECEB] pt-4 mt-6 flex justify-between text-xs text-[#8AA098]">
                      <span>OPD consultation consultation fee</span>
                      <span className="font-bold text-[#0B2B26]">Rs. 150 (Coverable)</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ─── TAB 3: PROFILE & SELF-REGISTRATION INFO ─── */}
          {activeTab === "profile" && (
            <div className="space-y-6 animate-fade-in">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Profile Overview Card */}
                <div className="lg:col-span-1 bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm flex flex-col items-center text-center">
                  <div className="w-20 h-20 rounded-full bg-gradient-to-br from-emerald-500 to-[#12463E] border-4 border-white flex items-center justify-center font-bold text-white text-3xl shadow-xl shadow-emerald-500/10">
                    {profile.fullName.split(" ").map(n => n[0]).join("").slice(0, 2).toUpperCase() || "PT"}
                  </div>
                  <h3 className="font-black text-xl text-[#0B2B26] mt-4">{profile.fullName}</h3>
                  <p className="text-xs text-[#8AA098] mt-1">Accredited Member since 2026</p>

                  <div className="w-full mt-6 bg-[#EEF4F1]/50 border border-[#D7E2DC] rounded-2xl p-4 space-y-3.5 text-left text-xs">
                    <div className="flex justify-between">
                      <span className="text-[#8AA098] font-semibold">Blood Group</span>
                      <span className="font-bold text-rose-600">{profile.bloodGroup}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-[#8AA098] font-semibold">Age / Gender</span>
                      <span className="font-bold text-[#0B2B26]">{profile.age} Y/O · {profile.gender}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-[#8AA098] font-semibold">Triage Policy Status</span>
                      <span className="font-bold text-emerald-600">Active</span>
                    </div>
                  </div>
                </div>

                {/* Edit Credentials */}
                <div className="lg:col-span-2 bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm">
                  <h3 className="font-bold text-[#0B2B26] text-base border-b border-[#E8ECEB] pb-3">Contact & Registration Details</h3>

                  <form className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6" onSubmit={(e) => e.preventDefault()}>
                    <div>
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Full Registered Name</label>
                      <input
                        type="text"
                        value={profile.fullName}
                        onChange={(e) => setProfile({ ...profile, fullName: e.target.value })}
                        className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Phone Number</label>
                      <input
                        type="tel"
                        value={profile.phone}
                        onChange={(e) => setProfile({ ...profile, phone: e.target.value })}
                        className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Email address</label>
                      <input
                        type="email"
                        value={profile.email}
                        onChange={(e) => setProfile({ ...profile, email: e.target.value })}
                        className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Emergency contact info</label>
                      <input
                        type="text"
                        value={profile.emergencyContact}
                        onChange={(e) => setProfile({ ...profile, emergencyContact: e.target.value })}
                        className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Insurance Provider</label>
                      <input
                        type="text"
                        value={profile.insuranceProvider}
                        onChange={(e) => setProfile({ ...profile, insuranceProvider: e.target.value })}
                        className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Insurance Policy Number</label>
                      <input
                        type="text"
                        value={profile.insuranceNumber}
                        onChange={(e) => setProfile({ ...profile, insuranceNumber: e.target.value })}
                        className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                      />
                    </div>

                    <div className="md:col-span-2">
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Residential Address</label>
                      <input
                        type="text"
                        value={profile.address}
                        onChange={(e) => setProfile({ ...profile, address: e.target.value })}
                        className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                      />
                    </div>

                    <div className="md:col-span-2 flex justify-end gap-2 border-t border-[#E8ECEB] pt-4 mt-4">
                      <button
                        type="button"
                        className="px-4 py-2.5 bg-[#12463E] hover:bg-[#0B2B26] text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-emerald-500/10"
                        onClick={handleSaveProfile}
                      >
                        Update Details
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  )
}
