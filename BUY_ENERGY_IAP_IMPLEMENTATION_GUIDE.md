# Buy Energy — In-App Purchase Implementation Guide (RevenueCat + App Store)

This guide explains how to turn the **Marketplace** tab on the Buy-Energy screen
(`lib/features/steps/view/player_energy_screen.dart`) into working, store-backed
purchases using RevenueCat, and how to grant the energy safely.

---

## 1. What you have today

`player_energy_screen.dart` has two tabs:

- **Marketplace** (`_packages`) — energy sold for real money
  (`10 → Rs 100`, `50 → Rs 280`, … `400 → Rs 2,100`). These are **consumable**
  in-app purchases. The price button is currently a stub: `onTap: () {}`.
- **Packs** (`_packs`) — boosts bought with the energy the player already owns
  (Defense Shield = 300 energy, etc.). **These are NOT in-app purchases** — they
  are in-game spends. Do not route them through the store; they spend
  `profiles.attack_energy` via a Supabase RPC.

This guide is about the **Marketplace** tab only.

## 2. The key concept: consumables ≠ subscriptions

You already wired the **Pro subscription** through RevenueCat entitlements
(`SubscriptionService`, `is_premium`). Energy packs are different:

| | Pro subscription | Energy pack |
|---|---|---|
| Store product type | Auto-renewable subscription / non-consumable | **Consumable** |
| RevenueCat concept | **Entitlement** (`is_premium`) | **No entitlement** — just a transaction |
| Bought | Once (until it lapses) | **Repeatedly** |
| What "owning" means | A boolean flag | A **quantity** you must add and spend |
| Restore purchases | Yes | **No** (consumables aren't restorable) |
| Who grants the value | Check entitlement | **You** grant energy on each purchase |

Because a consumable has no entitlement, RevenueCat/StoreKit only tells you *"the
purchase succeeded"* — **you** are responsible for adding the energy to the
user's balance, exactly once, and defending against replay/fraud.

## 3. Product model — decide your product IDs

Pick one App Store product per energy pack. Use a stable, namespaced scheme:

| Energy | Product ID (App Store / Play) | RevenueCat package id |
|---|---|---|
| 10  | `com.conquercircles.energy.10`  | `energy_10` |
| 50  | `com.conquercircles.energy.50`  | `energy_50` |
| 100 | `com.conquercircles.energy.100` | `energy_100` |
| 200 | `com.conquercircles.energy.200` | `energy_200` |
| 300 | `com.conquercircles.energy.300` | `energy_300` |
| 400 | `com.conquercircles.energy.400` | `energy_400` |

**Important:** the energy amount is decided by your backend from the product id,
**never** from the client. The `Rs 100` price is set in the store and localized
automatically — stop hardcoding it in `_packages`.

## 4. App Store Connect setup (iOS)

1. **Agreements** → sign the *Paid Applications* agreement (Business + Bank +
   Tax). Purchases don't work until this is "Active".
2. **My Apps → your app → In-App Purchases → Manage → +**.
3. Type: **Consumable**. Create one per pack:
   - Reference Name: `Energy 10`
   - Product ID: `com.conquercircles.energy.10`
   - Price: pick the tier (this replaces your hardcoded `Rs 100`).
   - Localization: display name + description (required for review).
   - Review screenshot + notes.
4. Create a **Sandbox tester** (Users and Access → Sandbox → Testers) to test
   without real charges.
5. Products can take minutes–hours to propagate; "Ready to Submit" is enough for
   sandbox testing.

## 5. Google Play setup (Android) — only if you ship Android

Your Android RevenueCat key currently starts with `test_` (a RevenueCat **Test
Store** key), not `goog_`. For real Play purchases:

1. Play Console → Monetize → Products → **In-app products** → create a
   **consumable** product per pack with the same product IDs.
2. Put the RevenueCat **Google** key (`goog_…`) in `main.dart` for Android.
3. Upload a signed build to a testing track and add license testers.

(For pure dashboard testing without store setup, the Test Store key works, but
products must be created in RevenueCat's Test Store and attached to an offering.)

## 6. RevenueCat dashboard setup

**One offering, many packages — not one offering per pack.** A RevenueCat
*offering* is a whole "shelf" of things to sell; each *package* on that shelf
wraps one store product. So all six energy packs live inside a **single**
`energy` offering as six packages:

```
Offering: "energy"                     ← ONE offering (the whole shop shelf)
├── Package "energy_10"   → product com.conquercircles.energy.10
├── Package "energy_50"   → product com.conquercircles.energy.50
├── Package "energy_100"  → product com.conquercircles.energy.100
├── Package "energy_200"  → product com.conquercircles.energy.200
├── Package "energy_300"  → product com.conquercircles.energy.300
└── Package "energy_400"  → product com.conquercircles.energy.400
```

In the client, `getOffering('energy').availablePackages` returns all six, and
you render one card per package. If you instead made six separate offerings,
you'd have to fetch and merge six things for no benefit — don't.

Steps:

1. **Products** → import/add each store product id
   (`com.conquercircles.energy.10` …). Set product type = **Consumable**.
2. **Entitlements** → **do not** attach energy products to any entitlement.
3. **Offerings** → create **one** dedicated offering with identifier `energy`,
   then inside it:
   - Add one **Package** per pack (six packages total). Use a **custom** package
     type and set the package identifier to `energy_10`, `energy_50`, …
     (RevenueCat's predefined `$rc_annual/$rc_monthly` types are for
     subscriptions; for consumables use custom identifiers).
   - Attach the matching product to each package.
4. Keep your existing subscription offering (`current`) as a **separate**
   offering. You'll fetch the `energy` offering **by identifier**
   (`getOffering('energy')`), while the paywall keeps using `current`.

## 7. Server-side granting — the secure design (recommended)

**Never grant energy purely on the client.** A jailbroken device or replayed
receipt can call your "add energy" endpoint repeatedly. Two layers:

### 7a. RevenueCat webhook → Supabase Edge Function (source of truth)

RevenueCat validates the receipt with Apple/Google, then POSTs a
`NON_RENEWING_PURCHASE` event to your webhook. This is the trustworthy signal.

Flow:
```
User taps pack → StoreKit payment sheet → RevenueCat validates
   → RevenueCat fires webhook (NON_RENEWING_PURCHASE)
      → Supabase Edge Function verifies + grants energy (idempotent)
   → client refreshes balance
```

### 7b. Idempotency

Grant against the **store transaction id** and record it, so the same purchase
can never add energy twice (webhook retries, app + webhook both firing, etc.).

## 8. Supabase: schema + RPC

Add a ledger of processed purchases and a grant function. This plugs straight
into the `energy_ledger` you already have — set the context so it shows as a
purchase in the Energy Usage screen.

```sql
-- Processed store purchases (idempotency guard)
create table if not exists public.energy_purchases (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  store_transaction_id text not null,
  product_id        text not null,
  energy_amount     integer not null,
  created_at        timestamptz not null default now(),
  unique (store_transaction_id)         -- dedupe: one grant per transaction
);
alter table public.energy_purchases enable row level security;
create policy energy_purchases_select_own on public.energy_purchases
  for select using (auth.uid() = user_id);

-- Map product id -> energy amount ON THE SERVER (never trust the client)
create or replace function public.energy_for_product(p_product_id text)
returns integer language sql immutable as $$
  select case p_product_id
    when 'com.conquercircles.energy.10'  then 10
    when 'com.conquercircles.energy.50'  then 50
    when 'com.conquercircles.energy.100' then 100
    when 'com.conquercircles.energy.200' then 200
    when 'com.conquercircles.energy.300' then 300
    when 'com.conquercircles.energy.400' then 400
    else 0 end;
$$;

-- Idempotent grant: adds energy once per transaction, logs to energy_ledger.
-- Call this from the Edge Function (service role) — and optionally from the
-- client as a fast-path (see 9b).
create or replace function public.grant_purchased_energy(
  p_user_id uuid,
  p_product_id text,
  p_store_transaction_id text
)
returns integer                     -- new balance
language plpgsql
security definer
set search_path = public
as $$
declare
  v_amount  integer := public.energy_for_product(p_product_id);
  v_balance integer;
begin
  if v_amount <= 0 then
    raise exception 'Unknown energy product %', p_product_id;
  end if;

  -- Idempotency: if this transaction was already processed, no-op.
  insert into public.energy_purchases
    (user_id, store_transaction_id, product_id, energy_amount)
  values (p_user_id, p_store_transaction_id, p_product_id, v_amount)
  on conflict (store_transaction_id) do nothing;

  if not found then
    -- already granted; return current balance unchanged
    select coalesce(attack_energy, 0) into v_balance
      from public.profiles where id = p_user_id;
    return v_balance;
  end if;

  -- Label the ledger entry (reuses your energy_ledger trigger).
  perform set_config('app.energy_ctx',
    jsonb_build_object('type','purchase','description','Energy purchase')::text, true);

  update public.profiles
     set attack_energy = coalesce(attack_energy, 0) + v_amount,
         updated_at = now()
   where id = p_user_id
   returning attack_energy into v_balance;

  return v_balance;
end;
$$;

grant execute on function public.grant_purchased_energy(uuid, text, text) to authenticated;
```

Because it writes `attack_energy`, your existing `trg_log_energy_change` trigger
fires and records a `purchase` / "Energy purchase" row in `energy_ledger`, so the
buy shows up in the Energy Usage screen automatically.

### Edge Function (webhook receiver) — sketch

```ts
// supabase/functions/revenuecat-webhook/index.ts
Deno.serve(async (req) => {
  // 1) Verify the shared Authorization header you set in RevenueCat.
  if (req.headers.get('Authorization') !== Deno.env.get('RC_WEBHOOK_SECRET')) {
    return new Response('unauthorized', { status: 401 });
  }
  const { event } = await req.json();
  if (event?.type === 'NON_RENEWING_PURCHASE') {
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY); // service role
    await supabase.rpc('grant_purchased_energy', {
      p_user_id: event.app_user_id,               // = your Supabase user id (see §10)
      p_product_id: event.product_id,
      p_store_transaction_id: event.transaction_id,
    });
  }
  return new Response('ok');
});
```

Set the webhook URL + `Authorization` secret in RevenueCat → Integrations →
Webhooks.

## 9. Client integration (Flutter)

### 9a. Extend the subscription service (or add an EnergyStoreService)

```dart
// in SubscriptionService
Future<Offering?> getEnergyOffering() async {
  try {
    final offerings = await Purchases.getOfferings();
    return offerings.getOffering('energy'); // the offering id from §6
  } catch (e) { developer.log('energy offering: $e'); return null; }
}

/// Buys a consumable energy package. Returns the store transaction id on
/// success (used to grant energy), or null on cancel/failure.
Future<String?> purchaseEnergy(Package package) async {
  try {
    final result = await Purchases.purchasePackage(package);
    // The most recent non-subscription transaction for this product:
    final txns = result.customerInfo.nonSubscriptionTransactions;
    return txns.isNotEmpty ? txns.last.transactionIdentifier : null;
  } on PlatformException catch (e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    if (code != PurchasesErrorCode.purchaseCancelledError) {
      developer.log('energy purchase failed: ${e.message}');
    }
    return null;
  }
}
```

### 9b. Provider + fast-path grant

Server webhook is the source of truth, but it can lag a second or two. For
instant UX, also call the RPC directly from the client after a successful
purchase — it's **idempotent**, so if the webhook already granted, the client
call is a no-op:

```dart
final energyOfferingProvider = FutureProvider.autoDispose<Offering?>((ref) {
  return SubscriptionService().getEnergyOffering();
});

// after a successful purchase:
final txId = await SubscriptionService().purchaseEnergy(package);
if (txId != null) {
  await Supabase.instance.client.rpc('grant_purchased_energy', params: {
    'p_user_id': Supabase.instance.client.auth.currentUser!.id,
    'p_product_id': package.storeProduct.identifier,
    'p_store_transaction_id': txId,
  });
  ref.invalidate(energyBalanceProvider); // refresh the Available Energy card
}
```

> If you want to be strict (server-only granting), skip the client RPC and just
> poll/refresh the balance after purchase; the webhook does the grant.

### 9c. Wire the Marketplace grid to real data

Turn `PlayerEnergyScreen` into a `ConsumerWidget`, watch `energyOfferingProvider`,
and render `offering.availablePackages`:

- Replace the hardcoded `_EnergyPackage(energy, price)` with the RevenueCat
  package: energy amount from `energy_for_product` (or a client map for display
  only), **price from `package.storeProduct.priceString`** (localized).
- The price button `onTap` runs the purchase + grant above, with a loading state
  and success/failure feedback.
- Show loading / empty / error + retry (same pattern as the paywall now uses).

## 10. Identify the user to RevenueCat (critical for consumables)

For `event.app_user_id` in the webhook to equal your Supabase user id, you must
log the user into RevenueCat — which you already added: `Purchases.logIn(userId)`
on sign-in (`_bindRevenueCatToAuth` in `main.dart`). Keep that. Without it,
purchases attach to an anonymous id and the webhook can't map to a profile.

## 11. Consumable gotchas

- **Finishing transactions:** RevenueCat auto-finishes (iOS) and auto-consumes
  (Android) consumables, so the user can buy the same pack again. You don't call
  StoreKit directly.
- **No restore:** don't offer "Restore" for energy — consumables aren't
  restorable. Restore stays on the subscription paywall only.
- **Pending/deferred purchases** (Ask to Buy, SCA): handle `purchaseEnergy`
  returning null without error; the webhook will grant when it clears.
- **Refunds/chargebacks:** RevenueCat sends `CANCELLATION` / refund events — you
  may optionally deduct energy in the webhook if you want to claw back.
- **Price display:** always use `storeProduct.priceString` (localized, correct
  currency). Delete the hardcoded `Rs …` strings.

## 12. Testing

1. iOS: run on a real device, sign the device into a **Sandbox** Apple ID
   (Settings → App Store → Sandbox Account), tap a pack → sandbox purchase sheet.
2. Verify: `energy_purchases` gets one row, `attack_energy` increases by the pack
   amount, and a `purchase` row appears in `energy_ledger`.
3. Buy the **same pack twice** → energy increases twice (consumable), but each is
   a distinct transaction id (two `energy_purchases` rows). 
4. Force a webhook retry (RevenueCat dashboard) → confirm energy is **not**
   double-granted (idempotency holds).
5. Android: license tester on an internal track with the `goog_` key.

## 13. Implementation checklist

- [ ] Create 6 **consumable** products in App Store Connect (+ Play if Android).
- [ ] Sign Paid Apps agreement; create sandbox testers.
- [ ] Add products in RevenueCat; build an **`energy`** offering (no entitlement).
- [ ] Put the correct platform keys in `main.dart` (Android needs `goog_…`).
- [ ] Apply the `energy_purchases` table + `grant_purchased_energy` RPC migration.
- [ ] Deploy the `revenuecat-webhook` Edge Function; set URL + secret in RevenueCat.
- [ ] Add `getEnergyOffering()` / `purchaseEnergy()` to the service.
- [ ] Convert `PlayerEnergyScreen` Marketplace to live offering + real prices.
- [ ] Grant on purchase (client fast-path) + rely on webhook as source of truth.
- [ ] Refresh the Available Energy card after purchase.
- [ ] Test sandbox: single buy, repeat buy, webhook retry (no double grant).

---

### Summary

The Pro paywall uses **entitlements**; energy packs are **consumables** and need
a **quantity granted per transaction**. Make the store + RevenueCat provide the
localized price and a validated purchase signal, and let a small, **idempotent**
Supabase RPC (called by the RevenueCat webhook, optionally also by the client)
add the energy — which automatically shows up in your existing `energy_ledger`.
Keep the **Packs** tab as in-game energy spends, entirely separate from IAP.
