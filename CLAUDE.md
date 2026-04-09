# Development Phases

## FastAPI Basic API	Endpoints: join household, fetch chores, submit chore
### File structure:

<backend/
├─ main.py
├─ models.py
├─ database.py
├─ routers/
│  ├─ households.py
│  ├─ devices.py
│  ├─ chores.py
│  ├─ submissions.py
└─ auth.py/>

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

3	Flutter Skeleton	Authentication, household joining, basic chore list
4	FastAPI Admin Endpoints	Approve/reject chores, manage chores
5	Flutter Full UI	Submission screen, admin panel, reward display
6	Device Auto-login	Store/retrieve deviceId securely, validate token
7	Testing	Unit tests for backend and frontend integration
8	Deployment	FastAPI on Fly.io / Supabase Edge Functions optional, Flutter app deployed to App Store/Play Store
