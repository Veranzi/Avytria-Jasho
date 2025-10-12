from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from ..middleware.auth import get_current_user
import firebase_admin
from firebase_admin import firestore

router = APIRouter()

# Lazy load firestore client
def get_db():
    try:
        return firestore.client()
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail="Firebase not configured. Please add service-account.json to secrets folder."
        )


class NotificationSettings(BaseModel):
    overspendingAlerts: Optional[bool] = None
    transactionAlerts: Optional[bool] = None
    savingsReminders: Optional[bool] = None
    jobAlerts: Optional[bool] = None
    securityAlerts: Optional[bool] = None
    smsNotifications: Optional[bool] = None
    emailNotifications: Optional[bool] = None
    pushNotifications: Optional[bool] = None


@router.put("/settings")
async def update_notification_settings(
    settings: NotificationSettings,
    current_user: dict = Depends(get_current_user)
):
    """Update notification settings"""
    try:
        settings_data = {
            "overspendingAlerts": settings.overspendingAlerts if settings.overspendingAlerts is not None else True,
            "transactionAlerts": settings.transactionAlerts if settings.transactionAlerts is not None else True,
            "savingsReminders": settings.savingsReminders if settings.savingsReminders is not None else True,
            "jobAlerts": settings.jobAlerts if settings.jobAlerts is not None else True,
            "securityAlerts": settings.securityAlerts if settings.securityAlerts is not None else True,
            "smsNotifications": settings.smsNotifications if settings.smsNotifications is not None else True,
            "emailNotifications": settings.emailNotifications if settings.emailNotifications is not None else True,
            "pushNotifications": settings.pushNotifications if settings.pushNotifications is not None else True,
            "updatedAt": firestore.SERVER_TIMESTAMP
        }
        
        get_db().collection("users").document(current_user["userId"]).update({
            "notificationSettings": settings_data
        })
        
        return {
            "success": True,
            "message": "Notification settings updated successfully",
            "data": {"settings": settings_data}
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update notification settings: {str(e)}"
        )


@router.get("/settings")
async def get_notification_settings(current_user: dict = Depends(get_current_user)):
    """Get notification settings"""
    try:
        user_ref = db.collection("users").document(current_user["userId"])
        user = user_ref.get()
        
        if not user.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user_data = user.to_dict()
        settings = user_data.get("notificationSettings", {
            "overspendingAlerts": True,
            "transactionAlerts": True,
            "savingsReminders": True,
            "jobAlerts": True,
            "securityAlerts": True,
            "smsNotifications": True,
            "emailNotifications": True,
            "pushNotifications": True
        })
        
        return {
            "success": True,
            "data": {"settings": settings}
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get notification settings: {str(e)}"
        )


@router.get("/access-logs")
async def get_access_logs(
    page: int = 1,
    limit: int = 20,
    current_user: dict = Depends(get_current_user)
):
    """Get access logs"""
    try:
        query = db.collection("access_logs").where(
            "userId", "==", current_user["userId"]
        ).order_by("timestamp", direction=firestore.Query.DESCENDING).limit(limit)
        
        logs = []
        for doc in query.stream():
            log_data = doc.to_dict()
            log_data["id"] = doc.id
            logs.append(log_data)
        
        return {
            "success": True,
            "data": {
                "logs": logs,
                "pagination": {
                    "page": page,
                    "limit": limit,
                    "total": len(logs)
                }
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get access logs: {str(e)}"
        )


async def log_access(user_id: str, action: str, metadata: dict = None):
    """Log user access (helper function)"""
    try:
        log_id = f"LOG_{int(datetime.now().timestamp() * 1000)}"
        log_data = {
            "logId": log_id,
            "userId": user_id,
            "action": action,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "metadata": metadata or {}
        }
        
        get_db().collection("access_logs").document(log_id).set(log_data)
    except Exception as e:
        print(f"Error logging access: {e}")

