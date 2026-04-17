# Summary: Territory/Attack System - Gap Analysis

## Executive Summary

Your Flutter app references a hex tile territory attack system, but **the entire backend database and RPCs are missing**. The app cannot function until core database tables and RPCs are created.

**Status: 0% Implemented** ⚠️

---

## What's Working ✅
- User authentication (Supabase)
- Step tracking & daily logging
- Attack energy generation (but wrong ratio)
- XP system with leveling
- Walking session tracking
- Live friend locations
- Territory model (for continuous territories, not hex)

---

## What's Broken ❌

### Database (Critical)
| Component | Status | Gap |
|-----------|--------|-----|
| hex_tiles table | ❌ Missing | App expects tile_id, owner_id, tile_energy, protection_until, lat, lng |
| attack_cooldowns table | ❌ Missing | App checks cooldowns but table doesn't exist |
| tile_attack_log table | ❌ Missing | No history of attacks/claims |
| Cluster tracking | ❌ Missing | No cluster bonus system |

### Backend RPCs (Critical)
| RPC | Status | Gap |
|-----|--------|-----|
| claim_or_attack_tile | ❌ Missing | Called by app, returns null or error |
| decay_territories | ❌ Missing | Tiles never lose energy, never become neutral |
| get_hex_tiles_in_bounds | ❌ Missing | Can't load visible tiles |
| calculate_cluster_bonus | ❌ Missing | No cluster bonuses |

### Game Mechanics (Critical)
| Feature | Status | Gap |
|---------|--------|-----|
| 12-hour protection window | ❌ Missing | No anti-frustration window |
| 30-min cooldown per tile | ❌ Missing | App checks but not enforced |
| Absence shield (24h) | ❌ Missing | No protection for sleeping players |
| Territory decay (3+ days) | ❌ Missing | Tiles hold forever |
| Cluster bonuses | ❌ Missing | No incentive for groups |
| Speed validation (2-15 km/h) | ⚠️ Partial | Frontend tracks speed, RPC doesn't validate |

### Gameplay Balance (High Priority)
| Issue | Current | Expected |
|-------|---------|----------|
| Step → Energy ratio | **10 steps = 1 energy** ❌ | **100 steps = 1 energy** |
| Earning speeds | Way too fast | ~66 tiles/day with normal walking |
| Energy cap | Works but applies wrong ratio | Should be 400 (free) / 600 (premium) |

---

## The 6 Critical Fixes (in order)

### 1️⃣ CREATE hex_tiles TABLE (~30 min)
```sql
CREATE TABLE hex_tiles (
  tile_id TEXT PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id),
  tile_energy INT (0-60),
  protection_until TIMESTAMP,
  last_visited_at TIMESTAMP,
  lat FLOAT, lng FLOAT,
  ...
);
```

### 2️⃣ CREATE attack_cooldowns TABLE (~20 min)
```sql
CREATE TABLE attack_cooldowns (
  attacker_id UUID,
  tile_id TEXT,
  cooldown_until TIMESTAMP,
  ...
);
```

### 3️⃣ CREATE claim_or_attack_tile RPC (~90 min)
**Logic:**
- ✅ Validate 2-15 km/h speed
- ✅ Check player has energy
- ✅ If neutral → claim (10 energy, +12hr protection)
- ✅ If own → reinforce (+5 energy, max 60)
- ✅ If enemy + protected → deny
- ✅ If enemy + shield → energy floor 20
- ✅ If enemy + cooldown → deny
- ✅ Otherwise → attack (damage or capture)
- ✅ Set 30-min cooldown
- ✅ Consume energy from player
- ✅ Log the action

### 4️⃣ FIX ENERGY RATIO (~10 min)
Change: `steps / 10` → `steps / 100`

### 5️⃣ UPDATE APP CODE (~30 min)
- Pass speed to claimOrAttackTile() RPC
- Parse RPC response correctly
- Handle all action types (claimed, captured, damaged, protected, cooldown, no_energy)

### 6️⃣ OPTIONAL: Add Decay & Clusters (~90 min)

---

## What App Code Is Expecting

### supabase_service.dart - claimOrAttackTile()
```dart
// App calls this when player taps a tile
final result = await _service.claimOrAttackTile(
  tileId: "12345_67890",
  lat: 51.5074,
  lng: -0.1278,
  speedKmh: 5.2,  // ← Currently NOT passed, add this
);

// Expects response like:
{
  'action': 'captured',  // or 'claimed', 'damaged', 'protected', 'cooldown', 'no_energy'
  'tile_id': '12345_67890',
  'tile_energy_before': 40,
  'tile_energy_after': 0,
  'attacker_energy_left': 25,
  'protection_reason': null,
  'hours_remaining': null,
}
```

### From map_provider.dart - loads visible tiles
```dart
// Currently calls this but table doesn't exist
final rows = await _client
  .from('hex_tiles')
  .select(...)
  .filter_by_bounds();

// Expects:
[
  {
    'tile_id': '1_1',
    'owner_id': 'user-uuid',
    'tile_energy': 25,
    'protection_until': '2026-04-14T15:00:00Z',
    'owner_username': 'FitWarrior',
  },
  ...
]
```

---

## Timeline Impact

| Phase | Work | Days |
|-------|------|------|
| Phase 1 | DB tables (3 tables) | 0.5 |
| Phase 2 | claim_or_attack_tile RPC | 1.0 |
| Phase 3 | Energy ratio fix | 0.1 |
| Phase 4 | App code updates | 0.5 |
| Phase 5 | Decay & clusters (optional) | 1.0 |
| **Total** | | **3-4 days** |

**Minimum viable attack system: 2-3 days**

---

## Deployment Order

1. **Migrations (DB tables)**
2. **RPC implementations**
3. **App code updates**
4. **Testing in emulator/staging**
5. **Production push**

All can be done locally first via `supabase start` before deploying to production.

---

## Files to Create

```
supabase/migrations/
├── 20260414_create_hex_tiles_table.sql
├── 20260414_create_attack_cooldowns_table.sql
├── 20260414_create_tile_attack_log_table.sql
├── 20260414_create_claim_or_attack_tile_rpc.sql
├── 20260414_create_decay_territories_rpc.sql
└── 20260414_create_cluster_bonus_rpc.sql
```

## Files to Edit

```
lib/services/
└── supabase_service.dart
    ├── Fix claimOrAttackTile() signature (add speedKmh)
    ├── Fix getTileState() fields
    ├── Add logTileAttack()
    └── Add getTileHistory()

lib/providers/
└── map_provider.dart
    └── Update attackTile() to pass speedKmh

lib/features/map/widgets/
└── tile_handler.dart
    ├── Update RPC result parsing
    └── Handle new action types
```

---

## Next Steps

1. **Ready to implement?** Start with Phase 1 (tables) + Phase 2 (RPC)
2. **Need code reviews?** Full SQL provided in GAP_ANALYSIS_HEX_SYSTEM.md
3. **Testing plan?** See IMPLEMENTATION_CHECKLIST.md

Good luck! 🚀

