from fastapi import APIRouter
from ..services.repos import UsersRepo, WalletsRepo, CreditRepo
from datetime import datetime

router = APIRouter()


@router.get("/test-repos")
def test_repos():
    """Test if repos are working"""
    results = {}
    
    # Test 1: Can we hash a password?
    try:
        password_hash = UsersRepo.hash_password("Test123!")
        results["password_hash"] = "SUCCESS"
    except Exception as e:
        results["password_hash"] = f"FAILED: {str(e)}"
    
    # Test 2: Can we check for existing users?
    try:
        user = UsersRepo.find_by_email("nonexistent@test.com")
        results["find_user"] = "SUCCESS" if user is None else f"Found: {user}"
    except Exception as e:
        results["find_user"] = f"FAILED: {str(e)}"
    
    # Test 3: Can we create a test user?
    try:
        user_id = f"test_user_{int(datetime.utcnow().timestamp())}"
        user_doc = {
            "email": f"test_{user_id}@test.com",
            "phoneNumber": f"+2547{user_id[-8:]}",
            "passwordHash": "test_hash",
            "fullName": "Test User",
            "location": "Test Location",
            "skills": [],
            "verificationLevel": "unverified",
            "isActive": True,
        }
        UsersRepo.create_user(user_id, user_doc)
        results["create_user"] = "SUCCESS"
        
        # Test 4: Can we create wallet?
        WalletsRepo.get_or_create(user_id)
        results["create_wallet"] = "SUCCESS"
        
        # Test 5: Can we create credit score?
        CreditRepo.get_or_create(user_id)
        results["create_credit"] = "SUCCESS"
        
    except Exception as e:
        results["create_test_data"] = f"FAILED: {str(e)}"
        import traceback
        results["traceback"] = traceback.format_exc()
    
    return {"success": True, "results": results}



