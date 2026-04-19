# Changelog

All notable changes to **nb-bridge** are documented in this file.

The project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** — incompatible API changes
- **MINOR** — new functionality, backwards-compatible
- **PATCH** — bug fixes, backwards-compatible

---

## [1.2.1] — 2026-04-19

### Fixed

- **origen_inventory image path** — `BridgeConfig.InventoryImagePaths.origen_inventory` was pointing at `ui/images/`, which is not where origen_inventory serves item icons. Corrected to `html/images/` to match the canonical convention used across the inventory's NUI.

This is a cosmetic fix — item icons now render correctly on servers using origen_inventory without having to override the bridge config manually. Existing consumers (nb-consumibles, nb-shops, nb-restaurants) benefit immediately.

---

## [1.2.0] — 2026-04-19

### Added

- **`origen_inventory` support** in the inventory module. Detected automatically alongside `ox_inventory`, `qb-inventory` and `qs-inventory`. `Bridge.InventorySystem == 'origen_inventory'` is a valid value.
- `Bridge.AddItem`, `Bridge.RemoveItem`, `Bridge.HasItem`, `Bridge.CanCarry` — routed through `exports.origen_inventory:addItem/removeItem/getItemCount/canCarryItem`.
- `Bridge.RegisterStash` — uses `exports.origen_inventory:registerStash(id, { label, slots, weight })` with the stash defaults from `Config.Stash` / `BridgeConfig.Stash`.
- `Bridge.ForceOpenStash` and `Bridge.ForceOpenPlayerInventory` — origen opens from the client, so the bridge now relays the request via the `nb-bridge:client:origenOpenInventory` event.
- `Bridge.GetAllItems` — reads the runtime item list from `exports.origen_inventory:Items()`.
- `Bridge.OpenStash`, `Bridge.OpenPlayerInventory`, `Bridge.GetItemCount` (client) — wired to `openInventory` and `Search('count', item)`.
- `Bridge.RegisterUsableItem` — additionally wires the handler through `exports.origen_inventory:CreateUseableItem` when origen is active, so "use" works regardless of which side triggers it.

### Compatibility

- **Fully backwards-compatible** with 1.1.0 — no renames, no signature changes.
- Requires `origen_inventory` only when your server uses it; the detection is opt-in.

---

## [1.1.0] — 2026-04-19

### Added

- **`Bridge.RegisterUsableItem(itemName, handler)`** — unified wrapper around `ESX.RegisterUsableItem` and `QBCore.Functions.CreateUseableItem`. Your callback receives `(source, { name, slot })` regardless of the framework, so consumer resources (like **nb-consumibles**) can register usable items once and work on both stacks.
- **`Bridge.IsUsableItemRegistered(itemName)`** — boolean lookup to check if an item was already registered through the bridge (useful for hot-reload flows that re-register items on config change).
- **qs-inventory support** in the inventory module — now auto-detected alongside `ox_inventory`, `qb-inventory` and the framework defaults. `AddItem`, `RemoveItem`, `HasItem`, `CanCarry`, `RegisterStash` and `ForceOpenStash` route through qs-inventory when it is the active inventory system.
- `Bridge.InventorySystem = 'qs-inventory'` is now a valid value for scripts that branch on inventory detection.

### Changed

- Internal registration ledger inside the inventory module prevents double-registration of the same usable item across reloads.

### Compatibility

- **Fully backwards-compatible** with 1.0.0. No renames, no signature changes.
- Consumers that require the new usable-item API (e.g. **nb-consumibles**) should declare `nb-bridge` >= 1.1.0 in their docs.

---

## [1.0.0] — 2026-04-03

First public release.

### Added

- **Framework auto-detection** — ESX Legacy and QBCore detected at boot, exposed as `Bridge.Framework` and `Bridge.FrameworkObject`.
- **Framework module** — unified API for players, permissions, money (cash/bank), jobs, gangs, metadata, playtime, teleport, billing, coords, player vars, command execution and the `OnPlayerLoaded` event.
- **Inventory module** — abstraction over `ox_inventory`, `qb-inventory` and framework defaults. Covers item CRUD, stash registration, force-open flows and the full items catalog.
- **Notify module** — `Bridge.Notify` (server) and `Bridge.ShowNotification` (client) with auto-detection of ox_lib, ESX, QBCore and GTA native fallbacks.
- **Vehicle module** — plate normalization and generation, vehicle spawning, vehicle properties, owner lookups and DB insertion for `owned_vehicles` / `player_vehicles`.
- **Callbacks module** — `Bridge.CreateCallback` / `Bridge.TriggerServerCallback` without manual exports. Namespaced names per resource to avoid collisions.
- **Licenses module** (server) — identity and license retrieval with auto-detection of `bcs_licensemanager`, `okokLicenses`, `esx_license` and QBCore metadata.
- **Progress module** (client) — progress bar with `ox_lib` when present, native animation fallback otherwise.
- **Config cascade** — consumer `Config` takes priority over `BridgeConfig`. Works for `AdminGroups`, `Stash`, `Debug`, etc.
- **Overrides folder** — drop `.lua` files under `overrides/client/` or `overrides/server/` to replace any `Bridge.*` function without editing the base resource.
- **Exports** — every Bridge function is also published as `exports['nb-bridge']:FuncName` for third-party scripts.

### Notes

- All `nb-*` resources now depend on this package, eliminating the duplicated `bridge/` folder in each one.

---

[1.2.1]: https://github.com/neenbyss/nb-bridge/releases/tag/v1.2.1
[1.2.0]: https://github.com/neenbyss/nb-bridge/releases/tag/v1.2.0
[1.1.0]: https://github.com/neenbyss/nb-bridge/releases/tag/v1.1.0
[1.0.0]: https://github.com/neenbyss/nb-bridge/releases/tag/v1.0.0
