import { HeartPulse } from "lucide-react"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { PatientLoginForm } from "@/features/auth/components/patient-login-form"
import { StaffLoginForm } from "@/features/auth/components/staff-login-form"

export default function LoginPage() {
  return (
    <Card className="w-full max-w-md border-none shadow-xl">
      <CardHeader className="text-center pb-2">
        <div className="flex justify-center mb-4">
          <div className="flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-600 to-blue-700 shadow-lg shadow-blue-200">
            <HeartPulse className="h-8 w-8 text-white" />
          </div>
        </div>
        <CardTitle className="text-xl text-foreground">
          Hospital Management System
        </CardTitle>
        <CardDescription>
          Sign in to access your account
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Tabs defaultValue="patient" className="w-full">
          <TabsList className="grid w-full grid-cols-2 mb-6">
            <TabsTrigger value="patient">Patient Login</TabsTrigger>
            <TabsTrigger value="staff">Staff Login</TabsTrigger>
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
