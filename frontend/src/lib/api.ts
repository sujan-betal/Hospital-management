const BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"

export class ApiError extends Error {
  status: number
  data: any

  constructor(message: string, status: number, data?: any) {
    super(message)
    this.name = "ApiError"
    this.status = status
    this.data = data
  }
}

// Backend errors come in two shapes: our own `{message}` envelope, and
// FastAPI-native `{detail}` (auth middleware, 422 validation). Surface the
// real reason instead of a generic "Request failed".
function extractErrorMessage(json: any): string {
  if (!json) return "Request failed"
  if (json.message) return json.message
  if (typeof json.detail === "string") return json.detail
  if (Array.isArray(json.detail) && json.detail.length) {
    const first = json.detail[0]
    if (first && typeof first.msg === "string") return first.msg
    return JSON.stringify(json.detail)
  }
  if (json.detail && typeof json.detail.msg === "string") return json.detail.msg
  return "Request failed"
}

async function request<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  }

  if (token) {
    headers["Authorization"] = `Bearer ${token}`
  }

  const res = await fetch(`${BASE_URL}${endpoint}`, {
    ...options,
    headers,
  })

  let json: any = null
  try {
    json = await res.json()
  } catch {
    json = null
  }

  if (!res.ok || json?.success === false) {
    if (res.status === 401 && typeof window !== "undefined") {
      localStorage.removeItem("access_token")
      localStorage.removeItem("user")
    }
    throw new ApiError(extractErrorMessage(json), res.status, json)
  }

  return json
}

export const api = {
  get: <T>(endpoint: string) => request<T>(endpoint),
  post: <T>(endpoint: string, body: unknown) =>
    request<T>(endpoint, { method: "POST", body: JSON.stringify(body) }),
  put: <T>(endpoint: string, body: unknown) =>
    request<T>(endpoint, { method: "PUT", body: JSON.stringify(body) }),
  patch: <T>(endpoint: string, body: unknown) =>
    request<T>(endpoint, { method: "PATCH", body: JSON.stringify(body) }),
  delete: <T>(endpoint: string) => request<T>(endpoint, { method: "DELETE" }),
}
