# Development Phases

## FastAPI Basic API	Endpoints: join household, fetch chores, submit chore
### File structure:

backend/
├─ main.py
├─ models.py
├─ database.py
├─ routers/
│  ├─ households.py
│  ├─ devices.py
│  ├─ chores.py
│  ├─ submissions.py
└─ auth.py

### Tasks
#### Database connection (database.py)
Use asyncpg or SQLAlchemy with Supabase connection string.
#### Models (models.py)
Define Pydantic models for request/response validation.
#### Routers
households.py → create/join household, list members
devices.py → register device, auto-login via token
chores.py → fetch available chores, update active flag (admin only)
submissions.py → submit chore, approve/reject (admin)
#### Auth (auth.py)
Verify Supabase JWT tokens for devices and users
Use is_admin to enforce admin-only endpoints

## Flutter Skeleton
### File structure (basic):

flutter_app/
├─ lib/
│  ├─ main.dart
│  ├─ screens/
│  │  ├─ login.dart
│  │  ├─ household_dashboard.dart
│  │  ├─ chores_list.dart
│  │  ├─ submission_screen.dart
│  │  └─ admin_panel.dart
│  ├─ services/
│  │  ├─ api_service.dart
│  │  ├─ auth_service.dart
│  │  └─ secure_storage_service.dart
│  └─ models/
│     ├─ chore.dart
│     ├─ device.dart
│     ├─ member.dart
│     └─ submission.dart


### Tasks
#### Authentication
Integrate Supabase Auth for login and token management.
Store deviceId and JWT token securely (flutter_secure_storage).
#### Household Setup
QR code scanning for joining household.
Optional Wi-Fi SSID verification (hash) for initial registration.
#### Chore Management
Fetch chores filtered by active and cadence.
Submit chores with optional notes or photo proof.
#### Admin Panel
View chore submissions from selected day.
Update chore active status.
#### Rewards Display
Dynamically calculate rewards based on DifficultyRewards.
