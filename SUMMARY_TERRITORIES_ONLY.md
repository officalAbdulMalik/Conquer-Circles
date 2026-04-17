# Territory Attack System - Quick Summary

> **Previous analysis (hex tiles) is now OBSOLETE. Read TERRITORY_GAPS.md instead.**

---

## What Changed?

| Aspect | Hex Tiles (OLD) | Territories (NEW) |
|--------|-----------------|------------------|
| **Unit of play** | 60m hexagons (H3 grid) | Freeform polygons (from walks) |
| **How claimed** | Entering tile at valid speed | Walking to create polygon |
| **Boundaries** | Grid-based, system-generated | Convex hull, player-generated |
| **Claiming logic** | Tile owner check | Territory owner check |
| **Total units** | ~Infinite grid | 1 per player max |
| **Database** | `hex_tiles` table (needed) | `territories` table (✅ exists) |
| **Attack RPC** | `claim_or_attack_tile` (broken) | `attack_or_claim_territory` (missing) |

---

## What You Actually HAVE

✅ **Territories table** - Already created and working
✅ **Territory model** - All fields defined
✅ **Load territories** - `getNearbyTerritories()` works
✅ **Geographic checks** - Polygon point-in-polygon logic works
✅ **Energy system** - Steps → attack energy conversion works
✅ **Walking sessions** - GPS tracking & convex hull generation works
✅ **Speed validation** - 2-15 km/h check implemented
✅ **Notifications** - Framework exists

---

## What You DON'T HAVE (The 6 Critical Gaps)

### ❌ 1. No `attack_or_claim_territory()` RPC
**Impact:** Can't attack/claim territories
**Solution:** Create RPC with:
- Speed validation
- Energy calculation
- Protection window check
- Absence shield logic
- Cooldown enforcement
- Territory transfer

### ❌ 2. No Territory Cooldown Table
**Impact:** Players can spam-attack same territory immediately
**Solution:** Create table to track "attacker X can't attack territory Y until TIME"

### ❌ 3. No Attack History Log
**Impact:** No UI history of who attacked when
**Solution:** Log each attack to `territory_attack_log`

### ❌ 4. No Energy Modifiers
**Impact:** Bonuses (+5 revisit, +10 cluster, etc.) not applied
**Solution:** Calculate in RPC based on:
- Days held
- Cluster membership
- Proximity to home base

### ❌ 5. No Decay System
**Impact:** Territories never become neutral, map never resets
**Solution:** Daily job that:
- Loses 2 energy/day after 3 days of no visit
- Becomes neutral when energy = 0

### ❌ 6. No App Methods
**Impact:** App can't trigger attacks
**Solution:** Add to `supabase_service.dart`:
```dart
attackOrClaimTerritory()
getTerritoryHistory()
isTerritoryOnCooldown()
```

---

## The Simple Flow

### Current (BROKEN)
```
User walks → Speed valid? → Call RPC → ❌ RPC DOESN'T EXIST → Nothing happens
```

### After Fix
```
User walks → Speed valid? → Inside enemy territory? → Call RPC → 
→ Check protection/shield/cooldown → Attack/damage/capture → Update DB → 
→ Show notification → Update UI
```

---

## Territory State Model

```dart
Territory {
  id: UUID              // territory identifier
  userId: UUID          // owner ID
  username: string      // owner name
  energy: 0-60          // defensive power
  protected_until: TZ   // 12-hour antifrustration
  shield_until: TZ      // 24-hour absence protection
  last_visited: TZ      // for decay calculation
  polygonPoints: [LatLng]  // boundary from walk
  center: LatLng        // centroid for labels
}
```

---

## The Attack System (What You Need to Build)

```sql
When player walks through a location:

1. Is it inside a territory? (polygon check)
   NO  → Is it unclaimed? 
         YES → CLAIM: Create territory, owner = player, energy = 10
         NO  → Skip
   
   YES → Is it player's own territory?
         YES → REINFORCE: energy += 5 (max 60)
         NO  → Go to step 2

2. Is it an enemy territory?
   
   a. CHECK PROTECTION (12 hours after claim)
      YES → Return: action = 'protected', block attack
      NO  → Continue
   
   b. CHECK ABSENCE SHIELD (24 hours since last visit)
      YES → Attack, but energy floor = 20
      NO  → Normal attack
   
   c. CHECK COOLDOWN (30 min since last attack attempt)
      YES → Return: action = 'cooldown', block attack
      NO  → Continue
   
   d. GET ATTACKER ENERGY
      IF 0 → Return: action = 'no_energy', block attack
      NO  → Continue
   
   e. PERFORM ATTACK
      territory_energy -= attacker_energy
      IF territory_energy <= 0 → CAPTURED: owner = attacker
      ELSE → DAMAGED: energy reduced, owner unchanged
      
   f. UPDATE STATE
      - Set 30-min cooldown
      - Consume attacker energy
      - Update territory
      - Log attack
      - Send notifications
```

---

## Implementation Order

**DO THESE FIRST:**
1. Create `territory_attack_cooldowns` table (20 min)
2. Create `attack_or_claim_territory` RPC (120 min)
3. Add `SupabaseService.attackOrClaimTerritory()` (30 min)
4. Update `MapProvider` to call it (30 min)
Total: **3.5 hours** → Fully working attack system

**THEN ADD POLISH:**
5. Energy modifiers (90 min)
6. Decay system (60 min)
7. Testing & refinement (60 min)

---

## Files to Modify

```
☐ supabase/migrations/
  ☐ Create_territory_attack_cooldowns.sql
  ☐ Create_territory_attack_log.sql  
  ☐ Create_attack_or_claim_territory_rpc.sql
  ☐ Create_decay_territories_rpc.sql (optional)

☐ lib/services/supabase_service.dart
  ☐ Add: attackOrClaimTerritory()
  ☐ Add: getTerritoryAttackHistory()
  ☐ Add: isTerritoryOnCooldown()

☐ lib/providers/map_provider.dart
  ☐ Update: _handleLocationUpdate() to call attackOrClaimTerritory()
  ☐ Update: _handleAttackResult() to handle territory actions

☐ DELETE (or disable):
  ☐ All hex_tiles references
  ☐ claimOrAttackTile() method
  ☐ All H3 tile math
```

---

## Key Insight

You ALREADY have 80% of the system. You just need the **attack/claim RPC** and **one app method** to connect them. The territories table, models, and UI are ready.

---

## Questions Answered

**Q: What about hex tiles?**
A: Ignore them. Delete all hex tile references. Use territories which are already working.

**Q: What's the main missing piece?**
A: The `attack_or_claim_territory()` RPC that checks protection windows, cooldowns, and updates territory ownership.

**Q: How long to get it working?**
A: 3.5 hours for a working attack system.

**Q: What about clusters and decay?**
A: Nice-to-have. Get core attacks working first, then add those.

---

## Ready to implement? Let me know which you want first:

1. ✅ The migration files (table creation)
2. ✅ The RPC (attack logic)
3. ✅ The app methods
4. ✅ The map provider integration
5. ✅ All of the above

