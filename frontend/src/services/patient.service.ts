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
  patient_user_id?: string
  doctor_name: string
  specialty: string
  date: string
  time: string
  status: string
  fee?: number
  payment_status?: string
  payment_id?: string
  razorpay_order_id?: string
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

export interface PatientAppointmentUpdatePayload {
  doctor_name?: string
  specialty?: string
  date?: string
  time?: string
}

export interface PatientPaymentOrder {
  key_id: string
  order_id: string
  amount: number
  currency: string
  receipt: string
  appointment_id: string
}

export interface PatientPaymentVerifyPayload {
  razorpay_order_id: string
  razorpay_payment_id: string
  razorpay_signature: string
}

export interface PatientPaymentVerifyResponse {
  appointment: PatientAppointment
  invoice: PatientInvoice | null
}

export interface Doctor {
  user_id: string
  name: string
  specialty: string
  department: string | null
  email: string
  phone: string | null
  rating?: number
  review_count?: number
  experience_years?: number
  is_top_rated?: boolean
}

export interface DoctorReview {
  id: number
  review_id: string
  appointment_id: string
  doctor_id: string
  doctor_name: string
  specialty: string
  patient_user_id: string
  patient_name: string
  rating: number
  comment: string
  created_at?: string | null
  updated_at?: string | null
}

export interface ReviewCreatePayload {
  appointment_id: string
  rating: number
  comment?: string
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

export interface BookedSlot {
  doctor_name: string
  time: string
}

export async function getBookedSlots(date: string) {
  return api.get<ApiResponse<BookedSlot[]>>(
    `/api/patient/appointments/booked-slots?date=${encodeURIComponent(date)}`
  )
}

export async function bookPatientAppointment(payload: PatientBookingPayload) {
  return api.post<ApiResponse<PatientAppointment>>("/api/patient/appointments", payload)
}

export async function updatePatientAppointment(
  appointmentId: string,
  payload: PatientAppointmentUpdatePayload
) {
  return api.put<ApiResponse<PatientAppointment>>(
    `/api/patient/appointments/${appointmentId}`,
    payload
  )
}

export async function createPatientPaymentOrder(appointmentId: string) {
  return api.post<ApiResponse<PatientPaymentOrder>>(
    `/api/patient/appointments/${appointmentId}/payment/order`,
    {}
  )
}

export async function verifyPatientPayment(
  appointmentId: string,
  payload: PatientPaymentVerifyPayload
) {
  return api.post<ApiResponse<PatientPaymentVerifyResponse>>(
    `/api/patient/appointments/${appointmentId}/payment/verify`,
    payload
  )
}

export async function getPatientInvoices() {
  return api.get<ApiResponse<PatientInvoice[]>>("/api/patient/invoices")
}

// ─── Doctor reviews ────────────────────────────────────────────

export async function getPatientReviews() {
  return api.get<ApiResponse<DoctorReview[]>>("/api/patient/reviews")
}

export async function submitDoctorReview(payload: ReviewCreatePayload) {
  return api.post<ApiResponse<DoctorReview>>("/api/patient/reviews", payload)
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
