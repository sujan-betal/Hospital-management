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
  created_at: string | null
}

export interface PatientPayload {
  user_name: string
  email?: string
  phone: string
  age?: number | null
  gender?: string | null
  insurance_provider?: string | null
}

export interface DoctorOption {
  user_id: string
  name: string
  specialty: string
  department: string | null
  email: string
  phone: string | null
}

export interface Appointment {
  id: number
  appointment_id: string
  patient_name: string
  patient_phone: string
  doctor_name: string
  specialty: string
  date: string
  time: string
  status: "SCHEDULED" | "CHECKED-IN" | "CANCELLED"
}

export interface AppointmentPayload {
  patient_name: string
  patient_phone?: string
  doctor_name: string
  specialty?: string
  date: string
  time: string
  status?: string
}

export interface InvoiceItem {
  description: string
  cost: number
}

export interface Invoice {
  id: number
  invoice_id: string
  patient_name: string
  date: string
  amount: number
  items: InvoiceItem[]
  insurance_status: string
  payment_status: string
}

export interface InvoicePayload {
  patient_name: string
  date: string
  items: InvoiceItem[]
  insurance_status?: string
  payment_status?: string
}

export interface DashboardStats {
  today_visits: number
  checked_in_today: number
  total_patients: number
  paid_billings: number
  unpaid_billings: number
  unpaid_invoices: number
  total_beds: number
  occupied_beds: number
  occupancy_rate: number
  pending_tasks: number
  admitted: number
}

export interface ApiResponse<T> {
  data: T
  success: boolean
  status_code: number
  message: string
}

// ─── Patients ───────────────────────────────────────────────

export async function listPatients() {
  return api.get<ApiResponse<Patient[]>>("/api/receptionist/patients")
}

export async function registerPatient(payload: PatientPayload) {
  return api.post<ApiResponse<Patient>>("/api/receptionist/patients", payload)
}

export async function updatePatient(userId: string, payload: Partial<PatientPayload>) {
  return api.put<ApiResponse<Patient>>(`/api/receptionist/patients/${userId}`, payload)
}

export async function deletePatient(userId: string) {
  return api.delete<ApiResponse<null>>(`/api/receptionist/patients/${userId}`)
}

// ─── Doctors ────────────────────────────────────────────────

export async function listDoctors() {
  return api.get<ApiResponse<DoctorOption[]>>("/api/receptionist/doctors")
}

// ─── Appointments ───────────────────────────────────────────

export async function listAppointments() {
  return api.get<ApiResponse<Appointment[]>>("/api/receptionist/appointments")
}

export async function bookAppointment(payload: AppointmentPayload) {
  return api.post<ApiResponse<Appointment>>("/api/receptionist/appointments", payload)
}

export async function updateAppointment(appointmentId: string, payload: Partial<AppointmentPayload>) {
  return api.put<ApiResponse<Appointment>>(`/api/receptionist/appointments/${appointmentId}`, payload)
}

export async function deleteAppointment(appointmentId: string) {
  return api.delete<ApiResponse<null>>(`/api/receptionist/appointments/${appointmentId}`)
}

// ─── Invoices ───────────────────────────────────────────────

export async function listInvoices() {
  return api.get<ApiResponse<Invoice[]>>("/api/receptionist/invoices")
}

export async function createInvoice(payload: InvoicePayload) {
  return api.post<ApiResponse<Invoice>>("/api/receptionist/invoices", payload)
}

export async function updateInvoice(invoiceId: string, payload: Partial<InvoicePayload>) {
  return api.put<ApiResponse<Invoice>>(`/api/receptionist/invoices/${invoiceId}`, payload)
}

export async function deleteInvoice(invoiceId: string) {
  return api.delete<ApiResponse<null>>(`/api/receptionist/invoices/${invoiceId}`)
}

// ─── Dashboard / Reports ────────────────────────────────────

export async function getDashboard() {
  return api.get<ApiResponse<DashboardStats>>("/api/receptionist/dashboard")
}
