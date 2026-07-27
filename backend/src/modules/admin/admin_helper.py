from typing import Dict, Any
from src.models.admin_model import Admin

def format_admin_data(admin: Admin) -> Dict[str, Any]:
    """
    Format the admin object into a standard dictionary response.
    """
    return {
        "id": admin.id,
        "user_name": admin.user_name,
        "email": admin.email,
        "user_id": str(admin.user_id),
        "role": admin.role,
        "status": admin.status
    }
