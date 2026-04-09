-- Create Households Table
CREATE TABLE households (
    household_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create Devices Table
CREATE TABLE devices (
    device_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(household_id) ON DELETE CASCADE,
    device_hash VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create Family Members Table
CREATE TABLE family_members (
    member_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(household_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create Chores Table
CREATE TABLE chores (
    chore_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    difficulty VARCHAR(20) CHECK (difficulty IN ('easy','medium','hard','flexible')),
    cadence VARCHAR(20) CHECK (cadence IN ('daily','weekly','monthly','on_request')),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create Reward Categories Table
CREATE TABLE reward_categories (
    reward_category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(household_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('integer','float','boolean')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create DifficultyRewards Table (Join Table)
CREATE TABLE difficulty_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES households(household_id) ON DELETE CASCADE,
    difficulty VARCHAR(20) CHECK (difficulty IN ('easy','medium','hard','flexible')),
    reward_category_id UUID REFERENCES reward_categories(reward_category_id) ON DELETE CASCADE,
    value FLOAT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create Chore Submissions Table
CREATE TABLE chore_submissions (
    submission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chore_id UUID REFERENCES chores(chore_id) ON DELETE CASCADE,
    member_id UUID REFERENCES family_members(member_id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(device_id) ON DELETE CASCADE,
    completed_at TIMESTAMP DEFAULT NOW(),
    approved BOOLEAN DEFAULT FALSE,
    notes TEXT
);
