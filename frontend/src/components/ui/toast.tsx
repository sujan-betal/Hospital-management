"use client"

import React, { createContext, useContext, useState, useCallback } from "react"
import { CheckCircle2, AlertCircle, Info, X } from "lucide-react"

type ToastType = "success" | "error" | "info"

interface ToastItem {
  id: number
  type: ToastType
  title: string
  description?: string
}

interface ToastContextValue {
  success: (title: string, description?: string) => void
  error: (title: string, description?: string) => void
  info: (title: string, description?: string) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

const ICON = {
  success: <CheckCircle2 className="h-5 w-5 text-emerald-400 shrink-0" />,
  error: <AlertCircle className="h-5 w-5 text-red-400 shrink-0" />,
  info: <Info className="h-5 w-5 text-sky-400 shrink-0" />,
}

const STYLE = {
  success: "bg-[#12463E] border-emerald-600",
  error: "bg-[#3A0D0D] border-red-500",
  info: "bg-[#0F2A3A] border-sky-600",
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([])

  const dismiss = useCallback((id: number) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  const push = useCallback(
    (type: ToastType, title: string, description?: string) => {
      const id = Date.now() + Math.random()
      setToasts((prev) => [...prev.slice(-3), { id, type, title, description }])
      window.setTimeout(() => dismiss(id), 4500)
    },
    [dismiss]
  )

  const value: ToastContextValue = {
    success: (title, description) => push("success", title, description),
    error: (title, description) => push("error", title, description),
    info: (title, description) => push("info", title, description),
  }

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="fixed bottom-6 right-6 z-[100] flex flex-col gap-2.5 w-[340px] max-w-[calc(100vw-2rem)]">
        {toasts.map((t) => (
          <div
            key={t.id}
            role="status"
            className={`flex items-start gap-3 border text-white rounded-2xl px-4 py-3.5 shadow-xl shadow-[#0B2B26]/30 animate-fade-in ${STYLE[t.type]}`}
          >
            {ICON[t.type]}
            <div className="flex-1 min-w-0">
              <p className="text-xs font-black leading-snug">{t.title}</p>
              {t.description && (
                <p className="text-[10px] text-white/70 mt-0.5 leading-snug">{t.description}</p>
              )}
            </div>
            <button
              onClick={() => dismiss(t.id)}
              className="text-white/50 hover:text-white transition-colors shrink-0"
              aria-label="Dismiss"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast() {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error("useToast must be used within a ToastProvider")
  return ctx
}
