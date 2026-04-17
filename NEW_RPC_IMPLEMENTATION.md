# NEW RPC: attack_or_claim_territory()

## RPC Signature
```sql
CREATE OR REPLACE FUNCTION attack_or_claim_territory(
  p_territory_id UUID,
  p_user_id UUID,
  p_speed_kmh FLOAT,
  p_lat FLOAT,
  p_lng FLOAT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
```

---

## Complete Implementation

```sql
CREATE OR REPLACE FUNCTION attack_or_claim_territory(
  p_territory_id UUID,
  p_user_id UUID,
  p_speed_kmh FLOAT,
  p_lat FLOAT,
  p_lng FLOAT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_territory              territories%ROWTYPE;
  v_attacker              profiles%ROWTYPE;
  v_defender              profiles%ROWTYPE;
  v_attacker_username     TEXT;
  v_defender_username     TEXT;
  v_is_friend             BOOL := FALSE;
  v_is_own_territory      BOOL := FALSE;
  v_is_protected          BOOL := FALSE;
  v_is_shielded           BOOL := FALSE;
  v_defense_steps_today   INT := 0;
  v_attacker_energy_before INT;
  v_territory_energy_before INT;
  v_energy_to_consume     INT;
  v_territory_energy_after INT;
  v_captured              BOOL := FALSE;
  v_cooldown_exists       BOOL := FALSE;
BEGIN
  -- === STEP 1: FETCH & LOCK ===
  SELECT * INTO v_territory FROM territories WHERE id = p_territory_id FOR UPDATE;
  SELECT * INTO v_attacker FROM profiles WHERE id = p_user_id FOR UPDATE;
  
  IF v_territory IS NULL THEN
    RETURN jsonb_build_object(
      'action', 'error',
      'reason', 'territory_not_found',
      'territory_id', p_territory_id
    );
  END IF;
  
  IF v_attacker IS NULL THEN
    RETURN jsonb_build_object(
      'action', 'error',
      'reason', 'attacker_not_found'
    );
  END IF;
  
  v_attacker_username := v_attacker.username;
  v_is_own_territory := (v_territory.user_id = p_user_id);
  
  -- === STEP 2: SPEED VALIDATION (Server-Side) ===
  IF p_speed_kmh < 2.0 OR p_speed_kmh > 15.0 THEN
    RETURN jsonb_build_object(
      'action', 'error',
      'reason', 'invalid_speed',
      'speed_kmh', p_speed_kmh,
      'required_range', '2.0-15.0 km/h',
      'message', 'You must be walking/running at 2-15 km/h to attack'
    );
  END IF;
  
  -- === STEP 3: OWN TERRITORY (Reinforce) ===
  IF v_is_own_territory THEN
    -- Owner can reinforce their own territory
    v_energy_to_consume := LEAST(v_attacker.attack_energy, 20); -- Max 20 energy per reinforce
    
    UPDATE territories
    SET 
      energy = LEAST(energy + v_energy_to_consume, 60),
      last_visited = NOW(),
      updated_at = NOW(),
      protection_until = GREATEST(protection_until, NOW() + INTERVAL '12 hours')
    WHERE id = p_territory_id;
    
    UPDATE profiles
    SET attack_energy = GREATEST(attack_energy - v_energy_to_consume, 0)
    WHERE id = p_user_id;
    
    INSERT INTO territory_attack_log (
      territory_id, attacker_id, defender_id,
      energy_used, energy_before, energy_after, captured
    )
    VALUES (
      p_territory_id, p_user_id, v_territory.user_id,
      v_energy_to_consume, v_territory.energy, LEAST(v_territory.energy + v_energy_to_consume, 60),
      FALSE
    );
    
    RETURN jsonb_build_object(
      'action', 'reinforced',
      'territory_id', p_territory_id,
      'energy_added', v_energy_to_consume,
      'territory_energy_after', LEAST(v_territory.energy + v_energy_to_consume, 60)
    );
  END IF;
  
  -- === STEP 4: FRIEND CHECK (Attack on Enemy Territory) ===
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
      'message', 'You can only attack territories owned by your friends',
      'territory_owner_id', v_territory.user_id
    );
  END IF;
  
  -- === STEP 5: ENERGY CHECK ===
  IF v_attacker.attack_energy <= 0 THEN
    RETURN jsonb_build_object(
      'action', 'no_energy',
      'reason', 'insufficient_attack_energy',
      'current_energy', v_attacker.attack_energy,
      'energy_needed', 1
    );
  END IF;
  
  -- === STEP 6: PROTECTION CHECK (12h) ===
  IF v_territory.protection_until IS NOT NULL AND v_territory.protection_until > NOW() THEN
    RETURN jsonb_build_object(
      'action', 'protected',
      'reason', 'protection_active',
      'territory_id', p_territory_id,
      'protection_until', v_territory.protection_until::TEXT,
      'hours_remaining', ROUND(
        EXTRACT(EPOCH FROM (v_territory.protection_until - NOW()))::NUMERIC / 3600, 
        1
      ),
      'message', 'This territory is protected from attacks'
    );
  END IF;
  
  -- === STEP 7: SHIELD CHECK (24h absence) ===
  -- Defender has shield if: shield_until > NOW() AND walked today
  SELECT COALESCE(steps, 0) INTO v_defense_steps_today
  FROM daily_steps
  WHERE user_id = v_territory.user_id AND date = CURRENT_DATE;
  
  v_is_shielded := (
    v_territory.shield_until IS NOT NULL 
    AND v_territory.shield_until > NOW()
    AND v_defense_steps_today > 0
  );
  
  IF v_is_shielded THEN
    RETURN jsonb_build_object(
      'action', 'shielded',
      'reason', 'absence_shield_active',
      'territory_id', p_territory_id,
      'shield_until', v_territory.shield_until::TEXT,
      'hours_remaining', ROUND(
        EXTRACT(EPOCH FROM (v_territory.shield_until - NOW()))::NUMERIC / 3600, 
        1
      ),
      'defender_walked_today', v_defense_steps_today > 0,
      'message', 'Territory is protected by absence shield'
    );
  END IF;
  
  -- === STEP 8: COOLDOWN CHECK (30 min per territory) ===
  SELECT EXISTS(
    SELECT 1 FROM territory_attack_cooldowns
    WHERE attacker_id = p_user_id 
    AND territory_id = p_territory_id 
    AND cooldown_until > NOW()
  ) INTO v_cooldown_exists;
  
  IF v_cooldown_exists THEN
    RETURN jsonb_build_object(
      'action', 'cooldown',
      'reason', 'attack_cooldown_active',
      'territory_id', p_territory_id,
      'cooldown_until', (
        SELECT cooldown_until FROM territory_attack_cooldowns
        WHERE attacker_id = p_user_id AND territory_id = p_territory_id
      )::TEXT,
      'minutes_remaining', ROUND(
        EXTRACT(EPOCH FROM (
          (SELECT cooldown_until FROM territory_attack_cooldowns
           WHERE attacker_id = p_user_id AND territory_id = p_territory_id)
          - NOW()
        ))::NUMERIC / 60
      ),
      'message', 'You must wait before attacking this territory again'
    );
  END IF;
  
  -- === STEP 9: CAPTURE LOGIC ===
  v_attacker_energy_before := v_attacker.attack_energy;
  v_territory_energy_before := v_territory.energy;
  v_energy_to_consume := v_attacker.attack_energy; -- Consume ALL attacker energy
  
  -- Capture if: attacker_energy >= territory_energy AND NOT shielded
  v_captured := (v_attacker_energy_before >= v_territory_energy_before);
  
  -- Territory energy after attack
  v_territory_energy_after := CASE
    WHEN v_captured THEN 10 -- Captured territories start at 10
    ELSE GREATEST(
      v_territory_energy_before - v_attacker_energy_before, -- Damage = attacker's energy
      20 -- Minimum energy floor (absence shield floor)
    )
  END;
  
  -- === STEP 10: UPDATE STATE ===
  -- Update attacker energy
  UPDATE profiles
  SET attack_energy = GREATEST(attack_energy - v_energy_to_consume, 0),
      last_active_at = NOW()
  WHERE id = p_user_id;
  
  -- Update territory
  IF v_captured THEN
    -- Captured: new owner, reset streak, new protection
    SELECT username INTO v_defender_username FROM profiles WHERE id = v_territory.user_id;
    
    UPDATE territories
    SET 
      user_id = p_user_id,
      energy = 10,
      capture_time = NOW(),
      protection_until = NOW() + INTERVAL '12 hours',
      shield_until = NOW() + INTERVAL '24 hours',
      last_visited = NOW(),
      updated_at = NOW()
    WHERE id = p_territory_id;
    
    -- Log event
    INSERT INTO territory_events (territory_id, previous_owner_id, new_owner_id, event_type)
    VALUES (p_territory_id, v_territory.user_id, p_user_id, 'capture');
  ELSE
    -- Damaged: energy reduced, update timestamp
    UPDATE territories
    SET 
      energy = v_territory_energy_after,
      last_visited = NOW(),
      updated_at = NOW()
    WHERE id = p_territory_id;
  END IF;
  
  -- === STEP 11: ATTACK LOG ===
  INSERT INTO territory_attack_log (
    territory_id, attacker_id, defender_id,
    energy_used, energy_before, energy_after, captured
  )
  VALUES (
    p_territory_id, p_user_id, v_territory.user_id,
    v_energy_to_consume, v_territory_energy_before, v_territory_energy_after,
    v_captured
  );
  
  -- === STEP 12: COOLDOWN ===
  INSERT INTO territory_attack_cooldowns (attacker_id, territory_id, cooldown_until)
  VALUES (p_user_id, p_territory_id, NOW() + INTERVAL '30 minutes')
  ON CONFLICT (attacker_id, territory_id)
  DO UPDATE SET cooldown_until = NOW() + INTERVAL '30 minutes';
  
  -- === STEP 13: NOTIFICATIONS ===
  IF v_captured THEN
    SELECT username INTO v_defender_username FROM profiles WHERE id = v_territory.user_id;
    
    -- Notify defender: territory lost
    PERFORM notify_user(
      v_territory.user_id,
      'territory_lost',
      'Territory Captured!',
      v_attacker_username || ' captured your territory.',
      jsonb_build_object(
        'territory_id', p_territory_id,
        'attacker_id', p_user_id,
        'attacker_username', v_attacker_username
      ),
      'push',
      3,
      INTERVAL '1 hour'
    );
    
    -- Notify attacker: victory
    PERFORM notify_user(
      p_user_id,
      'raid_success',
      'Territory Captured!',
      'You successfully captured ' || v_defender_username || '''s territory.',
      jsonb_build_object(
        'territory_id', p_territory_id,
        'defender_id', v_territory.user_id,
        'defender_username', v_defender_username
      ),
      'in_app',
      2,
      INTERVAL '1 hour'
    );
  ELSE
    -- Notify defender: under attack
    PERFORM notify_user(
      v_territory.user_id,
      'territory_attacked',
      'Territory Under Attack',
      v_attacker_username || ' attacked your territory!',
      jsonb_build_object(
        'territory_id', p_territory_id,
        'attacker_id', p_user_id,
        'attacker_username', v_attacker_username
      ),
      'push',
      2,
      INTERVAL '30 minutes'
    );
  END IF;
  
  -- === STEP 14: RETURN RESPONSE ===
  RETURN jsonb_build_object(
    'action', CASE WHEN v_captured THEN 'captured' ELSE 'damaged' END,
    'territory_id', p_territory_id,
    'captured', v_captured,
    'attacker_id', p_user_id::TEXT,
    'defender_id', v_territory.user_id::TEXT,
    'energy_used', v_energy_to_consume,
    'territory_energy_before', v_territory_energy_before,
    'territory_energy_after', v_territory_energy_after,
    'attacker_energy_remaining', GREATEST(v_attacker_energy_before - v_energy_to_consume, 0),
    'cooldown_until', (NOW() + INTERVAL '30 minutes')::TEXT,
    'message', CASE 
      WHEN v_captured THEN 'Territory captured! You earned ' || v_territory_energy_before || ' energy.'
      ELSE 'Territory damaged! Energy reduced from ' || v_territory_energy_before || ' to ' || v_territory_energy_after
    END
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'action', 'error',
    'reason', 'database_error',
    'message', SQLERRM
  );
END;
$$;
```

---

## Key Differences from claim_or_attack_tile

| Feature | Old (Hex Tiles) | New (Territories) |
|---------|-----------------|-------------------|
| Table | `hex_tiles` | `territories` |
| Speed Check | ❌ None | ✅ 2-15 km/h |
| Energy Model | Fixed 10 per hit | Full energy consumed |
| Capture | When attack_power >= tile_energy | When attacker_energy >= territory_energy |
| Protection | 12h from capture | 12h + 24h shield |
| Shield Logic | Complex presence check | Simple: shield_until > NOW() AND steps_today > 0 |
| Cooldown Table | `attack_cooldowns` | `territory_attack_cooldowns` |
| Log Table | `tile_attack_log` | `territory_attack_log` |
| Reinforcing | Not supported | ✅ Own territory only |
| Response Reasons | ❌ vague | ✅ Clear: 'invalid_speed', 'not_friends', 'protected', 'shielded', 'cooldown' |

---

## Return Values (For App Handling)

### Success Cases
```json
{
  "action": "captured",
  "territory_id": "uuid",
  "captured": true,
  "attacker_id": "uuid",
  "defender_id": "uuid",
  "energy_used": 25,
  "territory_energy_before": 30,
  "territory_energy_after": 10,
  "attacker_energy_remaining": 0,
  "cooldown_until": "2026-04-14T15:30:00Z",
  "message": "Territory captured! You earned 30 energy."
}
```

```json
{
  "action": "damaged",
  "territory_id": "uuid",
  "captured": false,
  "energy_used": 15,
  "territory_energy_before": 35,
  "territory_energy_after": 20,
  "attacker_energy_remaining": 0,
  "message": "Territory damaged! Energy reduced from 35 to 20"
}
```

### Error/Condition Cases (App-Triggerable)
```json
{
  "action": "protected",
  "reason": "protection_active",
  "hours_remaining": 2.5,
  "message": "This territory is protected from attacks"
}
```

```json
{
  "action": "shielded",
  "reason": "absence_shield_active",
  "hours_remaining": 18,
  "defender_walked_today": true,
  "message": "Territory is protected by absence shield"
}
```

```json
{
  "action": "cooldown",
  "reason": "attack_cooldown_active",
  "minutes_remaining": 25,
  "message": "You must wait before attacking this territory again"
}
```

```json
{
  "action": "error",
  "reason": "invalid_speed",
  "speed_kmh": 25.5,
  "required_range": "2.0-15.0 km/h",
  "message": "You must be walking/running at 2-15 km/h to attack"
}
```

```json
{
  "action": "no_energy",
  "reason": "insufficient_attack_energy",
  "current_energy": 0,
  "energy_needed": 1,
  "message": "You need attack energy to attack territories"
}
```

```json
{
  "action": "error",
  "reason": "not_friends",
  "message": "You can only attack territories owned by your friends",
  "territory_owner_id": "uuid"
}
```

---

## Migration SQL

```sql
-- 1. Create territory_attack_cooldowns table
CREATE TABLE IF NOT EXISTS territory_attack_cooldowns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attacker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  territory_id UUID NOT NULL REFERENCES territories(id) ON DELETE CASCADE,
  cooldown_until TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(attacker_id, territory_id)
);

-- 2. Create territory_attack_log table
CREATE TABLE IF NOT EXISTS territory_attack_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  territory_id UUID NOT NULL REFERENCES territories(id) ON DELETE CASCADE,
  attacker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  defender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  energy_used INT NOT NULL,
  energy_before INT NOT NULL,
  energy_after INT NOT NULL,
  captured BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create territory_events table (for gamification)
CREATE TABLE IF NOT EXISTS territory_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  territory_id UUID NOT NULL REFERENCES territories(id) ON DELETE CASCADE,
  previous_owner_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  new_owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('capture', 'reinforced', 'decay')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Enable RLS
ALTER TABLE territory_attack_cooldowns ENABLE ROW LEVEL SECURITY;
ALTER TABLE territory_attack_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE territory_events ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
CREATE POLICY "Users can view their own attack cooldowns"
  ON territory_attack_cooldowns FOR SELECT
  USING (auth.uid() = attacker_id);

CREATE POLICY "System can insert cooldowns"
  ON territory_attack_cooldowns FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can view attack logs for their territories"
  ON territory_attack_log FOR SELECT
  USING (
    auth.uid() = defender_id 
    OR auth.uid() = attacker_id
    OR EXISTS(
      SELECT 1 FROM circle_members cm1
      JOIN circle_members cm2 ON cm2.circle_id = cm1.circle_id
      WHERE cm1.user_id = auth.uid()
      AND (cm2.user_id = attacker_id OR cm2.user_id = defender_id)
    )
  );

CREATE POLICY "System can insert attack logs"
  ON territory_attack_log FOR INSERT
  WITH CHECK (true);

-- 6. Create indexes for performance
CREATE INDEX idx_territory_attack_cooldowns_attacker_territory
  ON territory_attack_cooldowns(attacker_id, territory_id);

CREATE INDEX idx_territory_attack_log_territory
  ON territory_attack_log(territory_id);

CREATE INDEX idx_territory_attack_log_attacker
  ON territory_attack_log(attacker_id);

CREATE INDEX idx_territory_attack_log_created
  ON territory_attack_log(created_at DESC);
```

---

## App Integration (Dart)

### Update SupabaseService
```dart
Future<Map<String, dynamic>> attackOrClaimTerritory({
  required String territoryId,
  required double speedKmh,
  required double lat,
  required double lng,
}) async {
  final user = currentUser;
  if (user == null) return {'action': 'error', 'message': 'not signed in'};
  try {
    final response = await _client.rpc(
      'attack_or_claim_territory',
      params: {
        'p_territory_id': territoryId,
        'p_user_id': user.id,
        'p_speed_kmh': speedKmh,
        'p_lat': lat,
        'p_lng': lng,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  } catch (e) {
    _log('attackOrClaimTerritory', e);
    return {'action': 'error', 'message': e.toString()};
  }
}
```

### Update MapProvider
```dart
Future<void> _processTerritoryEntry(
  String territoryId,
  LatLng location,
  double speedKmh,
) async {
  // App-side validation (UX feedback)
  if (speedKmh < 2 || speedKmh > 15) {
    state = state.copyWith(
      attackResult: {'action': 'error', 'reason': 'invalid_speed'},
    );
    return;
  }

  // Get territory for shield/protection checks
  final territories = state.nearbyTerritories;
  final territory = territories.firstWhereOrNull((t) => t.id == territoryId);
  
  if (territory == null) return;

  // App-side protection check (UX feedback)
  final now = DateTime.now();
  if (territory.protectionUntil != null && territory.protectionUntil!.isAfter(now)) {
    state = state.copyWith(
      attackResult: {'action': 'protected', 'hours_remaining': ...},
    );
    return;
  }

  // RPC call (with speed parameter)
  final result = await _service.attackOrClaimTerritory(
    territoryId: territoryId,
    speedKmh: speedKmh,
    lat: location.latitude,
    lng: location.longitude,
  );

  await _handleAttackResult(result, location);
}
```

