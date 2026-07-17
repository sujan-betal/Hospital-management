import { HeartPulse } from "lucide-react"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { PatientLoginForm } from "@/features/auth/components/patient-login-form"
import { StaffLoginForm } from "@/features/auth/components/staff-login-form"

export default function LoginPage() {
  return (
    <Card className="border-0 bg-white/95 backdrop-blur-xl shadow-2xl shadow-black/20">
      <CardHeader className="text-center pb-2 pt-8">
        <div className="flex justify-center mb-4">
          <div className="flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-600 to-indigo-600 shadow-lg shadow-blue-500/30 ring-1 ring-white/20">
            <HeartPulse className="h-8 w-8 text-white" />
          </div>
        </div>
        <CardTitle className="text-2xl font-bold text-gray-900">
          Hospital Management
        </CardTitle>
        <CardDescription className="text-gray-500 text-base">
          Sign in to access your account
        </CardDescription>
      </CardHeader>
      <CardContent className="pb-8 px-8">
        <Tabs defaultValue="patient" className="w-full">
          <TabsList className="grid w-full grid-cols-2 mb-8 bg-gray-100 p-1 rounded-xl">
            <TabsTrigger
              value="patient"
              className="flex items-center justify-center gap-2 rounded-lg data-[state=active]:bg-white data-[state=active]:shadow-sm data-[state=active]:text-blue-700 text-gray-500 py-2.5 text-sm font-medium transition-all"
            >
              <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" /></svg>
              Patient
            </TabsTrigger>
            <TabsTrigger
              value="staff"
              className="flex items-center justify-center gap-2 rounded-lg data-[state=active]:bg-white data-[state=active]:shadow-sm data-[state=active]:text-blue-700 text-gray-500 py-2.5 text-sm font-medium transition-all"
            >
              <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" /></svg>
              Staff
            </TabsTrigger>
          </TabsList>
          <TabsContent value="patient">
            <PatientLoginForm />
          </TabsContent>
          <TabsContent value="staff">
            <StaffLoginForm />
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  )
}
