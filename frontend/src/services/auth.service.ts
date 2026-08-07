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

export interface CreateDoctorPayload {
  user_name: string
  email: string
  phone?: string
  department?: string
}

export interface CreateSubAdminPayload {
  user_name: string
  email: string
  password?: string
  permissions: string[]
}

export interface CreateReceptionistPayload {
  user_name: string
  email: string
  password?: string
}

export interface AssignPermissionsPayload {
  admin_id: number
  permissions: string[]
}

export interface PermissionOption {
  key: string
  label: string
  description: string
}

export interface PermissionGroup {
  group: string
  items: PermissionOption[]
}

export interface StaffMember {
  user_id: string
  user_name: string
  email: string
  role: string
  status: string
  phone: string | null
  department: string | null
  created_at: string | null
  admin_id?: number | null
  permissions?: string[]
}

export interface UpdateStaffPayload {
  user_name?: string
  email?: string
  phone?: string
  department?: string
  status?: string
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

export async function createDoctor(payload: CreateDoctorPayload) {
  return api.post<ApiResponse<AdminData>>("/api/admin/doctors", payload)
}

export async function createSubAdmin(payload: CreateSubAdminPayload) {
  return api.post<ApiResponse<AdminData>>("/api/admin/subadmins", payload)
}

export async function createReceptionist(payload: CreateReceptionistPayload) {
  return api.post<ApiResponse<AdminData>>("/api/receptionist/register", payload)
}

export async function assignPermissions(payload: AssignPermissionsPayload) {
  return api.put<ApiResponse<{ admin_id: number; permissions: string[] }>>(
    "/api/admin/permissions",
    payload
  )
}

export async function listPermissions() {
  return api.get<ApiResponse<PermissionGroup[]>>("/api/admin/permissions")
}

export async function forgotPassword(email: string) {
  return api.post<ApiResponse<null>>("/api/doctor/forgot-password", { email })
}

export async function resetPassword(token: string, new_password: string) {
  return api.post<ApiResponse<null>>("/api/doctor/reset-password", {
    token,
    new_password,
  })
}

export async function listStaff() {
  return api.get<ApiResponse<StaffMember[]>>("/api/admin/staff")
}

export async function updateStaff(userId: string, payload: UpdateStaffPayload) {
  return api.put<ApiResponse<StaffMember>>(`/api/admin/staff/${userId}`, payload)
}

export async function deleteStaff(userId: string) {
  return api.delete<ApiResponse<null>>(`/api/admin/staff/${userId}`)
}
