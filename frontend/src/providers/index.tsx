import { AuthProvider } from "@/store/auth.store"

export default function Providers({ children }: { children: React.ReactNode }) {
  return <AuthProvider>{children}</AuthProvider>
}