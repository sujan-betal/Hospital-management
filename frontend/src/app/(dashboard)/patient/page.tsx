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
  AlertTriangle,
  X,
  Pencil,
  Wallet,
  Loader2,
  CalendarClock,
  Star,
  Award,
  Users,
  SortDesc
} from "lucide-react"
import {
  bookPatientAppointment,
  createPatientPaymentOrder,
  getBookedSlots,
  getPatientAppointments,
  getPatientDoctors,
  getPatientInvoices,
  getPatientProfile,
  getPatientReviews,
  submitDoctorReview,
  updatePatientAppointment,
  updatePatientProfile,
  verifyPatientPayment
} from "@/services/patient.service"
import type { Doctor, DoctorReview, PatientAppointment, PatientInvoice } from "@/services/patient.service"

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
  const [doctorSort, setDoctorSort] = useState<"top" | "name">("top")

  // Today's date in the browser's local timezone (booking only offers today).
  const [today] = useState(() => {
    const d = new Date()
    const local = new Date(d.getTime() - d.getTimezoneOffset() * 60000)
    return local.toISOString().split("T")[0]
  })

  // Slots already taken by ANY patient today, so they render as disabled.
  const [bookedSlots, setBookedSlots] = useState<{ doctor_name: string; time: string }[]>([])

  // Edit-appointment modal state.
  const [editingAppointment, setEditingAppointment] = useState<PatientAppointment | null>(null)
  const [editDate, setEditDate] = useState("")
  const [editTime, setEditTime] = useState("")
  const [savingEdit, setSavingEdit] = useState(false)

  // Payment flow state.
  const [payingAppointmentId, setPayingAppointmentId] = useState<string | null>(null)

  // Doctor review state.
  const [reviews, setReviews] = useState<DoctorReview[]>([])
  const [reviewingAppointment, setReviewingAppointment] = useState<PatientAppointment | null>(null)
  const [reviewRating, setReviewRating] = useState(0)
  const [reviewComment, setReviewComment] = useState("")
  const [reviewHover, setReviewHover] = useState(0)
  const [reviewSubmitting, setReviewSubmitting] = useState(false)
  const [reviewError, setReviewError] = useState("")

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
      const [apptRes, invRes, revRes] = await Promise.all([
        getPatientAppointments(),
        getPatientInvoices(),
        getPatientReviews(),
      ])
      setAppointments(apptRes?.data || [])
      setInvoices(invRes?.data || [])
      setReviews(revRes?.data || [])
    } catch {
      setAppointments([])
      setInvoices([])
      setReviews([])
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

  const loadBookedSlots = async () => {
    try {
      const res = await getBookedSlots(today)
      setBookedSlots(res?.data || [])
    } catch {
      // Keep whatever we already have.
    }
  }

  useEffect(() => {
    loadProfile()
    loadRecords()
    loadDoctors()
    loadBookedSlots()
  }, [])

  // Every active slot already taken today (from other patients + our own).
  const bookedSlotsByDoctor = useMemo(() => {
    const map: Record<string, Set<string>> = {}
    const collect = (doctorName: string, time: string) => {
      if (!map[doctorName]) map[doctorName] = new Set()
      map[doctorName].add(time)
    }
    bookedSlots.forEach((s) => collect(s.doctor_name, s.time))
    appointments.forEach((a) => {
      if (a.date === today && a.status.toUpperCase() !== "CANCELLED") {
        collect(a.doctor_name, a.time)
      }
    })
    return map
  }, [bookedSlots, appointments, today])

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
      ? [...doctors]
      : doctors.filter((d) => d.specialty === selectedSpecialty)
    if (doctorSort === "name") {
      list.sort((a, b) => a.name.localeCompare(b.name))
    } else {
      list.sort((a, b) => (b.rating || 0) - (a.rating || 0))
    }
    return list
  }, [doctors, selectedSpecialty, doctorSort])

  // Count of doctors per specialty (for the filter chips + summary header).
  const specialtyCounts = useMemo(() => {
    const counts: Record<string, number> = {}
    doctors.forEach((d) => {
      const key = d.specialty || "General Medicine"
      counts[key] = (counts[key] || 0) + 1
    })
    return counts
  }, [doctors])

  const topRatedCount = useMemo(
    () => doctors.filter((d) => d.is_top_rated).length,
    [doctors]
  )

  const renderStars = (rating: number) => {
    return (
      <div className="flex items-center gap-0.5" aria-label={`${rating} out of 5 stars`}>
        {[1, 2, 3, 4, 5].map((i) => (
          <Star
            key={i}
            className={`h-3.5 w-3.5 ${i <= Math.round(rating) ? "fill-amber-400 text-amber-400" : "text-[#D7E2DC] fill-[#E8ECEB]"}`}
          />
        ))}
      </div>
    )
  }

  // Appointments the patient has already reviewed (one review per visit).
  const reviewedAppointmentIds = useMemo(
    () => new Set(reviews.map((r) => r.appointment_id)),
    [reviews]
  )

  const openReviewModal = (appt: PatientAppointment) => {
    setReviewingAppointment(appt)
    setReviewRating(0)
    setReviewComment("")
    setReviewHover(0)
    setReviewError("")
  }

  const handleSubmitReview = async () => {
    if (!reviewingAppointment) return
    setReviewError("")
    if (reviewRating < 1) {
      setReviewError("Please select a star rating before submitting.")
      return
    }
    setReviewSubmitting(true)
    try {
      const res = await submitDoctorReview({
        appointment_id: reviewingAppointment.appointment_id,
        rating: reviewRating,
        comment: reviewComment.trim(),
      })
      if (res?.data) {
        setReviews((prev) => [res.data, ...prev])
        setReviewingAppointment(null)
        setBookingSuccess(
          `Thank you for rating Dr. ${reviewingAppointment.doctor_name}!`
        )
        setTimeout(() => setBookingSuccess(""), 6000)
      }
    } catch (err: any) {
      setReviewError(err?.message || "Could not submit your review. Please try again.")
    } finally {
      setReviewSubmitting(false)
    }
  }

  const handleBookSlot = async (doc: Doctor, slot: string) => {
    setBookingError("")
    setBookingSuccess("")
    setBooking(true)
    try {
      const res = await bookPatientAppointment({
        doctor_name: doc.name,
        specialty: doc.specialty,
        date: today,
        time: slot,
      })
      const created = res?.data
      if (created) setAppointments((prev) => [created, ...prev])
      setBookingSuccess(
        `Booking successful! Your consultation with ${doc.name} is confirmed for ${slot} today.`
      )
      loadBookedSlots()
      setTimeout(() => setBookingSuccess(""), 7000)
    } catch (err: any) {
      setBookingError(
        err?.message ||
          "Could not book the appointment. Please try again."
      )
    } finally {
      setBooking(false)
    }
  }

  const openEditModal = (appt: PatientAppointment) => {
    setEditingAppointment(appt)
    setEditDate(appt.date)
    setEditTime(appt.time)
    setBookingError("")
    setBookingSuccess("")
  }

  const handleSaveEdit = async () => {
    if (!editingAppointment) return
    setBookingError("")
    setBookingSuccess("")
    if (!editDate || !editTime) {
      setBookingError("Please choose both a date and a time.")
      return
    }
    setSavingEdit(true)
    try {
      const res = await updatePatientAppointment(editingAppointment.appointment_id, {
        date: editDate,
        time: editTime,
      })
      const updated = res?.data
      if (updated) {
        setAppointments((prev) =>
          prev.map((a) =>
            a.appointment_id === updated.appointment_id ? { ...a, ...updated } : a
          )
        )
      }
      setBookingSuccess("Appointment rescheduled successfully!")
      loadBookedSlots()
      setTimeout(() => setBookingSuccess(""), 6000)
      setEditingAppointment(null)
    } catch (err: any) {
      setBookingError(err?.message || "Could not reschedule the appointment. Please try again.")
    } finally {
      setSavingEdit(false)
    }
  }

  // Load the Razorpay checkout script once, then return it.
  const loadRazorpay = (): Promise<any> => {
    return new Promise((resolve) => {
      if ((window as any).Razorpay) {
        resolve((window as any).Razorpay)
        return
      }
      const script = document.createElement("script")
      script.src = "https://checkout.razorpay.com/v1/checkout.js"
      script.onload = () => resolve((window as any).Razorpay)
      script.onerror = () => resolve(null)
      document.body.appendChild(script)
    })
  }

  const handlePayNow = async (appt: PatientAppointment) => {
    setBookingError("")
    setBookingSuccess("")
    setPayingAppointmentId(appt.appointment_id)
    try {
      const orderRes = await createPatientPaymentOrder(appt.appointment_id)
      const order = orderRes?.data
      if (!order?.order_id) throw new Error("Could not start payment. Please try again.")

      const Razorpay = await loadRazorpay()
      if (!Razorpay) {
        throw new Error("Payment gateway could not be loaded. Please check your connection.")
      }

      const options = {
        key: order.key_id,
        amount: order.amount,
        currency: order.currency,
        name: "Aura Medical Center",
        description: `OPD Consultation – ${appt.doctor_name}`,
        order_id: order.order_id,
        prefill: {
          name: profile.fullName,
          contact: profile.phone,
          email: profile.email,
        },
        handler: async (response: any) => {
          try {
            const verifyRes = await verifyPatientPayment(appt.appointment_id, {
              razorpay_order_id: response.razorpay_order_id,
              razorpay_payment_id: response.razorpay_payment_id,
              razorpay_signature: response.razorpay_signature,
            })
            const updated = verifyRes?.data?.appointment
            if (updated) {
              setAppointments((prev) =>
                prev.map((a) =>
                  a.appointment_id === updated.appointment_id ? { ...a, ...updated } : a
                )
              )
            }
            loadRecords()
            setBookingSuccess("Payment successful! Your consultation fee is paid and the appointment is confirmed.")
            setTimeout(() => setBookingSuccess(""), 8000)
          } catch (err: any) {
            setBookingError(err?.message || "Payment was made but could not be verified. Please contact the front desk.")
          }
        },
        modal: {
          ondismiss: () => {
            setBookingSuccess("Payment cancelled. You can pay later from My Appointments.")
          },
        },
      }

      const rzp = new Razorpay(options)
      rzp.open()
    } catch (err: any) {
      setBookingError(err?.message || "Could not start payment. Please try again.")
    } finally {
      setPayingAppointmentId(null)
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
                        <div className="self-start md:self-center flex flex-col items-start md:items-end gap-2">
                          <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                            appt.status.toUpperCase() === "CANCELLED"
                              ? "bg-rose-50 text-rose-700 border border-rose-200"
                              : appt.status.toUpperCase() === "COMPLETED"
                              ? "bg-blue-50 text-blue-700 border border-blue-200"
                              : "bg-emerald-50 text-emerald-700 border border-emerald-200"
                          }`}>
                            {appt.status}
                          </span>
                          <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                            (appt.payment_status || "UNPAID").toUpperCase() === "PAID"
                              ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                              : "bg-amber-50 text-amber-700 border border-amber-200"
                          }`}>
                            Fee: Rs. {appt.fee ?? 150} · {(appt.payment_status || "UNPAID")}
                          </span>
                              {(appt.status.toUpperCase() === "SCHEDULED") && (
                                <div className="flex items-center gap-2 mt-1">
                                  <button
                                    onClick={() => openEditModal(appt)}
                                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[#D7E2DC] text-[#12463E] hover:bg-[#EEF4F1] text-[11px] font-bold transition-all"
                                  >
                                    <Pencil className="h-3 w-3" />
                                    Edit Timing
                                  </button>
                                  {(appt.payment_status || "UNPAID").toUpperCase() !== "PAID" && (
                                    <button
                                      onClick={() => handlePayNow(appt)}
                                      disabled={payingAppointmentId === appt.appointment_id}
                                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#12463E] hover:bg-[#0B2B26] text-white text-[11px] font-bold transition-all disabled:opacity-50"
                                    >
                                      {payingAppointmentId === appt.appointment_id ? (
                                        <Loader2 className="h-3 w-3 animate-spin" />
                                      ) : (
                                        <Wallet className="h-3 w-3" />
                                      )}
                                      {payingAppointmentId === appt.appointment_id ? "Starting…" : "Pay Now"}
                                    </button>
                                  )}
                                </div>
                              )}

                              {/* Rate the doctor after a completed visit */}
                              {(["CHECKED-IN", "COMPLETED"] as string[]).includes(
                                appt.status.toUpperCase()
                              ) && (
                                <div className="flex items-center gap-2 mt-1">
                                  {reviewedAppointmentIds.has(appt.appointment_id) ? (
                                    <span className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 text-[11px] font-bold">
                                      <CheckCircle className="h-3 w-3" />
                                      Reviewed
                                    </span>
                                  ) : (
                                    <button
                                      onClick={() => openReviewModal(appt)}
                                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-amber-50 border border-amber-200 text-amber-700 hover:bg-amber-100 text-[11px] font-bold transition-all"
                                    >
                                      <Star className="h-3 w-3 fill-amber-400 text-amber-400" />
                                      Rate Doctor
                                    </button>
                                  )}
                                </div>
                              )}
                        </div>
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
                  <p className="text-xs text-[#6B8078] mt-1">Browse the hospital&apos;s doctors by specialty &amp; rating, then pick a slot</p>
                </div>

                {/* Directory summary */}
                <div className="flex items-center gap-2">
                  <span className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#EEF4F1] border border-[#D7E2DC] text-[#12463E] text-xs font-bold">
                    <Users className="h-3.5 w-3.5" />
                    {doctors.length} Doctors
                  </span>
                  <span className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-amber-50 border border-amber-200 text-amber-700 text-xs font-bold">
                    <Award className="h-3.5 w-3.5" />
                    {topRatedCount} Top Rated
                  </span>
                  <button
                    onClick={() => setDoctorSort(doctorSort === "top" ? "name" : "top")}
                    title="Sort doctors by rating or by name"
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[#D7E2DC] text-[#12463E] hover:bg-[#EEF4F1] text-xs font-bold transition-all"
                  >
                    <SortDesc className="h-3.5 w-3.5" />
                    {doctorSort === "top" ? "Top Rated" : "Name A–Z"}
                  </button>
                </div>
              </div>

              {/* Specialty filter chips with counts */}
              <div className="flex flex-wrap gap-2">
                <button
                  onClick={() => setSelectedSpecialty("All Specialties")}
                  className={`px-3.5 py-2 rounded-xl text-xs font-semibold border transition-all ${
                    selectedSpecialty === "All Specialties"
                      ? "bg-emerald-500 border-emerald-500 text-white shadow-md shadow-emerald-500/10"
                      : "bg-white border-[#D7E2DC] text-[#4B5F58] hover:border-[#12463E]"
                  }`}
                >
                  All Specialties ({doctors.length})
                </button>
                {Array.from(new Set(doctors.map((d) => d.specialty))).map((sp) => (
                  <button
                    key={sp}
                    onClick={() => setSelectedSpecialty(sp)}
                    className={`px-3.5 py-2 rounded-xl text-xs font-semibold border transition-all ${
                      selectedSpecialty === sp
                        ? "bg-emerald-500 border-emerald-500 text-white shadow-md shadow-emerald-500/10"
                        : "bg-white border-[#D7E2DC] text-[#4B5F58] hover:border-[#12463E]"
                    }`}
                  >
                    {sp} ({specialtyCounts[sp] || 0})
                  </button>
                ))}
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
                            <div className="flex items-center gap-2">
                              <h3 className="font-bold text-[#0B2B26] text-base">{doc.name}</h3>
                              {doc.is_top_rated && (
                                <span className="flex items-center gap-0.5 px-1.5 py-0.5 rounded-md bg-amber-50 border border-amber-200 text-amber-700 text-[9px] font-bold uppercase tracking-wide">
                                  <Award className="h-2.5 w-2.5" /> Top Rated
                                </span>
                              )}
                            </div>
                            <span className="text-xs bg-emerald-50 text-emerald-800 px-2 py-0.5 rounded font-medium mt-1 inline-block">
                              {doc.specialty}
                            </span>
                            {/* Rating */}
                            <div className="flex items-center gap-2 mt-1.5">
                              {renderStars(doc.rating || 0)}
                              <span className="text-xs font-bold text-[#0B2B26]">
                                {(doc.rating || 0).toFixed(1)}
                              </span>
                              <span className="text-[10px] text-[#8AA098]">
                                · {doc.review_count || 0} reviews
                              </span>
                            </div>
                            {doc.experience_years ? (
                              <p className="text-[10px] text-[#8AA098] mt-0.5">
                                {doc.experience_years}+ years experience
                              </p>
                            ) : null}
                          </div>
                        </div>

                        {/* Available slots */}
                        <div className="mt-5 space-y-2">
                          <span className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider block">Available Slots today</span>
                          <div className="flex flex-wrap gap-2">
                            {SLOTS.map((slot) => {
                              const isBooked = bookedSlotsByDoctor[doc.name]?.has(slot) || false
                              const isDisabled = booking || isBooked
                              return (
                                <button
                                  key={slot}
                                  disabled={isDisabled}
                                  onClick={() => handleBookSlot(doc, slot)}
                                  title={isBooked ? "This time is already booked" : `Book ${slot}`}
                                  className={`px-3.5 py-2 text-xs font-semibold rounded-xl transition-all font-mono ${
                                    isBooked
                                      ? "bg-[#EEF4F1] text-[#9CAEA6] border border-[#D7E2DC] cursor-not-allowed"
                                      : "bg-[#F6F8F7] hover:bg-[#12463E] hover:text-white border border-[#D7E2DC] text-[#0B2B26]"
                                  } disabled:opacity-70`}
                                >
                                  {slot}
                                  {isBooked && <span className="ml-1.5 text-[9px] uppercase tracking-wide font-bold text-[#C0A24A]">Booked</span>}
                                </button>
                              )
                            })}
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

      {/* ─── RESCHEDULE APPOINTMENT MODAL ─── */}
      {editingAppointment && (
        <>
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50" onClick={() => setEditingAppointment(null)} />
          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center">
                  <CalendarClock className="h-5 w-5 text-emerald-600" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-[#0B2B26]">Reschedule Appointment</h3>
                  <p className="text-xs text-[#8AA098] mt-0.5">{editingAppointment.doctor_name}</p>
                </div>
              </div>
              <button
                onClick={() => setEditingAppointment(null)}
                className="w-8 h-8 rounded-full bg-[#F6F8F7] hover:bg-[#EEF4F1] flex items-center justify-center transition-all text-[#6B8078]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="space-y-4 mt-2">
              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1.5">Date</label>
                <input
                  type="date"
                  value={editDate}
                  min={today}
                  onChange={(e) => setEditDate(e.target.value)}
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26]"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1.5">Preferred Time</label>
                <div className="flex flex-wrap gap-2">
                  {SLOTS.map((slot) => {
                    const isCurrent = slot === editTime
                    const isTaken =
                      editDate === today &&
                      bookedSlotsByDoctor[editingAppointment.doctor_name]?.has(slot) &&
                      !(editingAppointment.date === today && editingAppointment.time === slot)
                    return (
                      <button
                        key={slot}
                        type="button"
                        disabled={isTaken}
                        onClick={() => setEditTime(slot)}
                        title={isTaken ? "This time is already booked" : slot}
                        className={`px-3.5 py-2 rounded-xl text-xs font-semibold border transition-all font-mono ${
                          isCurrent
                            ? "bg-[#12463E] text-white border-[#12463E]"
                            : isTaken
                            ? "bg-[#EEF4F1] text-[#9CAEA6] border border-[#D7E2DC] cursor-not-allowed"
                            : "bg-[#F6F8F7] border border-[#D7E2DC] text-[#0B2B26] hover:border-[#12463E]"
                        } disabled:opacity-70`}
                      >
                        {slot}
                      </button>
                    )
                  })}
                </div>
              </div>

              <div className="flex items-center gap-2 bg-[#EEF4F1]/60 border border-[#D7E2DC] rounded-xl px-4 py-3 text-xs text-[#6B8078]">
                <ShieldCheck className="h-4 w-4 text-[#12463E] shrink-0" />
                <span>
                  Rescheduling to {editDate || "…"} at {editTime || "…"}.
                  {editDate === today && editTime !== editingAppointment.time && bookedSlotsByDoctor[editingAppointment.doctor_name]?.has(editTime)
                    ? " This time is already booked — pick another."
                    : " You can still reschedule again later."}
                </span>
              </div>

              <div className="flex gap-3 mt-2">
                <button
                  onClick={() => setEditingAppointment(null)}
                  className="flex-1 h-11 rounded-xl border border-[#D7E2DC] text-xs font-bold text-[#6B8078] hover:bg-[#F6F8F7] transition-all"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSaveEdit}
                  disabled={savingEdit || !editDate || !editTime}
                  className="flex-1 h-11 rounded-xl bg-[#12463E] text-white text-xs font-bold hover:bg-[#0B2B26] shadow-md shadow-emerald-500/10 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  {savingEdit ? <Loader2 className="h-4 w-4 animate-spin" /> : <Pencil className="h-4 w-4" />}
                  {savingEdit ? "Saving…" : "Save New Time"}
                </button>
              </div>
            </div>
          </div>
        </>
      )}

      {/* ─── RATE DOCTOR MODAL ─── */}
      {reviewingAppointment && (
        <>
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50" onClick={() => setReviewingAppointment(null)} />
          <div className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white rounded-3xl border border-[#E8ECEB] shadow-2xl p-6 z-50 animate-fade-in">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-amber-50 border border-amber-100 flex items-center justify-center">
                  <Star className="h-5 w-5 fill-amber-400 text-amber-400" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-[#0B2B26]">Rate Your Doctor</h3>
                  <p className="text-xs text-[#8AA098] mt-0.5">
                    {reviewingAppointment.doctor_name} · {reviewingAppointment.specialty}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setReviewingAppointment(null)}
                className="w-8 h-8 rounded-full bg-[#F6F8F7] hover:bg-[#EEF4F1] flex items-center justify-center transition-all text-[#6B8078]"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="space-y-4 mt-2">
              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-2">How was your visit?</label>
                <div className="flex items-center gap-1.5">
                  {[1, 2, 3, 4, 5].map((i) => {
                    const active = reviewHover ? i <= reviewHover : i <= reviewRating
                    return (
                      <button
                        key={i}
                        type="button"
                        aria-label={`${i} star${i > 1 ? "s" : ""}`}
                        onMouseEnter={() => setReviewHover(i)}
                        onMouseLeave={() => setReviewHover(0)}
                        onClick={() => setReviewRating(i)}
                        className="p-1 transition-transform hover:scale-110"
                      >
                        <Star
                          className={`h-8 w-8 ${active ? "fill-amber-400 text-amber-400" : "fill-[#E8ECEB] text-[#E8ECEB]"}`}
                        />
                      </button>
                    )
                  })}
                  <span className="ml-2 text-sm font-bold text-[#0B2B26]">
                    {reviewRating > 0 ? reviewRating : "—"}/5
                  </span>
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-[#12463E] block mb-1.5">
                  Share your feedback (optional)
                </label>
                <textarea
                  value={reviewComment}
                  onChange={(e) => setReviewComment(e.target.value)}
                  maxLength={2000}
                  rows={4}
                  placeholder="e.g. The doctor was very patient and explained everything clearly…"
                  className="w-full bg-[#F6F8F7] border border-[#D7E2DC] rounded-xl px-4 py-3 text-sm text-[#0B2B26] resize-none focus:outline-none focus:border-[#12463E]"
                />
              </div>

              {reviewError && (
                <p className="text-xs font-semibold text-rose-600 flex items-center gap-1.5">
                  <AlertTriangle className="h-3.5 w-3.5" />
                  {reviewError}
                </p>
              )}

              <div className="flex gap-3 mt-2">
                <button
                  onClick={() => setReviewingAppointment(null)}
                  className="flex-1 h-11 rounded-xl border border-[#D7E2DC] text-xs font-bold text-[#6B8078] hover:bg-[#F6F8F7] transition-all"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSubmitReview}
                  disabled={reviewSubmitting}
                  className="flex-1 h-11 rounded-xl bg-amber-500 text-white text-xs font-bold hover:bg-amber-600 shadow-md shadow-amber-500/10 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  {reviewSubmitting ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Star className="h-4 w-4 fill-white" />
                  )}
                  {reviewSubmitting ? "Submitting…" : "Submit Review"}
                </button>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
