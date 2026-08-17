<div align="center">

# 🏥 AURA Medical Center — Hospital Management System

**Full-stack hospital operations platform — appointments, billing, bed tracking, doctor payouts & patient care, powered by one API.**

Built for **3 clients** · Backend (FastAPI) · Web (Next.js) · Mobile (Flutter)

</div>

<br/>

<div align="center">

![FastAPI](https://img.shields.io/badge/FastAPI-0.116-009688?logo=fastapi&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-16-000000?logo=next.js&logoColor=white)
![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black)
![Flutter](https://img.shields.io/badge/Flutter-3.12-02569B?logo=flutter&logoColor=white)
![TailwindCSS](https://img.shields.io/badge/TailwindCSS-4-06B6D4?logo=tailwindcss&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript&logoColor=white)
![API Endpoints](https://img.shields.io/badge/API-65%20endpoints-7C3AED)
![License](https://img.shields.io/badge/License-Proprietary-blue)

</div>

---

## ✨ Overview

A production-style hospital management system with **five role-based dashboards**, exposed through **65 REST endpoints** and consumed by a **Next.js web app** and a **Flutter mobile app** side by side.

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
- **📱 Cross-platform mobile** — A Flutter companion app mirroring the web features (auth, admin, doctor, receptionist, patient, profile & dashboard).

---

## 🧰 Tech Stack

### 🐍 Backend — `backend/`
| Layer | Tech |
|-------|------|
| Framework | FastAPI + Uvicorn |
| ORM / DB | SQLAlchemy 2 (async) · Alembic migrations · PostgreSQL (Supabase-ready) |
| Auth | PyJWT (jose) · OTP via Twilio · SMTP via aiosmtplib / Gmail |
| Payments | Razorpay |
| Extras | slowapi (rate limiting), APScheduler, Pydantic v2 |

### 🌐 Web Frontend — `frontend/`
| Layer | Tech |
|-------|------|
| Framework | Next.js 16 (App Router, Turbopack) |
| UI | React 19 · Tailwind CSS v4 · lucide-react · Radix UI |
| Forms | react-hook-form + zod validation |
| State | Lightweight React context (auth store) |

### 📱 Mobile App — `flutter/`
| Layer | Tech |
|-------|------|
| Framework | Flutter 3.12 (Dart SDK ^3.12) |
| Networking | `http` package · centralized `ApiClient` with JWT + envelope unwrapping |
| Storage | `shared_preferences` (session persistence) |
| UI | Material 3 · `google_fonts` |
| Architecture | Feature-first + layered (`core/` · `data/` · `domain/` · `features/`) |

---

## 📁 Project Structure

```
Hospital-management/
├── backend/                     # FastAPI API server (65 endpoints)
│   ├── server.py                # FastAPI app, startup migrations + seeding
│   ├── alembic/                 # Schema migration versions
│   └── src/
│       ├── config/              # DB engine, session, settings
│       ├── middleware/          # JWT auth + role/permission guard
│       ├── models/              # SQLAlchemy models (11 entities)
│       ├── modules/
│       │   ├── admin/           # staff, doctors, permissions, revenue
│       │   ├── doctor/          # profile, bank details, earnings
│       │   ├── receptionist/    # patients, appointments, invoices, dashboard
│       │   ├── patient/         # OTP auth, booking, payments, reviews
│       │   └── hospital/        # beds, admissions, tasks, settings
│       └── utils/               # JWT helpers, security (password hashing)
│
├── frontend/                    # Next.js web application
│   └── src/
│       ├── app/                 # Next.js routes: /login, /admin, /doctor, ...
│       ├── components/          # shared UI components
│       ├── features/            # per-domain feature components
│       ├── services/            # typed API clients (65/65 endpoints)
│       ├── store/               # auth store
│       └── lib/                 # API request wrapper
│
├── flutter/                     # Flutter mobile application
│   └── lib/
│       ├── core/network/        # ApiClient (base URL, JWT, error handling)
│       ├── data/repositories/   # auth repository (session)
│       ├── features/
│       │   ├── admin/           # beds, admissions, tasks, staff, revenue
│       │   ├── doctor/          # earnings, bank details
│       │   ├── receptionist/    # patients, appointments, invoices
│       │   ├── patient/         # profile, booking, payments, reviews
│       │   ├── auth/            # login, OTP, password reset
│       │   └── ...              # dashboard, profile
│       └── routes/              # app navigation
│
├── docker-compose.yml           # backend:8000 + frontend:3000
└── .gitignore
```

---

## 🚀 Getting Started

### Option A — Docker (recommended for web stack)

```bash
docker compose up --build
```

| Service | URL |
|---------|-----|
| 🌐 Web Frontend | http://localhost:3000 |
| 🐍 Backend API | http://localhost:8000 |
| 📖 API Docs (Swagger) | http://localhost:8000/docs |

### Option B — Local development

**1. Backend**

```bash
cd backend
python -m venv .venv && .venv\Scripts\activate      # Windows
pip install -r requirements.txt
# create backend/.env (see "Environment Variables" below)
uvicorn server:app --reload --port 8000
```

**2. Web Frontend**

```bash
cd frontend
npm install
# create frontend/.env.local with NEXT_PUBLIC_API_URL=http://localhost:8000
npm run dev
```

**3. Flutter Mobile App**

```bash
cd flutter
flutter pub get
# optional: point at a local backend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000  # iOS / desktop
```

> The Flutter app defaults to the deployed backend (`https://hospital-management-96s6.onrender.com`). Use `--dart-define=API_BASE_URL=...` to override.

> On first boot the backend **auto-applies migrations** and **seeds demo data** (doctors, beds, patients, appointments, invoices) so every panel works immediately.

---

## 🔌 API Overview

All routes are prefixed with `/api` and are JWT-protected by role. **All 65 endpoints are wired up in both the web and mobile clients.**

| Module | Method + Endpoints |
|--------|---------------------|
| **Admin** | `POST /admin/register` · `POST /admin/login` · `GET/PUT/DELETE /admin/staff` · `GET /admin/doctors` · `POST /admin/doctors` · `POST /admin/subadmins` · `GET/PUT /admin/permissions` · `GET/POST/PUT/DELETE /admin/beds` · `/admin/admissions` · `/admin/tasks` · `GET/PUT /admin/settings` · `GET /admin/revenue` |
| **Doctor** | `POST /doctor/login` · `POST /doctor/forgot-password` · `POST /doctor/reset-password` · `GET/PUT /doctor/bank-details` · `GET /doctor/earnings` |
| **Receptionist** | `POST /receptionist/register` · `GET /receptionist/doctors` · `GET/PUT /receptionist/beds` · `GET/POST/PUT/DELETE /receptionist/appointments` · `/receptionist/invoices` · `GET /receptionist/dashboard` |
| **Patient** | `GET/POST/PUT/DELETE /patient` · `POST /patient/otp/send` · `POST /patient/otp/verify` · `GET/PUT /patient/me` · `GET /patient/doctors` · `GET/POST/PUT /patient/appointments` · `POST .../payment/order` · `POST .../payment/verify` · `GET /patient/invoices` · `GET/POST /patient/reviews` |
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

### Web Frontend (`frontend/.env.local`)
| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_API_URL` | Backend base URL (`http://localhost:8000`) |
| `NEXT_PUBLIC_SUPABASE_URL` | Optional Supabase auth |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Optional Supabase anon key |

### Mobile App (Flutter)
| Variable | Purpose |
|----------|---------|
| `API_BASE_URL` | Backend base URL via `--dart-define` (defaults to the deployed backend) |

---

## 🧪 Testing

### Backend
Automated in-process API smoke suite (75 checks covering every module, role enforcement, payment flow & cleanup):

```bash
cd backend
.venv\Scripts\python.exe "%TEMP%\opencode\api_test.py"
```

### Web Frontend
```bash
cd frontend
npm run build     # type-checks + production build
npm run lint      # ESLint (Next core-web-vitals + TS rules)
```

### Flutter
```bash
cd flutter
flutter analyze   # static analysis / lints
flutter test      # unit + widget tests
```

---

## 🗺️ Roadmap (suggested)

- [x] Role-based dashboards (admin / sub-admin / doctor / receptionist / patient)
- [x] OTP + JWT authentication flows
- [x] Razorpay payment integration with doctor revenue split
- [x] Web (Next.js) + Mobile (Flutter) clients on the same API
- [ ] CI/CD pipelines (GitHub Actions + Render deploys)
- [ ] End-to-end widget/integration tests
- [ ] Offline-first caching on mobile

---

## 📜 License

Proprietary — all rights reserved. See your organization's licensing terms before reuse.

---

<div align="center">
Built with ❤️ — <strong>AURA Medical Center & ICU</strong>
</div>