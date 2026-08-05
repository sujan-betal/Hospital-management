import { api } from "@/lib/api"
import {
  listPatients,
  updatePatient,
  deletePatient,
  createPatient as createPatientService,
  type Patient,
} from "@/services/patient.service"

export { listPatients, updatePatient, deletePatient }

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
  fee: number
  payment_status: string
  status: "SCHEDULED" | "CHECKED-IN" | "COMPLETED" | "CANCELLED"
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

export interface Bed {
  id: number
  bed_id: string
  ward: string
  status: "AVAILABLE" | "OCCUPIED" | "SANITIZING" | "RESERVED"
  price: number
  floor: number
  assigned_nurse: string | null
  equipment: string[]
  patient: string | null
  created_at: string
  updated_at: string
}

export interface BedStatusUpdatePayload {
  status?: string
  patient?: string
}

export interface ApiResponse<T> {
  data: T
  success: boolean
  status_code: number
  message: string
}

// ─── Patients (owned by the Patient module) ─────────────────────

export async function registerPatient(payload: PatientPayload) {
  return createPatientService(payload)
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

// ─── Ward / Bed Management ──────────────────────────────────

export async function listBeds() {
  return api.get<ApiResponse<Bed[]>>("/api/receptionist/beds")
}

export async function updateBedStatus(bedId: string, payload: BedStatusUpdatePayload) {
  return api.put<ApiResponse<Bed>>(`/api/receptionist/beds/${bedId}`, payload)
}
