# RPC Analysis - Complete Documentation Index

## 📋 Quick Navigation

| Document | Purpose | Read Time |
|----------|---------|-----------|
| **RPC_ANALYSIS_SUMMARY.md** | Executive summary + next steps | 5 min |
| **CLAIM_ATTACK_RPC_ANALYSIS.md** | Detailed gap analysis (11 issues) | 15 min |
| **NEW_RPC_IMPLEMENTATION.md** | Complete working RPC + migrations | 20 min |
| **APP_SIDE_VALIDATION_FLOW.md** | App validation logic + examples | 15 min |

---

## 🎯 Start Here

### For Decision Makers
1. Read: [RPC_ANALYSIS_SUMMARY.md](RPC_ANALYSIS_SUMMARY.md) (5 min)
2. Skim: "Critical Gaps Summary" table

### For Backend Developers
1. Read: [CLAIM_ATTACK_RPC_ANALYSIS.md](CLAIM_ATTACK_RPC_ANALYSIS.md) (15 min)
2. Review: [NEW_RPC_IMPLEMENTATION.md](NEW_RPC_IMPLEMENTATION.md) (20 min)
3. Copy: Migration SQL + RPC code (ready to paste)

### For Mobile Developers
1. Read: [APP_SIDE_VALIDATION_FLOW.md](APP_SIDE_VALIDATION_FLOW.md) (15 min)
2. Reference: Code pseudocode examples
3. Update: SupabaseService + MapProvider with new method

---

## 🔴 The Problem (1-minute version)

**Current:** App calls `claim_or_attack_tile()` - a hex tile RPC
**Should be:** App should call `attack_or_claim_territory()` - a territory RPC

### Why it matters:
- ❌ Wrong table (hex_tiles vs territories)
- ❌ No speed validation (easy to cheat)
- ❌ Wrong energy model (fixed 10 damage vs full energy)
- ❌ Broken protection logic (bypass shields)
- ❌ No cooldown enforcement (spam attacks)

### Impact:
**Game is completely broken** — attacks don't work, validation missing, energy model wrong.

---

## ✅ The Solution (2-minute version)

**Create new RPC** that:
1. ✅ Targets `territories` table (not hex_tiles)
2. ✅ Validates speed 2-15 km/h server-side
3. ✅ Uses full energy consumption (not fixed 10)
4. ✅ Implements absence shield checks (shield_until + steps check)
5. ✅ Returns clear action codes for app

**App-side:**
1. ✅ Validate protection/shield/cooldown first (UX feedback)
2. ✅ Call RPC for final validation + attack execution
3. ✅ Display result (captured/damaged/protected/error)

---

## 📊 Gap Summary

| Gap | Current | Required | Priority |
|-----|---------|----------|----------|
| Table target | hex_tiles ❌ | territories ✅ | 🔴 CRITICAL |
| Speed validation | None ❌ | 2-15 km/h ✅ | 🔴 CRITICAL |
| Energy model | Fixed 10 ❌ | Full energy ✅ | 🔴 CRITICAL |
| Protection check | Basic ❌ | protection_until + shield_until ✅ | 🔴 CRITICAL |
| Cooldown table | attack_cooldowns ❌ | territory_attack_cooldowns ✅ | 🔴 CRITICAL |
| Capture logic | Broken ❌ | attacker >= territory ✅ | 🔴 CRITICAL |
| Friend check | Backwards ❌ | Friends only ✅ | 🟠 HIGH |
| Log table | tile_attack_log ❌ | territory_attack_log ✅ | 🟠 HIGH |
| Notifications | Incomplete ❌ | Full notifications ✅ | 🟡 MEDIUM |
| Cluster bonus | Wrong table ❌ | Dynamic calc ✅ | 🟡 MEDIUM |
| Decay system | None ❌ | RPC + scheduler ✅ | 🟡 MEDIUM |

---

## 🛠️ Implementation Checklist

### Database (10 min)
- [ ] Copy migration SQL from NEW_RPC_IMPLEMENTATION.md
- [ ] Run migrations (creates tables)
- [ ] Copy new RPC function code
- [ ] Create RPC in database

### Dart - SupabaseService (10 min)
- [ ] Add `attackOrClaimTerritory()` method with speed parameter
- [ ] Keep `claimOrAttackTile()` comments for reference only
- [ ] Test method compiles

### Dart - MapProvider (15 min)
- [ ] Update `_processTerritoryEntry()` to pass speedKmh to RPC
- [ ] Add app-side protection check (prevents RPC call)
- [ ] Add app-side shield check (prevents RPC call)
- [ ] Add app-side cooldown check (prevents RPC call)
- [ ] Update `onEnterTile()` method signature
- [ ] Test UI shows correct messages

### Testing (20 min)
- [ ] Test attack succeeds at valid speed (2-5 km/h)
- [ ] Test attack fails at invalid speed (0.5, 25 km/h)
- [ ] Test protection blocks attacks (shows message, no RPC)
- [ ] Test shield blocks attacks with steps > 0
- [ ] Test cooldown blocks repeated attacks
- [ ] Test energy consumption correct
- [ ] Test notifications sent on capture/damage

**Total: ~55 minutes**

---

## 📈 File Sizes & Content

```
RPC_ANALYSIS_SUMMARY.md              2.5 KB  ← START HERE
├─ Executive summary
├─ Critical gaps table
├─ Action items prioritized
└─ Time estimates

CLAIM_ATTACK_RPC_ANALYSIS.md        12 KB  ← DETAILED ANALYSIS
├─ 11 gap explanations with code examples
├─ 4 logical issues explained
├─ Design intent discussion
└─ Required fixes (prioritized)

NEW_RPC_IMPLEMENTATION.md            18 KB  ← COPY-PASTE CODE
├─ Complete RPC function (150 lines)
├─ All migration SQL (tables + RLS)
├─ Return value examples (all cases)
└─ Dart integration code examples

APP_SIDE_VALIDATION_FLOW.md         12 KB  ← ARCHITECTURE GUIDE
├─ Flow diagram (visual)
├─ Pseudocode example
├─ Data flow diagram
└─ When app validates vs RPC
```

---

## 🔗 Cross-References

### Related to Territory System
- [TERRITORY_GAPS.md](TERRITORY_GAPS.md) - Overall territory system analysis
- [MECHANICS_IMPLEMENTED_VS_MISSING.md](MECHANICS_IMPLEMENTED_VS_MISSING.md) - What's working/missing
- [START_HERE.md](START_HERE.md) - Quick territorial system intro

### Related to Database
- Database migrations: [migrations/](supabase/migrations/)
- Territory table schema: territories (25 columns in public schema)
- RPC list: attack_or_claim_territory, capture_territory, get_home_territory

### Related to App Code
- Main service: [lib/services/supabase_service.dart](lib/services/supabase_service.dart)
- Map provider: [lib/providers/map_provider.dart](lib/providers/map_provider.dart)
- Territory model: [lib/models/walk_models.dart](lib/models/walk_models.dart)

---

## ⚡ Quick Decisions

### Do I need to read all 4 documents?
**No.** Start with:
1. RPC_ANALYSIS_SUMMARY.md (5 min)
2. Then skip to what's relevant:
   - Backend dev? → NEW_RPC_IMPLEMENTATION.md
   - Frontend dev? → APP_SIDE_VALIDATION_FLOW.md
   - Full understanding? → All 4

### Can I just copy-paste the code?
**Yes!** From NEW_RPC_IMPLEMENTATION.md:
- Copy migration SQL (section: "Migration SQL")
- Copy RPC code (section: "Complete Implementation")
- Copy Dart code (section: "App Integration (Dart)")

### What if I have questions?
All 11 gaps are explained in CLAIM_ATTACK_RPC_ANALYSIS.md with code examples.

---

## 🚀 Implementation Path

```
1. Read Summary (5 min)
           ↓
2. Are you implementing? (Yes/No)
   ├─ Yes → Read detailed gap analysis (15 min)
   │        Read new RPC implementation (20 min)
   │        Copy SQL + code
   │        Implement in DB + app (55 min)
   │        Test (20 min)
   │        Total: ~2 hours
   │
   └─ No → Understand architecture (read flow doc)
          Total: 15 min
```

---

## 📞 Common Questions

### Q: Why does the app need to validate too if RPC validates?
**A:** Two benefits:
- **UX:** App shows instant feedback (no 500ms RPC wait)
- **Security:** Defense in depth (if app is hacked/spoofed, RPC catches it)

### Q: Can cluster bonuses be calculated in the app instead?
**A:** Better to calculate in RPC because:
- Consistency (same logic everywhere)
- Cluster membership changes (must recompute)
- Can't trust app to calculate correctly

### Q: Should decay run on schedule or on-demand?
**A:** On schedule (pg_cron daily):
- Simpler logic
- Automatic consistency
- No manual triggers needed

### Q: Where does the speed value come from?
**A:** From `MapProvider.state.currentSpeedKmh` which is calculated from GPS deltas:
```dart
final speedMsec = _calculateDistance(...) / timeElapsedSeconds;
final speedKmh = speedMsec * 3.6;  // m/s to km/h
```

### Q: What if territories table doesn't exist?
**A:** It exists! Confirmed with:
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'territories'
```
Has 25 columns including: energy, protection_until, shield_until, etc.

---

## 🎓 Learning Path

**For new team members:**
1. Start: RPC_ANALYSIS_SUMMARY.md
2. Then: APP_SIDE_VALIDATION_FLOW.md (understand architecture)
3. Then: CLAIM_ATTACK_RPC_ANALYSIS.md (deep dive on issues)
4. Finally: NEW_RPC_IMPLEMENTATION.md (implementation details)

**For existing team members:**
1. Just reference the specific section you need

---

## ✨ Next Steps

### Immediate (This Sprint)
- ✅ Whoever is handling backend: Review NEW_RPC_IMPLEMENTATION.md
- ✅ Whoever is handling frontend: Review APP_SIDE_VALIDATION_FLOW.md
- ✅ Plan: 2-hour implementation window

### Short Term (Next Week)
- Test end-to-end
- Deploy to production
- Monitor for edge cases

### Medium Term (Nice to Have)
- Add cluster bonus calculation
- Add decay scheduler
- Add anti-cheat monitoring

---

## 📧 Summary Emails

### For Your Stakeholder
Subject: Territory Attack System Critical RPC Issues Found

The game's attack system is broken. The app calls a hex tile RPC instead of a territory RPC. This causes:
- Attacks don't work (wrong table target)
- Easy speed cheating (no server validation)
- Wrong damage model (energy calculation broken)
- Missing security checks (shields, cooldowns)

**Solution:** Create new RPC (copy-paste ready)
**Timeline:** ~2 hours to full implementation + testing
**Docs:** 4 analysis documents with complete guidance

### For Your Backend Team
Subject: New Territory Attack RPC - Migration Ready

Please implement `attack_or_claim_territory()` RPC. All SQL is prepared and ready to copy-paste:
- Migration SQL (creates 3 tables)
- New RPC implementation (150 lines, well-commented)
- Includes: Speed validation, energy deduction, shield logic, cooldowns, logging, notifications

Complete code in NEW_RPC_IMPLEMENTATION.md

### For Your Frontend Team
Subject: Territory Attack RPC Changes - App Integration Required

The attack RPC is changing. You need to:
1. Add speedKmh parameter to claimOrAttackTile() call
2. Add app-side validation (protection, shield, cooldown checks)
3. Update MapProvider to use new RPC signature

Flow guide in APP_SIDE_VALIDATION_FLOW.md - includes pseudocode examples.

---
