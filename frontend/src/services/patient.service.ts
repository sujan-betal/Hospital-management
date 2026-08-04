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
