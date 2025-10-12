from fastapi import APIRouter, HTTPException, Request, Form
from pydantic import BaseModel
from typing import Optional, Dict
from datetime import datetime, timedelta
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

# Session store (in production, use Redis)
sessions: Dict[str, dict] = {}


class USSDRequest(BaseModel):
    sessionId: str
    serviceCode: str
    phoneNumber: str
    text: str = ""


# USSD Menu Definitions
MENUS = {
    "MAIN": """CON Welcome to Jasho
1. Check Balance
2. Savings
3. Jobs
4. Transactions
5. Loans
6. Help""",
    
    "SAVINGS_MENU": """CON Savings Menu
1. View Goals
2. Create Goal
3. Contribute
4. Standing Order
0. Back""",
    
    "JOBS_MENU": """CON Jobs Menu
1. Browse Jobs
2. My Applications
3. Post Job
4. My Posted Jobs
0. Back""",
    
    "TRANSACTIONS_MENU": """CON Transactions
1. Deposit
2. Withdraw
3. Send Money
4. Transaction History
0. Back""",
    
    "LOANS_MENU": """CON Loans
1. Check Eligibility
2. Apply for Loan
3. My Loans
4. Repay Loan
0. Back""",
    
    "HELP_MENU": """CON Help & Support
1. How to Save
2. How to Find Jobs
3. Contact Support
4. Report Fraud
0. Back"""
}


def cleanup_sessions():
    """Remove sessions older than 5 minutes"""
    now = datetime.now()
    expired = [sid for sid, sess in sessions.items() 
               if (now - sess["startTime"]).total_seconds() > 300]
    for sid in expired:
        del sessions[sid]


async def get_user_by_phone(phone: str):
    """Get user by phone number"""
    users = db.collection("users").where("phoneNumber", "==", phone).limit(1).stream()
    for user in users:
        return user.to_dict()
    return None


async def handle_balance(user: dict) -> str:
    """Handle balance check"""
    try:
        wallet = db.collection("wallets").document(user["userId"]).get()
        if not wallet.exists:
            return "END No wallet found. Please contact support."
        
        balances = wallet.to_dict().get("balances", {})
        return f"""END Your wallet balance:
KES: {balances.get('KES', 0):.2f}
USDT: {balances.get('USDT', 0):.4f}
USD: {balances.get('USD', 0):.2f}"""
    except Exception as e:
        return f"END Error retrieving balance: {str(e)}"


async def handle_savings(inputs: list, session: dict, user: dict) -> str:
    """Handle savings menu"""
    level = len(inputs)
    
    if level == 1:
        return MENUS["SAVINGS_MENU"]
    
    choice = inputs[1]
    
    if choice == "1":  # View Goals
        goals = db.collection("savings_goals").where(
            "userId", "==", user["userId"]
        ).limit(5).stream()
        
        goals_list = [g.to_dict() for g in goals]
        
        if not goals_list:
            return "END You have no savings goals yet.\nUse the app to create your first goal!"
        
        response = "END Your Savings Goals:\n"
        for i, goal in enumerate(goals_list, 1):
            progress = (goal["saved"] / goal["target"] * 100) if goal["target"] > 0 else 0
            response += f"\n{i}. {goal['name']}\n   KES {goal['saved']}/{goal['target']} ({progress:.0f}%)"
        
        return response
    
    elif choice == "0":
        return MENUS["MAIN"]
    
    return "END Feature coming soon in the mobile app!"


async def handle_jobs(inputs: list, session: dict, user: dict) -> str:
    """Handle jobs menu"""
    level = len(inputs)
    
    if level == 1:
        return MENUS["JOBS_MENU"]
    
    choice = inputs[1]
    
    if choice == "1":  # Browse Jobs
        jobs = db.collection("jobs").where("status", "==", "active").limit(5).stream()
        jobs_list = [j.to_dict() for j in jobs]
        
        if not jobs_list:
            return "END No jobs available at the moment.\nCheck back later or post your own job!"
        
        response = "END Available Jobs:\n"
        for i, job in enumerate(jobs_list, 1):
            response += f"\n{i}. {job['title']}\n   {job['location'].get('address', 'N/A')}\n   KES {job['priceKes']:.0f}"
        
        response += "\n\nUse the app to apply for jobs."
        return response
    
    elif choice == "0":
        return MENUS["MAIN"]
    
    return "END Feature coming soon in the mobile app!"


async def handle_transactions(inputs: list, session: dict, user: dict) -> str:
    """Handle transactions menu"""
    level = len(inputs)
    
    if level == 1:
        return MENUS["TRANSACTIONS_MENU"]
    
    choice = inputs[1]
    
    if choice == "1":  # Deposit
        return f"""END To deposit money, please use:
- M-Pesa: Paybill 123456, Account: {user['userId']}
- Bank transfer via the app
- Mobile money via the app"""
    
    elif choice == "4":  # Transaction History
        txns = db.collection("transactions").where(
            "userId", "==", user["userId"]
        ).order_by("initiatedAt", direction=firestore.Query.DESCENDING).limit(5).stream()
        
        txn_list = [t.to_dict() for t in txns]
        
        if not txn_list:
            return "END No transactions yet."
        
        response = "END Recent Transactions:\n"
        for txn in txn_list:
            sign = "+" if txn["type"] == "deposit" else "-"
            response += f"\n{sign}KES {txn['amount']:.2f}\n   {txn['description']}"
        
        return response
    
    elif choice == "0":
        return MENUS["MAIN"]
    
    return "END Withdrawals and transfers are available via the mobile app for enhanced security."


async def handle_loans(inputs: list, session: dict, user: dict) -> str:
    """Handle loans menu"""
    level = len(inputs)
    
    if level == 1:
        return MENUS["LOANS_MENU"]
    
    choice = inputs[1]
    
    if choice == "1":  # Check Eligibility
        # Get credit score
        credit = db.collection("credit_scores").document(user["userId"]).get()
        
        if not credit.exists:
            return """END Credit score not available yet.
Complete your profile in the app to get your credit score."""
        
        credit_data = credit.to_dict()
        return f"""END Loan Eligibility:
Credit Score: {credit_data['currentScore']}
Maximum Loan: KES {credit_data.get('maxLoanAmount', 0):.0f}
Interest Rate: {credit_data.get('interestRate', 15)}%

Apply for a loan via the mobile app!"""
    
    elif choice == "0":
        return MENUS["MAIN"]
    
    return "END Feature coming soon in the mobile app!"


def handle_help(inputs: list) -> str:
    """Handle help menu"""
    level = len(inputs)
    
    if level == 1:
        return MENUS["HELP_MENU"]
    
    choice = inputs[1]
    
    help_texts = {
        "1": """END How to Save Money:
1. Create a savings goal
2. Set your target amount
3. Contribute regularly
4. Enable standing orders for automatic savings
5. Track your progress in the app""",
        
        "2": """END How to Find Jobs:
1. Browse available jobs
2. Apply via the mobile app
3. Complete the job
4. Get paid directly to your wallet
5. Build your reputation with ratings""",
        
        "3": """END Contact Support:
Email: support@jasho.com
Phone: +254 700 000 000
WhatsApp: +254 700 000 001

Hours: Mon-Fri 8AM-6PM""",
        
        "4": """END To report fraud:
Use the mobile app for detailed reporting with evidence upload.
Or call: +254 700 000 002 (24/7)""",
        
        "0": MENUS["MAIN"]
    }
    
    return help_texts.get(choice, "END Invalid choice.")


async def handle_ussd_request(inputs: list, session: dict, user: dict) -> str:
    """Route USSD request based on user input"""
    level = len(inputs)
    
    if level == 0:
        return MENUS["MAIN"]
    
    main_choice = inputs[0]
    
    handlers = {
        "1": handle_balance,
        "2": handle_savings,
        "3": handle_jobs,
        "4": handle_transactions,
        "5": handle_loans,
        "6": lambda i, s, u: handle_help(i)
    }
    
    handler = handlers.get(main_choice)
    if handler:
        if main_choice == "1":
            return await handler(user)
        elif main_choice == "6":
            return handler(inputs)
        else:
            return await handler(inputs, session, user)
    
    return "END Invalid choice. Please try again."


@router.post("/ussd")
async def ussd_handler(
    sessionId: str = Form(...),
    serviceCode: str = Form(...),
    phoneNumber: str = Form(...),
    text: str = Form("")
):
    """Main USSD endpoint"""
    try:
        # Parse user input
        inputs = text.split("*") if text else []
        inputs = [i for i in inputs if i]
        
        # Clean up old sessions
        cleanup_sessions()
        
        # Get or create session
        if sessionId not in sessions:
            sessions[sessionId] = {
                "phoneNumber": phoneNumber,
                "data": {},
                "startTime": datetime.now()
            }
        
        session = sessions[sessionId]
        
        # Find user
        user = await get_user_by_phone(phoneNumber)
        
        if not user and len(inputs) == 0:
            return """END Welcome to Jasho!
You need to register first.
Download the Jasho app or visit jasho.com to sign up."""
        
        if not user:
            return "END Invalid session. Please try again."
        
        # Handle request
        response = await handle_ussd_request(inputs, session, user)
        
        return response
        
    except Exception as e:
        print(f"USSD Error: {e}")
        return "END Sorry, an error occurred. Please try again later."

