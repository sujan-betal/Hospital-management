"""Demo seed data for the receptionist front-desk dashboard.

Only inserted when the corresponding tables are empty so it is safe to
run on every startup.
"""

SEED_PATIENTS = [
    {
        "user_name": "Emma Watson",
        "email": "emma.watson@gmail.com",
        "phone": "+1 (555) 019-2834",
        "password": None,
        "age": 32,
        "gender": "Female",
        "insurance_provider": "BlueCross Health",
        "role": "PATIENT",
        "status": "ACTIVE",
    },
    {
        "user_name": "Liam Neeson",
        "email": "liam@taken.com",
        "phone": "+44 7911 123456",
        "password": None,
        "age": 68,
        "gender": "Male",
        "insurance_provider": "Aetna Premium",
        "role": "PATIENT",
        "status": "ACTIVE",
    },
    {
        "user_name": "Robert Downey Jr.",
        "email": "rdj@stark.com",
        "phone": "+1 (555) 300-3000",
        "password": None,
        "age": 55,
        "gender": "Male",
        "insurance_provider": "Star Health Assurance",
        "role": "PATIENT",
        "status": "ACTIVE",
    },
    {
        "user_name": "Scarlett Johansson",
        "email": "scarlett@avengers.org",
        "phone": "+1 (555) 102-8822",
        "password": None,
        "age": 36,
        "gender": "Female",
        "insurance_provider": "MetLife Shield",
        "role": "PATIENT",
        "status": "ACTIVE",
    },
]

SEED_APPOINTMENTS = [
    {
        "appointment_id": "APT-901",
        "patient_name": "Emma Watson",
        "patient_phone": "+1 (555) 019-2834",
        "doctor_name": "Dr. Gregory House",
        "specialty": "General Medicine",
        "date": "2026-07-20",
        "time": "10:15 AM",
        "status": "CHECKED-IN",
    },
    {
        "appointment_id": "APT-902",
        "patient_name": "Liam Neeson",
        "patient_phone": "+44 7911 123456",
        "doctor_name": "Dr. Stephen Strange",
        "specialty": "Cardiology",
        "date": "2026-07-20",
        "time": "11:00 AM",
        "status": "SCHEDULED",
    },
    {
        "appointment_id": "APT-903",
        "patient_name": "Robert Downey Jr.",
        "patient_phone": "+1 (555) 300-3000",
        "doctor_name": "Dr. Gregory House",
        "specialty": "General Medicine",
        "date": "2026-07-20",
        "time": "09:30 AM",
        "status": "CHECKED-IN",
    },
    {
        "appointment_id": "APT-904",
        "patient_name": "Scarlett Johansson",
        "patient_phone": "+1 (555) 102-8822",
        "doctor_name": "Dr. Allison Cameron",
        "specialty": "Pediatrics",
        "date": "2026-07-20",
        "time": "11:45 AM",
        "status": "SCHEDULED",
    },
]

SEED_INVOICES = [
    {
        "invoice_id": "INV-401",
        "patient_name": "Robert Downey Jr.",
        "date": "2026-07-20",
        "amount": 850,
        "items": '[{"description": "General Consultation (OPD)", "cost": 150}, '
                 '{"description": "ECG Diagnostic Scan", "cost": 300}, '
                 '{"description": "Cardiology Telemetry Hookup", "cost": 400}]',
        "insurance_status": "COVERED",
        "payment_status": "PAID",
    },
    {
        "invoice_id": "INV-402",
        "patient_name": "Emma Watson",
        "date": "2026-07-20",
        "amount": 450,
        "items": '[{"description": "General Consultation (OPD)", "cost": 150}, '
                 '{"description": "CBC Blood Panel", "cost": 300}]',
        "insurance_status": "PENDING",
        "payment_status": "UNPAID",
    },
]
