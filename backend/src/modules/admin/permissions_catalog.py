"""Catalog of assignable permissions for sub-admin accounts.

Each permission maps to a functional area of the hospital admin console.
The frontend renders these as checkboxes when an admin creates or edits a
sub-admin, and the backend enforces them via
``src.middleware.auth.authorization(required_permissions=[...])``.

The special key ``ALL`` grants every permission and bypasses all checks.
"""

PERMISSION_CATALOG = [
    {
        "group": "Access",
        "items": [
            {
                "key": "ALL",
                "label": "Full Access",
                "description": "Unrestricted access to every module and permission",
            },
        ],
    },
    {
        "group": "Staff & Access Control",
        "items": [
            {
                "key": "STAFF_MANAGE",
                "label": "Staff Management",
                "description": "Create, edit, suspend and delete staff accounts",
            },
            {
                "key": "SUBADMIN_CREATE",
                "label": "Sub-admin Creation",
                "description": "Create sub-admin accounts and assign their permissions",
            },
            {
                "key": "DOCTOR_MANAGE",
                "label": "Doctor Directory",
                "description": "View and manage the doctor directory",
            },
        ],
    },
    {
        "group": "Patients & Appointments",
        "items": [
            {
                "key": "PATIENT_MANAGE",
                "label": "Patient Management",
                "description": "View and manage patient records",
            },
            {
                "key": "APPOINTMENT_MANAGE",
                "label": "Appointments & OPD",
                "description": "Manage OPD appointments and patient visits",
            },
            {
                "key": "REVIEW_MANAGE",
                "label": "Patient Reviews",
                "description": "View and manage patient reviews and doctor ratings",
            },
        ],
    },
    {
        "group": "Hospital Operations",
        "items": [
            {
                "key": "ADMISSION_MANAGE",
                "label": "Admissions",
                "description": "Manage patient admissions, discharges and cancellations",
            },
            {
                "key": "BED_MANAGE",
                "label": "Wards & Beds",
                "description": "Manage wards, beds and bed occupancy",
            },
            {
                "key": "TASK_MANAGE",
                "label": "Clinical Tasks",
                "description": "Manage clinical and housekeeping tasks",
            },
        ],
    },
    {
        "group": "Billing & Settings",
        "items": [
            {
                "key": "INVOICE_MANAGE",
                "label": "Billing & Invoices",
                "description": "Manage invoices and billing records",
            },
            {
                "key": "SETTINGS_MANAGE",
                "label": "Hospital Settings",
                "description": "Manage hospital configuration and settings",
            },
        ],
    },
]

# Flat set of every assignable permission key for validation.
PERMISSION_KEYS = {
    item["key"] for group in PERMISSION_CATALOG for item in group["items"]
}

# Keys that are never sent to the Permission table because they are implicit.
# "ALL" is stored on purpose (the middleware treats it as a wildcard).
_ALL_PERMISSIONS = {"ALL"}


def normalize_permissions(permissions) -> list[str]:
    """Validate and normalize a permission list against the catalog.

    Returns a de-duplicated, uppercased list containing only known keys.
    If ``ALL`` is present it is returned on its own (it already grants
    everything, so extra keys are redundant).
    """
    if not permissions:
        return []

    keys = {str(p).strip().upper() for p in permissions if str(p).strip()}
    keys &= PERMISSION_KEYS

    if "ALL" in keys:
        return ["ALL"]

    return sorted(keys)
