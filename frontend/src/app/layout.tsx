import type { Metadata } from "next"
import Providers from "@/providers"
import "./globals.css"

export const metadata: Metadata = {
  title: "Hospital Management System",
  description: "A comprehensive hospital management platform",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-screen bg-background text-foreground antialiased">
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
