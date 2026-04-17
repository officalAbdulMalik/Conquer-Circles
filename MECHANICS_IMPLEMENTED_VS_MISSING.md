# Territory System - Game Mechanics Checklist

## Your Spec vs. What's Implemented

### ✅ IMPLEMENTED (Working Now)

| Requirement | Your Spec | Code Status | Location |
|-------------|-----------|-------------|----------|
| Player walks at 2-15 km/h | Yes | ✅ Enforced | `map_provider.dart` L277 |
| Speed tracked live | Yes | ✅ Working | Every GPS update |
| Location recorded | Yes | ✅ Working | `location_points` table |
| Territory boundaries defined | Yes | ✅ Working | `territories.geom` (PostGIS) |
| Detect if inside territory | Yes | ✅ Working | `_isPointInPolygon()` |
| Load nearby territories | Yes | ✅ Working | `getNearbyTerritories()` RPC |
| Player energy generated | Yes | ✅ Working | `convert_steps_to_energy()` RPC |
| Energy shows on UI | Yes | ✅ Working | Attack energy badge |
| Energy daily cap | Yes | ✅ Working | 400 free / 600 premium |
| Mobile notification framework | Yes | ✅ Working | `NotificationService` |

---

### ⚠️ PARTIALLY IMPLEMENTED (Skeleton Only)

| Requirement | Your Spec | Code Status | Location |
|-------------|-----------|-------------|----------|
| Claim neutral territory | Automatic when walk | ⚠️ Model ready | `Territory` class |
| Territory energy | 0-60 cap | ⚠️ Field exists | `territories.energy` |
| Protection window (12h) | Anti-frustration | ⚠️ Field only | `territories.protected_until` |
| Absence shield (24h) | Sleep protection | ⚠️ Field only | `territories.shield_until` |
| Attack notifications | Send when attacked | ⚠️ Framework only | `notifyTerritoryUnderAttack()` |

---

### ❌ NOT IMPLEMENTED (Logic Missing)

| Requirement | Your Spec | Code Status | Blocker |
|-------------|-----------|-------------|---------|
| **Claim territory** | Automatic | ❌ No RPC | No `attack_or_claim_territory()` |
| **Attack territory** | Use energy to damage | ❌ No RPC | No `attack_or_claim_territory()` |
| **Capture territory** | If energy depleted | ❌ No RPC | No `attack_or_claim_territory()` |
| **Enforce protection** | Block attacks first 12h | ❌ Not checked | No RPC enforcement |
| **Enforce absence shield** | Energy floor = 20 | ❌ Not checked | No RPC enforcement |
| **Cooldown (30 min)** | Prevent spam-attacks | ❌ No table | `territory_attack_cooldowns` missing |
| **Enforce cooldown** | Block if still on CD | ❌ No logic | No RPC enforcement |
| **Consume energy** | Reduce attacker's energy | ❌ Not done | No RPC updates |
| **Territory decay** | -2 energy/day (3+ days) | ❌ No job | No `decay_territories()` RPC |
| **Cluster bonuses** | +5/+10/+20 energy | ❌ No logic | No cluster detection |
| **Energy modifiers** | +5 revisit, +10 48h, etc. | ❌ Not calculated | No bonus logic |

---

## Feature Completion Map

### Step 1: Player Walks (✅ Working)
```
┌─────────────────────────────────────┐
│ GPS Tracking                        │
│ ✅ Location every 5m               │
│ ✅ Speed calculated                │
│ ✅ 100+ points recorded per session │
└─────────────────────────────────────┘
```

### Step 2: Valid Speed? (✅ Working)
```
┌─────────────────────────────────────┐
│ Speed Validation                    │
│ ✅ Must be 2-15 km/h               │
│ ✅ Checked every GPS update        │
│ ✅ Will trigger attack if in range │
└─────────────────────────────────────┘
```

### Step 3: Inside Territory? (✅ Working)
```
┌─────────────────────────────────────┐
│ Spatial Detection                   │
│ ✅ Has territory polygon            │
│ ✅ Has point-in-polygon algorithm   │
│ ✅ Detects boundary crossing       │
└─────────────────────────────────────┘
```

### Step 4: WHO Owns It? (✅ Working)
```
┌─────────────────────────────────────┐
│ Ownership Check                     │
│ ✅ territory.userId stored         │
│ ✅ Can load territory data          │
│ ✅ Can compare with attacker ID    │
└─────────────────────────────────────┘
```

### Step 5: ATTACK! (❌ BROKEN - CRITICAL)
```
┌─────────────────────────────────────┐
│ ❌ attack_or_claim_territory()      │
│    DOES NOT EXIST                   │
│                                     │
│ Missing logic:                      │
│ • Check protection window (12h)    │
│ • Check absence shield (24h)       │
│ • Check cooldown (30 min)          │
│ • Compare energies                 │
│ • Determine: claim/capture/damage  │
│ • Update territory ownership       │
│ • Update territory energy          │
│ • Consume attacker energy          │
│ • Set cooldown                     │
│ • Log action                       │
│ • Send notification                │
│                                     │
│ ❌ UNTIL THIS EXISTS, NOTHING      │
│    HAPPENS WHEN PLAYER WALKS IN    │
│    ENEMY TERRITORY                  │
└─────────────────────────────────────┘
```

### Step 6: Return Result (❌ BLOCKED)
```
┌─────────────────────────────────────┐
│ ❌ Can't return - RPC doesn't exist │
│                                     │
│ Should return:                      │
│ {                                   │
│   action: 'captured',               │
│   territory_energy_before: 40,      │
│   territory_energy_after: 0,        │
│   attacker_energy_left: 25,         │
│   cooldown_until: TIME              │
│ }                                   │
└─────────────────────────────────────┘
```

### Step 7: Update UI (❌ BLOCKED)
```
┌─────────────────────────────────────┐
│ ❌ Can't update - no result         │
│                                     │
│ Would show:                         │
│ • Toast: "Territory Captured!"      │
│ • Territory color changes           │
│ • Territory owner changes           │
│ • Energy bar updates                │
│ • Notification notification sent    │
└─────────────────────────────────────┘
```

---

## Mechanic Implementation Status

### Claiming
```
Requirement: "Territory automatically claimed when player walks through"

Current Flow:
1. Player walks ✅
2. Speed valid? ✅
3. Inside territory? ✅
4. Territory neutral (no owner)? ⚠️ Check possible
5. CLAIM: Set owner to player ❌ NOT IMPLEMENTED
6. Set energy to 10 ❌ NOT IMPLEMENTED
7. Set protection to NOW + 12h ❌ NOT IMPLEMENTED

Status: Ready but blocked by missing RPC
```

###  Reinforcing
```
Requirement: "If player revisits own territory, energy +5"

Current Flow:
1. Player walks ✅
2. Speed valid? ✅
3. Inside territory? ✅
4. Territory is mine? ⚠️ Check possible
5. REINFORCE: energy += 5 ❌ NOT IMPLEMENTED
6. Cap at 60 ❌ NOT IMPLEMENTED

Status: Ready but blocked by missing RPC
```

### Attacking
```
Requirement: "Attack enemy territory with available energy"

Current Flow:
1. Player walks ✅
2. Speed valid? ✅
3. Inside territory? ✅
4. Territory belongs to friend? ⚠️ Can load friend list
5. Check protection (12h)? ❌ No RPC check
6. Check shield (24h)? ❌ No RPC check
7. Check cooldown (30 min)? ❌ No table, no RPC
8. Get attacker energy? ⚠️ Query exists
9. Compare: territory_energy vs attack_energy? ❌ Not done
10. IF energy_before <= attack_energy -> CAPTURE ❌ Not done
11. ELSE -> DAMAGE ❌ Not done
12. Update DB ❌ Not done
13. Set cooldown ❌ Table missing

Status: Every step blocked after step 5
```

### Decay
```
Requirement: "If not visited 3+ days: lose 2 energy/day, become neutral at 0"

Current Flow:
1. Daily job runs? ❌ No scheduler
2. Check territories last_visited ❌ No decay logic
3. Update energy ❌ No RPC
4. If energy = 0, set owner_id = NULL ❌ Not done

Status: Not started
```

---

## What Prevents Each Action

| User Action | What Blocks It? |
|-------------|-----------------|
| Walk into **neutral** territory | Missing RPC: `attack_or_claim_territory()` |
| Walk into **own** territory | Missing RPC: `attack_or_claim_territory()` |
| Walk into **enemy** protected territory | Missing RPC protection check + `territory_attack_cooldowns` table |
| Walk into **enemy** unprotected territory | Missing RPC: `attack_or_claim_territory()` |
| See territory energy decrease | Missing RPC + missing `territory_attack_log` |
| See cooldown timer | Missing `territory_attack_cooldowns` table |
| See territory become neutral | Missing decay RPC + missing scheduler |
| Earn territory bonuses | Missing cluster detection + missing bonus logic |

---

## Implementation Dependency Tree

```
attack_or_claim_territory() RPC
├─ Needs: territory_attack_cooldowns table
│  └─ Can create independently ✅
├─ Needs: territory_attack_log table
│  └─ Can create independently ✅
├─ Needs: LOGIC for:
│  ├─ Protection window check ✅ (code there, needs RPC implementation)
│  ├─ Absence shield check ✅ (code there, needs RPC implementation)
│  ├─ Cooldown check ✅ (logic there, needs table + RPC)
│  ├─ Energy comparison ✅ (math ready, needs RPC)
│  ├─ Territory ownership update ✅ (RPC can do)
│  ├─ Energy reduction ✅ (RPC can do)
│  └─ Cooldown creation ✅ (RPC can do)
└─ Then: Add app method

Once RPC exists:
├─ Add: SupabaseService.attackOrClaimTerritory()
├─ Update: MapProvider._handleLocationUpdate()
└─ Game works! ✅
```

---

## How Much Code Exists Upstream?

| Component | Lines | Status |
|-----------|-------|--------|
| Territory models | ~200 | ✅ Complete |
| Load RPC calls | ~300 | ✅ Complete |
| GPS tracking | ~400 | ✅ Complete |
| Speed validation | ~50 | ✅ Complete |
| Polygon detection | ~50 | ✅ Complete |
| **Attack RPC** | 0 | ❌ Missing |
| **Attack service method** | 0 | ❌ Missing |
| Notifications | ~300 | ✅ Complete |
| **Total app code to write** | ~200-300 | ⚠️ Moderate |

---

## Bottom Line

**You have the infrastructure. You just need the attack logic.**

Once you create:
1. ✅ Cooldown table (SQL)
2. ✅ Attack RPC (120 lines of SQL)
3. ✅ Service method (20 lines of Dart)
4. ✅ Map integration (15 lines of Dart)

Everything else works automatically.

