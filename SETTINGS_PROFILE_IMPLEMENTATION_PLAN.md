# Settings & Profile Module — Implementation Plan

**Goal:** Make every Settings and Profile screen fully functional (data-driven + backend-wired), replacing static/stubbed content.
**Scope:** `lib/features/settings/**`, `lib/features/profile/**`, supporting providers, and `SupabaseService`.
**Constraint:** This is a plan only. No code is changed by this document.

---

## 1. Current-State Audit

This plan is grounded in what already exists in the repo. Summary of what works vs. what is static or stubbed today.

### Already functional (leave intact, only extend)
- **Edit Profile** (`edit_profile_view.dart` + `edit_profile_provider.dart`) — loads profile, uploads avatar, saves via `SupabaseService.updateProfile`. Note: birthday/height/weight fields are `readOnly` (no pickers wired yet).
- **Notification toggle** — wired to `profileProvider.toggleNotifications` → `SupabaseService.updateNotificationSettings`.
- **Change Password** (`update_password_screen.dart`) — wired to `authProvider.updatePassword`.
- **Location Service** (bottom sheet) — calls `mapProvider.initialize(forceRequest: true)`.
- **Sign Out** — wired to `profileProvider.logout`.
- **Goals** — navigates to `GoalsSelectionScreen(isEditMode: true)`; provider has `updateGoals`.
- **Profile stats + badges** — driven by `dashboardProvider` / `profileProvider`.

### Static / stubbed / non-functional (the work)
| Item | File | Problem |
|---|---|---|
| "Connected Account" row | `settings_view.dart:42` | `onTap: () {}` — no action |
| "Delete" (Accounts screen) | `settings_view.dart:89` | `onTap: () {}` — no delete |
| Delete Account (bottom sheet) | `settings_bottom_sheet.dart:331` | Only shows snackbar "request submitted" — no backend |
| Privacy Policy (profile sheet) | `profile_bottom_sheet.dart:183` | `onTap: () {}` — no action |
| Privacy Policy (settings sheet) | `settings_bottom_sheet.dart:158` | Hardcoded dialog text only |
| Premium banner | `profile_bottom_sheet.dart:84` | `onTap: () {}` — no navigation |
| Energy Usage screen | `energy_usage_screen.dart:12` | 100% hardcoded `_items` list |
| Referral screen | `referral_code_screen.dart` | Hardcoded code `AQIB50`, static steps + history, no share |
| FAQs screen | `faqs_screen.dart` | Hardcoded `_faqItems` |
| `SettingsState` (theme/units/alerts) | `settings_provider.dart` | Defined but never used by any UI, not persisted |
| `theme_selector.dart` | file | Empty |
| `theme_provider.dart` | file | Empty |
| Location Service row (profile sheet) | `profile_bottom_sheet.dart:176` | Display-only, no tap handler |

### Missing backend (SupabaseService)
Currently present: `getProfile`, `getProfileData`, `updateProfile`, `uploadProfileAvatar`, `updateNotificationSettings`, `updateGoals`, `updatePassword`, `signOut`.
Missing: account deletion, referral code/history, energy usage ledger, connected-account metadata, privacy-policy URL, settings persistence (theme/units/alerts).

---

## 2. Work Breakdown — Tasks & Subtasks

### TASK 1 — Backend foundation (Supabase) for the module
*Do this first; UI tasks depend on it.*

- **1.1 Account deletion**
  - Decide model: soft-delete flag + scheduled purge (matches existing "processed within 7 days" copy) vs. immediate hard delete.
  - Add Supabase RPC / Edge Function `request_account_deletion` (auth-scoped, marks `profiles.deletion_requested_at`, revokes session).
  - Add `SupabaseService.requestAccountDeletion()` calling it.
- **1.2 Referral data**
  - Confirm/create `referrals` schema: user's own `referral_code`, and a `referral_events` table (referred name, timestamp, energy awarded).
  - RPC `get_referral_summary` returning `{ code, total_earned, history[] }`.
  - Add `SupabaseService.getReferralSummary()`.
- **1.3 Energy usage ledger**
  - Confirm/create `energy_ledger` table (type, description, delta, created_at) already implied by attack/streak/badge mechanics.
  - RPC or query `get_energy_history(limit, cursor)`.
  - Add `SupabaseService.getEnergyHistory()`.
- **1.4 Connected accounts**
  - Read auth identities (Google/Apple/email) from Supabase auth user.
  - Add `SupabaseService.getConnectedIdentities()`.
- **1.5 Settings persistence**
  - Add columns (or `settings` jsonb) on `profiles`: `theme`, `units`, `daily_alerts`, `reminders`.
  - Add `SupabaseService.updateAppSettings(...)` and include values in `getProfileData`.
- **1.6 Static content endpoints (optional)**
  - Privacy Policy + FAQ: either a hosted URL (`url_launcher`) or a `content` table for in-app rendering. Pick one approach for both.
- **1.7 Regenerate types & smoke-test** each RPC from a scratch Dart script before wiring UI.

### TASK 2 — Account Deletion (make functional)
- **2.1** Create `accountProvider` (or extend `profileProvider`) with `deleteAccount()` → calls `SupabaseService.requestAccountDeletion()`, exposes loading/error.
- **2.2** `settings_bottom_sheet.dart`: replace snackbar-only `_showDeleteAccountDialog` flow with a real call; show progress, success, and error states.
- **2.3** `settings_view.dart:89`: wire the "Delete" row `onTap` to the same confirmation dialog + provider call (currently `() {}`).
- **2.4** On success: sign the user out and route to the auth/login entry point.
- **2.5** Handle re-auth requirement if Supabase requires a fresh login for destructive ops.

### TASK 3 — Referral screen (make data-driven)
- **3.1** Create `referralProvider` (FutureProvider/Notifier) using `SupabaseService.getReferralSummary()`.
- **3.2** `referral_code_screen.dart`: replace hardcoded `AQIB50` with `summary.code`; add loading + empty states.
- **3.3** Replace static `_history` with `summary.history` (map to `ReferralHistoryTile`); empty-state when none.
- **3.4** Add **Copy code** (Clipboard) and **Share** (`share_plus`) actions — the "Share Your Code" step currently has no button.
- **3.5** Keep the 3-step "How It Works" copy static (informational) but source energy amount from config if available.
- **3.6** Error/retry handling.

### TASK 4 — Energy Usage screen (make data-driven)
- **4.1** Create `energyUsageProvider` using `SupabaseService.getEnergyHistory()`.
- **4.2** `energy_usage_screen.dart`: replace static `_items` with fetched ledger; keep `+/-` colour logic (green gain / red spend) but derive from `delta` sign.
- **4.3** Add loading, empty ("No energy activity yet"), and error states.
- **4.4** Add pagination / pull-to-refresh if the ledger can grow.
- **4.5** Show current energy balance header (reuse `dashboard.attackEnergy` / `getAttackEnergy`).

### TASK 5 — Connected Account row (make functional)
- **5.1** `settings_view.dart:42`: replace `onTap: () {}`.
- **5.2** Show the real connected provider(s) from `getConnectedIdentities()` (Google/Apple/email) in the subtitle instead of the static "Social login".
- **5.3** On tap: open a detail sheet listing linked identities; optionally support link/unlink if backend allows.

### TASK 6 — Privacy Policy & FAQs (make functional)
- **6.1** Decide: external URL (open with `url_launcher`) vs. in-app content screen.
- **6.2** Privacy Policy — wire `profile_bottom_sheet.dart:183` (`() {}`) and replace the hardcoded dialog in `settings_bottom_sheet.dart:158` with the chosen approach.
- **6.3** FAQs — if content must be remote, load from backend into `faqs_screen.dart`; otherwise formally keep `_faqItems` static and document that decision.
- **6.4** Add Terms of Service alongside Privacy Policy if product requires it.

### TASK 7 — Premium banner / Plan & Purchase
- **7.1** `profile_bottom_sheet.dart:84`: wire `PremiumBannerCard(onTap:)` to navigate to `PremiumPaywallView` / `PlanPurchaseView`.
- **7.2** Hide or change the banner when `subscriptionProvider` reports an active subscription.
- **7.3** Verify purchase/restore flows in `subscription_provider.dart` are reachable from this entry point.

### TASK 8 — App Settings state (theme / units / alerts)
- **8.1** Decide whether the unused `settingsProvider` (theme/units/dailyAlerts/reminders) should be surfaced in the UI or removed. If kept:
- **8.2** Build the missing UI: a Preferences section with Theme selector, Units (Metric/Imperial) toggle, Daily Alerts and Reminders switches.
- **8.3** Implement `theme_provider.dart` (currently empty) and connect to `MaterialApp` themeMode; fill in `theme_selector.dart` (currently empty) or delete both if theming is out of scope.
- **8.4** Persist changes via `SupabaseService.updateAppSettings` (Task 1.5) and hydrate on load.
- **8.5** Ensure Units preference actually reformats displayed distance/weight where shown (edit profile, stats).

### TASK 9 — Edit Profile completeness
- **9.1** Wire the `readOnly` birthday field to a date picker feeding `editProfileProvider` (`_selectedBirthDate` already exists in provider).
- **9.2** Wire height/weight fields to numeric input or pickers (currently `readOnly`).
- **9.3** Add client-side validation (username required already handled; add length/format checks, email display consistency).
- **9.4** Confirm avatar upload success/failure surfaces to the user (snackbar via `state.message`).

### TASK 10 — Location Service consistency
- **10.1** In `profile_bottom_sheet.dart` (ProfileScreen version, line ~176) the row is display-only. Either add the same `mapProvider.initialize(forceRequest: true)` onTap used in the settings sheet, or route to OS settings when already denied.
- **10.2** Reflect live permission state consistently across both sheets.

### TASK 11 — Cross-cutting polish
- **11.1** Consolidate duplicate settings UIs: `settings_view.dart` ("Accounts") vs. `settings_bottom_sheet.dart` (SETTINGS) present overlapping actions with different behaviour (e.g., Delete). Decide the canonical surface and align behaviour.
- **11.2** Remove `print` debug statements in `profile_provider.dart` (`toggleNotifications`, `logout`) or replace with `debugPrint`/logger.
- **11.3** Add unused-widget cleanup: `settings_header.dart`, `settings_section.dart`, `profile_settings_tile.dart`, empty `theme_selector.dart` — confirm usage or remove.
- **11.4** Loading/empty/error states standardised across all new data screens (referral, energy, connected accounts).
- **11.5** Accessibility pass: tap target sizes, semantic labels on icon-only buttons, contrast.

### TASK 12 — Verification (required)
- **12.1** `flutter analyze` clean for all touched files.
- **12.2** Manual QA matrix: each row/action navigates or performs its backend call; verify success + failure paths (airplane mode / forced RPC error).
- **12.3** Widget tests for providers (referral, energy, delete-account) with mocked `SupabaseService`.
- **12.4** Verify account deletion end-to-end against a disposable test account, incl. sign-out + routing.
- **12.5** Verify settings persistence survives app restart.
- **12.6** Regression check: existing working items (edit profile, notifications, password, sign out) still function.

---

## 3. Suggested Sequencing

1. **Task 1** (backend) — unblocks everything else.
2. **Tasks 2, 3, 4** (delete, referral, energy) — the highest-value "make it real" screens.
3. **Tasks 5, 6, 7** (connected account, privacy/FAQ, premium) — smaller wiring jobs.
4. **Tasks 8, 9, 10** (settings state, edit-profile pickers, location) — completeness.
5. **Task 11** (polish/consolidation), then **Task 12** (verification) as the final gate.

## 4. Open Decisions (need product/owner input)
- Account deletion: soft-delete + 7-day purge (matches current copy) vs. immediate hard delete?
- Privacy Policy / FAQ / Terms: hosted URL vs. in-app content table?
- App theming (light/dark) + units: in scope now, or remove the dormant `settingsProvider`/`theme_provider`?
- Connected accounts: read-only display, or full link/unlink support?
- Referral reward amount: fixed (+50) or server-configured?

## 5. Dependencies & Packages to Confirm
- `share_plus` (referral share), `url_launcher` (privacy/terms), `image_picker` (already present) — confirm in `pubspec.yaml` before Task 3/6.
- Supabase RLS policies for any new tables (referrals, energy_ledger) must scope rows to the authenticated user.
