"use client"

import React, { useState, useEffect, useMemo } from "react"
import {
  Calendar,
  Clock,
  User,
  FileText,
  FlaskConical,
  CreditCard,
  LogOut,
  Stethoscope,
  CheckCircle,
  HeartPulse,
  ShieldCheck,
  CalendarPlus,
  Smartphone,
  ArrowRight,
  FileWarning,
  RefreshCw,
  AlertTriangle,
  X
} from "lucide-react"
import {
  bookPatientAppointment,
  getPatientAppointments,
  getPatientDoctors,
  getPatientInvoices,
  getPatientProfile,
  updatePatientProfile
} from "@/services/patient.service"
import type { Doctor, PatientAppointment, PatientInvoice } from "@/services/patient.service"

const SLOTS = ["09:30 AM", "10:15 AM", "11:00 AM", "01:15 PM", "03:30 PM", "04:45 PM"]

export default function PatientDashboard() {
  const [activeTab, setActiveTab] = useState<"records" | "book" | "profile">("records")
  const [currentTime, setCurrentTime] = useState("")
  const [showSignOutModal, setShowSignOutModal] = useState(false)

  // Patient info from the patient API (empty for brand-new OTP accounts).
  const [profile, setProfile] = useState({
    fullName: "",
    age: null as number | null,
    gender: "",
    phone: "",
    email: "",
    insuranceProvider: "",
  })

  const [appointments, setAppointments] = useState<PatientAppointment[]>([])
  const [invoices, setInvoices] = useState<PatientInvoice[]>([])
  const [doctors, setDoctors] = useState<Doctor[]>([])

  const [loadingRecords, setLoadingRecords] = useState(true)
  const [bookingSuccess, setBookingSuccess] = useState("")
  const [bookingError, setBookingError] = useState("")
  const [booking, setBooking] = useState(false)

  const [selectedSpecialty, setSelectedSpecialty] = useState("All Specialties")

  useEffect(() => {
    const updateTime = () => {
      const now = new Date()
      setCurrentTime(now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit", hour12: true }))
    }
    updateTime()
    const timer = setInterval(updateTime, 1000)
    return () => clearInterval(timer)
  }, [])

  const loadProfile = async () => {
    try {
      const res = await getPatientProfile()
      if (!res?.data) return
      const p = res.data
      setProfile((prev) => ({
        ...prev,
        fullName: p.user_name || prev.fullName,
        age: p.age ?? prev.age,
        gender: p.gender || prev.gender,
        phone: p.phone || prev.phone,
        email: p.email || prev.email,
        insuranceProvider:
          p.insurance_provider && p.insurance_provider !== "Self-Pay / None"
            ? p.insurance_provider
            : prev.insuranceProvider,
      }))
    } catch {
      // No token or API offline: keep whatever we have.
    }
  }

  const loadRecords = async () => {
    setLoadingRecords(true)
    try {
      const [apptRes, invRes] = await Promise.all([
        getPatientAppointments(),
        getPatientInvoices(),
      ])
      setAppointments(apptRes?.data || [])
      setInvoices(invRes?.data || [])
    } catch {
      setAppointments([])
      setInvoices([])
    } finally {
      setLoadingRecords(false)
    }
  }

  const loadDoctors = async () => {
    try {
      const res = await getPatientDoctors()
      setDoctors(res?.data || [])
    } catch {
      setDoctors([])
    }
  }

  useEffect(() => {
    loadProfile()
    loadRecords()
    loadDoctors()
  }, [])

  const metrics = useMemo(() => {
    const upcoming = appointments.filter(
      (a) => !["COMPLETED", "CANCELLED"].includes(a.status.toUpperCase())
    ).length
    const outstanding = invoices
      .filter((i) => i.payment_status.toUpperCase() === "UNPAID")
      .reduce((sum, i) => sum + (i.amount || 0), 0)
    return { upcoming, totalBills: invoices.length, outstanding }
  }, [appointments, invoices])

  const filteredDoctors = useMemo(() => {
    const list = selectedSpecialty === "All Specialties"
      ? doctors
      : doctors.filter((d) => d.specialty === selectedSpecialty)
    return list
  }, [doctors, selectedSpecialty])

  const handleBookSlot = async (doc: Doctor, slot: string) => {
    setBookingError("")
    setBooking(true)
    try {
      const today = new Date().toISOString().split("T")[0]
      const res = await bookPatientAppointment({
        doctor_name: doc.name,
        specialty: doc.specialty,
        date: today,
        time: slot,
      })
      const created = res?.data
      if (created) setAppointments((prev) => [created, ...prev])
      setBookingSuccess(`Your consultation with ${doc.name} is booked for ${slot} today!`)
      setTimeout(() => setBookingSuccess(""), 6000)
    } catch (err: any) {
      setBookingError(
        err?.message ||
          "Could not book the appointment. Please try again."
      )
    } finally {
      setBooking(false)
    }
  }

  const handleSaveProfile = async () => {
    setBookingError("")
    try {
      await updatePatientProfile({
        user_name: profile.fullName || undefined,
        email: profile.email || undefined,
        phone: profile.phone,
        age: profile.age,
        gender: profile.gender || undefined,
        insurance_provider: profile.insuranceProvider || undefined,
      })
      setBookingSuccess("Your profile was saved to the hospital database.")
      setTimeout(() => setBookingSuccess(""), 5000)
    } catch (err: any) {
      setBookingError(err?.message || "Could not save changes. Please try again.")
    }
  }

  const initials = profile.fullName.trim()
    ? profile.fullName.split(" ").map((n) => n[0]).join("").slice(0, 2).toUpperCase()
    : "PT"

  return (
    <div className="flex min-h-screen bg-[#F0F5F3] text-[#0B2B26]">
      {/* ─── SIDEBAR ─── */}
      <aside className="w-72 bg-[#0C1E1A] border-r border-[#1B352E] flex flex-col justify-between h-screen sticky top-0 shrink-0 text-[#E5ECE9]">
        <div>
          {/* Brand */}
          <div className="p-6">
            <div className="flex items-center gap-3 bg-gradient-to-r from-[#12463E] to-[#0A2622] p-4 rounded-2xl border border-[#1E5D52] shadow-lg">
              <div className="w-10 h-10 rounded-xl bg-emerald-500 flex items-center justify-center text-white shadow-md shadow-emerald-500/20">
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
              <span>My Appointments & Bills</span>
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
              <span>Profile Details</span>
            </button>
          </nav>
        </div>

        {/* Patient Profile footer */}
        <div className="p-4 border-t border-[#1B352E] bg-[#071310]">
          <div className="flex items-center gap-3 p-2 rounded-xl">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-[#12463E] flex items-center justify-center font-bold text-white border border-[#1E5D52]">
              {initials}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-white truncate font-sans">
                {profile.fullName || "New Patient"}
              </p>
              <p className="text-[10px] text-emerald-400 truncate">
                {profile.phone || "Logged in via OTP"}
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowSignOutModal(true)}
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
              {activeTab === "records" && "My Appointments & Bills"}
              {activeTab === "book" && "Schedule Care Appointment"}
              {activeTab === "profile" && "Patient Registration Details"}
            </h1>
            <p className="text-xs text-[#6B8078] mt-0.5">Aura Medical Center patient portal console.</p>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#EEF4F1] border border-[#D7E2DC] text-[#12463E] font-medium text-xs tabular-nums">
              <Clock className="h-3.5 w-3.5" />
              <span>{currentTime || "Loading clock..."}</span>
            </div>
            <div className="flex items-center gap-2 text-xs text-[#12463E] bg-[#EEF4F1] px-3.5 py-2 rounded-xl border border-[#D7E2DC] font-bold">
              <Smartphone className="h-3.5 w-3.5" />
              <span>{profile.phone || "Logged in via OTP"}</span>
            </div>
          </div>
        </header>

        {/* Content Wrapper */}
        <main className="flex-1 p-8 overflow-y-auto max-w-[1400px] w-full mx-auto space-y-6">
          {/* Notification banners */}
          {bookingSuccess && (
            <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-4 text-emerald-800 text-sm font-semibold flex items-center gap-2 animate-fade-in shadow-xs">
              <CheckCircle className="h-5 w-5 text-emerald-600" />
              <span>{bookingSuccess}</span>
            </div>
          )}
          {bookingError && (
            <div className="bg-rose-50 border border-rose-200 rounded-2xl p-4 text-rose-800 text-sm font-semibold flex items-center gap-2 animate-fade-in shadow-xs">
              <FileWarning className="h-5 w-5 text-rose-600" />
              <span>{bookingError}</span>
            </div>
          )}

          {/* ─── TAB 1: APPOINTMENTS & BILLS ─── */}
          {activeTab === "records" && (
            <div className="space-y-6 animate-fade-in">
              {/* Core metrics */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs flex items-center gap-4">
                  <div className="p-3.5 bg-emerald-50 rounded-2xl text-emerald-600">
                    <Calendar className="h-6 w-6" />
                  </div>
                  <div>
                    <h4 className="text-xs font-semibold text-[#8AA098] uppercase tracking-wider">Upcoming Appointments</h4>
                    <p className="text-2xl font-bold text-[#0B2B26] mt-1">
                      {loadingRecords ? "…" : metrics.upcoming}
                    </p>
                  </div>
                </div>

                <div className="bg-white p-6 rounded-3xl border border-[#E8ECEB] shadow-xs flex items-center gap-4">
                  <div className="p-3.5 bg-blue-50 rounded-2xl text-blue-600">
                    <FlaskConical className="h-6 w-6" />
                  </div>
                  <div>
                    <h4 className="text-xs font-semibold text-[#8AA098] uppercase tracking-wider">Total Bills</h4>
                    <p className="text-2xl font-bold text-[#0B2B26] mt-1">
                      {loadingRecords ? "…" : metrics.totalBills}
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
                      {loadingRecords ? "…" : `Rs. ${metrics.outstanding}`}
                    </p>
                  </div>
                </div>
              </div>

              {/* My appointments */}
              <div className="bg-white border border-[#E8ECEB] rounded-3xl overflow-hidden shadow-sm">
                <div className="p-6 border-b border-[#E8ECEB] bg-[#EEF4F1]/30 flex justify-between items-center">
                  <div>
                    <h3 className="font-bold text-[#0B2B26] text-base">My Appointments</h3>
                    <p className="text-xs text-[#6B8078] mt-1">Every consultation booked through the portal or front desk</p>
                  </div>
                  <button
                    onClick={() => setActiveTab("book")}
                    className="flex items-center gap-1.5 text-xs font-bold text-[#12463E] bg-white border border-[#D7E2DC] hover:bg-[#EEF4F1] px-3 py-2 rounded-xl transition-all"
                  >
                    <CalendarPlus className="h-3.5 w-3.5" />
                    Book new
                  </button>
                </div>

                <div className="divide-y divide-[#E8ECEB]">
                  {loadingRecords ? (
                    <p className="p-8 text-center text-sm text-[#8AA098]">Loading your appointments…</p>
                  ) : appointments.length === 0 ? (
                    <div className="p-10 text-center">
                      <Calendar className="h-10 w-10 text-[#C3CFC9] mx-auto" />
                      <p className="mt-3 text-sm font-semibold text-[#4B5F58]">No appointments yet</p>
                      <p className="text-xs text-[#8AA098] mt-1">
                        Book a slot with a doctor from the Book Appointment tab.
                      </p>
                      <button
                        onClick={() => setActiveTab("book")}
                        className="mt-4 inline-flex items-center gap-1.5 px-4 py-2 bg-[#12463E] hover:bg-[#0B2B26] text-white rounded-xl text-xs font-semibold transition-all"
                      >
                        Book Appointment <ArrowRight className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  ) : (
                    appointments.map((appt) => (
                      <div key={appt.appointment_id} className="p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-[#EEF4F1]/20 transition-all">
                        <div className="flex items-start gap-4">
                          <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 border border-emerald-100 flex items-center justify-center shrink-0">
                            <Stethoscope className="h-5 w-5" />
                          </div>
                          <div>
                            <div className="flex items-center gap-3">
                              <h4 className="font-bold text-[#0B2B26] text-base">{appt.doctor_name}</h4>
                              <span className="text-[10px] font-mono text-[#8AA098] bg-[#EEF4F1] border border-[#D7E2DC] px-2 py-0.5 rounded">
                                {appt.appointment_id}
                              </span>
                            </div>
                            <p className="text-xs text-[#6B8078] mt-1.5">
                              <span className="font-bold text-[#12463E]">{appt.specialty}</span>
                            </p>
                            <p className="text-xs text-[#4B5F58] mt-2 flex items-center gap-1.5">
                              <Calendar className="h-3.5 w-3.5 text-[#9CAEA6]" /> {appt.date}
                              <span className="text-[#C3CFC9]">·</span>
                              <Clock className="h-3.5 w-3.5 text-[#9CAEA6]" /> {appt.time}
                            </p>
                          </div>
                        </div>
                        <span className={`self-start md:self-center px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                          appt.status.toUpperCase() === "CANCELLED"
                            ? "bg-rose-50 text-rose-700 border border-rose-200"
                            : appt.status.toUpperCase() === "COMPLETED"
                            ? "bg-blue-50 text-blue-700 border border-blue-200"
                            : "bg-emerald-50 text-emerald-700 border border-emerald-200"
                        }`}>
                          {appt.status}
                        </span>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* Bills & invoices */}
              <div className="bg-white border border-[#E8ECEB] rounded-3xl overflow-hidden shadow-sm">
                <div className="p-6 border-b border-[#E8ECEB] bg-[#EEF4F1]/30">
                  <h3 className="font-bold text-[#0B2B26] text-base">Bills & Invoices</h3>
                  <p className="text-xs text-[#6B8078] mt-1">Invoices raised against your visits at the billing desk</p>
                </div>

                <div className="divide-y divide-[#E8ECEB]">
                  {loadingRecords ? (
                    <p className="p-8 text-center text-sm text-[#8AA098]">Loading your bills…</p>
                  ) : invoices.length === 0 ? (
                    <div className="p-10 text-center">
                      <CreditCard className="h-10 w-10 text-[#C3CFC9] mx-auto" />
                      <p className="mt-3 text-sm font-semibold text-[#4B5F58]">No bills yet</p>
                      <p className="text-xs text-[#8AA098] mt-1">
                        Any invoices created at the front desk for your phone number will appear here.
                      </p>
                    </div>
                  ) : (
                    invoices.map((inv) => (
                      <div key={inv.invoice_id} className="p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-[#EEF4F1]/20 transition-all">
                        <div className="flex items-start gap-4">
                          <div className="w-12 h-12 rounded-2xl bg-rose-50 text-rose-600 border border-rose-100 flex items-center justify-center shrink-0">
                            <CreditCard className="h-5 w-5" />
                          </div>
                          <div>
                            <div className="flex items-center gap-3">
                              <h4 className="font-bold text-[#0B2B26] text-base">{inv.invoice_id}</h4>
                              <span className="text-[10px] font-mono text-[#8AA098] bg-[#EEF4F1] border border-[#D7E2DC] px-2 py-0.5 rounded">
                                {inv.date}
                              </span>
                            </div>
                            {inv.items && inv.items.length > 0 && (
                              <ul className="text-xs text-[#6B8078] mt-1.5 space-y-0.5">
                                {inv.items.map((item, i) => (
                                  <li key={i} className="flex items-center justify-between gap-4 max-w-md">
                                    <span>{item.description}</span>
                                    <span className="font-semibold text-[#12463E]">Rs. {item.cost}</span>
                                  </li>
                                ))}
                              </ul>
                            )}
                            <p className="text-xs font-bold text-[#0B2B26] mt-2">Total: Rs. {inv.amount}</p>
                          </div>
                        </div>
                        <span className={`self-start md:self-center px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                          inv.payment_status.toUpperCase() === "PAID"
                            ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                            : "bg-rose-50 text-rose-700 border border-rose-200"
                        }`}>
                          {inv.payment_status}
                        </span>
                      </div>
                    ))
                  )}
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
                  <p className="text-xs text-[#6B8078] mt-1">Select a specialty to filter the hospital&apos;s doctors</p>
                </div>

                {/* Filters */}
                <div className="flex flex-wrap gap-2">
                  {["All Specialties", ...Array.from(new Set(doctors.map((d) => d.specialty)))].map((sp) => (
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

              {doctors.length === 0 ? (
                <div className="bg-white border border-[#E8ECEB] rounded-3xl p-10 text-center shadow-sm">
                  <Stethoscope className="h-10 w-10 text-[#C3CFC9] mx-auto" />
                  <p className="mt-3 text-sm font-semibold text-[#4B5F58]">No doctors available right now</p>
                  <p className="text-xs text-[#8AA098] mt-1">
                    The hospital has not added any active doctors yet.
                  </p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {filteredDoctors.map((doc) => (
                    <div key={doc.user_id} className="bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm hover:shadow-md transition-all flex flex-col justify-between">
                      <div>
                        <div className="flex items-start gap-4">
                          <div className="w-14 h-14 rounded-2xl bg-[#EEF4F1] border border-[#D7E2DC] flex items-center justify-center font-bold text-emerald-800 text-base shrink-0">
                            {doc.name.split(" ").slice(1).map((n) => n[0]).join("") || doc.name.slice(0, 2).toUpperCase()}
                          </div>
                          <div>
                            <h3 className="font-bold text-[#0B2B26] text-base">{doc.name}</h3>
                            <span className="text-xs bg-emerald-50 text-emerald-800 px-2 py-0.5 rounded font-medium mt-1 inline-block">
                              {doc.specialty}
                            </span>
                          </div>
                        </div>

                        {/* Available slots */}
                        <div className="mt-5 space-y-2">
                          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider block">Available Slots today</span>
                          <div className="flex flex-wrap gap-2">
                            {SLOTS.map((slot) => (
                              <button
                                key={slot}
                                disabled={booking}
                                onClick={() => handleBookSlot(doc, slot)}
                                className="px-3.5 py-2 bg-[#F6F8F7] hover:bg-[#12463E] hover:text-white border border-[#D7E2DC] text-xs font-semibold rounded-xl transition-all font-mono disabled:opacity-50"
                              >
                                {slot}
                              </button>
                            ))}
                          </div>
                        </div>
                      </div>

                      <div className="border-t border-[#E8ECEB] pt-4 mt-6 flex justify-between text-xs text-[#8AA098]">
                        <span>OPD consultation fee</span>
                        <span className="font-bold text-[#0B2B26]">Rs. 150</span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ─── TAB 3: PROFILE ─── */}
          {activeTab === "profile" && (
            <div className="space-y-6 animate-fade-in">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Profile Overview Card */}
                <div className="lg:col-span-1 bg-white border border-[#E8ECEB] rounded-3xl p-6 shadow-sm flex flex-col items-center text-center">
                  <div className="w-20 h-20 rounded-full bg-gradient-to-br from-emerald-500 to-[#12463E] border-4 border-white flex items-center justify-center font-bold text-white text-3xl shadow-xl shadow-emerald-500/10">
                    {initials}
                  </div>
                  <h3 className="font-black text-xl text-[#0B2B26] mt-4">{profile.fullName || "New Patient"}</h3>
                  <p className="text-xs text-[#8AA098] mt-1">Member since 2026</p>

                  <div className="w-full mt-6 bg-[#EEF4F1]/50 border border-[#D7E2DC] rounded-2xl p-4 space-y-3.5 text-left text-xs">
                    <div className="flex justify-between">
                      <span className="text-[#8AA098] font-semibold">Phone</span>
                      <span className="font-bold text-[#0B2B26]">{profile.phone || "—"}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-[#8AA098] font-semibold">Age / Gender</span>
                      <span className="font-bold text-[#0B2B26]">
                        {profile.age != null ? `${profile.age} Y/O` : "—"}
                        {profile.gender ? ` · ${profile.gender}` : ""}
                      </span>
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
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Full Name</label>
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
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Age</label>
                      <input
                        type="number"
                        min={0}
                        max={150}
                        value={profile.age ?? ""}
                        onChange={(e) => setProfile({ ...profile, age: e.target.value === "" ? null : Number(e.target.value) })}
                        className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-semibold text-[#12463E] block mb-1">Gender</label>
                      <select
                        value={profile.gender}
                        onChange={(e) => setProfile({ ...profile, gender: e.target.value })}
                        className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                      >
                        <option value="">Select…</option>
                        <option value="Male">Male</option>
                        <option value="Female">Female</option>
                        <option value="Other">Other</option>
                      </select>
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

      {/* ─── LOGOUT CONFIRMATION MODAL ─── */}
      {showSignOutModal && (
        <>
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50" onClick={() => setShowSignOutModal(false)} />
          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-sm bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-rose-50 border border-rose-100 flex items-center justify-center">
                  <AlertTriangle className="h-5 w-5 text-rose-500" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-[#0B2B26]">Logout</h3>
                  <p className="text-xs text-[#8AA098] mt-0.5">Are you sure you want to logout?</p>
                </div>
              </div>
              <button
                onClick={() => setShowSignOutModal(false)}
                className="w-8 h-8 rounded-full bg-[#F6F8F7] hover:bg-[#EEF4F1] flex items-center justify-center transition-all text-[#6B8078]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setShowSignOutModal(false)}
                className="flex-1 h-11 rounded-xl border border-[#D7E2DC] text-xs font-bold text-[#6B8078] hover:bg-[#F6F8F7] transition-all"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  localStorage.removeItem("access_token")
                  localStorage.removeItem("user")
                  window.location.href = "/login"
                }}
                className="flex-1 h-11 rounded-xl bg-rose-600 text-white text-xs font-bold hover:bg-rose-700 shadow-md shadow-rose-600/10 transition-all flex items-center justify-center gap-2"
              >
                <LogOut className="h-4 w-4" />
                Yes, Logout
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
