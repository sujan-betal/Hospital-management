"use client"

import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from "react"
import { loginStaff, registerAdmin, type AdminData, type LoginPayload, type RegisterPayload } from "@/services/auth.service"

interface AuthState {
  user: AdminData | null
  token: string | null
  loading: boolean
}

interface AuthContextType extends AuthState {
  login: (payload: LoginPayload) => Promise<void>
  register: (payload: RegisterPayload) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({
    user: null,
    token: null,
    loading: true,
  })

  useEffect(() => {
    const token = localStorage.getItem("access_token")
    const user = localStorage.getItem("user")
    if (token && user) {
      setState({ user: JSON.parse(user), token, loading: false })
    } else {
      setState((prev) => ({ ...prev, loading: false }))
    }
  }, [])

  const login = useCallback(async (payload: LoginPayload) => {
    const res = await loginStaff(payload)
    const { access_token, ...userData } = res.data
    if (access_token) {
      localStorage.setItem("access_token", access_token)
      localStorage.setItem("user", JSON.stringify(userData))
      setState({ user: userData, token: access_token, loading: false })
    }
  }, [])

  const register = useCallback(async (payload: RegisterPayload) => {
    await registerAdmin(payload)
  }, [])

  const logout = useCallback(() => {
    localStorage.removeItem("access_token")
    localStorage.removeItem("user")
    setState({ user: null, token: null, loading: false })
  }, [])

  return (
    <AuthContext.Provider value={{ ...state, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error("useAuth must be used within AuthProvider")
  return ctx
}
