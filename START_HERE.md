# Territory Attack System - 90 Second Summary

## ❌ THE GAP (What's Missing)

Your territories system is **80% complete**. The missing 20% is the attack logic.

### Three Things Missing

1. **No Attack RPC** → Can't trigger attacks
2. **No Cooldown Table** → Prevents spam-attacks  
3. **No App Method** → Can't call the RPC

---

## 🎯 Timeline to Full System

| Phase | What | Time | Critical? |
|-------|------|------|----------|
| 1 | Create cooldown table migration | 20 min | YES |
| 2 | Create attack RPC | 120 min | YES |
| 3 | Add app service method | 30 min | YES |
| 4 | Integrate into map provider | 30 min | YES |
| **SUBTOTAL** | **WORKING GAME** | **3.5 hours** | |
| 5 | Decay system (optional) | 60 min | NO |
| 6 | Cluster bonuses (optional) | 90 min | NO |
| **TOTAL** | **FULL SYSTEM** | **~6 hours** | |

---

## 📋 What Exists vs. Missing

### Database ✅ 90% Done
- `territories` table (✅ exists, has all fields)
- `territory_attack_cooldowns` table (❌ MISSING)
- `territory_attack_log` table (❌ MISSING)

### Game Logic ❌ 20% Done
- Load territories (✅)
- Check if inside territory (✅)
- Validate speed (✅)
- **Attack/claim territory** (❌ **MISSING RPC**)
- Track cooldown (❌)
- Decay energy (❌)

### App Code ⚠️ 50% Done
- Notification framework (✅)
- GPS tracking (✅)
- Territory models (✅)
- **attackOrClaimTerritory() method** (❌ **MISSING**)
- Map integration (❌ waiting for RPC)

---

## 🚀 The One Missing Function

```sql
-- This RPC makes the entire system work:
attack_or_claim_territory(
  territory_id, 
  attacker_id, 
  lat, lng, 
  speed_kmh
) 
RETURNS {
  action: 'claimed'|'captured'|'damaged'|'protected'|'cooldown'|'no_energy',
  territory_energy_before: INT,
  territory_energy_after: INT,
  attacker_energy_left: INT
}
```

---

## 📖 Read These Documents

1. **SUMMARY_TERRITORIES_ONLY.md** — Quick overview (2 min)
2. **TERRITORY_GAPS.md** — Full implementation guide with SQL (30 min)
3. **TERRITORY_DATABASE_GAPS.md** — Exact DB fields & status (10 min)
4. **TERRITORY_GAPS_VISUAL.md** — Pictures of what's implemented (5 min)

---

## 💡 What's Already Working

✅ Player tracking (GPS, speed, location)  
✅ Territory loading (nearby, mine, friends)  
✅ Energy generation (steps → attack energy)  
✅ Notifications (framework ready)  
✅ Spatial checks (point in polygon)  
✅ Data models (Territory class complete)  

---

## ❌ What's Broken

❌ Can't attack territories (RPC missing)  
❌ Can't set cooldowns (table missing)  
❌ Can't enforce protection windows (logic missing)  
❌ Can't enforce absence shield (logic missing)  
❌ Can't decay territories (RPC missing)  
❌ Can't detect clusters (logic missing)  

---

## 🎬 Ready to Build?

**Option A: Quick Start (3.5h)**
- Create cooldown table
- Create attack RPC (copy from TERRITORY_GAPS.md)
- Add service method
- Integrate into map provider
→ Game works end-to-end

**Option B: Full Build (6h)**
- Option A + decay system + cluster bonuses
→ Full feature set

**Option C: Show Me Code**
- See TERRITORY_GAPS.md for complete SQL & Dart code

---

**Key Insight:** You're closer than you think. Just need one RPC + one app method to go from 80% → 100%.

