# claim_or_attack_tile RPC Analysis

## Overview
The current `claim_or_attack_tile` RPC is designed for **hexagon tiles** (H3 grid system), NOT for **territories** (polygon-based). This is a **CRITICAL SYSTEM MISMATCH**.

---

## 🔴 CRITICAL GAPS & LOGICAL ISSUES

### 1. **WRONG TABLE TARGET**
**Issue:** RPC operates on `hex_tiles` table, but your game uses `territories` table.
```sql
-- CURRENT (WRONG)
SELECT * INTO v_tile FROM hex_tiles WHERE tile_id = p_tile_id FOR UPDATE;

-- SHOULD BE (TERRITORIES)
SELECT * INTO v_territory FROM territories WHERE id = p_territory_id FOR UPDATE;
```
**Impact:** RPC will never find territories; all attacks fail silently or throw errors.

---

### 2. **MISSING SPEED VALIDATION**
**Issue:** RPC accepts `p_lat`, `p_lng` parameters but NEVER validates walking speed (2-15 km/h).
```sql
-- CURRENT CODE (NO SPEED CHECK)
...parameters: {
  'p_tile_id': tileId,
  'p_user_id': user.id,
  'p_lat': lat,
  'p_lng': lng,
}
-- NO p_speed parameter!
```

**What's Missing:**
- No `p_speed` parameter in RPC signature
- No speed validation logic
- App passes `speedKmh` to `_processTileEntry()` but **DOESN'T pass it to RPC**

**App Code Shows Intent (line 296):**
```dart
final result = await _service.claimOrAttackTile(
  tileId: tileId,
  lat: location.latitude,
  lng: location.longitude,
  // ❌ MISSING: speedKmh parameter
);
```

**Frontend Speed Check (line 443):**
```dart
Future<Map<String, dynamic>?> onEnterTile(String tileId) async {
  final speedKmh = state.currentSpeedKmh;
  if (speedKmh < 2 || speedKmh > 15) return null; // ← Validates locally only
  // ...
}
```

**Impact:** 
- Speed validation happens ONLY on app side (easy to bypass with modified app)
- RPC has no server-side control
- User can cheat by spoofing GPS speed

---

### 3. **WRONG ENERGY MODEL**
**Issue:** RPC uses fixed attack values that don't match your game requirements.

**Current Logic (WRONG):**
```sql
v_attack_power  INT := 10;     -- Fixed 10 damage per attack
v_energy_cost   INT := 10;     -- Fixed 10 energy cost per attack
```

**Your Requirements (CORRECT):**
- Energy range: 0-60 per territory
- Attack cost: Full energy expenditure (not fixed 10)
- Damage based on attacker's current energy vs territory energy
- Example: If you have 25 energy, all 25 is used in attack

**Current Impact:**
- Territory can have 60 energy, you hit for 10 damage → 6 attacks needed
- This contradicts your "consume energy on attack" design

---

### 4. **WRONG PROTECTION FIELDS**
**Issue:** Protection logic references wrong columns and checks wrong conditions.

**Current (Hex Tiles):**
```sql
-- Uses hex_tiles columns
IF v_tile.protection_until IS NOT NULL AND v_tile.protection_until > NOW() THEN
IF v_owner_territory.protection_until IS NOT NULL AND v_owner_territory.protection_until > NOW()
```

**Missing (Territory System):**
```sql
-- Should check BOTH columns
protection_until  -- 12-hour protection after claim
shield_until      -- 24-hour absence shield (blocks attacks if steps > 0)
```

**Logical Flaw:** 
The RPC checks `protection_until` but:
1. Never validates `shield_until` properly
2. Never checks if defender walked today (steps > 0)
3. Never applies the "absence floor" (20 energy minimum)

---

### 5. **WRONG CAPTURE LOGIC**
**Issue:** Capture condition doesn't account for absence shield or energy floors.

**Current (WRONG):**
```sql
v_captured := (v_attack_power >= v_tile.tile_energy AND v_absence_floor = 0);
v_new_energy := CASE
  WHEN v_captured THEN 0
  ELSE GREATEST(v_tile.tile_energy - v_attack_power, v_absence_floor)
END;
```

**Problems:**
1. Uses fixed `v_attack_power` (10) instead of attacker's actual energy
2. Sets captured energy to 0 instead of 10 (new starter energy)
3. Doesn't account for cluster bonuses

**Your Requirements:**
- Capture if: `attacker_energy >= territory_energy AND no_absence_shield`
- Captured territory should start at 10 energy (not 0)
- Must add cluster bonuses to defender's territory

---

### 6. **MISSING COOLDOWN TABLE REFERENCE**
**Issue:** RPC checks `attack_cooldowns` table, but your app needs `territory_attack_cooldowns`.

**Current Breaks:**
```sql
IF EXISTS (
  SELECT 1 FROM attack_cooldowns  -- ← Old hex system table
  WHERE attacker_id = p_user_id AND tile_id = p_tile_id AND cooldown_until > NOW()
)
```

**Should Be:**
```sql
IF EXISTS (
  SELECT 1 FROM territory_attack_cooldowns
  WHERE attacker_id = p_user_id AND territory_id = p_territory_id AND cooldown_until > NOW()
)
```

---

### 7. **FRIEND CHECK IS WRONG LOGIC**
**Issue:** RPC rejects attacks if NOT in same circle, but territories should allow attacks on friends only.

**Current Logic (CONFUSING):**
```sql
IF NOT v_in_same_circle THEN
  IF NOT EXISTS (invites check) THEN
    RETURN error 'not_in_circle'
  END IF;
END IF;
```

**Problems:**
1. Checks circle first, then falls back to friend check (backwards)
2. Allows strangers if they're in ANY circle together
3. Doesn't match your requirement: "friends only"

**Correct Logic:**
```sql
-- Must be in accepted friend invite AND territories are nearby
SELECT EXISTS(
  SELECT 1 FROM invites
  WHERE status = 'accepted' AND invite_type = 'friend'
  AND ((inviter_id = p_user_id AND invitee_id = v_territory.user_id)
    OR (invitee_id = p_user_id AND inviter_id = v_territory.user_id))
) INTO v_is_friend;

IF NOT v_is_friend THEN
  RETURN error 'not_friends'
END IF;
```

---

### 8. **LOG TABLE MISMATCH**
**Issue:** RPC writes to `tile_attack_log` but should write to `territory_attack_log`.

**Current:**
```sql
INSERT INTO tile_attack_log (
  tile_id, attacker_id, defender_id,
  attack_energy_used, tile_energy_before, tile_energy_after, captured
)
```

**Should Be:**
```sql
INSERT INTO territory_attack_log (
  territory_id, attacker_id, defender_id,
  energy_used, energy_before, energy_after, captured
)
```

---

### 9. **NOTIFICATION SYSTEM BROKEN**
**Issue:** Notifications reference old tables/functions that may not exist.

**Current:**
```sql
PERFORM notify_user(v_tile.owner_id, 'territory_lost', ...)
PERFORM notify_user(p_user_id, 'raid_victory', ...)
```

**Issues:**
1. Uses `notify_user()` which may have wrong signature
2. Sends duplicate notifications (territory_lost + raid_victory for one event)
3. No concept of "last notification" to prevent spam

---

### 10. **MISSING CLUSTER BONUS LOGIC**
**Issue:** RPC checks `tile_clusters` table that doesn't exist in territory system.

**Current (HEX TILES):**
```sql
IF v_tile.cluster_id IS NOT NULL THEN
  SELECT COALESCE(bonus_energy, 0) INTO v_cluster_bonus
    FROM tile_clusters WHERE cluster_id = v_tile.cluster_id;
  v_add := v_add + v_cluster_bonus;
END IF;
```

**Territory System:** 
- Clusters calculated from nearby territories in same circle
- +5 for 3 adjacent, +10 for 7 adjacent, +20 for 15 adjacent
- Must detect clusters dynamically (no cluster_id field)

---

### 11. **MISSING DECAY LOGIC**
**Issue:** No decay system implemented. Territories don't become neutral over time.

**Current:** Nothing (decay RPC doesn't exist)

**Your Requirements:**
- 2 energy/day after 3+ days no visit
- Becomes neutral at 0 energy
- Should run on schedule (pg_cron job)

---

## 🟡 APP-SIDE VALIDATION ISSUES

### Speed Validation (App Only)
**Location:** [map_provider.dart#L443](lib/providers/map_provider.dart#L443)
```dart
Future<Map<String, dynamic>?> onEnterTile(String tileId) async {
  final speedKmh = state.currentSpeedKmh;
  if (speedKmh < 2 || speedKmh > 15) return null; // ← Only on app
}
```

**Problem:** 
- App rejects locally but RPC accepts any speed
- Cheater can modify app or use API directly
- Should ALSO validate on RPC

**Correct Approach:**
1. **App validates first** (UX feedback)
2. **RPC validates again** (security)

### Protection Validation (App Only)
**Location:** Not found in app code

**Problem:** 
- App should check `protection_until` and `shield_until` from territory data
- Prevent UI interactions when protected
- But RPC must also validate (in case app is bypassed)

---

## ✅ WHAT APP SIDE CAN DO

**User's Intent:** "Validation of speed countdown and protected will be on app side on the data from supabase not on the backend so app can easily trigger the conditions"

### This means:
1. **App fetches** `territories` with `protection_until`, `shield_until` timestamps
2. **App calculates:**
   - Is protected? `protection_until > NOW()`
   - Is shielded? `shield_until > NOW() AND steps_today > 0`
   - Can attack? `speed_valid AND not_protected AND has_energy`
3. **App updates UI** based on these conditions
4. **RPC still validates** as final check (for security)

### Example Data From Supabase:
```dart
final territory = Territory(
  id: '123',
  userId: 'attacker-id',
  energy: 25,
  protectionUntil: DateTime.now().add(Duration(hours: 2)),
  shieldUntil: DateTime.now().add(Duration(hours: 24)),
  lastVisited: DateTime.now().subtract(Duration(days: 1)),
);

// App calculates
final isProtected = territory.protectionUntil!.isAfter(DateTime.now());
final isShielded = territory.shieldUntil!.isAfter(DateTime.now());
const bool defendedToday = true; // from steps_today check

if (isProtected) {
  // Show: "Protected for 2h remaining"
}
if (isShielded && defendedToday) {
  // Show: "Absence shield active"
}
```

---

## 📋 REQUIRED FIXES (Priority Order)

### Priority 1: CRITICAL (Blocks Game)
- [ ] **Create new RPC** `attack_or_claim_territory()` that works with territories table
- [ ] Add speed parameter and validate 2-15 km/h
- [ ] Implement correct energy model (consume full energy on attack)
- [ ] Add territory_attack_cooldowns table check
- [ ] Create territory_attack_log table
- [ ] Implement capture logic with absence shield

### Priority 2: HIGH (Breaks Logic)
- [ ] Add cluster bonus calculation for territories
- [ ] Fix friend/circle validation logic
- [ ] Implement energy floor (20) logic
- [ ] Add decay RPC + pg_cron scheduler

### Priority 3: MEDIUM (Polish)
- [ ] Update notifications system
- [ ] Add speed parameter to app's claimOrAttackTile()
- [ ] Add territory data with timestamps to nearby-territories response

### Priority 4: LOW (Optional)
- [ ] Add revisit bonus calculation
- [ ] Add first-capture bonus
- [ ] Dashboard stats updates

---

## 🔑 Key Takeaway

**The current `claim_or_attack_tile` RPC is for the deprecated HEX TILE system.**

Your game needs a **NEW RPC** specifically for territories that:
1. ✅ Targets `territories` table (not `hex_tiles`)
2. ✅ Validates speed 2-15 km/h on backend
3. ✅ Uses full energy consumption model
4. ✅ Checks `territory_attack_cooldowns` (not `attack_cooldowns`)
5. ✅ Implements absence shield logic
6. ✅ Returns clear app-triggerable conditions (protected, shielded, cooldown, etc.)

**App receives:** `{ action: 'protected'|'shielded'|'cooldown'|'damaged'|'captured'|'no_energy', ... }`

**App displays:** Cool-downs, remaining protection time, why attack failed (for UX clarity)
