from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, Field
from typing import Optional, List
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


class FraudReport(BaseModel):
    category: str
    description: str = Field(min_length=20)
    relatedItemId: Optional[str] = None
    relatedItemType: Optional[str] = None
    evidenceImages: Optional[List[str]] = None


class FraudReportUpdate(BaseModel):
    status: Optional[str] = None
    resolution: Optional[str] = None
    action: Optional[str] = None


def determine_priority(category: str) -> str:
    """Determine priority based on fraud category"""
    high_priority = ["Identity Theft", "Payment Fraud", "Scam/Fraud"]
    medium_priority = ["Fake Job Posting", "Phishing Attempt", "Impersonation"]
    
    if category in high_priority:
        return "high"
    elif category in medium_priority:
        return "medium"
    return "low"


@router.post("/report")
async def report_fraud(report: FraudReport, current_user: dict = Depends(get_current_user)):
    """Submit a fraud report"""
    try:
        report_id = f"FRAUD_{int(datetime.now().timestamp() * 1000)}"
        
        report_data = {
            "reportId": report_id,
            "reportedBy": current_user["userId"],
            "category": report.category,
            "description": report.description,
            "relatedItemId": report.relatedItemId,
            "relatedItemType": report.relatedItemType,
            "evidenceImages": report.evidenceImages or [],
            "status": "pending",
            "priority": determine_priority(report.category),
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
            "investigatedBy": None,
            "resolution": None,
        }
        
        get_db().collection("fraud_reports").document(report_id).set(report_data)
        
        return {
            "success": True,
            "message": "Fraud report submitted successfully. Our security team will investigate.",
            "data": {
                "reportId": report_id,
                "status": "pending"
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to submit fraud report: {str(e)}"
        )


@router.get("/my-reports")
async def get_my_reports(
    page: int = 1,
    limit: int = 20,
    status_filter: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """Get user's fraud reports"""
    try:
        query = db.collection("fraud_reports").where(
            "reportedBy", "==", current_user["userId"]
        ).order_by("createdAt", direction=firestore.Query.DESCENDING).limit(limit)
        
        if status_filter:
            query = query.where("status", "==", status_filter)
        
        reports = []
        for doc in query.stream():
            report_data = doc.to_dict()
            report_data["id"] = doc.id
            reports.append(report_data)
        
        return {
            "success": True,
            "data": {
                "reports": reports,
                "pagination": {
                    "page": page,
                    "limit": limit,
                    "total": len(reports)
                }
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get fraud reports: {str(e)}"
        )


@router.get("/admin/reports")
async def get_all_reports(
    page: int = 1,
    limit: int = 50,
    status_filter: Optional[str] = None,
    priority: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """Get all fraud reports (admin only)"""
    try:
        # Check if user is admin
        if current_user.get("role") != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required"
            )
        
        query = db.collection("fraud_reports").order_by(
            "createdAt", direction=firestore.Query.DESCENDING
        ).limit(limit)
        
        if status_filter:
            query = query.where("status", "==", status_filter)
        
        if priority:
            query = query.where("priority", "==", priority)
        
        reports = []
        for doc in query.stream():
            report_data = doc.to_dict()
            report_data["id"] = doc.id
            reports.append(report_data)
        
        return {
            "success": True,
            "data": {
                "reports": reports,
                "pagination": {
                    "page": page,
                    "limit": limit,
                    "total": len(reports)
                }
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get fraud reports: {str(e)}"
        )


@router.put("/admin/reports/{report_id}")
async def update_fraud_report(
    report_id: str,
    update: FraudReportUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Update fraud report status (admin only)"""
    try:
        # Check if user is admin
        if current_user.get("role") != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required"
            )
        
        report_ref = db.collection("fraud_reports").document(report_id)
        report = report_ref.get()
        
        if not report.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Fraud report not found"
            )
        
        update_data = {
            "updatedAt": firestore.SERVER_TIMESTAMP,
            "investigatedBy": current_user["userId"]
        }
        
        if update.status:
            update_data["status"] = update.status
        if update.resolution:
            update_data["resolution"] = update.resolution
        if update.action:
            update_data["action"] = update.action
        
        report_ref.update(update_data)
        
        return {
            "success": True,
            "message": "Fraud report updated successfully"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update fraud report: {str(e)}"
        )

