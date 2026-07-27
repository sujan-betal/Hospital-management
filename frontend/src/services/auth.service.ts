import { api } from "@/lib/api"

export interface LoginPayload {
  email: string
  password: string
}

export interface RegisterPayload {
  user_name: string
  email: string
  password: string
}

export interface AdminData {
  id: number
  user_name: string
  email: string
  user_id: string
  role: string
  status: string
  access_token?: string
  token_type?: string
}

export interface ApiResponse<T> {
  data: T
  success: boolean
  status_code: number
  message: string
}

export async function loginStaff(payload: LoginPayload) {
  return api.post<ApiResponse<AdminData>>("/api/admin/login", payload)
}

export async function registerAdmin(payload: RegisterPayload) {
  return api.post<ApiResponse<AdminData>>("/api/admin/register", payload)
}
