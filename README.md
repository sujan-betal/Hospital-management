# 🏥 Hospital Management System

A full-stack hospital management application for managing patients, doctors, appointments, and billing.

## Features

- 🩺 Doctor & specialty management
- 📅 Appointment booking and scheduling
- 👤 Patient records management
- 💳 Billing and payment tracking
- 🔐 Role-based authentication (Admin, Doctor, Staff)

## Tech Stack

**Frontend**
- Next.js (TypeScript)
- Tailwind CSS

**Backend**
- FastAPI (Python)
- PostgreSQL

**Deployment**
- Frontend: Vercel
- Backend: Render
- Containerization: Docker (see `docker-compose.yml`)

## Project Structure



Hospital-management/
├── backend/ # FastAPI backend (Python)
├── frontend/ # Next.js frontend (TypeScript)
├── docker-compose.yml
└── .gitignore


## Getting Started

### Prerequisites
- Node.js 18+
- Python 3.10+
- PostgreSQL

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### Frontend Setup
```bash
cd frontend
npm install
npm run dev
```

### Environment Variables

Create a `.env` file in both `frontend/` and `backend/` — see `.env.example` (if provided) for required keys such as `DATABASE_URL`, `NEXT_PUBLIC_API_URL`, etc.

## Live Demo

🔗 [View Production](https://hospital-management-hzeh5wvbn-sujan-betals-projects.vercel.app)

## Contributors

- [Sujan-Codenet](https://github.com/sujan-codenet)
- [sujan-betal](https://github.com/sujan-betal)

## License

This project is currently unlicensed / private use.


## Getting Started

### Prerequisites
- Node.js 18+
- Python 3.10+
- PostgreSQL

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### Frontend Setup
```bash
cd frontend
npm install
npm run dev
```

### Environment Variables

Create a `.env` file in both `frontend/` and `backend/` — see `.env.example` (if provided) for required keys such as `DATABASE_URL`, `NEXT_PUBLIC_API_URL`, etc.



## Contributors
- [sujan-betal](https://github.com/sujan-betal)

## License

This project is currently unlicensed / private use.
