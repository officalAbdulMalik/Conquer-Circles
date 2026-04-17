# Territory System - Exact Gaps & Database Fields

## Database Table Status

### ✅ `territories` - COMPLETE

| Column | Type | Exists | Used? | Notes |
|--------|------|--------|-------|-------|
| id | UUID | ✅ | ✅ | User ID (PK) |
| user_id | UUID | ✅ | ✅ | Foreign key to auth.users |
| username | TEXT | ✅ | ✅ | Owner's username |
| color | TEXT | ✅ | ✅ | Hex color for map |
| energy | INT (0-60) | ✅ | ✅ | Defensive power |
| geom | GEOMETRY | ✅ | ✅ | PostGIS polygon |
| polygon_points | JSONB | ✅ | ✅ | [{lat, lng}] for UI |
| capture_time | TIMESTAMP | ✅ | ⚠️ | Stored but not updated on capture |
| last_visited | TIMESTAMP | ✅ | ⚠️ | Stored but decay not implemented |
| protected_until | TIMESTAMP | ✅ | ⚠️ | Stored but NOT enforced in RPC |
| shield_until | TIMESTAMP | ✅ | ⚠️ | Stored but NOT enforced in RPC |
| created_at | TIMESTAMP | ✅ | ✅ | Auto-populated |
| updated_at | TIMESTAMP | ✅ | ⚠️ | Never updated on attack |

**Status:** All fields exist but NOT USED by attack logic

---

### ❌ `territory_attack_cooldowns` - MISSING

| Column | Type | Purpose |
|--------|------|---------|
| attacker_id | UUID | Attacker's user ID |
| territory_id | UUID | Territory being attacked |
| cooldown_until | TIMESTAMP | When cooldown expires |

**Status:** Table does NOT exist. Need to create.

---

### ❌ `territory_attack_log` - MISSING (Table exists but unused)

| Column | Type | Purpose |
|--------|------|---------|
| id | UUID | Log entry ID |
| territory_id | UUID | Which territory was attacked |
| attacker_id | UUID | Who attacked |
| defender_id | UUID | Territory owner |
| action | TEXT | 'claimed', 'captured', 'damaged', etc. |
| energy_before | INT | Territory energy pre-attack |
| energy_after | INT | Territory energy post-attack |
| attack_power_used | INT | Attacker's energy spent |
| created_at | TIMESTAMP | When it happened |

**Status:** Table definition doesn't exist. Need to create.

---

## App Service Methods - Status

### ✅ Methods That Exist

```dart
+ getNearbyTerritories(lat, lng, radius)      // Loads visible territories
+ getHomeTerritory()                           // Gets player's own territory
+ upsertTerritoryMetadata(territory)           // Updates territory (limited)
+ getAttackEnergy()                            // Gets player's current energy
+ convertStepsToEnergy(steps)                  // RPC: steps → energy
+ getTileState(tileId)                         // For HEX TILES (ignore)
+ hasCooldown(tileId)                          // For HEX TILES (ignore)
```

### ❌ Methods That Don't Exist (CRITICAL)

```dart
- attackOrClaimTerritory()                     // ← MAIN MISSING METHOD
- getTerritoryAttackHistory()                  // Helper for UI history
- isTerritoryOnCooldown()                      // Check if can attack
- getTerritoryEnergyModifier()                 // Cluster/proximity bonuses
- decayTerritories()                           // Daily decay job (RPC call)
```

---

## RPC Functions - Status

### ✅ RPCs That Exist

```sql
+ convert_steps_to_energy(user_id, steps)      // Steps → attack energy
+ convert_steps_to_xp(user_id, steps)          // Steps → XP progression
+ get_territories_nearby(lat, lng, radius)    // Load visible territories
+ get_home_territory(user_id)                 // Get player's territory
+ get_steps_dashboard()                        // Dashboard data
+ end_walking_session(session_id)             // Merges convex hull
+ start_walking_session(user_id)              // Creates walking session
```

### ❌ RPCs That Don't Exist (CRITICAL)

```sql
- attack_or_claim_territory(                   // ← MAIN MISSING RPC
    territory_id, 
    attacker_id, 
    lat, lng, 
    speed_kmh
  )                                          
  
  Should return: {
    action: 'claimed'|'captured'|'damaged'|'protected'|'cooldown'|'no_energy',
    territory_energy_before: INT,
    territory_energy_after: INT,
    attacker_energy_left: INT,
    cooldown_until: TIMESTAMP,
    ...
  }

- decay_territories()                          // -2 energy/day (3+ days no visit)
- calculate_cluster_bonus(territory_id)        // +5/+10/+20 energy cluster bonus
```

---

## Game Logic - Implementation Status

### When Player Enters Enemy Territory

```
┌─ Speed Check ────────────────────┐
│ Requirement: 2-15 km/h          │
│ Status: ✅ Implemented in app   │
│ Next: Speed passed to RPC        │
└─────────────────────────────────┘
          ↓
┌─ Territory Check ────────────────┐
│ Requirement: Point in polygon    │
│ Status: ✅ Implemented in app   │
│ Method: _isPointInPolygon()      │
└─────────────────────────────────┘
          ↓
┌─ Protection Window ──────────────┐
│ Requirement: ≤12 hours old       │
│ Field: protected_until (✅ exists)│
│ Logic: ❌ NOT IN RPC             │
│ Action: Block if protected       │
└─────────────────────────────────┘
          ↓
┌─ Absence Shield ─────────────────┐
│ Requirement: 24h since visit     │
│ Field: shield_until (✅ exists)   │
│ Logic: ❌ NOT IN RPC             │
│ Action: Energy floor = 20        │
└─────────────────────────────────┘
          ↓
┌─ Cooldown Check ─────────────────┐
│ Requirement: 30 min between hits │
│ Table: ❌ DOESN'T EXIST          │
│ Logic: ❌ NOT IMPLEMENTED        │
│ Action: Block if on cooldown     │
└─────────────────────────────────┘
          ↓
┌─ Energy Check ───────────────────┐
│ Requirement: Player has energy   │
│ Status: ✅ Query exists          │
│ Logic: ✅ Check happens elsewhere│
│ Action: Block if 0 energy        │
└─────────────────────────────────┘
          ↓
┌─ ATTACK LOGIC ───────────────────┐
│ Requirement: Compare energies    │
│ Status: ❌ RPC DOESN'T EXIST     │
│ Should do:                       │
│  - Compare territory vs attacker │
│  - Calculate damage              │
│  - Check if captured             │
│  - Update ownership if captured  │
│  - Consume energy                │
│  - Set cooldown                  │
│  - Log action                    │
│  - Send notifications            │
│ Action: EVERYTHING BLOCKED       │
└─────────────────────────────────┘
```

---

## The 6 Things You Need to Do

### Priority 1 (System Won't Work Without These)

#### 1️⃣ Create Migration: territory_attack_cooldowns

```sql
CREATE TABLE public.territory_attack_cooldowns (
  attacker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  territory_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cooldown_until TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  PRIMARY KEY (attacker_id, territory_id)
);

CREATE INDEX idx_cooldowns_expiry ON territory_attack_cooldowns(cooldown_until);
```

**Time: 20 min**

#### 2️⃣ Create Migration: territory_attack_log

```sql
CREATE TABLE public.territory_attack_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  territory_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  attacker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  energy_before INT NOT NULL,
  energy_after INT NOT NULL,
  attack_power_used INT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_attack_log_territory ON territory_attack_log(territory_id);
```

**Time: 20 min**

#### 3️⃣ Create RPC: attack_or_claim_territory()

The BIG one - contains all attack logic, protection checks, energy recalc, etc.

```sql
CREATE OR REPLACE FUNCTION attack_or_claim_territory(
  p_territory_id UUID,
  p_attacker_id UUID,
  p_lat FLOAT,
  p_lng FLOAT,
  p_speed_kmh FLOAT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
-- 100+ lines of logic for all game mechanics
-- See TERRITORY_GAPS.md for full SQL code
$$;
```

**Time: 120 min** (see full code in TERRITORY_GAPS.md)

#### 4️⃣ Add Service Method

In `lib/services/supabase_service.dart`:

```dart
Future<Map<String, dynamic>> attackOrClaimTerritory({
  required String territoryId,
  required double lat,
  required double lng,
  required double speedKmh,
}) async {
  final user = currentUser;
  if (user == null) return {'action': 'error'};
  
  try {
    final response = await _client.rpc(
      'attack_or_claim_territory',
      params: {
        'p_territory_id': territoryId,
        'p_attacker_id': user.id,
        'p_lat': lat,
        'p_lng': lng,
        'p_speed_kmh': speedKmh,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  } catch (e) {
    _log('attackOrClaimTerritory', e);
    return {'action': 'error', 'message': e.toString()};
  }
}
```

**Time: 30 min**

#### 5️⃣ Integrate into Map Provider

In `lib/providers/map_provider.dart`, update `_handleLocationUpdate()`:

```dart
// When inside territory at valid speed:
if (speedKmh >= 2 && speedKmh <= 15) {
  final territoryId = _findTerritoryAtLocation(latLng);
  if (territoryId != null) {
    final result = await _service.attackOrClaimTerritory(
      territoryId: territoryId,
      lat: position.latitude,
      lng: position.longitude,
      speedKmh: speedKmh,
    );
    await _handleAttackResult(result, latLng);
  }
}
```

**Time: 30 min**

### Priority 2 (Game Works But Not Perfect)

#### 6️⃣ Add Decay System

Create RPC to decay territory energy daily:

```sql
CREATE OR REPLACE FUNCTION decay_territories()
RETURNS JSONB
-- Lose 2 energy/day after 3 days no visit
-- Become neutral when energy = 0
```

Schedule daily run with `pg_cron`.

**Time: 60 min**

---

## Summary

| Item | Status | What to Do |
|------|--------|-----------|
| Database: territories | ✅ Exists | Nothing |
| Database: cooldowns | ❌ Missing | Create table (20 min) |
| Database: attack log | ❌ Missing | Create table (20 min) |
| RPC: attack logic | ❌ Missing | Create RPC (120 min) |
| Service method | ❌ Missing | Add method (30 min) |
| Map integration | ⚠️ Partial | Update provider (30 min) |
| Decay system | ❌ Missing | Optional (60 min) |
| **TOTAL** | **20% complete** | **~3.5 hours** |

---

## Files to Create

```
supabase/migrations/
├── YYYYMMDDHHMMSS_create_territory_attack_cooldowns.sql
├── YYYYMMDDHHMMSS_create_territory_attack_log.sql
└── YYYYMMDDHHMMSS_create_attack_or_claim_territory_rpc.sql

Modifications:
├── lib/services/supabase_service.dart (add method)
├── lib/providers/map_provider.dart (call method)
└── (optional) supabase migrations for decay RPC
```

---

## Next Steps

1. Ready to implement? Pick one:
   - ✅ Create migrations (tables)
   - ✅ Create RPC (logic)
   - ✅ Add service method
   - ✅ Integrate into map provider
   - ✅ All of the above

2. Need the SQL code? See **TERRITORY_GAPS.md** (complete code provided)

3. Questions? See **SUMMARY_TERRITORIES_ONLY.md** (quick overview)

