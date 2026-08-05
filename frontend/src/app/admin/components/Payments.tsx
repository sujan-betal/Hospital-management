"use client"

import React, { useState, useEffect } from "react"
import {
  Wallet,
  Save,
  RefreshCw,
  Percent,
  Building2,
  Stethoscope,
  Receipt,
  Loader2,
  IndianRupee,
  Landmark,
  Pencil,
  CheckCircle2,
  Clock,
  XCircle,
  UserRound
} from "lucide-react"
import {
  getRevenueOverview,
  listAdminDoctors,
  updateDoctorBankDetails,
  updateHospitalSettings,
  type AdminDoctor,
  type RevenueOverview
} from "@/services/admin.service"

export function Payments() {
  const [revenue, setRevenue] = useState<RevenueOverview | null>(null)
  const [doctorAccounts, setDoctorAccounts] = useState<AdminDoctor[]>([])
  const [doctorSharePercent, setDoctorSharePercent] = useState(30)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [savingBank, setSavingBank] = useState(false)
  const [error, setError] = useState("")
  const [showToast, setShowToast] = useState(false)
  const [bankDoctor, setBankDoctor] = useState<AdminDoctor | null>(null)
  const [bankForm, setBankForm] = useState({
    account_holder: "",
    account_number: "",
    ifsc: "",
    bank_name: "",
    upi_id: ""
  })
  const [bankError, setBankError] = useState("")

  const loadRevenue = async () => {
    setLoading(true)
    setError("")
    try {
      const res = await getRevenueOverview()
      setRevenue(res.data)
      setDoctorSharePercent(res.data.settings.doctor_share_percent)
      try {
        const docs = await listAdminDoctors()
        setDoctorAccounts(docs.data)
      } catch {
        setDoctorAccounts([])
      }
    } catch (e: any) {
      setError(e?.message || "Failed to load revenue data")
    } finally {
      setLoading(false)
    }
  }

  const openBankModal = (doctor: AdminDoctor) => {
    setBankDoctor(doctor)
    setBankError("")
    setBankForm({
      account_holder: doctor.bank_account_holder || doctor.user_name,
      account_number: doctor.bank_account_number.startsWith("XXXX") ? "" : doctor.bank_account_number,
      ifsc: doctor.bank_ifsc || "",
      bank_name: doctor.bank_name || "",
      upi_id: doctor.upi_id || ""
    })
  }

  const handleSaveBank = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!bankDoctor) return
    setSavingBank(true)
    setBankError("")
    try {
      await updateDoctorBankDetails(bankDoctor.user_id, {
        ...bankForm,
        bank_name: bankForm.bank_name || undefined,
        upi_id: bankForm.upi_id || undefined
      })
      setBankDoctor(null)
      await loadRevenue()
      setShowToast(true)
      setTimeout(() => setShowToast(false), 3000)
    } catch (err: any) {
      setBankError(err?.message || "Failed to save bank details")
    } finally {
      setSavingBank(false)
    }
  }

  useEffect(() => {
    loadRevenue()
  }, [])

  const handleSaveSplit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setError("")
    try {
      await updateHospitalSettings({ doctor_share_percent: doctorSharePercent })
      await loadRevenue()
      setShowToast(true)
      setTimeout(() => setShowToast(false), 3000)
    } catch (err: any) {
      setError(err?.message || "Failed to save split")
    } finally {
      setSaving(false)
    }
  }

  const adminKeepPercent = 100 - doctorSharePercent

  if (loading && !revenue) {
    return (
      <div className="flex items-center justify-center py-32 text-[#6B8078]">
        <Loader2 className="h-6 w-6 animate-spin mr-3 text-emerald-600" />
        <span className="text-sm font-semibold">Loading revenue breakdown...</span>
      </div>
    )
  }

  if (!revenue) {
    return (
      <div className="flex flex-col items-center justify-center py-32 gap-4">
        <p className="text-sm font-bold text-[#6B8078]">{error || "Could not load revenue data"}</p>
        <button
          onClick={loadRevenue}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 transition-all"
        >
          <RefreshCw className="h-4 w-4" /> Retry
        </button>
      </div>
    )
  }

  const { summary, doctors, payments } = revenue
  const currency = revenue.settings.currency.includes("INR") ? "Rs." : "Rs."

  return (
    <div className="space-y-6 animate-fade-in relative">
      {error && (
        <div className="bg-rose-50 border border-rose-200 text-rose-700 text-xs font-bold rounded-2xl px-4 py-3">
          {error}
        </div>
      )}

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div className="bg-white rounded-3xl border border-[#E8ECEB] p-5 shadow-xs">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center">
              <Wallet className="h-5 w-5 text-emerald-600" />
            </div>
            <div>
              <p className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Total Collected</p>
              <p className="text-lg font-black text-[#0B2B26] leading-tight">
                {currency} {summary.total_collected.toLocaleString()}
              </p>
            </div>
          </div>
          <p className="text-[10px] text-[#9CAEA6] font-medium">
            {summary.payment_count} confirmed payment{summary.payment_count === 1 ? "" : "s"}
          </p>
        </div>

        <div className="bg-white rounded-3xl border border-[#E8ECEB] p-5 shadow-xs">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-xl bg-[#12463E] border border-[#1E5D52] flex items-center justify-center">
              <Building2 className="h-5 w-5 text-emerald-400" />
            </div>
            <div>
              <p className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Admin Keeps</p>
              <p className="text-lg font-black text-[#0B2B26] leading-tight">
                {currency} {summary.admin_keep.toLocaleString()}
              </p>
            </div>
          </div>
          <p className="text-[10px] text-[#9CAEA6] font-medium">{100 - summary.doctor_share_percent}% of collected fees</p>
        </div>

        <div className="bg-white rounded-3xl border border-[#E8ECEB] p-5 shadow-xs">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center">
              <Stethoscope className="h-5 w-5 text-emerald-600" />
            </div>
            <div>
              <p className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Doctors Earn</p>
              <p className="text-lg font-black text-[#0B2B26] leading-tight">
                {currency} {summary.doctor_share.toLocaleString()}
              </p>
            </div>
          </div>
          <p className="text-[10px] text-[#9CAEA6] font-medium">{summary.doctor_share_percent}% paid out to doctors</p>
        </div>

        <div className="bg-white rounded-3xl border border-[#E8ECEB] p-5 shadow-xs">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center">
              <CheckCircle2 className="h-5 w-5 text-emerald-600" />
            </div>
            <div>
              <p className="text-[10px] font-bold text-[#8AA098] uppercase tracking-wider">Paid Out</p>
              <p className="text-lg font-black text-[#0B2B26] leading-tight">
                {currency} {(summary.paid_out ?? 0).toLocaleString()}
              </p>
            </div>
          </div>
          <p className="text-[10px] text-[#9CAEA6] font-medium">
            {(summary.pending ?? 0) > 0
              ? `${currency} ${summary.pending.toLocaleString()} pending payout`
              : "All doctor shares disbursed"}
          </p>
        </div>
      </div>

      {/* Dynamic Split Config */}
      <form
        onSubmit={handleSaveSplit}
        className="bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs"
      >
        <div className="flex items-center gap-3 border-b border-[#E8ECEB] pb-4 mb-5">
          <Wallet className="h-5 w-5 text-emerald-600" />
          <div>
            <h3 className="text-base font-bold text-[#0B2B26]">Dynamic Revenue Split</h3>
            <p className="text-[11px] text-[#6B8078]">
              Patient payments land in the hospital account. Set the doctor&apos;s share and the hospital keeps the rest.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 items-end">
          <div className="space-y-1.5">
            <label htmlFor="doctor-share" className="text-xs font-bold text-[#12463E]">Doctor Share (%)</label>
            <div className="relative">
              <Percent className="absolute left-3.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[#8AA098]" />
              <input
                id="doctor-share"
                type="number"
                min={0}
                max={100}
                value={doctorSharePercent}
                onChange={(e) => setDoctorSharePercent(Number(e.target.value))}
                className="w-full h-11 pl-10 pr-3 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label htmlFor="admin-keep" className="text-xs font-bold text-[#12463E]">Admin Keeps (%)</label>
            <div className="relative">
              <Building2 className="absolute left-3.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[#8AA098]" />
              <input
                id="admin-keep"
                type="number"
                value={adminKeepPercent}
                disabled
                className="w-full h-11 pl-10 pr-3 rounded-xl border border-[#D7E2DC] bg-[#EEF4F1] text-xs text-[#0B2B26] cursor-not-allowed"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label htmlFor="split-slider" className="text-xs font-bold text-[#12463E]">&nbsp;</label>
            <div className="flex gap-2">
              <input
                id="split-slider"
                type="range"
                min={0}
                max={100}
                value={doctorSharePercent}
                onChange={(e) => setDoctorSharePercent(Number(e.target.value))}
                className="w-full h-10 accent-emerald-600"
              />
              <button
                type="submit"
                disabled={saving}
                className="shrink-0 h-11 px-5 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white text-xs font-bold transition-all flex items-center justify-center gap-2"
              >
                {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                Save Split
              </button>
            </div>
          </div>
        </div>

        <div className="mt-5 p-3.5 bg-[#EEF4F1] rounded-2xl border border-[#D7E2DC] flex items-center gap-3">
          <IndianRupee className="h-4 w-4 text-emerald-600 shrink-0" />
          <p className="text-[11px] text-[#12463E] font-semibold leading-relaxed">
            Example: a {currency} 150 consultation pays the doctor {currency}{" "}
            {Math.round((150 * doctorSharePercent) / 100)} and keeps {currency}{" "}
            {150 - Math.round((150 * doctorSharePercent) / 100)} for the hospital. The split is
            snapshotted on each payment, so changing it later only affects new payments.
          </p>
        </div>
      </form>

      {/* Per-doctor breakdown */}
      <div className="bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs">
        <div className="flex items-center gap-3 border-b border-[#E8ECEB] pb-4 mb-4">
          <Stethoscope className="h-5 w-5 text-emerald-600" />
          <h3 className="text-base font-bold text-[#0B2B26]">Payout by Doctor</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="text-[10px] uppercase tracking-wider text-[#8AA098] border-b border-[#E8ECEB]">
                <th className="py-3 font-bold">Doctor</th>
                <th className="py-3 font-bold">Payments</th>
                <th className="py-3 font-bold">Collected</th>
                <th className="py-3 font-bold">Admin Keeps</th>
                <th className="py-3 font-bold">Doctor Earns</th>
                <th className="py-3 font-bold">Paid Out</th>
                <th className="py-3 font-bold">Pending</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8ECEB]">
              {doctors.length === 0 && (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-xs text-[#9CAEA6] font-medium">
                    No paid consultations yet — payments will appear here once patients pay.
                  </td>
                </tr>
              )}
              {doctors.map((d) => (
                <tr key={d.doctor_name} className="hover:bg-[#F6F8F7] transition-colors">
                  <td className="py-3.5 text-xs font-bold text-[#0B2B26]">{d.doctor_name}</td>
                  <td className="py-3.5 text-xs text-[#6B8078]">{d.payments}</td>
                  <td className="py-3.5 text-xs font-semibold text-[#0B2B26]">
                    {currency} {d.collected.toLocaleString()}
                  </td>
                  <td className="py-3.5 text-xs text-[#12463E] font-semibold">
                    {currency} {d.admin_keep.toLocaleString()}
                  </td>
                  <td className="py-3.5 text-xs text-emerald-700 font-bold">
                    {currency} {d.doctor_share.toLocaleString()}
                  </td>
                  <td className="py-3.5 text-xs text-[#0B2B26] font-semibold">
                    {currency} {(d.paid_out ?? 0).toLocaleString()}
                  </td>
                  <td className="py-3.5 text-xs">
                    {(d.pending ?? 0) > 0 ? (
                      <span className="inline-flex items-center gap-1 text-amber-700 font-bold">
                        <Clock className="h-3.5 w-3.5" /> {currency} {(d.pending ?? 0).toLocaleString()}
                      </span>
                    ) : (
                      <span className="text-[#9CAEA6]">—</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Doctor payout accounts */}
      <div className="bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs">
        <div className="flex items-center justify-between border-b border-[#E8ECEB] pb-4 mb-4">
          <div className="flex items-center gap-3">
            <Landmark className="h-5 w-5 text-emerald-600" />
            <div>
              <h3 className="text-base font-bold text-[#0B2B26]">Doctor Payout Accounts</h3>
              <p className="text-[11px] text-[#6B8078]">
                Bank details doctors receive their share to. Entered here or self-served from the doctor portal.
              </p>
            </div>
          </div>
          <button
            onClick={loadRevenue}
            className="flex items-center gap-2 px-3 py-2 rounded-xl border border-[#D7E2DC] text-[#12463E] text-xs font-bold hover:bg-[#F6F8F7] transition-all"
          >
            <RefreshCw className="h-3.5 w-3.5" /> Refresh
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="text-[10px] uppercase tracking-wider text-[#8AA098] border-b border-[#E8ECEB]">
                <th className="py-3 font-bold">Doctor</th>
                <th className="py-3 font-bold">Account Holder</th>
                <th className="py-3 font-bold">Account No.</th>
                <th className="py-3 font-bold">IFSC</th>
                <th className="py-3 font-bold">Bank</th>
                <th className="py-3 font-bold">Status</th>
                <th className="py-3 font-bold"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8ECEB]">
              {doctorAccounts.length === 0 && (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-xs text-[#9CAEA6] font-medium">
                    No doctors registered yet.
                  </td>
                </tr>
              )}
              {doctorAccounts.map((d) => (
                <tr key={d.user_id} className="hover:bg-[#F6F8F7] transition-colors">
                  <td className="py-3.5 text-xs font-bold text-[#0B2B26]">{d.user_name}</td>
                  <td className="py-3.5 text-xs text-[#6B8078]">{d.bank_account_holder || "—"}</td>
                  <td className="py-3.5 text-xs text-[#6B8078]">{d.bank_account_number || "—"}</td>
                  <td className="py-3.5 text-xs text-[#6B8078]">{d.bank_ifsc || "—"}</td>
                  <td className="py-3.5 text-xs text-[#6B8078]">{d.bank_name || "—"}</td>
                  <td className="py-3.5">
                    {d.has_bank_details ? (
                      <span className="inline-flex items-center gap-1 text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-2.5 py-1 text-[10px] font-bold">
                        <CheckCircle2 className="h-3 w-3" /> Configured
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-[#8AA098] bg-[#F0F3F2] border border-[#E2E8E5] rounded-full px-2.5 py-1 text-[10px] font-bold">
                        <XCircle className="h-3 w-3" /> Not set
                      </span>
                    )}
                  </td>
                  <td className="py-3.5 text-right">
                    <button
                      onClick={() => openBankModal(d)}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-[#D7E2DC] text-[#12463E] text-[11px] font-bold hover:bg-emerald-50 transition-all"
                    >
                      <Pencil className="h-3 w-3" />
                      {d.has_bank_details ? "Edit" : "Add"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Recent payments */}
      <div className="bg-white rounded-3xl border border-[#E8ECEB] p-6 shadow-xs">
        <div className="flex items-center gap-3 border-b border-[#E8ECEB] pb-4 mb-4">
          <Receipt className="h-5 w-5 text-emerald-600" />
          <h3 className="text-base font-bold text-[#0B2B26]">Recent Paid Consultations</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="text-[10px] uppercase tracking-wider text-[#8AA098] border-b border-[#E8ECEB]">
                <th className="py-3 font-bold">Appointment</th>
                <th className="py-3 font-bold">Patient</th>
                <th className="py-3 font-bold">Doctor</th>
                <th className="py-3 font-bold">Fee</th>
                <th className="py-3 font-bold">Split</th>
                <th className="py-3 font-bold">Admin</th>
                <th className="py-3 font-bold">Doctor</th>
                <th className="py-3 font-bold">Payout</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8ECEB]">
              {payments.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-xs text-[#9CAEA6] font-medium">
                    No paid consultations yet.
                  </td>
                </tr>
              )}
              {payments.slice(0, 10).map((p) => (
                <tr key={p.appointment_id} className="hover:bg-[#F6F8F7] transition-colors">
                  <td className="py-3.5 text-xs font-semibold text-[#12463E]">{p.appointment_id}</td>
                  <td className="py-3.5 text-xs text-[#0B2B26] font-medium">{p.patient_name}</td>
                  <td className="py-3.5 text-xs text-[#6B8078]">{p.doctor_name}</td>
                  <td className="py-3.5 text-xs font-semibold text-[#0B2B26]">
                    {currency} {p.fee.toLocaleString()}
                  </td>
                  <td className="py-3.5 text-xs text-[#6B8078]">{p.doctor_share_percent}%</td>
                  <td className="py-3.5 text-xs text-[#12463E] font-semibold">
                    {currency} {p.admin_share.toLocaleString()}
                  </td>
                  <td className="py-3.5 text-xs text-emerald-700 font-bold">
                    {currency} {p.doctor_share.toLocaleString()}
                  </td>
                  <td className="py-3.5">
                    {p.payout_status === "PAID" ? (
                      <span className="inline-flex items-center gap-1 text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-2.5 py-1 text-[10px] font-bold">
                        <CheckCircle2 className="h-3 w-3" /> Paid
                      </span>
                    ) : p.payout_status === "FAILED" ? (
                      <span className="inline-flex items-center gap-1 text-rose-700 bg-rose-50 border border-rose-100 rounded-full px-2.5 py-1 text-[10px] font-bold">
                        <XCircle className="h-3 w-3" /> Failed
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-amber-700 bg-amber-50 border border-amber-100 rounded-full px-2.5 py-1 text-[10px] font-bold">
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

      {/* Bank details modal */}
      {bankDoctor && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-[#0B2B26]/40 backdrop-blur-sm p-4">
          <div className="bg-white w-full max-w-lg rounded-3xl border border-[#E8ECEB] shadow-2xl animate-fade-in">
            <div className="flex items-center justify-between border-b border-[#E8ECEB] px-6 py-4">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center">
                  <UserRound className="h-4.5 w-4.5 text-emerald-600" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-[#0B2B26]">{bankDoctor.user_name}</h3>
                  <p className="text-[10px] text-[#8AA098] font-medium">Payout bank details</p>
                </div>
              </div>
              <button
                onClick={() => setBankDoctor(null)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#8AA098] hover:bg-[#F0F3F2] transition-all text-sm font-bold"
                aria-label="Close"
              >
                ×
              </button>
            </div>
            <form onSubmit={handleSaveBank} className="px-6 py-5 space-y-4">
              {bankError && (
                <div className="bg-rose-50 border border-rose-200 text-rose-700 text-xs font-bold rounded-xl px-4 py-2.5">
                  {bankError}
                </div>
              )}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-[#12463E]">Account Holder Name</label>
                <input
                  required
                  value={bankForm.account_holder}
                  onChange={(e) => setBankForm({ ...bankForm, account_holder: e.target.value })}
                  className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  placeholder="Full name as on bank account"
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-[#12463E]">Account Number</label>
                <input
                  required
                  value={bankForm.account_number}
                  onChange={(e) => setBankForm({ ...bankForm, account_number: e.target.value })}
                  className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  placeholder="9–18 digit account number"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">IFSC Code</label>
                  <input
                    required
                    value={bankForm.ifsc}
                    onChange={(e) => setBankForm({ ...bankForm, ifsc: e.target.value.toUpperCase() })}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                    placeholder="11 chars, e.g. HDFC0001234"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-[#12463E]">Bank Name</label>
                  <input
                    value={bankForm.bank_name}
                    onChange={(e) => setBankForm({ ...bankForm, bank_name: e.target.value })}
                    className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                    placeholder="e.g. HDFC Bank"
                  />
                </div>
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-[#12463E]">UPI ID (optional)</label>
                <input
                  value={bankForm.upi_id}
                  onChange={(e) => setBankForm({ ...bankForm, upi_id: e.target.value })}
                  className="w-full h-11 px-3.5 rounded-xl border border-[#D7E2DC] bg-[#F6F8F7] text-xs text-[#0B2B26] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all"
                  placeholder="name@bank"
                />
              </div>
              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setBankDoctor(null)}
                  className="px-4 py-2.5 rounded-xl border border-[#D7E2DC] text-[#6B8078] text-xs font-bold hover:bg-[#F0F3F2] transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={savingBank}
                  className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white text-xs font-bold transition-all"
                >
                  {savingBank ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                  Save Details
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Floating success toast */}
      {showToast && (
        <div className="fixed bottom-6 right-6 z-50 bg-[#12463E] text-white border border-emerald-600 rounded-2xl px-5 py-3.5 shadow-xl shadow-[#0B2B26]/30 flex items-center gap-3 animate-fade-in">
          <Wallet className="h-5 w-5 text-emerald-400 animate-bounce" />
          <div>
            <p className="text-xs font-black">Saved</p>
            <p className="text-[10px] text-white/70">Payout details updated successfully.</p>
          </div>
        </div>
      )}
    </div>
  )
}
