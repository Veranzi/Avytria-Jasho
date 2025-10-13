from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from starlette.middleware.sessions import SessionMiddleware
from .config import settings
from fastapi.staticfiles import StaticFiles
import firebase_admin
from firebase_admin import credentials
import os

# Initialize Firebase Admin SDK (if not already initialized)
if not firebase_admin._apps:
    try:
        # Try to load from ../secrets/service-account.json (relative to python-backend folder)
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
        cred_path = os.path.join(base_dir, 'secrets', 'service-account.json')
        
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print(f"[SUCCESS] Firebase initialized with service account from: {cred_path}")
        else:
            # Try default credentials
            firebase_admin.initialize_app()
            print("[SUCCESS] Firebase initialized with default credentials")
    except Exception as e:
        print(f"[WARNING] Firebase not initialized: {e}")
        print(f"   Expected path: {cred_path if 'cred_path' in locals() else 'secrets/service-account.json'}")
        print("   App will run with limited functionality.")


def create_app() -> FastAPI:
    app = FastAPI(title=settings.app_name)

    # Configure CORS to allow all origins (including Flutter app)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Allow all origins
        allow_credentials=False,  # Must be False when allow_origins is "*"
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["*"],
    )
    app.add_middleware(GZipMiddleware, minimum_size=1024)
    app.add_middleware(SessionMiddleware, secret_key=settings.jwt_secret)

    # Routers will be included below to match Flutter ApiService endpoints
    from .routers import (
        auth, user, wallet, ai, heatmap, chatbot, credit_score, gamification, 
        savings, profile_image, cybersecurity, fraud, ratings, notifications, jobs, ussd, debug
    )

    app.include_router(auth.router, prefix=settings.api_prefix + "/auth", tags=["auth"])
    app.include_router(user.router, prefix=settings.api_prefix + "/user", tags=["user"])
    app.include_router(wallet.router, prefix=settings.api_prefix + "/wallet", tags=["wallet"])
    app.include_router(ai.router, prefix=settings.api_prefix + "/ai", tags=["ai"])
    app.include_router(heatmap.router, prefix=settings.api_prefix + "/heatmap", tags=["heatmap"])
    app.include_router(chatbot.router, prefix=settings.api_prefix + "/chatbot", tags=["chatbot"])
    app.include_router(credit_score.router, prefix=settings.api_prefix + "/credit-score", tags=["credit-score"])
    app.include_router(gamification.router, prefix=settings.api_prefix + "/gamification", tags=["gamification"])
    app.include_router(savings.router, prefix=settings.api_prefix + "/savings", tags=["savings"])
    app.include_router(profile_image.router, prefix=settings.api_prefix + "/profile-image", tags=["profile-image"])
    app.include_router(cybersecurity.router, prefix=settings.api_prefix + "/cybersecurity", tags=["cybersecurity"])
    
    # NEW ROUTES - ALL FEATURES IMPLEMENTED
    app.include_router(fraud.router, prefix=settings.api_prefix + "/fraud", tags=["fraud"])
    app.include_router(ratings.router, prefix=settings.api_prefix + "/ratings", tags=["ratings"])
    app.include_router(notifications.router, prefix=settings.api_prefix + "/notifications", tags=["notifications"])
    app.include_router(jobs.router, prefix=settings.api_prefix + "/jobs", tags=["jobs"])
    app.include_router(ussd.router, prefix=settings.api_prefix + "/ussd", tags=["ussd"])
    app.include_router(debug.router, prefix=settings.api_prefix + "/debug", tags=["debug"])

    # Static files for uploaded profile images
    app.mount(
        "/uploads/profile-images",
        StaticFiles(directory=str(settings.uploads_dir)),
        name="profile-images",
    )

    @app.get("/health")
    def health():
        return {"status": "running"}

    return app


app = create_app()

