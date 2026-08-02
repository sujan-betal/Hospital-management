export interface Bed {
  id: string
  ward: "ICU" | "Emergency" | "General Ward" | "Pediatrics" | "Maternity"
  status: "available" | "occupied" | "sanitizing" | "reserved"
  price: number
  floor: number
  assignedNurse: string
  equipment: string[]
  patient: string | null
}

export interface Admission {
  id: string
  patientName: string
  patientAge: number
  patientGender: "Male" | "Female" | "Other"
  wardType: "ICU" | "Emergency" | "General Ward" | "Pediatrics" | "Maternity"
  bedId: string
  admitDate: string
  dischargeDate: string
  billingAmount: number
  status: "admitted" | "scheduled" | "discharged" | "cancelled"
  insuranceStatus: "covered" | "uninsured" | "pending"
  patientEmail: string
  patientPhone: string
}

export interface Doctor {
  id: string
  name: string
  specialty: "Cardiology" | "Neurology" | "Pediatrics" | "Orthopedics" | "General Medicine"
  status: "On Duty" | "On Call" | "Off Duty"
  activePatients: number
  email: string
  phone: string
}

export interface MedicalTask {
  id: string
  bedId: string
  task: string
  priority: "low" | "medium" | "high" | "emergency"
  assignedTo: string
  status: "pending" | "in-progress" | "completed"
  type: "nursing" | "lab-test" | "pharmacy" | "sanitization"
  timestamp: string
}

export const initialBeds: Bed[] = [
  { id: "ICU-101", ward: "ICU", status: "occupied", price: 850, floor: 1, assignedNurse: "Nurse Sarah Jenkins", equipment: ["Ventilator", "Cardiac Monitor", "Oxygen Infusion"], patient: "Robert Downey Jr." },
  { id: "ICU-102", ward: "ICU", status: "available", price: 850, floor: 1, assignedNurse: "Nurse Sarah Jenkins", equipment: ["Ventilator", "Cardiac Monitor", "Defibrillator"], patient: null },
  { id: "ER-201", ward: "Emergency", status: "occupied", price: 400, floor: 2, assignedNurse: "Nurse David Vance", equipment: ["Oxygen Port", "IV Stand", "Suction Unit"], patient: "Liam Neeson" },
  { id: "ER-202", ward: "Emergency", status: "sanitizing", price: 400, floor: 2, assignedNurse: "Nurse David Vance", equipment: ["Oxygen Port", "IV Stand"], patient: null },
  { id: "GEN-301", ward: "General Ward", status: "occupied", price: 150, floor: 3, assignedNurse: "Nurse Maria Gomez", equipment: ["IV Stand", "Calling Button"], patient: "Emma Watson" },
  { id: "GEN-302", ward: "General Ward", status: "available", price: 150, floor: 3, assignedNurse: "Nurse Maria Gomez", equipment: ["IV Stand", "Calling Button"], patient: null },
  { id: "GEN-303", ward: "General Ward", status: "reserved", price: 150, floor: 3, assignedNurse: "Nurse Maria Gomez", equipment: ["IV Stand", "Telemetry Hookup"], patient: null },
  { id: "PED-401", ward: "Pediatrics", status: "occupied", price: 200, floor: 4, assignedNurse: "Nurse John Doe", equipment: ["Oxygen Port", "Pediatric Pulse-Ox"], patient: "Tommy Watson" },
  { id: "PED-402", ward: "Pediatrics", status: "available", price: 200, floor: 4, assignedNurse: "Nurse John Doe", equipment: ["Oxygen Port"], patient: null },
  { id: "MAT-501", ward: "Maternity", status: "occupied", price: 300, floor: 5, assignedNurse: "Nurse Sarah Jenkins", equipment: ["Fetal Monitor", "Neonatal Warmer"], patient: "Scarlett Johansson" },
]

export const initialAdmissions: Admission[] = [
  { id: "ADM-8392", patientName: "Emma Watson", patientAge: 32, patientGender: "Female", wardType: "General Ward", bedId: "GEN-301", admitDate: "2026-07-15", dischargeDate: "2026-07-22", billingAmount: 1050, status: "admitted", insuranceStatus: "covered", patientEmail: "emma.watson@gmail.com", patientPhone: "+1 (555) 019-2834" },
  { id: "ADM-9481", patientName: "Liam Neeson", patientAge: 68, patientGender: "Male", wardType: "Emergency", bedId: "ER-201", admitDate: "2026-07-19", dischargeDate: "2026-07-24", billingAmount: 2000, status: "admitted", insuranceStatus: "pending", patientEmail: "liam@taken.com", patientPhone: "+44 7911 123456" },
  { id: "ADM-4829", patientName: "Scarlett Johansson", patientAge: 36, patientGender: "Female", wardType: "Maternity", bedId: "MAT-501", admitDate: "2026-07-18", dischargeDate: "2026-07-25", billingAmount: 2100, status: "admitted", insuranceStatus: "covered", patientEmail: "scarlett@avengers.org", patientPhone: "+1 (555) 102-8822" },
  { id: "ADM-1049", patientName: "Robert Downey Jr.", patientAge: 55, patientGender: "Male", wardType: "ICU", bedId: "ICU-101", admitDate: "2026-07-17", dischargeDate: "2026-07-21", billingAmount: 3400, status: "admitted", insuranceStatus: "covered", patientEmail: "rdj@stark.com", patientPhone: "+1 (555) 300-3000" },
  { id: "ADM-1102", patientName: "Leonardo DiCaprio", patientAge: 47, patientGender: "Male", wardType: "ICU", bedId: "ICU-102", admitDate: "2026-07-21", dischargeDate: "2026-07-28", billingAmount: 5950, status: "scheduled", insuranceStatus: "uninsured", patientEmail: "leo@di-caprio.com", patientPhone: "+1 (555) 987-6543" },
  { id: "ADM-5819", patientName: "Brad Pitt", patientAge: 56, patientGender: "Male", wardType: "General Ward", bedId: "GEN-302", admitDate: "2026-07-10", dischargeDate: "2026-07-14", billingAmount: 600, status: "discharged", insuranceStatus: "covered", patientEmail: "pitt@brad.net", patientPhone: "+1 (555) 321-7654" },
  { id: "ADM-9901", patientName: "Will Smith", patientAge: 52, patientGender: "Male", wardType: "Emergency", bedId: "ER-202", admitDate: "2026-07-12", dischargeDate: "2026-07-13", billingAmount: 400, status: "cancelled", insuranceStatus: "uninsured", patientEmail: "freshprince@will.com", patientPhone: "+1 (555) 111-2222" },
]

export const initialDoctors: Doctor[] = [
  { id: "DOC-001", name: "Dr. Gregory House", specialty: "General Medicine", status: "On Duty", activePatients: 4, email: "house@aura-med.org", phone: "+1 (555) 123-9081" },
  { id: "DOC-002", name: "Dr. Meredith Grey", specialty: "Neurology", status: "On Duty", activePatients: 2, email: "grey@aura-med.org", phone: "+1 (555) 345-1234" },
  { id: "DOC-003", name: "Dr. Shaun Murphy", specialty: "Orthopedics", status: "On Duty", activePatients: 1, email: "murphy@aura-med.org", phone: "+1 (555) 890-4321" },
  { id: "DOC-004", name: "Dr. Stephen Strange", specialty: "Cardiology", status: "On Call", activePatients: 1, email: "strange@aura-med.org", phone: "+1 (555) 456-7890" },
  { id: "DOC-005", name: "Dr. Allison Cameron", specialty: "Pediatrics", status: "Off Duty", activePatients: 0, email: "cameron@aura-med.org", phone: "+1 (555) 789-0123" },
]

export const initialMedicalTasks: MedicalTask[] = [
  { id: "TSK-8812", bedId: "ICU-101", task: "Administer 10ml Epinephrine and monitor blood pressure", priority: "emergency", assignedTo: "Nurse Sarah Jenkins", status: "in-progress", type: "nursing", timestamp: "10:30 AM" },
  { id: "TSK-8813", bedId: "MAT-501", task: "Deliver prescribed post-natal antibiotics from pharmacy", priority: "high", assignedTo: "Nurse Sarah Jenkins", status: "pending", type: "pharmacy", timestamp: "12:15 PM" },
  { id: "TSK-8814", bedId: "ER-202", task: "Sanitize bed post discharge and replace sheets", priority: "medium", assignedTo: "Nurse David Vance", status: "pending", type: "sanitization", timestamp: "11:45 AM" },
  { id: "TSK-8815", bedId: "GEN-301", task: "Collect blood samples for comprehensive CBC and glucose test", priority: "high", assignedTo: "Nurse Maria Gomez", status: "completed", type: "lab-test", timestamp: "08:15 AM" },
  { id: "TSK-8816", bedId: "PED-401", task: "Administer saline nebulizer", priority: "low", assignedTo: "Nurse John Doe", status: "completed", type: "nursing", timestamp: "09:30 AM" },
]

/* ─── Staff Credentials ─── */
export interface StaffCredential {
  id: string
  user_id?: string
  fullName: string
  role: "doctor" | "receptionist" | "subadmin" | "admin"
  email: string
  phone: string
  department: string
  employeeId: string
  status: "active" | "suspended" | "inactive"
  createdAt: string
  lastLogin: string | null
}

export const initialStaffCredentials: StaffCredential[] = [
  {
    id: "CRED-001",
    fullName: "Dr. Gregory House",
    role: "doctor",
    email: "house@auramedical.org",
    phone: "+91 98765 43210",
    department: "General Medicine",
    employeeId: "EMP-D001",
    status: "active",
    createdAt: "2026-01-15",
    lastLogin: "2026-07-20 09:15 AM"
  },
  {
    id: "CRED-002",
    fullName: "Dr. Meredith Grey",
    role: "doctor",
    email: "grey@auramedical.org",
    phone: "+91 98765 43211",
    department: "Neurology",
    employeeId: "EMP-D002",
    status: "active",
    createdAt: "2026-02-10",
    lastLogin: "2026-07-19 03:42 PM"
  },
  {
    id: "CRED-003",
    fullName: "Dr. Stephen Strange",
    role: "doctor",
    email: "strange@auramedical.org",
    phone: "+91 98765 43212",
    department: "Cardiology",
    employeeId: "EMP-D003",
    status: "active",
    createdAt: "2026-03-05",
    lastLogin: "2026-07-18 11:00 AM"
  },
  {
    id: "CRED-004",
    fullName: "Priya Sharma",
    role: "receptionist",
    email: "priya.sharma@auramedical.org",
    phone: "+91 91234 56789",
    department: "Front Desk - OPD",
    employeeId: "EMP-R001",
    status: "active",
    createdAt: "2026-01-20",
    lastLogin: "2026-07-20 08:30 AM"
  },
  {
    id: "CRED-005",
    fullName: "Rahul Verma",
    role: "receptionist",
    email: "rahul.verma@auramedical.org",
    phone: "+91 91234 56790",
    department: "Front Desk - Emergency",
    employeeId: "EMP-R002",
    status: "active",
    createdAt: "2026-04-12",
    lastLogin: "2026-07-20 07:45 AM"
  },
  {
    id: "CRED-006",
    fullName: "Dr. Allison Cameron",
    role: "doctor",
    email: "cameron@auramedical.org",
    phone: "+91 98765 43213",
    department: "Pediatrics",
    employeeId: "EMP-D004",
    status: "inactive",
    createdAt: "2026-02-28",
    lastLogin: null
  },
  {
    id: "CRED-007",
    fullName: "Anita Desai",
    role: "receptionist",
    email: "anita.desai@auramedical.org",
    phone: "+91 91234 56791",
    department: "Front Desk - Maternity",
    employeeId: "EMP-R003",
    status: "suspended",
    createdAt: "2026-05-01",
    lastLogin: "2026-06-15 04:20 PM"
  },
]

