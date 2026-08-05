import { api } from "@/lib/api"

export interface ApiResponse<T> {
  data: T
  success: boolean
  status_code: number
  message: string
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

export interface DoctorEarningPayment {
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
}

export interface DoctorEarnings {
  bank: DoctorBankDetails
  summary: {
    total_earned: number
    paid_out: number
    pending: number
    payments_count: number
    doctor_share_percent: number
  }
  payments: DoctorEarningPayment[]
}

export async function getDoctorBankDetails() {
  return api.get<ApiResponse<DoctorBankDetails>>("/api/doctor/bank-details")
}

export async function updateDoctorBankDetails(payload: DoctorBankDetailsPayload) {
  return api.put<ApiResponse<DoctorBankDetails>>("/api/doctor/bank-details", payload)
}

export async function getDoctorEarnings() {
  return api.get<ApiResponse<DoctorEarnings>>("/api/doctor/earnings")
}
