from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, Field
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


class JobRating(BaseModel):
    rating: float = Field(ge=0, le=5)
    comment: Optional[str] = None


class UserRating(BaseModel):
    rating: float = Field(ge=0, le=5)
    comment: Optional[str] = None
    context: Optional[str] = None


async def update_user_rating(user_id: str):
    """Update user's average rating"""
    try:
        ratings_query = db.collection("ratings").where("ratedUser", "==", user_id).stream()
        
        ratings = [doc.to_dict()["rating"] for doc in ratings_query]
        
        if not ratings:
            return
        
        avg_rating = sum(ratings) / len(ratings)
        
        get_db().collection("users").document(user_id).update({
            "averageRating": round(avg_rating, 2),
            "totalRatings": len(ratings)
        })
    except Exception as e:
        print(f"Error updating user rating: {e}")


@router.post("/job/{job_id}")
async def rate_job(
    job_id: str,
    rating_data: JobRating,
    current_user: dict = Depends(get_current_user)
):
    """Rate a job"""
    try:
        # Get job
        job_ref = db.collection("jobs").document(job_id)
        job = job_ref.get()
        
        if not job.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Job not found"
            )
        
        job_data = job.to_dict()
        
        # Check if user was involved in the job
        if (job_data.get("assignedTo") != current_user["userId"] and 
            job_data.get("postedBy") != current_user["userId"]):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only rate jobs you were involved in"
            )
        
        # Check if already rated
        existing_rating = db.collection("ratings").where(
            "jobId", "==", job_id
        ).where(
            "ratedBy", "==", current_user["userId"]
        ).limit(1).get()
        
        if existing_rating:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You have already rated this job"
            )
        
        # Create rating
        rating_id = f"RATING_{int(datetime.now().timestamp() * 1000)}"
        rated_user = (job_data.get("postedBy") if job_data.get("assignedTo") == current_user["userId"] 
                     else job_data.get("assignedTo"))
        
        rating_doc = {
            "ratingId": rating_id,
            "type": "job",
            "jobId": job_id,
            "ratedBy": current_user["userId"],
            "ratedUser": rated_user,
            "rating": rating_data.rating,
            "comment": rating_data.comment,
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        
        get_db().collection("ratings").document(rating_id).set(rating_doc)
        
        # Update job with rating
        job_ref.update({
            "rating": rating_data.rating,
            "review": rating_data.comment
        })
        
        # Update user's average rating
        await update_user_rating(rated_user)
        
        return {
            "success": True,
            "message": "Rating submitted successfully",
            "data": {"rating": rating_doc}
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to submit rating: {str(e)}"
        )


@router.post("/user/{user_id}")
async def rate_user(
    user_id: str,
    rating_data: UserRating,
    current_user: dict = Depends(get_current_user)
):
    """Rate a user/poster"""
    try:
        if user_id == current_user["userId"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot rate yourself"
            )
        
        # Create rating
        rating_id = f"RATING_{int(datetime.now().timestamp() * 1000)}"
        
        rating_doc = {
            "ratingId": rating_id,
            "type": "user",
            "ratedBy": current_user["userId"],
            "ratedUser": user_id,
            "rating": rating_data.rating,
            "comment": rating_data.comment,
            "context": rating_data.context,
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        
        get_db().collection("ratings").document(rating_id).set(rating_doc)
        
        # Update user's average rating
        await update_user_rating(user_id)
        
        return {
            "success": True,
            "message": "Rating submitted successfully",
            "data": {"rating": rating_doc}
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to submit rating: {str(e)}"
        )


@router.get("/user/{user_id}")
async def get_user_ratings(
    user_id: str,
    page: int = 1,
    limit: int = 20,
    current_user: dict = Depends(get_current_user)
):
    """Get ratings for a user"""
    try:
        query = db.collection("ratings").where(
            "ratedUser", "==", user_id
        ).order_by("createdAt", direction=firestore.Query.DESCENDING).limit(limit)
        
        ratings = []
        total_rating = 0
        
        for doc in query.stream():
            rating_data = doc.to_dict()
            rating_data["id"] = doc.id
            ratings.append(rating_data)
            total_rating += rating_data["rating"]
        
        avg_rating = total_rating / len(ratings) if ratings else 0
        
        return {
            "success": True,
            "data": {
                "ratings": ratings,
                "averageRating": round(avg_rating, 2),
                "totalRatings": len(ratings),
                "pagination": {
                    "page": page,
                    "limit": limit,
                    "total": len(ratings)
                }
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get ratings: {str(e)}"
        )

