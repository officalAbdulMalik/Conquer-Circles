# Territory & Attack System - Gap Analysis & Implementation Plan

## Current State vs Required Logic

### CRITICAL GAPS FOUND

#### 1. **DATABASE SCHEMA - MISSING TABLES** ❌
- `hex_tiles` table **DOES NOT EXIST**
- `attack_cooldowns` table **DOES NOT EXIST**
- `tile_attack_log` table **DOES NOT EXIST** (for history tracking)
- `territory_clusters` table **DOES NOT EXIST** (for cluster bonuses)

**Status:** Migration files needed

---

#### 2. **CORE RPCS - MISSING** ❌
- `claim_or_attack_tile` RPC **DOES NOT EXIST**
- `decay_territories` RPC **DOES NOT EXIST** (runs on schedule)
- `get_hex_tiles_in_bounds` RPC **DOES NOT EXIST**
- `calculate_cluster_bonus` RPC **DOES NOT EXIST**

**Status:** Code referenced in app but backend not implemented

---

#### 3. **PROTECTION SYSTEMS - NOT IMPLEMENTED** ❌

**Protection Window (Anti-Frustration):**
- ✅ Model defined in `MapTile` (protectionUntil field)
- ❌ NOT enforced in database
- ❌ NOT set on tile claim (should be 12 hours)
- ❌ NOT returned by claim_or_attack_tile RPC

**Absence Shield (Work/Vacation Protection):**
- ❌ Tile energy minimum (20) NOT enforced
- ❌ Last active check NOT implemented
- ❌ Logic missing: "if user active in last 24h, tile energy floor is 20"

**Status:** Partially designed, not implemented

---

#### 4. **TERRITORY DECAY - NOT IMPLEMENTED** ❌
- ❌ No scheduled decay job
- ❌ No decay RPC
- ❌ No tracking of "days since visit"
- ❌ No logic: "If not visited 3 days → lose 2 energy/day"
- ❌ No logic: "If energy reaches 0 → becomes neutral"

**Status:** Completely missing

---

#### 5. **CLUSTER BONUS SYSTEM - NOT IMPLEMENTED** ❌
- ❌ No cluster detection logic
- ❌ No cluster bonus calculation (3 tiles +5, 7 tiles +10, 15 tiles +20)
- ❌ No connected tiles verification
- ❌ Clusters not tracked in DB

**Status:** Completely missing

---

#### 6. **ATTACK ENERGY CONVERSION - PARTIALLY IMPLEMENTED** ⚠️
- ✅ Conversion RPC exists (`convert_steps_to_energy`)
- ✅ Daily cap implemented (400 free / 600 premium)
- ❌ **ISSUE**: Conversion rate is **10 steps = 1 energy** (should be **100 steps = 1 energy**)
- ❌ Energy consumed NOT tracked when tile attacked
- ❌ Attack energy cap NOT enforced at 400/600 during attacks

**Status:** Partially implemented, wrong ratio

---

#### 7. **COOLDOWN SYSTEM - PARTIALLY IMPLEMENTED** ⚠️
- ✅ `attack_cooldowns` table exists in code reference
- ✅ `hasCooldown()` method exists in service
- ❌ Cooldown NOT enforced in claim_or_attack_tile RPC
- ❌ Cooldown NOT set (30 min) after each attack
- ❌ Cooldown duration hardcoded but not configurable

**Status:** Table exists, but RPC enforcement missing

---

#### 8. **SPEED VALIDATION - PARTIALLY IMPLEMENTED** ⚠️
- ✅ Speed tracking exists (currentSpeedMps, currentSpeedKmh)
- ✅ Speed badge displayed in UI
- ❌ Speed validation NOT enforced in claim_or_attack_tile
- ❌ Logic missing: "Must be 2-15 km/h to claim tile"
- ❌ No rejection code for "speed_out_of_bounds"

**Status:** Frontend only, backend missing

---

#### 9. **TILE ENERGY MODIFIERS - NOT IMPLEMENTED** ❌
- ❌ Base energy = 10 NOT set
- ❌ +5 energy for same-day revisit NOT implemented
- ❌ +10 energy for 48h+ ownership NOT implemented
- ❌ +15 energy for cluster NOT implemented
- ❌ +10 energy for near home base NOT implemented
- ❌ 60 energy cap NOT enforced

**Status:** Completely missing

---

#### 10. **TERRITORY LOGGING - NOT IMPLEMENTED** ❌
- ❌ `tile_attack_log` table missing
- ❌ Attack history NOT recorded
- ❌ Territory claims NOT logged
- ❌ Owner changes NOT tracked

**Status:** Completely missing

---

#### 11. **APP CODE ISSUES** ⚠️
- `getTileState()` method exists but RPC not implemented
- `claimOrAttackTile()` calls non-existent RPC
- `MapTile` model incomplete (missing tileId parsing)
- Energy response mapping incorrect (expects different RPC format)

**Status:** Code ready but backend broken

---

## STEP-BY-STEP IMPLEMENTATION PLAN

### **PHASE 1: Database Foundation** (1-2 hours)

#### Step 1.1: Create hex_tiles table
**File:** `supabase/migrations/YYYYMMDDHHMMSS_create_hex_tiles_table.sql`

```sql
CREATE TABLE public.hex_tiles (
  tile_id TEXT PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  tile_energy INT DEFAULT 10 CHECK (tile_energy >= 0 AND tile_energy <= 60),
  last_visited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  protection_until TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  capture_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  lat FLOAT NOT NULL,
  lng FLOAT NOT NULL,
  geom GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(lng, lat), 4326)) STORED,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_hex_tiles_owner ON hex_tiles(owner_id);
CREATE INDEX idx_hex_tiles_geom ON hex_tiles USING GIST(geom);
CREATE INDEX idx_hex_tiles_protection ON hex_tiles(protection_until);

-- Enable RLS
ALTER TABLE hex_tiles ENABLE ROW LEVEL SECURITY;

-- Anyone can read tiles
CREATE POLICY "Read all tiles" ON hex_tiles FOR SELECT USING (true);

-- Only owner can update their tile (or system RPC)
CREATE POLICY "Update own tile" ON hex_tiles FOR UPDATE 
USING (auth.uid() = owner_id OR auth.uid() IS NULL);
```

#### Step 1.2: Create attack_cooldowns table
**File:** `supabase/migrations/YYYYMMDDHHMMSS_create_attack_cooldowns_table.sql`

```sql
CREATE TABLE public.attack_cooldowns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attacker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tile_id TEXT NOT NULL REFERENCES public.hex_tiles(tile_id) ON DELETE CASCADE,
  cooldown_until TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_cooldowns_attacker ON attack_cooldowns(attacker_id);
CREATE INDEX idx_cooldowns_tile ON attack_cooldowns(tile_id);
CREATE INDEX idx_cooldowns_expiry ON attack_cooldowns(cooldown_until);

ALTER TABLE attack_cooldowns ENABLE ROW LEVEL SECURITY;

-- Users can only see their own cooldowns
CREATE POLICY "Read own cooldowns" ON attack_cooldowns FOR SELECT
USING (auth.uid() = attacker_id);
```

#### Step 1.3: Create tile_attack_log table
**File:** `supabase/migrations/YYYYMMDDHHMMSS_create_tile_attack_log.sql`

```sql
CREATE TABLE public.tile_attack_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tile_id TEXT NOT NULL REFERENCES public.hex_tiles(tile_id) ON DELETE CASCADE,
  attacker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  defender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL CHECK (action IN ('claimed', 'captured', 'damaged', 'protected', 'cooldown', 'no_energy')),
  energy_before INT NOT NULL,
  energy_after INT NOT NULL,
  attack_power_used INT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_attack_log_tile ON tile_attack_log(tile_id);
CREATE INDEX idx_attack_log_attacker ON tile_attack_log(attacker_id);
CREATE INDEX idx_attack_log_created ON tile_attack_log(created_at);

ALTER TABLE tile_attack_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Read all attack logs" ON tile_attack_log FOR SELECT USING (true);
```

#### Step 1.4: Modify profiles table to add territory fields
**File:** `supabase/migrations/YYYYMMDDHHMMSS_add_territory_fields_to_profiles.sql`

```sql
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS tiles_owned INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS tiles_conquered INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_tile_claim TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Update last_active_at on profile activity
CREATE OR REPLACE FUNCTION update_last_active()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles SET last_active_at = NOW() WHERE id = NEW.owner_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_update_last_active_on_tile_claim
AFTER INSERT OR UPDATE ON hex_tiles
FOR EACH ROW
EXECUTE FUNCTION update_last_active();
```

---

### **PHASE 2: Attack & Claim RPC** (2-3 hours)

#### Step 2.1: Create claim_or_attack_tile RPC

**File:** `supabase/migrations/YYYYMMDDHHMMSS_create_claim_or_attack_tile_rpc.sql`

```sql
CREATE OR REPLACE FUNCTION claim_or_attack_tile(
  p_tile_id TEXT,
  p_user_id UUID,
  p_lat FLOAT,
  p_lng FLOAT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tile_owner_id UUID;
  v_tile_energy INT;
  v_protection_until TIMESTAMP;
  v_current_energy INT;
  v_player_is_premium BOOLEAN;
  v_player_is_friends BOOLEAN;
  v_last_visited TIMESTAMP;
  v_hours_since_visit INT;
  v_cooldown_until TIMESTAMP;
  v_action TEXT;
  v_energy_after INT;
  v_attacker_energy INT;
  v_speed_kmh FLOAT;
BEGIN
  -- ──────────────────────────────────────────────────────────────
  -- 0. VALIDATION: Speed check
  -- ──────────────────────────────────────────────────────────────
  -- Speed will be sent as p_speed_kmh (add to function params)
  -- For now: SKIP (implement after app sends speed)
  -- IF p_speed_kmh < 2 OR p_speed_kmh > 15 THEN
  --   RETURN jsonb_build_object(
  --     'action', 'invalid_speed',
  --     'message', 'Walking speed must be 2-15 km/h'
  --   );
  -- END IF;

  -- ──────────────────────────────────────────────────────────────
  -- 1. GET CURRENT ATTACK ENERGY
  -- ──────────────────────────────────────────────────────────────
  SELECT attack_energy, is_premium INTO v_attacker_energy, v_player_is_premium
  FROM profiles WHERE id = p_user_id;

  IF v_attacker_energy IS NULL THEN
    v_attacker_energy := 0;
  END IF;

  -- Check for zero energy
  IF v_attacker_energy <= 0 AND NOT (p_tile_id IS NOT NULL AND p_tile_id != '') THEN
    RETURN jsonb_build_object(
      'action', 'no_energy',
      'message', 'No attack energy available',
      'attacker_energy_left', 0
    );
  END IF;

  -- ──────────────────────────────────────────────────────────────
  -- 2. GET TILE STATE (or INSERT if neutral)
  -- ──────────────────────────────────────────────────────────────
  SELECT owner_id, tile_energy, protection_until, last_visited_at
  INTO v_tile_owner_id, v_tile_energy, v_protection_until, v_last_visited
  FROM hex_tiles WHERE tile_id = p_tile_id;

  IF v_tile_energy IS NULL THEN
    -- Neutral tile - insert new
    INSERT INTO hex_tiles (tile_id, owner_id, tile_energy, lat, lng, protection_until, capture_time)
    VALUES (p_tile_id, p_user_id, 10, p_lat, p_lng, NOW() + INTERVAL '12 hours', NOW())
    ON CONFLICT DO NOTHING;
    
    RETURN jsonb_build_object(
      'action', 'claimed',
      'message', 'Tile claimed!',
      'tile_id', p_tile_id,
      'tile_energy_after', 10,
      'attacker_energy_left', v_attacker_energy
    );
  END IF;

  -- ──────────────────────────────────────────────────────────────
  -- 3. VERIFY OWN TILE (reinforcement)
  -- ──────────────────────────────────────────────────────────────
  IF v_tile_owner_id = p_user_id THEN
    -- Reinforce: +5 energy if revisited same day, max 60
    v_energy_after := LEAST(v_tile_energy + 5, 60);
    
    UPDATE hex_tiles 
    SET tile_energy = v_energy_after,
        last_visited_at = NOW(),
        updated_at = NOW()
    WHERE tile_id = p_tile_id;
    
    RETURN jsonb_build_object(
      'action', 'claimed',
      'message', 'Tile reinforced!',
      'tile_id', p_tile_id,
      'tile_energy_before', v_tile_energy,
      'tile_energy_after', v_energy_after,
      'attacker_energy_left', v_attacker_energy
    );
  END IF;

  -- ──────────────────────────────────────────────────────────────
  -- 4. CHECK PROTECTION WINDOW
  -- ──────────────────────────────────────────────────────────────
  IF v_protection_until IS NOT NULL AND v_protection_until > NOW() THEN
    RETURN jsonb_build_object(
      'action', 'protected',
      'message', 'Tile is protected!',
      'tile_id', p_tile_id,
      'protection_reason', 'tile',
      'hours_remaining', EXTRACT(EPOCH FROM (v_protection_until - NOW())) / 3600.0,
      'attacker_energy_left', v_attacker_energy
    );
  END IF;

  -- ──────────────────────────────────────────────────────────────
  -- 5. CHECK ABSENCE SHIELD (user active last 24h → energy floor = 20)
  -- ──────────────────────────────────────────────────────────────
  v_hours_since_visit := EXTRACT(EPOCH FROM (NOW() - v_last_visited)) / 3600.0;
  IF v_hours_since_visit < 24 AND v_tile_energy > 20 THEN
    -- Tile has absence shield - energy can't go below 20
    IF v_attacker_energy >= v_tile_energy THEN
      -- Reduce to 20 (shield kicks in)
      UPDATE hex_tiles 
      SET tile_energy = 20,
          updated_at = NOW()
      WHERE tile_id = p_tile_id;
      
      RETURN jsonb_build_object(
        'action', 'damaged',
        'message', 'Tile protected by Absence Shield!',
        'tile_id', p_tile_id,
        'tile_energy_before', v_tile_energy,
        'tile_energy_after', 20,
        'attack_power_used', v_tile_energy - 20,
        'attacker_energy_left', v_attacker_energy - (v_tile_energy - 20)
      );
    END IF;
  END IF;

  -- ──────────────────────────────────────────────────────────────
  -- 6. CHECK COOLDOWN
  -- ──────────────────────────────────────────────────────────────
  SELECT cooldown_until INTO v_cooldown_until 
  FROM attack_cooldowns 
  WHERE attacker_id = p_user_id AND tile_id = p_tile_id
  LIMIT 1;

  IF v_cooldown_until IS NOT NULL AND v_cooldown_until > NOW() THEN
    RETURN jsonb_build_object(
      'action', 'cooldown',
      'message', 'You are on cooldown for this tile',
      'tile_id', p_tile_id,
      'cooldown_until', v_cooldown_until,
      'attacker_energy_left', v_attacker_energy
    );
  END IF;

  -- ──────────────────────────────────────────────────────────────
  -- 7. PERFORM ATTACK
  -- ──────────────────────────────────────────────────────────────
  v_energy_after := GREATEST(0, v_tile_energy - v_attacker_energy);
  
  IF v_energy_after <= 0 THEN
    -- CAPTURED
    UPDATE hex_tiles 
    SET owner_id = p_user_id,
        tile_energy = 10,
        protection_until = NOW() + INTERVAL '12 hours',
        capture_time = NOW(),
        last_visited_at = NOW(),
        updated_at = NOW()
    WHERE tile_id = p_tile_id;
    
    -- Set cooldown and consume energy
    DELETE FROM attack_cooldowns WHERE attacker_id = p_user_id AND tile_id = p_tile_id;
    INSERT INTO attack_cooldowns (attacker_id, tile_id, cooldown_until)
    VALUES (p_user_id, p_tile_id, NOW() + INTERVAL '30 minutes');
    
    UPDATE profiles 
    SET attack_energy = attack_energy - v_attacker_energy,
        tiles_conquered = tiles_conquered + 1,
        last_tile_claim = NOW()
    WHERE id = p_user_id;
    
    RETURN jsonb_build_object(
      'action', 'captured',
      'message', 'Tile captured!',
      'tile_id', p_tile_id,
      'tile_energy_before', v_tile_energy,
      'tile_energy_after', 10,
      'attack_power_used', v_attacker_energy,
      'defender_id', v_tile_owner_id,
      'attacker_energy_left', 0
    );
  ELSE
    -- DAMAGED
    UPDATE hex_tiles 
    SET tile_energy = v_energy_after,
        updated_at = NOW()
    WHERE tile_id = p_tile_id;
    
    -- Set cooldown and consume energy
    DELETE FROM attack_cooldowns WHERE attacker_id = p_user_id AND tile_id = p_tile_id;
    INSERT INTO attack_cooldowns (attacker_id, tile_id, cooldown_until)
    VALUES (p_user_id, p_tile_id, NOW() + INTERVAL '30 minutes');
    
    UPDATE profiles 
    SET attack_energy = attack_energy - v_attacker_energy,
        last_tile_claim = NOW()
    WHERE id = p_user_id;
    
    RETURN jsonb_build_object(
      'action', 'damaged',
      'message', 'Tile damaged but survived',
      'tile_id', p_tile_id,
      'tile_energy_before', v_tile_energy,
      'tile_energy_after', v_energy_after,
      'attack_power_used', v_attacker_energy,
      'defender_id', v_tile_owner_id,
      'attacker_energy_left', 0
    );
  END IF;
END;
$$;
```

---

### **PHASE 3: Decay & Cluster Systems** (1-2 hours)

#### Step 3.1: Territory Decay RPC

**File:** `supabase/migrations/YYYYMMDDHHMMSS_create_decay_territories_rpc.sql`

```sql
CREATE OR REPLACE FUNCTION decay_territories()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_decayed_count INT := 0;
  v_neutralized_count INT := 0;
BEGIN
  -- Tiles not visited in 3+ days: lose 2 energy per day
  UPDATE hex_tiles
  SET tile_energy = GREATEST(0, tile_energy - 2)
  WHERE last_visited_at < NOW() - INTERVAL '3 days'
    AND tile_energy > 0;
  
  v_decayed_count := FOUND::INT::coalesce(0);
  
  -- Tiles that reached 0 energy: become neutral
  UPDATE hex_tiles
  SET owner_id = NULL
  WHERE tile_energy = 0 AND owner_id IS NOT NULL;
  
  v_neutralized_count := FOUND::INT::coalesce(0);
  
  RETURN jsonb_build_object(
    'decayed_tiles', v_decayed_count,
    'neutralized_tiles', v_neutralized_count
  );
END;
$$;
```

**Add scheduler:**
```sql
SELECT cron.schedule('decay_territories_daily', '0 3 * * *', 'SELECT decay_territories()');
```

#### Step 3.2: Cluster Bonus Calculation

**File:** `supabase/migrations/YYYYMMDDHHMMSS_create_cluster_bonus_rpc.sql`

```sql
CREATE OR REPLACE FUNCTION calculate_cluster_bonus(p_tile_id TEXT)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_id UUID;
  v_cluster_size INT;
  v_bonus INT := 0;
BEGIN
  SELECT owner_id INTO v_owner_id FROM hex_tiles WHERE tile_id = p_tile_id;
  
  IF v_owner_id IS NULL THEN
    RETURN 0;
  END IF;
  
  -- Count connected tiles (simple 8-neighbor check for hex grid)
  -- This is a simplified version - real implementation needs hex math
  WITH RECURSIVE neighbors AS (
    SELECT tile_id, owner_id FROM hex_tiles WHERE tile_id = p_tile_id
    UNION ALL
    SELECT ht.tile_id, ht.owner_id FROM hex_tiles ht
    INNER JOIN neighbors n ON ST_DWithin(ht.geom, 
      (SELECT geom FROM hex_tiles WHERE tile_id = p_tile_id), 
      130) -- ~60m hex radius * 2
    WHERE ht.owner_id = v_owner_id
  )
  SELECT COUNT(*) INTO v_cluster_size FROM neighbors;
  
  -- Apply bonuses
  IF v_cluster_size >= 15 THEN
    v_bonus := 20;
  ELSIF v_cluster_size >= 7 THEN
    v_bonus := 10;
  ELSIF v_cluster_size >= 3 THEN
    v_bonus := 5;
  END IF;
  
  RETURN v_bonus;
END;
$$;
```

---

### **PHASE 4: App Code Updates** (2-3 hours)

#### Step 4.1: Fix supabase_service.dart

**Update getTileState() to include all required fields:**
```dart
Future<Map<String, dynamic>?> getTileState(String tileId) async {
  try {
    return await _client
        .from('hex_tiles')
        .select('tile_id, owner_id, tile_energy, protection_until, last_visited_at, lat, lng')
        .eq('tile_id', tileId)
        .maybeSingle();
  } catch (e) {
    _log('getTileState', e);
    return null;
  }
}
```

**Update claimOrAttackTile() to pass speed:**
```dart
Future<Map<String, dynamic>> claimOrAttackTile({
  required String tileId,
  required double lat,
  required double lng,
  required double speedKmh,  // ADD THIS
}) async {
  final user = currentUser;
  if (user == null) return {'action': 'error', 'message': 'not signed in'};
  try {
    final response = await _client.rpc(
      'claim_or_attack_tile',
      params: {
        'p_tile_id': tileId,
        'p_user_id': user.id,
        'p_lat': lat,
        'p_lng': lng,
        'p_speed_kmh': speedKmh,  // ADD THIS
      },
    );
    return Map<String, dynamic>.from(response as Map);
  } catch (e) {
    _log('claimOrAttackTile', e);
    return {'action': 'error', 'message': e.toString()};
  }
}
```

**Add new method to log attacks:**
```dart
Future<void> logTileAttack(Map<String, dynamic> attackData) async {
  try {
    await _client.from('tile_attack_log').insert(attackData);
  } catch (e) {
    _log('logTileAttack', e);
  }
}
```

#### Step 4.2: Fix step-to-energy conversion ratio

**In the migration file `add_season_recap_system.sql`, CHANGE:**
```sql
-- OLD (WRONG): 10 steps = 1 energy
v_energy_to_add := steps_today / 10;

-- NEW (CORRECT): 100 steps = 1 energy
v_energy_to_add := steps_today / 100;
```

#### Step 4.3: Add speed to map_provider tile interaction

**In `map_provider.dart` attackTile() method:**
```dart
Future<void> attackTile(String tileId, double lat, double lng) async {
  try {
    final speedKmh = state.currentSpeedKmh ?? 0.0;  // Get current speed
    
    final result = await _service.claimOrAttackTile(
      tileId: tileId,
      lat: lat,
      lng: lng,
      speedKmh: speedKmh,  // PASS SPEED
    );
    
    state = state.copyWith(lastAttackResult: result);
  } catch (e) {
    print('[Map] Attack error: $e');
  }
}
```

---

### **PHASE 5: Edge Cases & Protection** (1 hour)

#### Step 5.1: Add validation constraints

**In hex_tiles migration, add:**
```sql
-- Prevent claiming tiles too close in time
ALTER TABLE hex_tiles ADD COLUMN IF NOT EXISTS claimed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add friend verification check (if needed for attacks)
-- Add speed validation in RPC params
```

#### Step 5.2: Add Drift detection

**Create RPC to handle timezone/time drift:**
```sql
CREATE OR REPLACE FUNCTION sync_player_timestamp(p_user_id UUID)
RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE profiles SET last_sync_time = NOW() WHERE id = p_user_id;
  RETURN NOW();
END;
$$;
```

---

## TESTING CHECKLIST

### Manual Testing
- [ ] Claim neutral tile → tile becomes owned with 10 energy + 12hr protection
- [ ] Revisit own tile → energy increases to 15 (max 60)
- [ ] Attack protected tile → receives "protected" action
- [ ] Attack with insufficient energy → tile damaged, not captured
- [ ] Attack with exact energy → tile captured, becomes new owner
- [ ] Test 30-min cooldown blocks next attack on same tile
- [ ] Test 24-hour absence shield (energy floor = 20)
- [ ] Verify tile energy decay after 3 days no visit
- [ ] Verify destroyed tile (0 energy) becomes neutral
- [ ] Verify cluster bonuses working (3, 7, 15 tile thresholds)

### Automated Tests
- [ ] Speed validation (2-15 km/h enforcement)
- [ ] Energy cap enforcement (400/600)
- [ ] Protection duration enforcement
- [ ] Cooldown duration enforcement
- [ ] Tile energy cap (60 max)

---

## PRIORITY QUEUE

**Must Do First:**
1. ✓ Create hex_tiles, attack_cooldowns, tile_attack_log tables
2. ✓ Implement claim_or_attack_tile RPC
3. ✓ Fix step-to-energy ratio (100:1)
4. ✓ Update app code to pass speed to RPC

**Should Do Next:**
5. Implement decay RPC + scheduler
6. Implement cluster bonus RPC
7. Add attack logging to app
8. Add friend verification check

**Nice to Have:**
9. Data export/analytics
10. Season recap calculations
11. Leaderboards
12. Anti-cheat measures

---

## ESTIMATED TIMELINE

| Phase | Tasks | Hours | Blocker? |
|-------|-------|-------|----------|
| 1 | DB Schema | 2 | YES |
| 2 | RPCs | 3 | YES |
| 3 | Decay/Clusters | 2 | NO |
| 4 | App Updates | 2 | YES |
| 5 | Edge Cases | 1 | NO |
| **Total** | | **~10 hours** | |

**Recommended:** Complete Phase 1-2 and Phase 4 first (6 hours minimum viable product), then add Phase 3-5 features.

