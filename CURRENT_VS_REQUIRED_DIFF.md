# Side-by-Side: Current vs Required

## Problem 1: Wrong Table

### ❌ CURRENT (HEX TILES)
```sql
SELECT * INTO v_tile FROM hex_tiles WHERE tile_id = p_tile_id FOR UPDATE;

IF v_tile.tile_id IS NULL OR v_tile.owner_id IS NULL THEN
  -- This is NULL for every territory because hex_tiles table has 0 territory data
END IF;

INSERT INTO hex_tiles (tile_id, owner_id, tile_energy, ...)
  VALUES (p_tile_id, p_user_id, ...);
```

### ✅ REQUIRED (TERRITORIES)
```sql
SELECT * INTO v_territory FROM territories WHERE id = p_territory_id FOR UPDATE;

IF v_territory.id IS NULL THEN
  -- Return error (territory doesn't exist)
END IF;

UPDATE territories
SET user_id = p_user_id, energy = ..., ...
WHERE id = p_territory_id;
```

**Impact:** Current RPC always fails silently or throws "table hex_tiles missing" error.

---

## Problem 2: No Speed Validation

### ❌ CURRENT
```dart
Future<Map<String, dynamic>> claimOrAttackTile({
  required String tileId,
  required double lat,          // ← only location
  required double lng,
  // ❌ NO speed parameter!
}) async {
  final response = await _client.rpc(
    'claim_or_attack_tile',
    params: {
      'p_tile_id': tileId,
      'p_user_id': user.id,
      'p_lat': lat,
      'p_lng': lng,
      // ❌ NO speed passed to RPC
    },
  );
}
```

### ✅ REQUIRED
```dart
Future<Map<String, dynamic>> attackOrClaimTerritory({
  required String territoryId,
  required double speedKmh,     // ✅ Speed parameter
  required double lat,
  required double lng,
}) async {
  final response = await _client.rpc(
    'attack_or_claim_territory',
    params: {
      'p_territory_id': territoryId,
      'p_user_id': user.id,
      'p_speed_kmh': speedKmh,  // ✅ Speed to RPC
      'p_lat': lat,
      'p_lng': lng,
    },
  );
}
```

**Impact:** Current RPC has no speed check. Player can cheat by modifying GPS or app.

---

## Problem 3: Wrong Energy Model

### ❌ CURRENT (FIXED DAMAGE)
```sql
v_attack_power  INT := 10;     -- FIXED: Always 10 damage
v_energy_cost   INT := 10;     -- FIXED: Always 10 cost

v_captured := (v_attack_power >= v_tile.tile_energy AND v_absence_floor = 0);
v_new_energy := CASE
  WHEN v_captured THEN 0        -- ❌ Captured = 0 energy (wrong)
  ELSE GREATEST(v_tile.tile_energy - v_attack_power, v_absence_floor)
END;

UPDATE profiles
  SET attack_energy = attack_energy - v_energy_cost  -- Only deduct 10!
```

### ✅ REQUIRED (FULL ENERGY)
```sql
v_energy_to_consume := v_attacker.attack_energy;  -- ✅ ALL energy used

v_captured := (v_attacker_energy_before >= v_territory_energy_before);
v_new_energy := CASE
  WHEN v_captured THEN 10       -- ✅ Captured = 10 starting energy
  ELSE GREATEST(territory_energy - attacker_energy, 20)
END;

UPDATE profiles
  SET attack_energy = GREATEST(attack_energy - v_energy_to_consume, 0);
```

**Impact:** 
- Current: Territory with 60 energy requires 6 attacks of 10 damage each
- Required: Territory with 60 energy requires 1 attack with 60 energy
- **These are completely different game mechanics**

---

## Problem 4: Wrong Protection Logic

### ❌ CURRENT
```sql
-- Checks ONLY protection_until on hex_tiles
IF v_tile.protection_until IS NOT NULL AND v_tile.protection_until > NOW() THEN
  -- Only checks one timestamp
  RETURN error 'protected'
END IF;

-- Then checks owner's territory (weird two-tier check)
IF v_owner_territory.protection_until IS NOT NULL AND v_owner_territory.protection_until > NOW() THEN
  RETURN error 'protected'
END IF;

-- Completely wrong: doesn't check shield_until at all
-- Doesn't check if defender walked today (steps > 0)
```

### ✅ REQUIRED
```sql
-- Check 12-hour capture protection
IF v_territory.protection_until IS NOT NULL AND v_territory.protection_until > NOW() THEN
  RETURN jsonb_build_object(
    'action', 'protected',
    'reason', 'protection_active',
    'hours_remaining', hours
  )
END IF;

-- Check 24-hour absence shield (only active if steps > 0)
SELECT COALESCE(steps, 0) INTO v_defense_steps_today
  FROM daily_steps WHERE user_id = v_territory.user_id AND date = CURRENT_DATE;

v_is_shielded := (
  v_territory.shield_until IS NOT NULL
  AND v_territory.shield_until > NOW()
  AND v_defense_steps_today > 0
);

IF v_is_shielded THEN
  RETURN jsonb_build_object(
    'action', 'shielded',
    'reason', 'absence_shield_active'
  )
END IF;
```

**Impact:** Current allows bypass of protection rules by attacking during shield window.

---

## Problem 5: Cooldown Table Mismatch

### ❌ CURRENT
```sql
-- Checks OLD hex tile cooldown table (doesn't exist for territories)
IF EXISTS (
  SELECT 1 FROM attack_cooldowns  -- ❌ Old system table
  WHERE attacker_id = p_user_id 
  AND tile_id = p_tile_id         -- ❌ References tile, not territory
  AND cooldown_until > NOW()
) THEN
  RETURN error 'cooldown'
END IF;

-- Insert into old table
INSERT INTO attack_cooldowns (...)  -- ❌ Old tables
```

### ✅ REQUIRED
```sql
-- Checks NEW territory cooldown table
IF EXISTS (
  SELECT 1 FROM territory_attack_cooldowns  -- ✅ New system table
  WHERE attacker_id = p_user_id
  AND territory_id = p_territory_id        -- ✅ References territory
  AND cooldown_until > NOW()
) THEN
  RETURN error 'cooldown'
END IF;

-- Insert into new table
INSERT INTO territory_attack_cooldowns (
  attacker_id, territory_id, cooldown_until
)
VALUES (p_user_id, p_territory_id, NOW() + INTERVAL '30 minutes');
```

**Impact:** Current cooldown check finds 0 results (table empty), allows spam attacks.

---

## Problem 6: Friend Check is Backwards

### ❌ CURRENT (CONFUSING LOGIC)
```sql
-- First check circle membership
SELECT EXISTS (
  SELECT 1 FROM circle_members cm1
  JOIN circle_members cm2 ON cm2.circle_id = cm1.circle_id
  WHERE cm1.user_id = p_user_id
  AND cm2.user_id = v_tile.owner_id
) INTO v_in_same_circle;

-- Then if NOT in circle, check friend relationship (backwards!)
IF NOT v_in_same_circle THEN
  IF NOT EXISTS (invites check) THEN
    RETURN error 'not_in_circle'
  END IF;
END IF;
-- ❌ Allows ANY circle members to attack (not just friends)
```

### ✅ REQUIRED (FRIENDS ONLY)
```sql
-- Check ONLY friend relationships
SELECT EXISTS(
  SELECT 1 FROM invites
  WHERE status = 'accepted' AND invite_type = 'friend'
  AND (
    (inviter_id = p_user_id AND invitee_id = v_territory.user_id)
    OR (invitee_id = p_user_id AND inviter_id = v_territory.user_id)
  )
) INTO v_is_friend;

IF NOT v_is_friend THEN
  RETURN jsonb_build_object(
    'action', 'error',
    'reason', 'not_friends',
    'message', 'You can only attack territories owned by your friends'
  )
END IF;
```

**Impact:** Current allows attacks between ANY circle members, not just friends.

---

## Problem 7: Capture Logic is Wrong

### ❌ CURRENT
```sql
-- Uses FIXED attack_power, not attacker's actual energy
v_attack_power INT := 10;  -- ❌ Always 10

-- Capture when fixed 10 >= tile energy
v_captured := (v_attack_power >= v_tile.tile_energy AND v_absence_floor = 0);

-- Captured tile becomes 0 energy (wrong)
v_new_energy := CASE
  WHEN v_captured THEN 0  -- ❌ Captured = 0 is gamebreaking
  ELSE GREATEST(...)
END;

-- Never adds cluster bonuses to new owner
-- Never checks if attacker is in home circle
```

### ✅ REQUIRED
```sql
-- Uses attacker's ACTUAL energy
v_energy_to_consume := v_attacker.attack_energy;

-- Capture when attacker energy >= territory energy
v_captured := (v_attacker_energy_before >= v_territory_energy_before);

-- Captured territory starts at 10 (balanced for new owner)
v_new_energy := CASE
  WHEN v_captured THEN 10  -- ✅ Fair starting energy
  ELSE GREATEST(
    v_territory_energy_before - v_attacker_energy_before,  -- Damage = attacker energy
    20  -- Minimum floor (absence shield protection)
  )
END;

-- Update to new owner with protections
UPDATE territories
SET
  user_id = p_user_id,
  energy = 10,
  protection_until = NOW() + INTERVAL '12 hours',
  shield_until = NOW() + INTERVAL '24 hours',
  capture_time = NOW()
WHERE id = p_territory_id;
```

**Impact:** Current makes captured territories worthless (0 energy) with no protection.

---

## Problem 8: Energy Response Values Wrong

### ❌ CURRENT RESPONSE
```json
{
  "action": "damaged",
  "tile_id": "abc123",
  "tile_energy_before": 30,
  "tile_energy_after": 20,
  "attacker_energy_left": 12,
  "message": "You damaged the tile!"
}
// ❌ Missing clear action reasons
// ❌ No protection_until timestamp
// ❌ No cooldown times
```

### ✅ REQUIRED RESPONSE
```json
{
  "action": "damaged",
  "territory_id": "abc123",
  "captured": false,
  "energy_used": 15,
  "territory_energy_before": 30,
  "territory_energy_after": 15,
  "attacker_energy_remaining": 0,
  "cooldown_until": "2026-04-14T15:30:00Z",
  "message": "Territory damaged! Energy reduced from 30 to 15"
}
```

**Error Response Example:**
```json
{
  "action": "protected",
  "reason": "protection_active",
  "hours_remaining": 8.5,
  "message": "This territory is protected from attacks"
}
```

**Impact:** App can't determine WHY attack failed (reason codes).

---

## Problem 9: Log Table Schema Mismatch

### ❌ CURRENT TABLE
```sql
CREATE TABLE tile_attack_log (
  id UUID PRIMARY KEY,
  tile_id TEXT,           -- ❌ Wrong: territory uses UUID
  attacker_id UUID,
  defender_id UUID,
  attack_energy_used INT,
  tile_energy_before INT,
  tile_energy_after INT,
  captured BOOLEAN
);

INSERT INTO tile_attack_log (...)  -- ❌ Only for old hex system
```

### ✅ REQUIRED TABLE
```sql
CREATE TABLE territory_attack_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  territory_id UUID NOT NULL REFERENCES territories(id),
  attacker_id UUID NOT NULL REFERENCES profiles(id),
  defender_id UUID NOT NULL REFERENCES profiles(id),
  energy_used INT NOT NULL,
  energy_before INT NOT NULL,
  energy_after INT NOT NULL,
  captured BOOLEAN NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO territory_attack_log (...)  -- ✅ Referenced by new RPC
```

**Impact:** Current RPC tries to insert into wrong table (doesn't exist or wrong schema).

---

## Problem 10: No Logging of Why Validation Failed

### ❌ CURRENT
```dart
Future<void> _handleAttackResult(
  Map<String, dynamic> result,
  LatLng location,
) async {
  // ❌ No way to know WHY attack failed
  if (result['action'] == 'error') {
    showMessage('Attack failed');  // Vague!
  }
}
```

### ✅ REQUIRED
```dart
Future<void> _handleAttackResult(
  Map<String, dynamic> result,
  LatLng location,
) async {
  final action = result['action'] as String;
  
  switch (action) {
    case 'protected':
      final hours = result['hours_remaining'];
      showMessage('🛡️ Protected for $hours hours');  // Clear!
      break;
    case 'shielded':
      final hours = result['hours_remaining'];
      showMessage('⚡ Absence shield active for $hours hours');
      break;
    case 'cooldown':
      final minutes = result['minutes_remaining'];
      showMessage('⏱️ Cooldown: Wait $minutes minutes');
      break;
    case 'no_energy':
      showMessage('💥 No attack energy available');
      break;
    case 'error':
      final reason = result['reason'];
      showMessage('Error: $reason');
      break;
    // ... etc
  }
}
```

**Impact:** Player has no idea why attack failed (UX problem).

---

## Summary: Current vs Required

| Aspect | Current ❌ | Required ✅ |
|--------|-----------|-----------|
| **Table** | hex_tiles | territories |
| **Speed Check** | None | 2-15 km/h server-side |
| **Energy Model** | Fixed 10 damage | Full energy consumed |
| **Energy Cost** | Only 10 deducted | All energy deducted |
| **Captured Energy** | 0 (broken) | 10 (balanced) |
| **Protection Check** | 1 timestamp | protection_until + shield_until |
| **Shield Logic** | Missing | shield_until + steps_today |
| **Capture Logic** | Fixed 10 >= energy | attacker >= territory |
| **Cooldown Table** | attack_cooldowns | territory_attack_cooldowns |
| **Friend Check** | Backwards (allows circles) | Friends only |
| **Log Table** | tile_attack_log | territory_attack_log |
| **Response Codes** | Vague (just "error") | Clear (protected/shielded/cooldown) |
| **Error Messages** | Generic | Specific with remaining times |

---

## Impact Assessment

### What Doesn't Work Currently
- ❌ Attacking territories (wrong table)
- ❌ Speed validation (missing)
- ❌ Energy model (wrong math)
- ❌ Protection enforcement (broken logic)
- ❌ Cooldowns (wrong table)
- ❌ Attack history (wrong table/schema)

### What Works Accidentally
- ✅ App reads location (fine)
- ✅ App calculates speed (fine)
- ✅ Energy generation (separate system)
- ✅ Walking sessions (separate system)

### What's Completely Missing
- ❌ New RPC function
- ❌ Cooldown table
- ❌ Attack log table
- ❌ Event tracking table
- ❌ Decay system
- ❌ Cluster bonus logic

**Result:** The entire attack/claim/defense system is non-functional.

