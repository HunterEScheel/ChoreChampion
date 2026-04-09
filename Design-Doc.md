## Database Structure

### Households
| Field | Type | Description |
|-------|------|-------------|
| household_id | UUID (PK) | Unique household identifier |
| name | VARCHAR | Household name |
| created_at | TIMESTAMP | Creation date |
| updated_at | TIMESTAMP | Last update |

### Devices
| Field | Type | Description |
|-------|------|-------------|
| device_id | UUID (PK) | Unique device identifier |
| household_id | UUID (FK) | Household the device belongs to |
| device_hash | VARCHAR | Hashed device ID for verification |
| is_admin | BOOLEAN | Admin privileges |
| last_seen | TIMESTAMP | Last sync time |
| active | BOOLEAN | Device active in household |
| created_at | TIMESTAMP | Creation date |

### Family Members
| Field | Type | Description |
|-------|------|-------------|
| member_id | UUID (PK) | Unique member identifier |
| household_id | UUID (FK) | Household membership |
| name | VARCHAR | Member name |
| created_at | TIMESTAMP | Member creation date |
| updated_at | TIMESTAMP | Last update |

### Chores
| Field | Type | Description |
|-------|------|-------------|
| chore_id | UUID (PK) | Unique chore identifier |
| name | VARCHAR | Name of chore |
| difficulty | ENUM('easy','medium','hard','flexible') | Difficulty tier |
| cadence | ENUM('daily','weekly','monthly','on_request') | How often chore can be completed |
| active | BOOLEAN | Whether chore is currently available |
| created_at | TIMESTAMP | Creation date |
| updated_at | TIMESTAMP | Last update |

### Reward Categories
| Field | Type | Description |
|-------|------|-------------|
| reward_category_id | UUID (PK) | Unique reward category |
| household_id | UUID (FK) | Which household this category belongs to |
| name | VARCHAR | Name of reward (Screen Time, Cash, Points, etc.) |
| type | ENUM('integer','float','boolean') | Data type for value |
| created_at | TIMESTAMP | Creation date |
| updated_at | TIMESTAMP | Last update |

### DifficultyRewards (Join Table)
| Field | Type | Description |
|-------|------|-------------|
| id | UUID (PK) | Unique identifier |
| household_id | UUID (FK) | Household this mapping belongs to |
| difficulty | ENUM('easy','medium','hard','flexible') | Difficulty tier |
| reward_category_id | UUID (FK) | Linked reward category |
| value | FLOAT / INT / BOOL | Amount of reward for this difficulty & category |
| created_at | TIMESTAMP | Creation date |
| updated_at | TIMESTAMP | Last update |

### Chore Submissions
| Field | Type | Description |
|-------|------|-------------|
| submission_id | UUID (PK) | Unique submission |
| chore_id | UUID (FK) | Chore completed |
| member_id | UUID (FK) | Family member who completed it |
| device_id | UUID (FK) | Device used to submit |
| completed_at | TIMESTAMP | When task was done |
| approved | BOOLEAN | Approved by admin |
| notes | TEXT | Optional notes or proof links |



## Backend Layer (FastAPI)

### Roles:
- Handle chore submission validation
- Calculate rewards dynamically from DifficultyRewards
- Verify device tokens for auto-login
- Approve or reject submissions (admin functionality)
- Cadence enforcement (daily/weekly/on-request)

### Endpoints Example:
- POST /households/join → join household via QR or SSID
- POST /chores/submit → submit chore
- GET /chores → get available chores for the household
- POST /submissions/approve → admin approves submission
- GET /rewards → fetch current earned rewards
### Auth:
- Supabase issues JWT tokens
- Store tokens securely on Flutter devices
- FastAPI validates tokens for all API requests



## Frontend Layer (Flutter)

### Device auto-login:
- On first join, store deviceId and JWT in secure storage (flutter_secure_storage)
- On app launch, auto-login using stored token
- If token expired → rejoin via QR/SSID
### UI Features:
- Chore list filtered by cadence + active flag
- Submission button + optional proof (photo or notes)
- Reward dashboard (screen time, cash, etc.)
- Admin panel for approving submissions


## 4. Auth Flow
Admin device creates household → Supabase Auth creates user + household record.
Child device joins:
- On Wi-Fi: verify SSID + hashed MAC
- Off Wi-Fi: scan QR code
Store token and deviceId in secure storage
Subsequent app launches:
 - Check token in secure storage → auto-login
 - Token expiration handled by Supabase refresh mechanism
### Task 3 - Family settings page for parents (Payment Options, Difficulty, Chores)
### Task 4 - Chore form for daily submission
### Task 5 - reporting page for parents to see history
### Task 6 - implement "split task" for user to be able to say "I did half of this thing"
