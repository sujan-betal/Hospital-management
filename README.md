<div align="center">

# 🏥 AURA Medical Center — Hospital Management System

**A full-stack hospital management platform — appointments, billing, bed tracking, doctor payouts & patient care in one place.**

</div>

<div align="center">

![FastAPI](https://img.shields.io/badge/FastAPI-0.116-009688?logo=fastapi&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-16-000000?logo=next.js&logoColor=white)
![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black)
![TailwindCSS](https://img.shields.io/badge/TailwindCSS-4-06B6D4?logo=tailwindcss&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript&logoColor=white)
![License](https://img.shields.io/badge/License-Proprietary-blue)

</div>

---

## ✨ Overview

A production-style hospital management system with **five role-based dashboards**:

| Role | Access |
|------|--------|
| 👨‍⚕️ **Admin** | Staff & doctor directory, permissions, beds, admissions, tasks, settings, revenue & payouts |
| 🗂️ **Sub-Admin** | Same as Admin, scoped by a granular **permission system** |
| 🩺 **Doctor** | Profile, bank details, earnings split, appointments & reviews |
| 🧑‍💼 **Receptionist** | Patient registration, appointments, billing/invoices, bed status, dashboard |
| 🧍 **Patient** | OTP login, profile, doctor search, online booking, Razorpay checkout, reviews |

---

## 🧩 Features

- **🔐 Authentication** — JWT (access tokens) with role-based access control; OTP login for patients (Twilio); SMTP email flows for password setup & recovery.
- **🔑 Granular Permissions** — Sub-admins & staff are granted module-level permissions (beds, admissions, tasks, etc.) checked on every request.
- **📅 Appointments** — Receptionist & patient booking with **booked-slot conflict detection**, rescheduling, and status workflow (`scheduled → checked-in → completed`).
- **💳 Payments** — Razorpay order creation + signature verification; invoice generation; automatic **admin/doctor revenue split** (70/30).
- **🛏️ Bed & Admissions** — Bed occupancy tracking with automatic occupancy-rate reporting.
- **🧾 Billing** — Itemized invoices with paid/unpaid status and insurance flagging.
- **📊 Dashboard Analytics** — Today's visits, check-ins, billings, occupancy rate, pending tasks, admitted patients.
- **⭐ Doctor Reviews** — Patients rate completed visits; duplicate reviews rejected.
- **🚀 Self-healing startup** — Alembic migrations + demo-data seeding run automatically on boot.

---

## 🧰 Tech Stack

### Backend — `backend/`
| Layer | Tech |
|-------|------|
| Framework | FastAPI + Uvicorn |
| ORM / DB | SQLAlchemy 2 (async) · Alembic migrations · PostgreSQL (Supabase-ready) |
| Auth | PyJWT (jose) · OTP via Twilio · SMTP via aiosmtplib / Gmail |
| Payments | Razorpay |
| Extras | slowapi (rate limiting), APScheduler, Pydantic v2 |

### Frontend — `frontend/`
| Layer | Tech |
|-------|------|
| Framework | Next.js 16 (App Router, Turbopack) |
| UI | React 19 · Tailwind CSS v4 · lucide-react |
| Forms | react-hook-form + zod validation |
| State | Lightweight React context (auth store) |

---

## 📁 Project Structure

```
Hospital-management/
├── backend/
│   ├── server.py                 # FastAPI app, startup migrations + seeding
│   ├── alembic/                  # Schema migration versions
│   └── src/
│       ├── config/               # DB engine, session, settings
│       ├── middleware/           # JWT auth + role/permission guard
│       ├── models/               # SQLAlchemy models (11 entities)
│       ├── modules/
│       │   ├── admin/            # staff, doctors, permissions, beds, tasks, revenue
│       │   ├── doctor/           # profile, bank details, earnings
│       │   ├── receptionist/     # patients, appointments, invoices, dashboard
│       │   ├── patient/          # OTP auth, booking, payments, reviews
│       │   └── hospital/         # settings, admissions
│       └── utils/                # JWT helpers, security (password hashing)
│
├── frontend/
│   └── src/
│       ├── app/                  # Next.js routes: /login, /admin, /doctor, ...
│       ├── components/           # shared UI components
│       ├── features/             # per-domain feature components
│       ├── services/             # typed API clients (admin, doctor, receptionist, patient)
│       ├── store/                # auth store
│       └── lib/                  # API request wrapper
│
├── docker-compose.yml            # backend:8000 + frontend:3000
└── .gitignore
```

---

## 🚀 Getting Started

### Option A — Docker (recommended)

```bash
docker compose up --build
```

- Frontend → http://localhost:3000
- Backend → http://localhost:8000

### Option B — Local development

**1. Backend**

```bash
cd backend
python -m venv .venv && .venv\Scripts\activate      # Windows
pip install -r requirements.txt
# create backend/.env (see "Environment Variables" below)
uvicorn server:app --reload --port 8000
```

**2. Frontend**

```bash
cd frontend
npm install
# create frontend/.env.local with NEXT_PUBLIC_API_URL=http://localhost:8000
npm run dev
```

> On first boot the backend **auto-applies migrations** and **seeds demo data** (doctors, beds, patients, appointments, invoices) so every panel works immediately.

---

## 🔌 API Overview

All routes are prefixed with `/api` and are JWT-protected by role.

| Module | Endpoints (examples) |
|--------|----------------------|
| **Admin** | `POST /admin/register` · `/admin/login` · `GET /admin/staff` · `/admin/doctors` · `POST /admin/doctors` · `/admin/subadmins` · `PUT /admin/permissions` · `GET/POST/PUT /admin/beds` · `/admin/admissions` · `/admin/tasks` · `/admin/settings` · `GET /admin/revenue` |
| **Doctor** | `POST /doctor/login` · `POST /doctor/reset-password` · `POST /doctor/forgot-password` · `GET/PUT /doctor/bank-details` · `GET /doctor/earnings` |
| **Receptionist** | `POST /receptionist/register` · `GET/POST/PUT /receptionist/beds` · `/receptionist/appointments` · `/receptionist/invoices` · `GET /receptionist/dashboard` |
| **Patient** | `POST /patient` · `POST /patient/otp/send` · `/patient/otp/verify` · `GET/PUT /patient/me` · `POST /patient/appointments` · `POST .../payment/order` · `/payment/verify` · `POST /patient/reviews` |
| **System** | `GET /health` |

Interactive docs are auto-generated by FastAPI:

```
http://localhost:8000/docs
```

---

## ⚙️ Environment Variables

### Backend (`backend/.env`)
| Variable | Purpose |
|----------|---------|
| `PORT` | Uvicorn port (default `8005`, Docker uses `8000`) |
| `FRONTEND_URI` | CORS allow-list (comma separated) |
| `JWT_SECRET_KEY`, `JWT_ALGORITHM` | Token signing |
| `DATABASE_URL` | `postgresql+asyncpg://...` connection string |
| `TWILIO_*` | Patient OTP SMS |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Payment gateway (test keys work) |
| `SMTP_*`, `FROM_EMAIL` | Password-set / recovery emails |
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Optional Supabase integration |

### Frontend (`frontend/.env.local`)
| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_API_URL` | Backend base URL (`http://localhost:8000`) |
| `NEXT_PUBLIC_SUPABASE_URL` | Optional Supabase auth |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Optional Supabase anon key |

---

## 🧪 Testing

The backend ships with an automated in-process API smoke suite (75 checks covering every module, role enforcement, payment flow & cleanup):

```bash
cd backend
.venv\Scripts\python.exe "%TEMP%\opencode\api_test.py"
```

Frontend validation:

```bash
cd frontend
npm run build     # type-checks + production build
npm run lint      # ESLint (Next core-web-vitals + TS rules)
```

---

## 📜 License

Proprietary — all rights reserved. See your organization's licensing terms before reuse.

---

<div align="center">
Built with ❤️ — <strong>AURA Medical Center & ICU</strong>
</div>
