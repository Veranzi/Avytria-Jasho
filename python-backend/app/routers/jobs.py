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


class JobCreate(BaseModel):
    title: str
    description: str
    category: str
    location: dict
    priceKes: float
    urgency: Optional[str] = "normal"
    estimatedDuration: Optional[str] = None
    requirements: Optional[List[str]] = None
    skills: Optional[List[str]] = None
    images: Optional[List[str]] = None


class JobApplication(BaseModel):
    message: Optional[str] = None
    proposedPrice: Optional[float] = None
    estimatedDuration: Optional[str] = None


class JobReview(BaseModel):
    rating: float = Field(ge=0, le=5)
    review: Optional[str] = None
    completionNotes: Optional[str] = None


@router.get("")
async def get_jobs(
    page: int = 1,
    limit: int = 20,
    category: Optional[str] = None,
    location: Optional[str] = None,
    minPrice: Optional[float] = None,
    maxPrice: Optional[float] = None,
    urgency: Optional[str] = None,
    q: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """Get all jobs with filters"""
    try:
        query = db.collection("jobs").where("status", "==", "active")
        
        if category:
            query = query.where("category", "==", category)
        if urgency:
            query = query.where("urgency", "==", urgency)
        
        query = query.order_by("createdAt", direction=firestore.Query.DESCENDING).limit(limit)
        
        jobs = []
        for doc in query.stream():
            job_data = doc.to_dict()
            job_data["id"] = doc.id
            
            # Apply additional filters
            if minPrice and job_data.get("priceKes", 0) < minPrice:
                continue
            if maxPrice and job_data.get("priceKes", 0) > maxPrice:
                continue
            if location and location.lower() not in job_data.get("location", {}).get("address", "").lower():
                continue
            if q and q.lower() not in job_data.get("title", "").lower() and q.lower() not in job_data.get("description", "").lower():
                continue
            
            jobs.append(job_data)
        
        return {
            "success": True,
            "data": {
                "jobs": jobs,
                "pagination": {
                    "page": page,
                    "limit": limit,
                    "total": len(jobs)
                }
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get jobs: {str(e)}"
        )


@router.get("/{job_id}")
async def get_job(job_id: str, current_user: dict = Depends(get_current_user)):
    """Get job by ID"""
    try:
        job_ref = db.collection("jobs").document(job_id)
        job = job_ref.get()
        
        if not job.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Job not found"
            )
        
        job_data = job.to_dict()
        job_data["id"] = job.id
        
        # Increment views
        job_ref.update({"views": firestore.Increment(1)})
        
        return {
            "success": True,
            "data": {"job": job_data}
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get job: {str(e)}"
        )


@router.post("")
async def post_job(job_data: JobCreate, current_user: dict = Depends(get_current_user)):
    """Post a new job"""
    try:
        job_id = f"JOB_{int(datetime.now().timestamp() * 1000)}"
        
        job_doc = {
            "jobId": job_id,
            "title": job_data.title,
            "description": job_data.description,
            "category": job_data.category,
            "location": job_data.location,
            "priceKes": job_data.priceKes,
            "urgency": job_data.urgency,
            "estimatedDuration": job_data.estimatedDuration,
            "requirements": job_data.requirements or [],
            "skills": job_data.skills or [],
            "images": job_data.images or [],
            "postedBy": current_user["userId"],
            "status": "active",
            "assignedTo": None,
            "applicationCount": 0,
            "views": 0,
            "rating": None,
            "review": None,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP
        }
        
        get_db().collection("jobs").document(job_id).set(job_doc)
        
        return {
            "success": True,
            "message": "Job posted successfully",
            "data": {"job": job_doc}
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to post job: {str(e)}"
        )


@router.post("/{job_id}/apply")
async def apply_for_job(
    job_id: str,
    application: JobApplication,
    current_user: dict = Depends(get_current_user)
):
    """Apply for a job"""
    try:
        job_ref = db.collection("jobs").document(job_id)
        job = job_ref.get()
        
        if not job.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Job not found"
            )
        
        # Check if already applied
        existing_app = db.collection("job_applications").where(
            "jobId", "==", job_id
        ).where(
            "applicantId", "==", current_user["userId"]
        ).limit(1).get()
        
        if existing_app:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Already applied for this job"
            )
        
        # Create application
        app_id = f"APP_{int(datetime.now().timestamp() * 1000)}"
        app_doc = {
            "applicationId": app_id,
            "jobId": job_id,
            "applicantId": current_user["userId"],
            "message": application.message,
            "proposedPrice": application.proposedPrice,
            "estimatedDuration": application.estimatedDuration,
            "status": "pending",
            "appliedAt": firestore.SERVER_TIMESTAMP
        }
        
        get_db().collection("job_applications").document(app_id).set(app_doc)
        
        # Update job application count
        job_ref.update({"applicationCount": firestore.Increment(1)})
        
        return {
            "success": True,
            "message": "Application submitted successfully",
            "data": {"application": app_doc}
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to apply for job: {str(e)}"
        )


@router.post("/{job_id}/complete")
async def complete_job(
    job_id: str,
    review: JobReview,
    current_user: dict = Depends(get_current_user)
):
    """Complete a job and add review"""
    try:
        job_ref = db.collection("jobs").document(job_id)
        job = job_ref.get()
        
        if not job.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Job not found"
            )
        
        job_data = job.to_dict()
        
        # Check if user owns or is assigned to the job
        if (job_data.get("postedBy") != current_user["userId"] and 
            job_data.get("assignedTo") != current_user["userId"]):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        # Update job
        job_ref.update({
            "status": "completed",
            "rating": review.rating,
            "review": review.review,
            "completionNotes": review.completionNotes,
            "completedAt": firestore.SERVER_TIMESTAMP
        })
        
        return {
            "success": True,
            "message": "Job completed successfully",
            "data": {"job": {**job_data, "status": "completed"}}
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete job: {str(e)}"
        )


@router.get("/user/{type}")
async def get_user_jobs(
    type: str,
    page: int = 1,
    limit: int = 20,
    status_filter: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """Get user's jobs (posted or assigned)"""
    try:
        if type not in ["posted", "assigned"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail='Type must be "posted" or "assigned"'
            )
        
        field = "postedBy" if type == "posted" else "assignedTo"
        query = db.collection("jobs").where(field, "==", current_user["userId"])
        
        if status_filter:
            query = query.where("status", "==", status_filter)
        
        query = query.order_by("createdAt", direction=firestore.Query.DESCENDING).limit(limit)
        
        jobs = []
        for doc in query.stream():
            job_data = doc.to_dict()
            job_data["id"] = doc.id
            jobs.append(job_data)
        
        return {
            "success": True,
            "data": {
                "jobs": jobs,
                "type": type,
                "pagination": {
                    "page": page,
                    "limit": limit,
                    "total": len(jobs)
                }
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user jobs: {str(e)}"
        )

