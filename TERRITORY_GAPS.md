# Territory Attack System - Gap Analysis (Revised)

**Status:** Territories system EXISTS but attack/claim logic NOT IMPLEMENTED

> ✅ Hex tile system being DROPPED. Focus: Territories only.

---

## What You Have ✅

### Database
| Component | Status | Details |
|-----------|--------|---------|
| `territories` table | ✅ EXISTS | Stores: user_id, energy, geom, polygon_points, protected_until, shield_until, last_visited |
| `Territory` model | ✅ EXISTS | All fields needed for game logic |
| Territory queries | ✅ EXISTS | `getNearbyTerritories()`, `getHomeTerritory()` |
| `walking_sessions` RPC | ✅ EXISTS | `end_walking_session()` merges convex hull |
| Attack energy system | ✅ EXISTS | Steps→energy conversion working |

### Tracking
- ✅ Player location during walk
- ✅ Speed validation (2-15 km/h check exists)
- ✅ Territory boundaries (polygon point checking)
- ✅ Notifications framework

---

## What You NEED ❌

### 1. Territory Attack/Claim RPC

A single RPC that handles:

```
When player walks through enemy territory:
✅ REQUIREMENT: Check speed 2-15 km/h
✅ REQUIREMENT: Get attacker's current energy
✅ REQUIREMENT: Get territory owner & energy
✅ REQUIREMENT: Check 12-hour protection window
✅ REQUIREMENT: Check 24-hour absence shield (energy floor = 20)
✅ REQUIREMENT: Check cooldown (30 min per territory)
✅ REQUIREMENT: If attack succeeds → update territory owner
✅ REQUIREMENT: If territory damaged → reduce energy
✅ REQUIREMENT: Consume attacker's energy
✅ REQUIREMENT: Set cooldown
✅ REQUIREMENT: Return action result
```

**Missing Function:**
```sql
attack_or_claim_territory(
  p_territory_id UUID,
  p_attacker_id UUID,
  p_lat FLOAT,
  p_lng FLOAT,
  p_speed_kmh FLOAT
)
RETURNS {
  action: 'claimed' | 'captured' | 'damaged' | 'protected' | 'cooldown' | 'no_energy' | 'not_friends',
  territory_energy_before: INT,
  territory_energy_after: INT,
  attacker_energy_left: INT,
  ...
}
```

### 2. Territory Cooldown Table

Track when a player can attack the same territory again.

**Missing Table:**
```sql
CREATE TABLE territory_attack_cooldowns (
  attacker_id UUID,
  territory_id UUID,
  cooldown_until TIMESTAMP
);
```

### 3. Territory Energy Modifiers

When claiming/defending territory, apply bonuses:

```
Base energy when claimed: 10
+5 energy: if owner revisits same day
+10 energy: if held 48+ hours
+15 energy: part of a cluster (3+ connected territories)
+10 energy: near home base
Max: 60 energy
```

**Missing Logic:**
- No calculation of these bonuses
- No cluster detection
- No home base proximity check

### 4. Territory Decay

After 3+ days without visit, territory loses energy.

**Missing:**
- No scheduled decay job
- No RPC: `decay_territories()`
- No logic: "If energy = 0, become neutral"

### 5. Territory Attack History Log

For UI showing "who attacked when":

**Missing Table:**
```sql
CREATE TABLE territory_attack_log (
  territory_id UUID,
  attacker_id UUID,
  action TEXT,
  energy_before INT,
  energy_after INT,
  created_at TIMESTAMP
);
```

### 6. Service Methods in Supabase Service

**Missing App Code:**
```dart
// MISSING: attackOrClaimTerritory()
Future<Map<String, dynamic>> attackOrClaimTerritory({
  required String territoryId,
  required double lat,
  required double lng,
  required double speedKmh,
})

// MISSING: get territory attack history
Future<List<Map>> getTerritoryAttackHistory(String territoryId)

// MISSING: check if territory is cooldown
Future<bool> isTerritoryOnCooldown(String territoryId)

// MISSING: get territory energy modifiers
Future<int> calculateTerritoryEnergy(String territoryId)

// MISSING: trigger decay
Future<void> decayTerritories()
```

### 7. Territory Events Tracking

Event log for when territories change:

**Table Exists But Empty:**
- `territory_events` table exists but never used

---

## The 6 Core Gaps (For Territory Attack)

| # | Gap | Impact | Complexity |
|---|-----|--------|-----------|
| 1 | No `attack_or_claim_territory()` RPC | **Can't attack** | High |
| 2 | No territory cooldown table | Players spam-attack | Medium |
| 3 | No energy modifiers logic | Unfair balance | Medium |
| 4 | No decay system | Territories never become neutral | Medium |
| 5 | No attack history table | No UI feedback | Low |
| 6 | No app methods calling RPC | App can't trigger attacks | Medium |

---

## What The Requirements Need

From your spec, these are the TERRITORY-specific requirements:

### Claiming Territory
```
1. When player walks through unclaimed area:
   ✅ Territory is automatically claimed
   ✅ Ownership transferred to player
   ✅ Energy set to 10 (base)
   ✅ Protected for 12 hours
   
2. When player re-walks their own territory:
   ✅ Energy increases (+5 each revisit, max 60)
   ✅ Last visited time updated
```

### Attacking Enemy Territory
```
1. When player walks through friend's territory:
   ✅ Check if within 2-15 km/h speed
   ❌ Check if territory in protected window (12h)
   ❌ Check if territory has absence shield (24h, energy floor 20)
   ✅ Use attack_energy to damage territory
   ✅ If energy depleted → capture territory
   ✅ If energy remains → damage and set cooldown (30 min)
   ❌ Set cooldown on attacker (can't attack this territory for 30 min)
   ❌ Transfer ownership if captured
```

### Territory Strength
```
Base: 10 energy
Modifiers:
  ❌ +5 if revisited same day
  ❌ +10 if held 48+ hours
  ❌ +15 if part of cluster (3+ connected)
  ❌ +10 if near home base
Max: 60 energy cap
```

### Protection Systems
```
Protection Window (12 hours):
  ✅ Model field exists (protectedUntil)
  ❌ NOT enforced in RPC
  ❌ NOT set on claim/capture

Absence Shield (24 hour):
  ✅ Model field exists (shieldUntil)
  ❌ NOT enforced in RPC
  ❌ Energy floor = 20 NOT implemented
```

### Decay
```
❌ If not visited 3+ days: lose 2 energy/day
❌ If energy = 0: become neutral (set owner_id = NULL)
❌ Scheduled daily job missing
```

---

## Mapping to Database

### territories table needs:
```sql
ALTER TABLE territories ADD COLUMN IF NOT EXISTS (
  last_visited_at TIMESTAMP DEFAULT NOW(),
  claimed_at TIMESTAMP DEFAULT NOW(),
  in_cluster BOOLEAN DEFAULT FALSE
);
```

### New tables needed:
```sql
CREATE TABLE territory_attack_cooldowns (
  attacker_id UUID,
  territory_id UUID,
  cooldown_until TIMESTAMP,
  PRIMARY KEY (attacker_id, territory_id)
);

CREATE TABLE territory_attack_log (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  territory_id UUID,
  attacker_id UUID,
  action TEXT,
  energy_before INT,
  energy_after INT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Implementation Checklist

### PHASE 1: Core Attack RPC (HIGH PRIORITY)

#### Step 1.1: Create attack_or_claim_territory RPC
```sql
-- Handles EVERYTHING:
-- - Neutral territory claim (no owner)
-- - Own territory reinforce (increase energy)
-- - Enemy territory attack (damage/capture)
-- - Protection window check
-- - Absence shield enforcement
-- - Cooldown check
-- - Energy consumption

function attack_or_claim_territory(
  p_territory_id UUID,
  p_attacker_id UUID,
  p_lat FLOAT,
  p_lng FLOAT,
  p_speed_kmh FLOAT
) RETURNS JSONB;
```

#### Step 1.2: Create territory cooldown table
```sql
CREATE TABLE territory_attack_cooldowns
```

#### Step 1.3: Create territory attack log
```sql
CREATE TABLE territory_attack_log
```

### PHASE 2: Energy Modifiers & Clusters (MEDIUM PRIORITY)

#### Step 2.1: Cluster detection RPC
```sql
function calculate_territory_cluster_bonus(p_territory_id UUID)
```

#### Step 2.2: Add cluster fields
```sql
ALTER TABLE territories ADD COLUMN in_cluster BOOLEAN
```

### PHASE 3: Decay System (MEDIUM PRIORITY)

#### Step 3.1: Create decay RPC
```sql
function decay_territories() RETURNS JSONB
```

#### Step 3.2: Schedule daily job
```sql
SELECT cron.schedule('decay_territories', '0 3 * * *', 'SELECT decay_territories()');
```

### PHASE 4: App Integration (HIGH PRIORITY)

#### Step 4.1: Add service method
```dart
Future<Map<String, dynamic>> attackOrClaimTerritory({
  required String territoryId,
  required double lat,
  required double lng,
  required double speedKmh,
})
```

#### Step 4.2: Call from map_provider
```dart
// When player is inside enemy territory at valid speed
final result = await _service.attackOrClaimTerritory(
  territoryId: territory.id,
  lat: position.latitude,
  lng: position.longitude,
  speedKmh: speedKmh,
);
```

#### Step 4.3: Handle result
```dart
// Update UI with attack result
// Refresh territories
// Show notifications
```

---

## Current Territory Data (Example)

From your DB (3 territories exist):
```
User A's territory: energy=25, protected_until=NULL, last_visited=2 days ago
User B's territory: energy=10, protected_until=2026-04-14T20:00Z, last_visited=1 hour ago  
User C's territory: energy=0 (should be neutral but still owned)
```

---

## Missing vs. Existing Summary

| Feature | Hex Tiles | Territories | Priority |
|---------|-----------|-------------|----------|
| Database table | ❌ Needed | ✅ Exists | N/A → DELETE |
| Attack RPC | ❌ Exists but broken | ❌ DOESN'T EXIST | **HIGH** |
| Cooldown system | ❌ Exists but broken | ❌ DOESN'T EXIST | **HIGH** |
| Protection window | ⚠️ Partial | ⚠️ Field but not enforced | **HIGH** |
| Absence shield | ❌ Not enforced | ❌ Not enforced | **HIGH** |
| Energy modifiers | ❌ Not calculated | ❌ Not calculated | MEDIUM |
| Cluster bonuses | ❌ Not calculated | ❌ Not calculated | MEDIUM |
| Decay system | ❌ Not implemented | ❌ Not implemented | MEDIUM |
| Attack log | ❌ Exists but unused | ⚠️ Table exists, unused | LOW |
| App methods | ❌ Broken | ❌ MISSING | **HIGH** |

---

## Time Estimate

| Phase | Task | Time |
|-------|------|------|
| 1a | Territory cooldown table | 20 min |
| 1b | Territory attack log table | 20 min |
| 1c | attack_or_claim_territory RPC | 120 min |
| 1d | App service method | 30 min |
| 1e | Map provider integration | 30 min |
| **Phase 1 Total** | **Core system** | **3.5 hours** |
| 2 | Energy modifiers & clusters | 90 min |
| 3 | Decay system | 60 min |
| 4 | Testing & refinement | 60 min |
| **TOTAL** | | **~6 hours** |

**Minimum viable:** Phase 1 only (3.5 h)  
**Full implementation:** All phases (6 h)

---

## Next Action

Ready for me to:
1. Create the attack_or_claim_territory RPC SQL?
2. Add service methods to supabase_service.dart?
3. Integrate into map_provider.dart?

Pick one and I'll implement it!

