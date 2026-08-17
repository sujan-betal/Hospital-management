# 🌐 Web Frontend — AURA Medical Center

Production-ready **Next.js 16** client for the Hospital Management System.

## Quick Start

```bash
npm install
npm run dev        # http://localhost:3000
```

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server (Turbopack) |
| `npm run build` | Type-check + production build |
| `npm run start` | Serve production build |
| `npm run lint` | ESLint (Next core-web-vitals + TS rules) |

## Environment

Create `frontend/.env.local`:

```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

## Structure

```
src/
├── app/          # Next.js routes (/login, /admin, /doctor, ...)
├── components/   # shared UI components
├── features/     # per-domain feature components
├── services/     # typed API clients (all 65 backend endpoints)
├── store/        # auth store
└── lib/          # API request wrapper
```