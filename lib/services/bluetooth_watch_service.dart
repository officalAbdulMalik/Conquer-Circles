// Deprecated & removed.
//
// This service previously scanned for *all* nearby Bluetooth LE devices and
// listed them in the "Connect Wearable" screen. That was misleading: Apple
// Watch (and most fitness watches) do not expose step data over generic
// Bluetooth. Steps arrive on the phone through the OS health store — Apple
// Health on iOS, Health Connect on Android — and the app reads them there.
//
// Watch connection now goes through `WearableService` + `HealthService`
// (Apple Health / Health Connect). There is intentionally no Bluetooth
// scanning or device picker anymore.
//
// This file is left as an empty placeholder because it cannot be deleted in
// this environment. It has no imports and no references.
