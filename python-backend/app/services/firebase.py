from __future__ import annotations
from typing import Optional
import os
import firebase_admin
from firebase_admin import credentials, firestore, storage
from ..config import settings
from .mock_db import get_mock_db


_initialized = False
_db = None
_bucket = None
_use_mock = False


def init_firebase() -> None:
    global _initialized, _db, _bucket, _use_mock
    if _initialized:
        return
    
    # Check if Firebase is already initialized by main.py
    if firebase_admin._apps:
        try:
            _db = firestore.client()
            if settings.firebase_storage_bucket:
                _bucket = storage.bucket(settings.firebase_storage_bucket)
            _initialized = True
            _use_mock = False
            print("✅ Firebase client connected")
            return
        except Exception as e:
            print(f"⚠️  Firebase client error: {e}")
    
    # Try to initialize Firebase
    cred_path = settings.firebase_credentials or os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    try:
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred, {
                'storageBucket': settings.firebase_storage_bucket
            } if settings.firebase_storage_bucket else None)
        else:
            # Application default credentials
            firebase_admin.initialize_app()
        _db = firestore.client()
        if settings.firebase_storage_bucket:
            _bucket = storage.bucket(settings.firebase_storage_bucket)
        _initialized = True
        _use_mock = False
        print("✅ Firebase initialized successfully")
    except Exception as e:
        # Use mock database as fallback
        print(f"⚠️  Firebase unavailable: {e}")
        print("📦 Using MOCK DATABASE for development")
        _db = get_mock_db()
        _initialized = True
        _use_mock = True


def get_db():
    """Get database (Firebase or Mock)"""
    if not _initialized:
        init_firebase()
    return _db


def get_bucket():
    """Get storage bucket (Firebase only)"""
    if not _initialized:
        init_firebase()
    return _bucket


def is_mock_db() -> bool:
    """Check if using mock database"""
    if not _initialized:
        init_firebase()
    return _use_mock
