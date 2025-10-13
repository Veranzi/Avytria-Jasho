"""
Quick script to delete test users with incompatible password hashes.
Run this once if you want to clean up old test accounts.
"""
from app.services.firebase import get_db

def cleanup_test_users():
    """Delete test users (emails containing 'test' or '@jasho.com')"""
    db = get_db()
    users_col = db.collection("users")
    
    # Find test users
    test_emails = ['test@jasho.com', 'newuser@jasho.com', 'user', 'test']
    deleted_count = 0
    
    for doc in users_col.stream():
        user_data = doc.to_dict()
        email = user_data.get('email', '').lower()
        
        # Check if it's a test user
        if any(test_word in email for test_word in test_emails):
            print(f"Deleting test user: {email} (ID: {doc.id})")
            doc.reference.delete()
            deleted_count += 1
    
    print(f"\n✅ Cleaned up {deleted_count} test user(s)")
    print("You can now register fresh users with working passwords!")

if __name__ == "__main__":
    cleanup_test_users()

