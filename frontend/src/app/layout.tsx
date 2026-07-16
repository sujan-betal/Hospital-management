import type { Metadata } from "next"
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
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
