# App-Side Validation Flow

## Architecture Decision
**App validates FIRST, RPC validates SECOND** — provides UX feedback + security.

---

## Flow Diagram

```
User walks at valid speed (2-15 km/h)
            ↓
GPS triggers location update
            ↓
Map provider calculates tile/territory
            ↓
┌─────────────────────────────────────────────┐
│   APP-SIDE VALIDATION (UX Feedback)         │
├─────────────────────────────────────────────┤
│ 1. Check speed: 2-15 km/h?                  │
│    → GetDuringWalk                          │
│    → Calculate from GPS deltas              │
│ 2. Fetch territory from nearbyTerritories   │
│ 3. Check protection_until > NOW()?          │
│    → Show: "Protected for 2.5h remaining"   │
│    → STOP HERE (no RPC call)                │
│ 4. Check shield_until > NOW()?              │
│    → Show: "Absence shield active"          │
│    → STOP HERE (no RPC call)                │
│ 5. Check cooldown_until > NOW()?            │
│    → Show: "Cooldown: 15m remaining"        │
│    → STOP HERE (no RPC call)                │
│ 6. Check attackEnergy > 0?                  │
│    → Show: "No energy to attack"            │
│    → STOP HERE (no RPC call)                │
│ 7. All checks pass → proceed to RPC         │
└─────────────────────────────────────────────┘
            ↓
        CALL RPC
            ↓
┌─────────────────────────────────────────────┐
│   BACKEND VALIDATION (Security Gate)        │
├─────────────────────────────────────────────┤
│ 1. Verify speed: 2-15 km/h                  │
│    → REJECT if fails                        │
│ 2. Verify attacker has energy               │
│    → REJECT if fails                        │
│ 3. Verify friend relationship               │
│    → REJECT if not friends                  │
│ 4. Verify protection not active             │
│    → REJECT if protected                    │
│ 5. Verify shield not active                 │
│    → REJECT if shielded + steps > 0         │
│ 6. Verify no active cooldown                │
│    → REJECT if cooldown exists              │
│ 7. All checks pass → execute attack         │
│ 8. Update state + log + notifications       │
└─────────────────────────────────────────────┘
            ↓
    Return result to app
            ↓
App updates UI with outcome
```

---

## Data Fetched by App

From `get_territories_nearby()` response:
```dart
class Territory {
  final String id;
  final String userId;
  final String username;
  final int energy;           // 0-60
  final String color;
  final DateTime? protectionUntil;  // ← App uses this
  final DateTime? shieldUntil;      // ← App uses this
  final DateTime captureTime;
  final DateTime lastVisited;
  final List<LatLng> polygonPoints;
  final LatLng center;
}
```

---

## App-Side Pseudocode

```dart
// During walk, on GPS location update
Future<void> _handleLocationUpdate(Position position, double speedKmh) async {
  // === APP-SIDE VALIDATION LAYER ===
  
  // 1. Get current territory near location
  final nearbyTerritories = state.nearbyTerritories;
  final territory = _findTerritoryAtLocation(position.latitude, position.longitude);
  
  if (territory == null) return; // Not on any territory
  
  // 2. Speed check (prevents RPC call)
  if (speedKmh < 2.0 || speedKmh > 15.0) {
    showMessage("Slow down! Walking speed required (2-15 km/h). Current: ${speedKmh.toStringAsFixed(1)} km/h");
    return;
  }
  
  final now = DateTime.now();
  
  // 3. Protection check (prevents RPC call)
  if (territory.protectionUntil != null && territory.protectionUntil!.isAfter(now)) {
    final hoursLeft = _calculateHoursDifference(territory.protectionUntil!, now);
    showMessage("Territory is protected! Protected for ${hoursLeft.toStringAsFixed(1)}h");
    return;
  }
  
  // 4. Shield check (prevents RPC call)
  if (territory.shieldUntil != null && territory.shieldUntil!.isAfter(now)) {
    // Check if defender walked today (from cached daily_steps)
    final defenderStepsToday = await _getDefenderStepsToday(territory.userId);
    if (defenderStepsToday > 0) {
      final hoursLeft = _calculateHoursDifference(territory.shieldUntil!, now);
      showMessage("Absence shield blocks attacks! Shield active for ${hoursLeft.toStringAsFixed(1)}h");
      return;
    }
  }
  
  // 5. Energy check (prevents RPC call)
  final myAttackEnergy = await _getMyAttackEnergy();
  if (myAttackEnergy <= 0) {
    showMessage("⚡ No attack energy! Walk more to generate energy.");
    return;
  }
  
  // 6. Cooldown check (prevents RPC call)
  final activeCooldown = await _getTerritoryAttackCooldown(territory.id);
  if (activeCooldown != null && activeCooldown.isAfter(now)) {
    final minutesLeft = _calculateMinutesDifference(activeCooldown, now);
    showMessage("⏱️ Cooldown active! Wait ${minutesLeft.toStringAsFixed(0)} more minutes");
    return;
  }
  
  // === ALL APP-SIDE CHECKS PASSED → CALL RPC ===
  // RPC validates again (as security gate)
  final result = await _service.attackOrClaimTerritory(
    territoryId: territory.id,
    speedKmh: speedKmh,
    lat: position.latitude,
    lng: position.longitude,
  );
  
  // === HANDLE RPC RESPONSE ===
  _handleAttackResult(result);
}

// Handle attack result
void _handleAttackResult(Map<String, dynamic> result) {
  final action = result['action'] as String;
  
  switch (action) {
    case 'captured':
      showSuccess("🎉 Territory captured!");
      _updateMapAfterAttack();
      break;
      
    case 'damaged':
      final before = result['territory_energy_before'] as int;
      final after = result['territory_energy_after'] as int;
      showSuccess("💥 Territory damaged! Energy: $before → $after");
      _updateMapAfterAttack();
      break;
      
    case 'protected':
      final hoursLeft = result['hours_remaining'];
      showMessage("🛡️ Territory already protected for ${hoursLeft}h");
      // This shouldn't happen if app validation passed
      break;
      
    case 'shielded':
      final hoursLeft = result['hours_remaining'];
      showMessage("🛡️ Absence shield: Territory protected for ${hoursLeft}h");
      // This shouldn't happen if app validation passed
      break;
      
    case 'cooldown':
      final minutesLeft = result['minutes_remaining'];
      showMessage("⏱️ Cooldown: Wait ${minutesLeft} more minutes");
      // This shouldn't happen if app validation passed
      break;
      
    case 'no_energy':
      showMessage("⚡ No energy! Walk more to get energy for attacking");
      break;
      
    case 'error':
      final reason = result['reason'] as String;
      final message = result['message'] as String;
      showError("$reason: $message");
      break;
  }
}
```

---

## Data Flow Diagram

```
┌─────────────────────────────┐
│  territories Table          │
│  ├─ id                      │
│  ├─ user_id                 │
│  ├─ energy (0-60)           │ ← App reads
│  ├─ protection_until        │ ← App reads & checks
│  ├─ shield_until            │ ← App reads & checks
│  └─ last_visited            │
└──────────────┬──────────────┘
               │
        (SELECT nearby)
               │
         Returns to App
               │
         ┌─────▼────────┐
         │  MapProvider │
         │              │
         │ Calculate:   │ ← App-side logic
         │ ├─ protected?│
         │ ├─ shielded? │
         │ ├─ speed OK? │
         │ └─ cooldown? │
         └─────┬────────┘
               │
         ┌─────▼────────────────────┐
         │ Should call RPC?         │
         │ ├─ All checks passed?    │
         │ └─ YES → call RPC        │
         └─────┬────────────────────┘
               │
      attack_or_claim_territory()
      RPC (ALL CHECKS AGAIN)
               │
         ┌─────▼────────────┐
         │  Update State    │
         │  ├─ territory    │
         │  ├─ profiles     │
         │  ├─ cooldown     │
         │  ├─ log          │
         │  └─ notify       │
         └──────────────────┘
```

---

## Key Points

1. **App Prevents Unnecessary RPC Calls**
   - Check speed, protection, shield BEFORE calling RPC
   - Saves bandwidth + latency

2. **RPC Validates as Security Gate**
   - Even if app is compromised/modified
   - Attack still blocked on backend

3. **User Experience**
   - App shows immediate feedback (no 500ms wait)
   - "Protected for 2.5h" displays instantly
   - "Invalid speed" shows during movement

4. **Data Consistency**
   - App reads from cache (territories from last fetch)
   - RPC reads fresh data from DB
   - If mismatch, RPC wins (is correct)

---

## Example UI Messages

| Scenario | App Shows | RPC Confirms |
|----------|-----------|--------------|
| Walking at 5 km/h toward friend's territory | ✅ "Ready to attack" | ✅ Processes attack |
| Walking at 0.5 km/h toward territory | ❌ "Slow down! Speed required" | ❌ Rejects if app bypassed |
| Territory under 12h protection | ❌ "Protected for 8h remaining" | ❌ Rejects if somehow bypassed |
| Territory has absence shield (defender walked) | ❌ "Absence shield: 18h remaining" | ❌ Rejects if somehow bypassed |
| Attack cooldown active | ❌ "Cooldown: 12m remaining" | ❌ Rejects if tried to bypass |
| No attack energy | ❌ "No energy to attack" | ❌ Rejects if tried to bypass |

---

## What App Should NOT Validate

- Friendship relationship (RPC checks)
- Territory ownership change (RPC handles)
- Energy deduction accuracy (RPC handles)
- Cooldown creation (RPC handles)
- Notifications (RPC handles)
- Territory energy updates (RPC handles)

These are RPC-only responsibilities for consistency.

