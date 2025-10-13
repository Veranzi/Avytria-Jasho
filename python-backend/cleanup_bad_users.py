#!/usr/bin/env python3
"""
Cleanup script to remove users with bad password hashes from Firebase.
This fixes the UnknownHashError that crashes the backend.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import os
import sys

def cleanup_bad_users():
    """Remove users with corrupted/unrecognized password hashes."""
    
    # Initialize Firebase
    if not firebase_admin._apps:
        try:
            base_dir = os.path.dirname(os.path.dirname(__file__))
            cred_path = os.path.join(base_dir, 'secrets', 'service-account.json')
            
            if not os.path.exists(cred_path):
                print(f"❌ Error: Firebase credentials not found at {cred_path}")
                print("   Make sure 'secrets/service-account.json' exists.")
                sys.exit(1)
            
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print("✅ Firebase initialized successfully")
        except Exception as e:
            print(f"❌ Firebase initialization failed: {e}")
            sys.exit(1)
    
    db = firestore.client()
    
    # Get all users
    users_ref = db.collection('users')
    users = users_ref.stream()
    
    deleted_count = 0
    kept_count = 0
    
    print("\n🔍 Scanning users for bad password hashes...")
    
    for user_doc in users:
        user_data = user_doc.to_dict()
        user_id = user_doc.id
        email = user_data.get('email', 'unknown')
        password_hash = user_data.get('passwordHash', '')
        
        # Check if password hash looks corrupted
        # Argon2 hashes start with $argon2, bcrypt with $2b$
        is_valid = password_hash.startswith('$argon2') or password_hash.startswith('$2b$') or password_hash.startswith('$2a$')
        
        if not is_valid:
            print(f"  ❌ Deleting user {email} (ID: {user_id}) - Bad hash: {password_hash[:30]}...")
            
            # Delete user document
            db.collection('users').document(user_id).delete()
            
            # Delete associated wallet
            try:
                db.collection('wallets').document(user_id).delete()
            except:
                pass
            
            # Delete associated credit score
            try:
                db.collection('credit_scores').document(user_id).delete()
            except:
                pass
            
            deleted_count += 1
        else:
            print(f"  ✅ Keeping user {email} - Valid hash")
            kept_count += 1
    
    print(f"\n📊 Cleanup Complete:")
    print(f"   ✅ Kept: {kept_count} users")
    print(f"   ❌ Deleted: {deleted_count} users with bad hashes")
    print(f"\n💡 You can now register fresh accounts that will work properly!")

if __name__ == "__main__":
    print("="*60)
    print("   JASHO - Bad Password Hash Cleanup Script")
    print("="*60)
    
    try:
        cleanup_bad_users()
    except KeyboardInterrupt:
        print("\n\n⚠️  Cleanup cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error during cleanup: {e}")
        sys.exit(1)
    
    print("\n✅ All done! Restart your backend now.")

