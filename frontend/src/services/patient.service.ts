import { api } from "@/lib/api"

export interface Patient {
  id: number
  user_id: string
  user_name: string
  name: string
  email: string
  phone: string
  age: number | null
  gender: string | null
  insurance_provider: string
  status: string
  role: string
  created_at: string | null
  updated_at: string | null
  access_token?: string
  token_type?: string
}

export interface PatientCreatePayload {
  user_name: string
  email?: string
  phone: string
  age?: number | null
  gender?: string | null
  insurance_provider?: string | null
}

export interface PatientOtpSendResponse {
  phone: string
  patient_name: string
  expires_in: number
  otp?: string
}

export interface PatientUpdatePayload {
  user_name?: string
  email?: string
  phone?: string
  age?: number | null
  gender?: string | null
  insurance_provider?: string | null
  status?: string
}

export interface PatientAppointment {
  id: number
  appointment_id: string
  patient_name: string
  patient_phone: string
  doctor_name: string
  specialty: string
  date: string
  time: string
  status: string
  created_at?: string | null
  updated_at?: string | null
}

export interface PatientInvoiceItem {
  description: string
  cost: number
}

export interface PatientInvoice {
  id: number
  invoice_id: string
  patient_name: string
  patient_phone: string
  date: string
  amount: number
  items: PatientInvoiceItem[]
  insurance_status: string
  payment_status: string
  created_at?: string | null
  updated_at?: string | null
}

export interface PatientBookingPayload {
  doctor_name: string
  specialty: string
  date: string
  time: string
}

export interface Doctor {
  user_id: string
  name: string
  specialty: string
  department: string | null
  email: string
  phone: string | null
}

export interface ApiResponse<T> {
  data: T
  success: boolean
  status_code: number
  message: string
}

// ─── OTP login ────────────────────────────────────────────────

export async function sendPatientOtp(phone: string) {
  return api.post<ApiResponse<PatientOtpSendResponse>>("/api/patient/otp/send", { phone })
}

export async function verifyPatientOtp(phone: string, otp: string) {
  return api.post<ApiResponse<Patient>>("/api/patient/otp/verify", { phone, otp })
}

// ─── Self-service profile ───────────────────────────────────────

export async function getPatientProfile() {
  return api.get<ApiResponse<Patient>>("/api/patient/me")
}

export async function updatePatientProfile(payload: PatientUpdatePayload) {
  return api.put<ApiResponse<Patient>>("/api/patient/me", payload)
}

// ─── Self-service appointments & billing ─────────────────────────

export async function getPatientDoctors() {
  return api.get<ApiResponse<Doctor[]>>("/api/patient/doctors")
}

export async function getPatientAppointments() {
  return api.get<ApiResponse<PatientAppointment[]>>("/api/patient/appointments")
}

export async function bookPatientAppointment(payload: PatientBookingPayload) {
  return api.post<ApiResponse<PatientAppointment>>("/api/patient/appointments", payload)
}

export async function getPatientInvoices() {
  return api.get<ApiResponse<PatientInvoice[]>>("/api/patient/invoices")
}

// ─── Staff/admin patient management ─────────────────────────────

export async function createPatient(payload: PatientCreatePayload) {
  return api.post<ApiResponse<Patient>>("/api/patient", payload)
}

export async function listPatients() {
  return api.get<ApiResponse<Patient[]>>("/api/patient")
}

export async function getPatient(userId: string) {
  return api.get<ApiResponse<Patient>>(`/api/patient/${userId}`)
}

export async function updatePatient(userId: string, payload: PatientUpdatePayload) {
  return api.put<ApiResponse<Patient>>(`/api/patient/${userId}`, payload)
}

export async function deletePatient(userId: string) {
  return api.delete<ApiResponse<null>>(`/api/patient/${userId}`)
}
