import { api } from "@/lib/api"

export interface ApiResponse<T> {
  data: T
  success: boolean
  status_code: number
  message: string
}

export interface HospitalSettings {
  id: number
  hospital_name: string
  address: string
  currency: string
  copay_rate: number
  emergency_markup: number
  doctor_share_percent: number
  auto_telemetry: boolean
  sanitation_interval: number
  auto_dirty: boolean
  created_at?: string
  updated_at?: string
}

export interface SettingsUpdatePayload {
  hospital_name?: string
  address?: string
  copay_rate?: number
  emergency_markup?: number
  doctor_share_percent?: number
  auto_telemetry?: boolean
  sanitation_interval?: number
  auto_dirty?: boolean
}

export interface RevenueDoctor {
  doctor_name: string
  payments: number
  collected: number
  admin_keep: number
  doctor_share: number
  paid_out: number
  pending: number
}

export interface RevenuePayment {
  appointment_id: string
  patient_name: string
  doctor_name: string
  date: string
  time: string
  fee: number
  payment_status: string
  doctor_share_percent: number
  admin_share: number
  doctor_share: number
  payout_status: string
  payout_id: string
  payout_error: string
  payout_date: string
  created_at?: string
}

export interface RevenueOverview {
  settings: HospitalSettings
  summary: {
    payment_count: number
    total_collected: number
    admin_keep: number
    doctor_share: number
    doctor_share_percent: number
    paid_out: number
    pending: number
  }
  doctors: RevenueDoctor[]
  payments: RevenuePayment[]
}

export interface DoctorBankDetails {
  account_holder: string
  account_number: string
  ifsc: string
  bank_name: string
  upi_id: string
  has_bank_details: boolean
  razorpayx_contact_id: string
  razorpayx_fund_account_id: string
}

export interface DoctorBankDetailsPayload {
  account_holder: string
  account_number: string
  ifsc: string
  bank_name?: string
  upi_id?: string
}

export interface AdminDoctor {
  id: number
  user_name: string
  email: string
  user_id: string
  role: string
  status: string
  phone: string | null
  department: string | null
  rating: number
  review_count: number
  experience_years: number
  is_top_rated: boolean
  has_bank_details: boolean
  bank_account_holder: string
  bank_account_number: string
  bank_ifsc: string
  bank_name: string
  upi_id: string
  razorpayx_fund_account_id: string
}

export async function getHospitalSettings() {
  return api.get<ApiResponse<HospitalSettings>>("/api/admin/settings")
}

export async function updateHospitalSettings(payload: SettingsUpdatePayload) {
  return api.put<ApiResponse<HospitalSettings>>("/api/admin/settings", payload)
}

export async function getRevenueOverview() {
  return api.get<ApiResponse<RevenueOverview>>("/api/admin/revenue")
}

export async function listAdminDoctors() {
  return api.get<ApiResponse<AdminDoctor[]>>("/api/admin/doctors")
}

export async function updateDoctorBankDetails(
  userId: string,
  payload: DoctorBankDetailsPayload
) {
  return api.put<ApiResponse<DoctorBankDetails>>(
    `/api/admin/doctors/${userId}/bank-details`,
    payload
  )
}

// ─── Wards & Beds ───────────────────────────────────────────

export interface ApiBed {
  id: number
  bed_id: string
  ward: string
  status: "AVAILABLE" | "OCCUPIED" | "SANITIZING" | "RESERVED" | string
  price: number
  floor: number
  assigned_nurse: string | null
  equipment: string[]
  patient: string | null
  created_at: string
  updated_at: string
}

export interface BedCreatePayload {
  bed_id: string
  ward: string
  status: string
  price: number
  floor: number
  assigned_nurse?: string | null
  equipment: string[]
  patient?: string | null
}

export type BedUpdatePayload = Partial<BedCreatePayload>

export async function listBeds() {
  return api.get<ApiResponse<ApiBed[]>>("/api/admin/beds")
}

export async function createBed(payload: BedCreatePayload) {
  return api.post<ApiResponse<ApiBed>>("/api/admin/beds", payload)
}

export async function updateBed(bedId: string, payload: BedUpdatePayload) {
  return api.put<ApiResponse<ApiBed>>(`/api/admin/beds/${bedId}`, payload)
}

export async function deleteBed(bedId: string) {
  return api.delete<ApiResponse<null>>(`/api/admin/beds/${bedId}`)
}
