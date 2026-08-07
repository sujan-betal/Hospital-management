import { AuthProvider } from "@/store/auth.store"
import { ToastProvider } from "@/components/ui/toast"

export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <ToastProvider>{children}</ToastProvider>
    </AuthProvider>
  )
}
