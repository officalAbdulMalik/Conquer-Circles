# IMPLEMENTATION CHECKLIST - Quick Reference

## CRITICAL ISSUES (MUST FIX FIRST)

### 🔴 Issue #1: Hex Tiles Table Missing
**Impact:** App crashes or no tiles visible on map
**Status:** BLOCKING
**Fix Time:** 30 min

```
☐ Create migration: create_hex_tiles_table.sql
☐ Add fields: tile_id, owner_id, tile_energy, protection_until, lat, lng, geom
☐ Add RLS policies (read all, update own)
☐ Add indexes for owner, geom, protection
☐ Run: supabase migration up
☐ Verify table exists in Supabase dashboard
```

---

### 🔴 Issue #2: Attack Cooldowns Table Missing  
**Impact:** Players can spam-attack same tile
**Status:** BLOCKING
**Fix Time:** 20 min

```
☐ Create migration: create_attack_cooldowns_table.sql
☐ Add fields: id, attacker_id, tile_id, cooldown_until
☐ Add indexes for attacker_id, tile_id, cooldown_until
☐ Add RLS: users can only see own cooldowns
☐ Run: supabase migration up
```

---

### 🔴 Issue #3: claim_or_attack_tile RPC Missing
**Impact:** Tile claiming/attacking does nothing
**Status:** BLOCKING
**Fix Time:** 1-2 hours

```
☐ Create migration: create_claim_or_attack_tile_rpc.sql
☐ Implement logic:
  ☐ Validate speed is 2-15 km/h
  ☐ Check player has attack energy
  ☐ Get current tile state
  ☐ If neutral → claim with 10 energy + 12hr protection
  ☐ If own → reinforce (+5 energy, max 60)
  ☐ If enemy + protected → block attack
  ☐ If enemy + has shield → energy floor 20
  ☐ If enemy + cooldown → block attack
  ☐ If enemy → damage or capture based on energy
  ☐ Set 30-min cooldown after attack
  ☐ Update player.attack_energy
  ☐ Update tile.last_visited_at
☐ Run: supabase migration up
☐ Test with: curl -X POST // or use Supabase dashboard
```

---

### 🟡 Issue #4: Wrong Step-to-Energy Ratio
**Impact:** Players earn energy too slowly (10:1 instead of 100:1)
**Status:** HIGH PRIORITY
**Fix Time:** 10 min

```
☐ Edit migration: add_season_recap_system.sql
☐ Find: v_energy_to_add := steps_today / 10;
☐ Change to: v_energy_to_add := steps_today / 100;
☐ Or create new migration: fix_energy_conversion_ratio.sql
☐ Test: Walk 100 steps → should get 1 energy (not 10)
```

---

### 🟡 Issue #5: App Doesn't Pass Speed to RPC
**Impact:** Speed validation can't work (always passes)
**Status:** HIGH PRIORITY
**Fix Time:** 30 min

```
☐ Edit: lib/services/supabase_service.dart
  ☐ Update claimOrAttackTile() signature: add speedKmh parameter
  ☐ Pass speedKmh in RPC params
  
☐ Edit: lib/providers/map_provider.dart
  ☐ Update attackTile() to read state.currentSpeedKmh
  ☐ Pass speedKmh when calling _service.claimOrAttackTile()
  
☐ Edit: lib/features/map/view/map_view.dart or tile handler
  ☐ Ensure speed is available before calling attack
  
☐ Test: View map → check speed badge shows value → tap tile
```

---

## MEDIUM PRIORITY (IMPLEMENT AFTER ABOVE)

### 🟠 Issue #6: Tile Attack Log Missing
**Impact:** No history of attacks/claims
**Status:** IMPORTANT
**Fix Time:** 20 min

```
☐ Create migration: create_tile_attack_log.sql
☐ Add table with: id, tile_id, attacker_id, defender_id, action, energy_before/after, created_at
☐ Add indexing for queries
☐ Update claim_or_attack_tile RPC to INSERT log entries
☐ Add method in supabase_service: getTileHistory(tileId)
```

---

### 🟠 Issue #7: Territory Decay Not Scheduled
**Impact:** Tiles stay owned forever, map stale
**Status:** IMPORTANT  
**Fix Time:** 45 min

```
☐ Create migration: create_decay_territories_rpc.sql
☐ Implement decay logic:
  ☐ If last_visited_at < 3 days ago: lose 2 energy/day
  ☐ If energy reaches 0: set owner_id = NULL
  ☐ Update updated_at timestamp
  
☐ Create migration: schedule_decay_job.sql
  ☐ Use pg_cron to run daily: SELECT decay_territories();
  ☐ Suggested time: 3 AM UTC
  
☐ Verify in Supabase: Check Extensions panel for pg_cron enabled
```

---

### 🟠 Issue #8: Cluster Bonuses Not Implemented
**Impact:** No bonus for connected tiles
**Status:** NICE TO HAVE
**Fix Time:** 1 hour

```
☐ Create migration: create_calculate_cluster_bonus_rpc.sql
☐ Implement cluster detection:
  ☐ Count connected tiles (same owner)
  ☐ Return bonus: 3+ tiles = +5 energy, 7+ = +10, 15+ = +20
  
☐ Call in claim_or_attack_tile RPC when claiming:
  ☐ v_cluster_bonus := calculate_cluster_bonus(p_tile_id)
  ☐ tile_energy += v_cluster_bonus (capped at 60)
  
☐ Test: Claim tiles in pattern → verify bonuses applied
```

---

## TESTING & VERIFICATION

### Quick Validation Tests

**Test 1: Tile Claiming (Neutral → Owned)**
```
1. Start app, navigate map
2. Tap neutral hex tile
3. Expect: action='claimed', energy=10, protection shows 12h
4. Tap tile again in another session
5. Expect: action='claimed', energy=15 (reinforced)
6. Expect: tile shows as blue/owned
```

**Test 2: Attack (Own vs Enemy)**
```
1. Create two user accounts (User A, User B)
2. User A claims Tile X
3. User B tries to attack Tile X (with 100+ attack energy)
4. Expect: action='captured', User B now owns tile
5. User A tries to attack immediately
6. Expect: action='cooldown', blocked for 30 min
```

**Test 3: Protection Window**
```
1. User A just claimed a tile (protection_until = NOW + 12h)
2. User B tries to attack within 12 hours
3. Expect: action='protected', blocked
4. Wait 12 hours (or manually update DB for testing)
5. User B attacks again
6. Expect: action='captured' or 'damaged'
```

**Test 4: Absence Shield**
```
1. User A claims Tile X (owner_id = User A, energy = 10)
2. User A walks to tile again (within 24h)
3. User B attacks with 50 energy (tile has 10)
4. Expect: tile energy = 20 (shield protects it to floor)
5. Attack consumes 10 energy (to bring from 10 → 20)
```

**Test 5: Speed Validation**
```
1. User walks at 1 km/h (too slow)
2. Tap tile
3. Expect: action='invalid_speed' or rejected
4. User walks at 2-15 km/h
5. Tap tile
6. Expect: attack succeeds (if other conditions met)
```

### Database Sanity Checks

```sql
-- Check tiles table structure
SELECT * FROM hex_tiles LIMIT 1;

-- Check tile ownership
SELECT tile_id, owner_id, tile_energy, protection_until 
FROM hex_tiles WHERE owner_id IS NOT NULL LIMIT 10;

-- Check cooldowns active
SELECT attacker_id, tile_id, cooldown_until 
FROM attack_cooldowns 
WHERE cooldown_until > NOW();

-- Check tile energy distribution
SELECT 
  tile_energy,
  COUNT(*) as count 
FROM hex_tiles 
GROUP BY tile_energy 
ORDER BY tile_energy DESC;

-- Verify protection windows
SELECT 
  tile_id, 
  EXTRACT(EPOCH FROM (protection_until - NOW())) / 3600 as hours_remaining,
  owner_id
FROM hex_tiles 
WHERE protection_until > NOW();
```

---

## GIT COMMIT SEQUENCE

```bash
# Commit 1: Database foundation
git commit -m "feat: add hex_tiles, attack_cooldowns, and tile_attack_log tables"

# Commit 2: Core RPC logic
git commit -m "feat: implement claim_or_attack_tile RPC with protection and cooldown"

# Commit 3: Energy fix
git commit -m "fix: correct step-to-energy ratio from 10:1 to 100:1"

# Commit 4: App integration
git commit -m "feat: pass speed to tile attack, update service and provider"

# Commit 5: Decay system
git commit -m "feat: add territory decay RPC and daily scheduler"

# Commit 6: Cluster bonuses
git commit -m "feat: implement cluster bonus calculation"
```

---

## QUICK LINKS TO UPDATE

Files that need editing:
- [ ] `lib/services/supabase_service.dart` - claimOrAttackTile() method
- [ ] `lib/providers/map_provider.dart` - attackTile() method  
- [ ] `supabase/migrations/` - new migration files (see Phase 1-3)
- [ ] `lib/features/map/widgets/tile_handler.dart` - may need RPC return parsing updates

---

## DEPLOYMENT STEPS

**Local Development:**
```bash
cd supabase
supabase migration up
supabase functions deploy get-steps-dashboard  # if any RPC-dependent functions
```

**Staging/Production:**
1. Create new migration files with datestamp
2. Test migrations on local `supabase_test` schema first
3. Deploy migrations: `supabase db push`
4. Deploy app code: `flutter pub get && flutter run`
5. Verify with test data (see Testing section)

---

## KNOWN LIMITATIONS (For Now)

- ⚠️ Speed validation requires new RPC parameters (add gradually)
- ⚠️ Cluster bonus uses basic distance check (hex math can be improved)
- ⚠️ Decay runs daily at fixed time (could use cron events)
- ⚠️ No "last attack" timestamp per tile (could add for better UX)
- ⚠️ No energy gift/steal mechanics yet (designed but not coded)

---

## SUPPORT MATRIX

| Feature | Implemented? | Tested? | Production Ready? |
|---------|--------------|---------|---|
| Tile claiming (neutral) | ❌ NO | ❌ NO | ❌ NO |
| Tile reinforcement (own) | ❌ NO | ❌ NO | ❌ NO |
| Tile attacking (enemy) | ❌ NO | ❌ NO | ❌ NO |
| 12h protection window | ❌ NO | ❌ NO | ❌ NO |
| 30-min cooldown | ❌ NO | ❌ NO | ❌ NO |
| Absence shield (24h) | ❌ NO | ❌ NO | ❌ NO |
| Speed validation | ⚠️ PARTIAL | ❌ NO | ❌ NO |
| Energy conversion (100:1) | ❌ WRONG | ❌ NO | ❌ NO |
| Territory decay | ❌ NO | ❌ NO | ❌ NO |
| Cluster bonuses | ❌ NO | ❌ NO | ❌ NO |
| Attack history | ❌ NO | ❌ NO | ❌ NO |

