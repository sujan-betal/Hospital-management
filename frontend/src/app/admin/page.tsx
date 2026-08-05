"use client"

import React, { useEffect, useState } from "react"
import { Sidebar } from "./components/Sidebar"
import { Navbar } from "./components/Navbar"
import { Overview } from "./components/Overview"
import { WardsAndBeds } from "./components/WardsAndBeds"
import { PatientAdmissions } from "./components/PatientAdmissions"
import { AttendingDoctors } from "./components/AttendingDoctors"
import { ClinicalTasks } from "./components/ClinicalTasks"
import { StaffCredentials } from "./components/StaffCredentials"
import { HospitalSettings } from "./components/HospitalSettings"
import { Payments } from "./components/Payments"
import RequireAuth from "@/components/RequireAuth"
import {
  initialBeds,
  initialAdmissions,
  initialDoctors,
  initialMedicalTasks,
  initialStaffCredentials,
  Bed,
  Admission,
  Doctor,
  MedicalTask,
  StaffCredential
} from "./mockData"
import {
  listBeds,
  createBed,
  updateBed as updateBedApi,
  deleteBed as deleteBedApi,
  ApiBed,
  BedCreatePayload,
  BedUpdatePayload,
} from "@/services/admin.service"

// Map the backend snake_case bed record onto the camelCase Bed shape
// the admin components render.
function fromApiBed(b: ApiBed): Bed {
  return {
    id: b.bed_id,
    ward: b.ward,
    status: b.status.toLowerCase() as Bed["status"],
    price: b.price,
    floor: b.floor,
    assignedNurse: b.assigned_nurse || "",
    equipment: b.equipment || [],
    patient: b.patient,
  }
}

export default function AdminDashboard() {
  const [activeTab, setActiveTab] = useState<string>("overview")
  
  // Hospital-wide state
  const [beds, setBeds] = useState<Bed[]>(initialBeds)
  const [bedsLoading, setBedsLoading] = useState(true)
  const [admissions, setAdmissions] = useState<Admission[]>(initialAdmissions)
  const [doctors, setDoctors] = useState<Doctor[]>(initialDoctors)
  const [tasks, setTasks] = useState<MedicalTask[]>(initialMedicalTasks)
  const [staffCredentials, setStaffCredentials] = useState<StaffCredential[]>(initialStaffCredentials)

  // Modal triggers
  const [isAddAdmissionOpen, setIsAddAdmissionOpen] = useState(false)
  const [isAddTaskOpen, setIsAddTaskOpen] = useState(false)

  // Load live beds from the backend on mount. Falls back to demo data
  // only when the request fails (offline / not authenticated).
  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await listBeds()
        if (!cancelled && res.data) setBeds(res.data.map(fromApiBed))
      } catch {
        // keep initialBeds
      } finally {
        if (!cancelled) setBedsLoading(false)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [])

  // Handle Updates
  const handleUpdateBed = async (updatedBed: Bed) => {
    const payload: BedUpdatePayload = {
      ward: updatedBed.ward,
      status: updatedBed.status.toUpperCase(),
      price: updatedBed.price,
      floor: updatedBed.floor,
      assigned_nurse: updatedBed.assignedNurse,
      equipment: updatedBed.equipment,
      patient: updatedBed.status !== "occupied" ? null : updatedBed.patient,
    }
    try {
      const res = await updateBedApi(updatedBed.id, payload)
      setBeds((prev) =>
        prev.map((b) => (b.id === updatedBed.id ? fromApiBed(res.data) : b))
      )
    } catch (err: any) {
      alert(err?.message || "Failed to update bed")
    }
  }

  const handleAddBed = async (newBed: Bed) => {
    const payload: BedCreatePayload = {
      bed_id: newBed.id,
      ward: newBed.ward,
      status: newBed.status.toUpperCase(),
      price: newBed.price,
      floor: newBed.floor,
      assigned_nurse: newBed.assignedNurse || null,
      equipment: newBed.equipment,
      patient: newBed.status === "occupied" ? newBed.patient : null,
    }
    try {
      const res = await createBed(payload)
      setBeds((prev) => [fromApiBed(res.data), ...prev])
      return true
    } catch (err: any) {
      alert(err?.message || "Failed to add bed")
      return false
    }
  }

  const handleDeleteBed = async (bedId: string) => {
    try {
      await deleteBedApi(bedId)
      setBeds((prev) => prev.filter((b) => b.id !== bedId))
      return true
    } catch (err: any) {
      alert(err?.message || "Failed to delete bed")
      return false
    }
  }

  const handleAddAdmission = (newAdm: Admission) => {
    setAdmissions([newAdm, ...admissions])
    
    // Side effect: if bed was allocated directly, mark it as occupied
    if (newAdm.bedId !== "Pending" && newAdm.status === "admitted") {
      setBeds(beds.map(b => b.id === newAdm.bedId ? { ...b, status: "occupied", patient: newAdm.patientName } : b))
    }

    // Side effect: increase doctor load (General Medicine default or matching specialty)
    setDoctors(doctors.map(d => {
      if (d.specialty === "General Medicine" && newAdm.wardType === "General Ward") {
        return { ...d, activePatients: d.activePatients + 1 }
      }
      if (d.specialty === "Cardiology" && newAdm.wardType === "ICU") {
        return { ...d, activePatients: d.activePatients + 1 }
      }
      return d
    }))
  }

  const handleUpdateAdmission = (updatedAdm: Admission) => {
    setAdmissions(admissions.map((adm) => (adm.id === updatedAdm.id ? updatedAdm : adm)))

    // Side effects:
    if (updatedAdm.status === "admitted") {
      // Mark assigned bed as occupied
      setBeds(beds.map(b => b.id === updatedAdm.bedId ? { ...b, status: "occupied", patient: updatedAdm.patientName } : b))
    } else if (updatedAdm.status === "discharged") {
      // Mark bed as sanitizing
      setBeds(beds.map(b => b.id === updatedAdm.bedId ? { ...b, status: "sanitizing", patient: null } : b))
      
      // Auto dispatch sanitization task
      const now = new Date()
      const timestamp = now.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", hour12: true })
      const autoCleanTask: MedicalTask = {
        id: `TSK-${Math.floor(1000 + Math.random() * 9000)}`,
        bedId: updatedAdm.bedId,
        task: "Post-discharge sanitization and sterile linen replacement",
        priority: "medium",
        assignedTo: beds.find(b => b.id === updatedAdm.bedId)?.assignedNurse || "Nurse Sarah Jenkins",
        status: "pending",
        type: "sanitization",
        timestamp
      }
      setTasks([autoCleanTask, ...tasks])

      // Decrease Doctor Patient Load
      setDoctors(doctors.map(d => {
        if (d.specialty === "General Medicine" && updatedAdm.wardType === "General Ward") {
          return { ...d, activePatients: Math.max(0, d.activePatients - 1) }
        }
        if (d.specialty === "Cardiology" && updatedAdm.wardType === "ICU") {
          return { ...d, activePatients: Math.max(0, d.activePatients - 1) }
        }
        return d
      }))
    } else if (updatedAdm.status === "cancelled") {
      // Free the bed if it was assigned
      if (updatedAdm.bedId !== "Pending") {
        setBeds(beds.map(b => b.id === updatedAdm.bedId ? { ...b, status: "available", patient: null } : b))
      }
    }
  }

  const handleAddTask = (newTask: MedicalTask) => {
    setTasks([newTask, ...tasks])

    // Side effect: update bed status based on task type
    if (newTask.type === "sanitization") {
      setBeds(beds.map(b => b.id === newTask.bedId ? { ...b, status: "sanitizing", assignedNurse: newTask.assignedTo } : b))
    }
  }

  const handleUpdateTask = (updatedTask: MedicalTask) => {
    setTasks(tasks.map((t) => (t.id === updatedTask.id ? updatedTask : t)))

    // Side effect: if sanitization complete, mark bed available
    if (updatedTask.status === "completed" && updatedTask.type === "sanitization") {
      setBeds(beds.map(b => b.id === updatedTask.bedId ? { ...b, status: "available" } : b))
    }
  }

  // Active View Switcher
  const renderActiveView = () => {
    switch (activeTab) {
      case "overview":
        return (
          <Overview
            beds={beds}
            admissions={admissions}
            tasks={tasks}
            onNavigate={(tab) => setActiveTab(tab)}
            onAddAdmissionClick={() => {
              setActiveTab("admissions")
              setIsAddAdmissionOpen(true)
            }}
            onAddTaskClick={() => {
              setActiveTab("tasks")
              setIsAddTaskOpen(true)
            }}
          />
        )
      case "beds":
        return (
          <WardsAndBeds
            beds={beds}
            loading={bedsLoading}
            onAddBed={handleAddBed}
            onUpdateBed={handleUpdateBed}
            onDeleteBed={handleDeleteBed}
          />
        )
      case "admissions":
        return (
          <PatientAdmissions
            reservations={admissions}
            rooms={beds}
            onAddReservation={handleAddAdmission}
            onUpdateReservation={handleUpdateAdmission}
            isCreateOpen={isAddAdmissionOpen}
            setIsCreateOpen={setIsAddAdmissionOpen}
          />
        )
      case "doctors":
        return <AttendingDoctors guests={doctors} />
      case "tasks":
        return (
          <ClinicalTasks
            tasks={tasks}
            onAddTask={handleAddTask}
            onUpdateTask={handleUpdateTask}
            isCreateOpen={isAddTaskOpen}
            setIsCreateOpen={setIsAddTaskOpen}
          />
        )
      case "credentials":
        return (
          <StaffCredentials
            credentials={staffCredentials}
            onAddCredential={(cred) => setStaffCredentials([cred, ...staffCredentials])}
            onUpdateCredential={(cred) => setStaffCredentials(staffCredentials.map(c => c.id === cred.id ? cred : c))}
            onDeleteCredential={(id) => setStaffCredentials(staffCredentials.filter(c => c.id !== id))}
          />
        )
      case "settings":
        return <HospitalSettings />
      case "payments":
        return <Payments />
      default:
        return (
          <Overview
            beds={beds}
            admissions={admissions}
            tasks={tasks}
            onNavigate={(tab) => setActiveTab(tab)}
            onAddAdmissionClick={() => {
              setActiveTab("admissions")
              setIsAddAdmissionOpen(true)
            }}
            onAddTaskClick={() => {
              setActiveTab("tasks")
              setIsAddTaskOpen(true)
            }}
          />
        )
    }
  }

  return (
    <RequireAuth>
      <div className="flex min-h-screen bg-[#F6F8F7]">
        {/* Sidebar navigation panel */}
        <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

        {/* Main Workspace */}
        <div className="flex-1 flex flex-col min-w-0">
          {/* Top Navbar */}
          <Navbar activeTab={activeTab} />

          {/* Tab content wrapper */}
          <main className="flex-1 p-8 overflow-y-auto max-w-[1600px] w-full mx-auto">
            {renderActiveView()}
          </main>
        </div>
      </div>
    </RequireAuth>
  )
}
