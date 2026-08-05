"""Demo doctor directory for the patient booking panel.

Only inserted when the hospital has fewer than 5 active doctors, so a
real admin-created directory is never cluttered. Each demo doctor carries
a rating, review count and experience so patients can compare specialists.
"""

DEMO_DOCTORS = [
    {
        "user_name": "Dr. Aisha Mehta",
        "email": "aisha.mehta@auracare.demo",
        "phone": "+91 98110 00101",
        "department": "Cardiology",
        "rating": 4.9,
        "review_count": 182,
        "experience_years": 14,
        "role": "DOCTOR",
        "status": "ACTIVE",
    },
    {
        "user_name": "Dr. Rohan Kapoor",
        "email": "rohan.kapoor@auracare.demo",
        "phone": "+91 98110 00102",
        "department": "Neurology",
        "rating": 4.7,
        "review_count": 96,
        "experience_years": 11,
        "role": "DOCTOR",
        "status": "ACTIVE",
    },
    {
        "user_name": "Dr. Neha Sharma",
        "email": "neha.sharma@auracare.demo",
        "phone": "+91 98110 00103",
        "department": "Pediatrics",
        "rating": 4.8,
        "review_count": 154,
        "experience_years": 9,
        "role": "DOCTOR",
        "status": "ACTIVE",
    },
    {
        "user_name": "Dr. Arjun Nair",
        "email": "arjun.nair@auracare.demo",
        "phone": "+91 98110 00104",
        "department": "Orthopedics",
        "rating": 4.5,
        "review_count": 88,
        "experience_years": 12,
        "role": "DOCTOR",
        "status": "ACTIVE",
    },
    {
        "user_name": "Dr. Priya Verma",
        "email": "priya.verma@auracare.demo",
        "phone": "+91 98110 00105",
        "department": "Dermatology",
        "rating": 4.6,
        "review_count": 121,
        "experience_years": 8,
        "role": "DOCTOR",
        "status": "ACTIVE",
    },
    {
        "user_name": "Dr. Kabir Singh",
        "email": "kabir.singh@auracare.demo",
        "phone": "+91 98110 00106",
        "department": "General Medicine",
        "rating": 4.3,
        "review_count": 64,
        "experience_years": 10,
        "role": "DOCTOR",
        "status": "ACTIVE",
    },
]
