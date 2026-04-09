# ChoreChampion

## What it is
ChoreChampion is an organizational chore app to provide an easy and intuitive way for 
families to digitally navigate chore completion and rewards.

## Settings
### Reward Categories
- Name (Screen Time, Cash, etc)
- Type (bigint, integer, float, boolean)

## Difficulty Settings
- Difficulty level (easy, medium, hard)
- rewards (based on [#Reward Categories])

### Chores Available
- Name of chore
- Difficulty
- Cadence (daily, weekly, monthly, as requested)
- Active (y/n)

---

## Example Chores Tables
### Reward Categories

| Category | Type |
|----------|------|
| Screen Time | Integer |
| US Dollars | float |


### Difficulty
| Difficulty | Screen Time (min) | Cash ($) |
|------------|-------------------|----------|
| Easy | 5 | 0.5 | 
| Medium | 15 | 1.5 |
| Hard | 30 | 3 |
| Flexible | 0 | 0 |



| Chore | Difficulty | Cadence | Active |
|-------|-----------|---------|--------|
| Make bed | Easy | daily | true |
| Take out trash | Easy | weekly | true |
| Feed pets | Easy | daily | true |
| Wipe kitchen counters | Easy | daily | true |
| Sweep common areas | Easy | daily | true |
| Load dishwasher | Easy | daily | true |
| Empty dishwasher | Easy | daily | true |
| Run laundry load (wash and dry) | Easy | weekly | true |
| Wash dishes | Medium | daily | true |
| Vacuum one area | Medium | weekly | true |
| Dust furniture | Medium | weekly | true |
| Fold laundry (half basket) | Medium | weekly | true |
| Clean bathroom sink & mirror | Medium | weekly | true |
| Fold full laundry load | Hard | weekly | true |
| Clean full bathroom | Hard | on_request | true |
| Mow lawn | Hard | weekly | true/false |
| Clear driveway | Hard | on_request | true |
| Wash car | Hard | on_request | true |
| Vacuum or mop entire house | Hard | weekly | true |
| Yard work / gardening | Hard | on_request | true |
| Walk the dogs | Hard | daily | true |
| Garage / attic / basement deep clean | Hard | on_request | true |
| Special Request | Flexible | on_request | true |

---

## Notes for App Integration
1. Tasks **above basic personal cleanup** are eligible for rewards.  
2. Each family member submits completed chores via app at the end of the day.  
3. Parent/Guardian reviews submissions to **approve or flag for review** if incomplete or suspicious.  
4. Rewards are automatically calculated based on difficulty tier.  
5. Flexible / Special Request tasks require manual approval and negotiable reward assignment.  
6. Daily, weekly, and monthly totals can be tracked for both screen time and cash earned.  
7. Optional streaks or bonus rewards can be added for consecutive days of completion.  
8. `Cadence` controls submission eligibility; `Active` toggles visibility in the app.  
