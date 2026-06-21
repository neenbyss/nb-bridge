---
name: nb-bridge
author: "@KamerrEzz x NeenbyssStudio"
description: >-
  Complete reference for nb-bridge v2.0.0 — Neenbyss Studios' FiveM framework
  abstraction layer (ESX / QBCore / QBX). Load this skill when writing,
  modifying, or migrating any nb-* resource that touches framework APIs:
  players, money, jobs, gangs, inventory, items, stashes, notifications,
  server callbacks, vehicles, licenses, progress bars, lifecycle events
  (bridge.event.*), or runtime diagnostics (bridge.diagnostics()).
triggers:
  - nb-bridge
  - exports['nb-bridge']
  - bridge.player
  - bridge.inventory
  - bridge.vehicle
  - bridge.notify
  - bridge.callback
  - bridge.license
  - bridge.progress
  - bridge.event
  - bridge.diagnostics
  - /nbdiag
  - nb-* (FiveM resources using Neenbyss bridge)
---

# nb-bridge v2.0.0 — Complete Reference

## Overview

`nb-bridge` is a single FiveM resource (Lua 5.4) that provides one unified API
(`Bridge.*`) over **ESX Legacy**, **QBCore**, and **QBX**. Every `nb-*` resource
depends on it instead of shipping its own framework folder.

**v2.0.0 breaking change from v1.x:** The API is now namespaced (`Bridge.player.*`,
`Bridge.inventory.*`, etc.) and uses camelCase method names. The old flat PascalCase
API (`Bridge.GetJob`, `Bridge.AddMoney`) no longer exists.

The primary consumer pattern in v2.0.0 is the **export getter**:

```lua
-- In your fxmanifest.lua:
dependency 'nb-bridge'

-- At the top of each script:
local bridge = exports['nb-bridge']:get()

-- Then call methods through the returned table:
bridge.player.addMoney(source, 'bank', 500, 'salary')
bridge.notify.send(source, 'Payment received', 'success')
```

The `loader.lua` pattern (`shared_scripts { '@nb-bridge/loader.lua' }`) is
**deprecated in v2.0.0** and will be removed in a future major version.

---

## CONSUMER API — CRITICAL (read this first)

### Export getter (recommended, v2.0.0)

```lua
-- fxmanifest.lua
dependency 'nb-bridge'

-- server.lua / client.lua
local bridge = exports['nb-bridge']:get()
```

`exports['nb-bridge']:get()` returns the live `Bridge` table. Call it once at
the top of your script and reuse the local reference throughout the resource.

### server.cfg load order (mandatory)

```
ensure es_extended   -- or qb-core / qbx_core
ensure nb-bridge     -- AFTER the framework, BEFORE any nb-* resource
ensure nb-myresource
```

nb-bridge will error loudly if no compatible framework is detected at boot.

### Loader (deprecated, v1.x compat only)

```lua
-- fxmanifest.lua
dependencies { 'nb-bridge', 'oxmysql' }
shared_scripts { '@nb-bridge/loader.lua' }

-- Populates a global Bridge table — no local reference needed:
Bridge.player.addMoney(source, 'bank', 500)
```

The loader errors if: Lua 5.4 is not enabled, nb-bridge is not started first,
or the loader is included more than once in the same resource.

---

## Framework Detection & Priority

Detection runs synchronously at boot in `shared/init.lua`. Priority order:

1. **QBX** — checks `qbx_core` first. QBX also exposes a `qb-core` compat shim,
   so checking `qb-core` first would mis-detect QBX as QBCore. Always QBX first.
2. **ESX** — checks `es_extended`.
3. **QBCore** — checks `qb-core`.

After detection:
- `Bridge.Framework` → `'ESX'` | `'QBCore'` | `'QBX'`
- `Bridge.FrameworkObject` → raw framework shared object (ESX) / exports ref (QBX) / core object (QBCore)

**Never read `Bridge.Framework` before `shared/init.lua` runs.** For consumers
using the export getter, this is always safe — nb-bridge runs detection before
exposing the `get()` export.

---

## CONFIG (BridgeConfig keys)

Defined in `config.lua`. Consumer scripts can override per-key by setting their
own `Config` table — bridge checks `Config` (consumer) first, then falls back
to `BridgeConfig`.

| Key | Default | Description |
|-----|---------|-------------|
| `BridgeConfig.Debug` | `false` | Enable debug prints from bridge modules |
| `BridgeConfig.AdminGroups` | `{'admin','superadmin','god'}` | Groups considered admin for `bridge.player.isAdmin()` |
| `BridgeConfig.Stash.Slots` | `50` | Default stash slot count for `registerStash` |
| `BridgeConfig.Stash.MaxWeight` | `100000` | Default stash max weight |
| `BridgeConfig.InventoryImagePaths` | per-system NUI paths | Image URL template per inventory system (has `%s` placeholder for item name) |
| `BridgeConfig.GroupMap` | ACE node map | Maps group names to ACE nodes for QBCore/QBX permission checks |

**Config cascade example:**
```lua
-- In your consumer resource:
Config = {}
Config.AdminGroups = { 'admin', 'superadmin', 'god', 'headadmin' }
Config.Stash = { Slots = 100, MaxWeight = 200000 }
-- bridge.player.isAdmin() and bridge.inventory.registerStash() will use these values
```

**GroupMap (QBCore/QBX only):**
```lua
BridgeConfig.GroupMap = {
    god        = 'group.god',
    superadmin = 'group.superadmin',
    admin      = 'group.admin',
    mod        = 'group.mod',
}
```

---

## Debugger (global utility)

```lua
Debugger(module: string, ...: any)
```

Global function, NOT on Bridge. Prints only when `BridgeConfig.Debug == true`
or the consumer's `Config.Debug == true`. Tables are auto-encoded to JSON.

```lua
Debugger('MyModule', 'Player loaded:', source, playerData)
-- prints: [nb-myresource][SERVER][MyModule] Player loaded: 3 {"job":"police",...}
```

---

## bridge.player.* — Server Methods

All server-side player methods require `source` (player server ID) as first arg.

### getPlayer

```lua
bridge.player.getPlayer(source: number): table|nil
```

Returns the raw framework player object: `xPlayer` (ESX), `Player` (QBCore/QBX).
Use for direct framework access only. Prefer the normalized methods below.

### getIdentifier

```lua
bridge.player.getIdentifier(source: number): string|nil
```

Returns `license:XXXX` identifier (ESX) or `citizenid` (QBCore/QBX).

### getSSN

```lua
bridge.player.getSSN(source: number): string|nil
```

**ESX only.** Returns SSN string in format `XXX-XX-XXXX`. Returns `nil` on
QBCore/QBX — no equivalent exists.

### getPlayerName

```lua
bridge.player.getPlayerName(source: number): string
```

Returns full character name (`firstname lastname`). Falls back to `GetPlayerName(source)`
if player object is unavailable. ESX reads `xPlayer.getName()`. QBCore/QBX reads
`charinfo.firstname .. ' ' .. charinfo.lastname`.

### getGroup

```lua
bridge.player.getGroup(source: number): string
-- returns: 'god' | 'superadmin' | 'admin' | 'mod' | 'user'
```

ESX: reads `xPlayer.getGroup()` directly. QBCore/QBX: walks `BridgeConfig.GroupMap`
entries in priority order (god → superadmin → admin → mod) using `IsPlayerAceAllowed`.
Returns `'user'` if no matching ACE is found.

### setGroup

```lua
bridge.player.setGroup(source: number, group: string): boolean
```

**ESX only.** Sets group via `xPlayer.setGroup(group)`. Always returns `false`
on QBCore/QBX — ACE groups are managed outside framework.

### isAdmin

```lua
bridge.player.isAdmin(source: number): boolean
```

Checks `getGroup(source)` against `Config.AdminGroups` (consumer) or
`BridgeConfig.AdminGroups` (fallback). Works across all frameworks.

### getMoney

```lua
bridge.player.getMoney(source: number, moneyType: string): number
-- moneyType: 'cash' | 'bank'
-- returns: 0 on error or if player not found
```

ESX maps `'cash'` → `'money'` account internally. QBCore/QBX reads
`player.PlayerData.money[moneyType]`. Never returns nil — always a number.

### addMoney

```lua
bridge.player.addMoney(source: number, moneyType: string, amount: number, reason?: string): boolean
```

**GOTCHA — ESX:** `addAccountMoney()` has no return value. The bridge returns
`true` whenever `xPlayer` is non-nil. You cannot detect ESX add failures from the
outside. Pre-validate with `getMoney` if needed.

**Guards:** Returns `false` immediately if `amount <= 0` or `amount == nil`.

| Framework | Implementation |
|-----------|---------------|
| ESX | `xPlayer.addAccountMoney(account, amount, reason)` — always `true` when player exists |
| QBCore | `player.Functions.AddMoney(moneyType, amount, reason)` |
| QBX | `exports.qbx_core:AddMoney(source, moneyType, amount, reason)` |

### removeMoney

```lua
bridge.player.removeMoney(source: number, moneyType: string, amount: number, reason?: string): boolean
```

**ESX pre-check:** Bridge reads balance before removing and returns `false` when
`current < amount` (prevents silent overdraft — ESX `removeAccountMoney` has no
return value).

| Framework | Implementation |
|-----------|---------------|
| ESX | balance pre-check → `xPlayer.removeAccountMoney(account, amount, reason)` |
| QBCore | `player.Functions.RemoveMoney(moneyType, amount, reason)` |
| QBX | `exports.qbx_core:RemoveMoney(source, moneyType, amount, reason)` |

### setMoney

```lua
bridge.player.setMoney(source: number, moneyType: string, amount: number, reason?: string): boolean
```

Sets account to exact amount. Same ESX caveat as `addMoney` (no return from framework).

### getAccounts

```lua
bridge.player.getAccounts(source: number): table
-- returns: { cash = number, bank = number, ... }
```

ESX: normalizes account list — maps `money` → `cash`. QBCore/QBX: returns
`player.PlayerData.money` table directly. Returns `{}` on error.

### getJob

```lua
bridge.player.getJob(source: number): table|nil
```

Returns canonical job table or `nil` if player not found:

```lua
{
    name         = string,   -- job identifier, e.g. 'police'
    label        = string,   -- display name, e.g. 'Police'
    grade        = number,   -- grade level number
    grade_name   = string,   -- grade internal name
    grade_label  = string,   -- grade display name
    grade_salary = number,   -- salary for this grade
    onDuty       = boolean,  -- true if on duty
}
```

ESX: `grade` is raw number from `xPlayer.getJob().grade`. QBCore/QBX: reads
`job.grade.level`. `grade_salary` maps to `payment` field on QBCore/QBX.

### setJob

```lua
bridge.player.setJob(source: number, job: string, grade: number, onDuty?: boolean): boolean
```

`onDuty` is ESX-only (passed to `xPlayer.setJob`). Ignored on QBCore/QBX.

### getGang

```lua
bridge.player.getGang(source: number): table|nil
```

**QBCore/QBX only.** Returns `nil` on ESX — ESX has no gang system.

```lua
{
    name        = string,
    label       = string,
    grade       = number,
    grade_name  = string,
    grade_label = string,
}
```

### setGang

```lua
bridge.player.setGang(source: number, gangName: string, grade: number): boolean
```

**QBCore/QBX only.** Returns `false` on ESX. QBX uses `exports.qbx_core:SetGang`
with pcall + fallback to `player.Functions.SetGang` for older QBX builds.

### getAllPlayers

```lua
bridge.player.getAllPlayers(): number[]
```

Returns array of online player source IDs.

**GOTCHA — QBX:** Uses `exports.qbx_core:GetQBPlayers()` which returns a
`source → Player` hash table. The bridge iterates keys (`for src in pairs(...)`)
to build the source array. Do NOT call `GetPlayers()` directly on QBX — it
returns a different shape.

| Framework | Internal call |
|-----------|--------------|
| ESX | `Bridge.FrameworkObject.GetExtendedPlayers()` — returns xPlayer array, bridge extracts `.source` |
| QBX | `exports.qbx_core:GetQBPlayers()` — hash table, bridge extracts keys |
| QBCore | `Bridge.FrameworkObject.Functions.GetPlayers()` — returns source array directly |

### getPlayTime

```lua
bridge.player.getPlayTime(source: number): number|nil
```

**ESX only.** Returns playtime in seconds. Returns `nil` on QBCore/QBX.

### getCoords

```lua
bridge.player.getCoords(source: number): vector3|nil
```

ESX: `xPlayer.getCoords(true)`. QBCore/QBX: `GetEntityCoords(GetPlayerPed(source))`.

### setCoords

```lua
bridge.player.setCoords(source: number, coords: vector3|vector4|table): boolean
```

ESX: calls `xPlayer.setCoords(coords)`. QBCore/QBX: calls `SetEntityCoords` on
the player ped directly.

### triggerClientEvent

```lua
bridge.player.triggerClientEvent(source: number, eventName: string, ...: any)
```

ESX: prefers `xPlayer.triggerEvent` when available, falls back to
`TriggerClientEvent`. QBCore/QBX: always `TriggerClientEvent`.

### playerVar

```lua
bridge.player.playerVar(source: number, key: string, value?: any): any|nil
```

**ESX only.** Get/set xPlayer variables via `xPlayer.get(key)` / `xPlayer.set(key, value)`.
Returns `nil` on QBCore/QBX.

- Get: `playerVar(source, 'someKey')` → value or nil
- Set: `playerVar(source, 'someKey', 'myValue')` → `true`

### setMeta / getMeta / clearMeta

```lua
bridge.player.setMeta(source: number, index: string, value: any, subIndex?: string): boolean
bridge.player.getMeta(source: number, index?: string, subIndex?: string): any
bridge.player.clearMeta(source: number, index: string, subIndex?: string): boolean
```

Full metadata management across all frameworks. ESX requires `xPlayer.setMeta`
method to exist (available in modern ESX Legacy). QBCore: `player.Functions.SetMetaData`.
QBX: `exports.qbx_core:SetMetadata` / `GetMetadata` with dot notation for subIndex
(`'key.subkey'`).

`getMeta` with `index == nil` returns the full metadata table.

### executeCommand

```lua
bridge.player.executeCommand(source: number, command: string): boolean
```

**ESX only.** Executes a command on behalf of a player. Returns `false` on
QBCore/QBX.

### createBill

```lua
bridge.player.createBill(src: number, targetId: number, amount: number, description?: string, jobName?: string): boolean
```

Creates an invoice using the server's billing system. Detection order:
1. `esx_billing` (ESX) — fires `esx_billing:sendBill`. **Requires `jobName`** —
   returns `false` and logs warning if nil.
2. `qb-billing` (QBCore/QBX) — `exports['qb-billing']:CreateBill(...)`.
3. `okokBilling` (fallback) — pcall-wrapped.

Returns `false` when no billing system is found.

### registerCommand

```lua
bridge.player.registerCommand(
    name: string,
    group: string|nil,
    cb: fun(source: number, args: table, rawCommand: string|nil),
    suggestion?: { help: string, params: { { name: string, help: string } } }
)
```

Registers a chat command with optional permission gating.

| Framework | Implementation |
|-----------|---------------|
| ESX | `Bridge.FrameworkObject.RegisterCommand(name, group or 'user', ...)` |
| QBX | `lib.addCommand(...)` with `restricted = 'group.' .. group` (pcall-wrapped; falls back to RegisterCommand + ACE check) |
| QBCore | `RegisterCommand(...)` + `IsPlayerAceAllowed` guard |

### onPlayerLoaded (server)

```lua
bridge.player.onPlayerLoaded(cb: fun(source: number, identifier: string|nil))
```

Fires when a player's character data is loaded on the server.

| Framework | Event |
|-----------|-------|
| ESX | `esx:playerLoaded` |
| QBCore / QBX | `QBCore:Server:PlayerLoaded` |

### onPlayerUnloaded (server)

```lua
bridge.player.onPlayerUnloaded(cb: fun(source: number))
```

Fires when a player disconnects or logs out (server side).

**GOTCHA — QBX:** Registers TWO events (`QBCore:Server:OnPlayerUnload` +
`qbx_core:server:playerLoggedOut`). Both can fire for the same source on a clean
character-select logout. The bridge **debounces within a 1-second window** — `cb`
is called at most once per source per second. Do NOT debounce again in your code.

| Framework | Event |
|-----------|-------|
| ESX | `esx:playerDropped` |
| QBCore | `QBCore:Server:OnPlayerUnload` |
| QBX | `QBCore:Server:OnPlayerUnload` + `qbx_core:server:playerLoggedOut` (debounced) |

---

## bridge.player.* — Client Methods

Client methods do NOT take `source` — they operate on the local player.

### getPlayerData

```lua
bridge.player.getPlayerData(): table|nil
```

Returns raw framework player data (not normalized). ESX: `ESX.GetPlayerData()`.
QBCore: `QBCore.Functions.GetPlayerData()`. QBX: `exports.qbx_core:GetPlayerData()`.

### getJob (client)

```lua
bridge.player.getJob(): table|nil
```

Same normalized shape as server-side `getJob`. Reads from `getPlayerData()` and
normalizes per framework.

### getGang (client)

```lua
bridge.player.getGang(): table|nil
```

**QBCore/QBX only.** Returns `nil` on ESX.

### getMoney (client)

```lua
bridge.player.getMoney(moneyType: string): number
-- moneyType: 'cash' | 'bank'
```

Reads from local player data. ESX iterates `pd.accounts` (normalizing `money` → `cash`).
QBCore/QBX reads `pd.money[moneyType]`.

### getAccounts (client)

```lua
bridge.player.getAccounts(): table
-- returns: { cash = number, bank = number }
```

### getIdentifier (client)

```lua
bridge.player.getIdentifier(): string|nil
```

ESX: `pd.identifier`. QBCore/QBX: `pd.citizenid`.

### getPlayerName (client)

```lua
bridge.player.getPlayerName(): string
```

### getGroup (client)

```lua
bridge.player.getGroup(): string
```

ESX: `pd.group`. QBCore/QBX: always returns `'user'` (group checks are server-only
on ACE-based systems). **Do not use client-side group for security gates.**

### onPlayerLoaded (client)

```lua
bridge.player.onPlayerLoaded(cb: fun())
```

Callback receives no arguments. Use `bridge.player.getJob()` etc. inside it.

| Framework | Event |
|-----------|-------|
| ESX | `esx:playerLoaded` |
| QBCore / QBX | `QBCore:Client:OnPlayerLoaded` |

### onPlayerUnloaded (client)

```lua
bridge.player.onPlayerUnloaded(cb: fun())
```

| Framework | Event |
|-----------|-------|
| ESX | `esx:onPlayerLogout` |
| QBCore / QBX | `QBCore:Client:OnPlayerUnload` |

### onJobUpdate (client)

```lua
bridge.player.onJobUpdate(cb: fun(job: table))
```

`job` is the same normalized table as `getJob()`.

| Framework | Event |
|-----------|-------|
| ESX | `esx:setJob` |
| QBCore / QBX | `QBCore:Client:OnJobUpdate` |

### onGangUpdate (client)

```lua
bridge.player.onGangUpdate(cb: fun(gang: table))
```

**QBCore/QBX only.** No-op on ESX.

| Framework | Event |
|-----------|-------|
| QBCore / QBX | `QBCore:Client:OnGangUpdate` |

---

## bridge.inventory.* — Server Methods

### Inventory System Detection

Auto-detection runs in a background thread ~500ms after boot. Detection order:

1. `ox_inventory`
2. `qb-inventory`
3. `qs-inventory`
4. `origen_inventory`
5. `default` (framework native)

**GOTCHA:** `Bridge.InventorySystem` is set ~500ms after boot. Do NOT read it
at file-load time (e.g., in global scope). Read it inside event handlers or
CreateThread with a Wait.

**Synchronous fallback:** All public methods call `ResolveInventorySystem()` at
the top, which resolves via `GetResourceState` synchronously if the async
detection hasn't fired yet. This makes all methods safe to call at resource start.

**GOTCHA — QBX:** QBX **always** requires ox_inventory. `Bridge.InventorySystem`
will always be `'ox_inventory'` on a QBX server. No separate QBX branch exists
in inventory code — the ox_inventory path handles it.

### addItem

```lua
bridge.inventory.addItem(source: number, item: string, count: number, metadata?: table|string, slot?: number): boolean
```

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:AddItem(source, item, count, metadata, slot)` |
| qs-inventory | `exports['qs-inventory']:AddItem(source, item, count, slot, metadata)` — note args swap |
| origen_inventory | `exports.origen_inventory:addItem(source, item, count, metadata, slot, false)` |
| qb-inventory | `player.Functions.AddItem(item, count, slot, metadata)` |
| default (ESX) | `xPlayer.addInventoryItem(item, count)` — no slot/metadata support |
| default (QBCore) | `player.Functions.AddItem(item, count, slot, metadata)` |

**GOTCHA — qs-inventory:** Argument order is `(source, item, count, slot, metadata)` —
slot comes before metadata. ox_inventory is `(source, item, count, metadata, slot)`.

### removeItem

```lua
bridge.inventory.removeItem(source: number, item: string, count: number, metadata?: table|string, slot?: number): boolean
```

**GOTCHA — qs-inventory:** `RemoveItem` has no return value — bridge returns `true`
unconditionally after calling it. Validate with `hasItem` before removing.

| System | Return |
|--------|--------|
| ox_inventory | returns `false` on failure |
| qs-inventory | always `true` (no return from export) |
| origen_inventory | `ok == true` |
| qb-inventory | from `player.Functions.RemoveItem` |

### hasItem

```lua
bridge.inventory.hasItem(source: number, item: string, count?: number): boolean
-- count defaults to 1
```

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:GetItemCount(source, item) >= count` |
| qs-inventory | `exports['qs-inventory']:GetItemTotalAmount(source, item) >= count` |
| origen_inventory | `exports.origen_inventory:getItemCount(source, item, false, false) >= count` |
| qb-inventory | `player.Functions.GetItemByName(item).amount >= count` |
| default (ESX) | `xPlayer.getInventoryItem(item).count >= count` |

### canCarry

```lua
bridge.inventory.canCarry(source: number, item: string, count?: number, metadata?: table|string): boolean
-- returns true when qb-inventory/default — no weight check available
```

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:CanCarryItem(source, item, count, metadata)` |
| qs-inventory | `exports['qs-inventory']:CanCarryItem(source, item, count)` |
| origen_inventory | `exports.origen_inventory:canCarryItem(source, item, count, metadata)` |
| qb-inventory / default | always `true` |

### registerStash

```lua
bridge.inventory.registerStash(stashId: string, label: string, jobName?: string, coords?: vector3)
```

Registers a stash with the active inventory system. Uses
`Config.Stash` (consumer) or `BridgeConfig.Stash` for `Slots` and `MaxWeight`.

Idempotent — calling twice for the same `stashId` is a no-op.

`jobName` maps to an ACE group restriction on ox_inventory: `groups = { [jobName] = 0 }`.

**Not needed for qb-inventory / default** — those systems don't require server-side
stash registration.

### isStashRegistered

```lua
bridge.inventory.isStashRegistered(stashId: string): boolean
```

Checks in-memory registration table (not the inventory system itself).

### forceOpenStash

```lua
bridge.inventory.forceOpenStash(source: number, stashId: string)
```

Forces a stash open for a player from server side.

**GOTCHA — origen_inventory:** origen opens stashes client-side. The bridge fires
`nb-bridge:client:origenOpenInventory` to route the request. This net event is
registered automatically by `modules/inventory/client.lua`.

### forceOpenPlayerInventory

```lua
bridge.inventory.forceOpenPlayerInventory(source: number, targetServerId: number): boolean
```

Opens another player's inventory for `source`.

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:forceOpenInventory(source, 'player', targetServerId)` |
| qb-inventory | `TriggerClientEvent('inventory:client:OpenInventory', source, {}, 'otherplayer', targetServerId)` |
| qs-inventory | Export if available, else `TriggerClientEvent('qsinv:openOtherInventory', ...)` |
| origen_inventory | `nb-bridge:client:origenOpenInventory` event |

### getAllItems

```lua
bridge.inventory.getAllItems(): table
```

Returns the full item registry from the inventory system.

| System | Source |
|--------|--------|
| ox_inventory | `exports.ox_inventory:Items()` |
| qs-inventory | `exports['qs-inventory']:GetItemList()` |
| origen_inventory | `exports.origen_inventory:Items()` |
| QBCore (default) | `Bridge.FrameworkObject.Shared.Items` |

### registerUsableItem

```lua
bridge.inventory.registerUsableItem(itemName: string, cb: fun(source: number, item: table)): boolean
-- item = { name = string, slot = number? }
```

Idempotent — registering the same item twice is silently ignored (returns `true`).

**GOTCHA — origen_inventory:** The bridge registers ONLY through
`exports.origen_inventory:CreateUseableItem` and does NOT also register through
ESX/QBCore. Doing both would cause the callback to fire twice. Do NOT add a
secondary registration in your code.

| System | Implementation |
|--------|---------------|
| origen_inventory | `exports.origen_inventory:CreateUseableItem(itemName, cb)` — framework skipped |
| ESX | `Bridge.FrameworkObject.RegisterUsableItem(itemName, cb)` |
| QBX | `exports.qbx_core:CreateUseableItem(itemName, cb)` (pcall-wrapped) |
| QBCore | `Bridge.FrameworkObject.Functions.CreateUseableItem(itemName, cb)` |

### isUsableItemRegistered

```lua
bridge.inventory.isUsableItemRegistered(itemName: string): boolean
```

Checks the bridge's in-memory registration table. Returns `true` if
`registerUsableItem` was called for this item in this resource session.

### getItemMetadata

```lua
bridge.inventory.getItemMetadata(source: number, itemName: string): table|nil
```

**ox_inventory only.** Returns the metadata table of the first matching item slot.
Returns `nil` on ALL other inventory systems — they do not expose per-slot metadata
through the bridge.

Internally calls `exports.ox_inventory:GetItem(source, itemName, nil, false)` and
returns `.metadata`.

---

## bridge.inventory.* — Client Methods

### openStash

```lua
bridge.inventory.openStash(stashId: string)
```

Opens a stash for the local player.

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:openInventory('stash', stashId)` |
| qb-inventory / qs-inventory | `TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId)` + `TriggerEvent('inventory:client:SetCurrentStash', stashId)` |
| origen_inventory | `exports.origen_inventory:openInventory('stash', stashId)` |

### openPlayerInventory

```lua
bridge.inventory.openPlayerInventory(targetServerId: number)
```

Opens another player's inventory from the client side.

### getItemCount

```lua
bridge.inventory.getItemCount(item: string): number
```

Returns count of `item` in the local player's inventory.

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:GetItemCount(item)` |
| qs-inventory | `exports['qs-inventory']:Search(item)` |
| origen_inventory | `exports.origen_inventory:Search('count', item)` — handles both number and table return |
| QBCore/QBX default | iterates `pd.items` for matching name |
| ESX default | iterates `pd.inventory` for matching name |

### getImagePath

```lua
bridge.inventory.getImagePath(): string
-- returns: format string like 'nui://ox_inventory/web/images/%s.png'
```

Returns the NUI image URL template for the active inventory system. Use `string.format`
with the item name:

```lua
local path = bridge.inventory.getImagePath()
local imgUrl = path:format('water')
-- → 'nui://ox_inventory/web/images/water.png'
```

**GOTCHA — origen_inventory:** The default path targets v2 (`ui/images/`). If the
server runs origen v1 (`html/images/`), override in consumer config:
```lua
Config.InventoryImagePaths = { origen_inventory = 'nui://origen_inventory/html/images/%s.png' }
```

---

## bridge.vehicle.* — Server Methods

### generatePlate

```lua
bridge.vehicle.generatePlate(): string
-- returns: random 8-char uppercase alphanumeric string
```

### normalizePlate

```lua
bridge.vehicle.normalizePlate(plate: string|nil): string
-- strips trailing spaces from GTA plate strings
```

### giveVehicle

```lua
bridge.vehicle.giveVehicle(source: number, model: string, props?: table): boolean
```

Inserts a vehicle into the framework's vehicle ownership database.

| Framework | Table | Key column |
|-----------|-------|-----------|
| ESX | `owned_vehicles` | `owner` (license identifier) |
| QBCore / QBX | `player_vehicles` | `citizenid` |

`props` is stored as JSON in the vehicle column. `plate` is auto-generated via
`generatePlate()` if not in props. Requires `oxmysql`.

**GOTCHA:** `giveVehicle` uses `MySQL.insert.await` — only call from a server
context and only where async is acceptable.

### getVehicleOwnerName

```lua
bridge.vehicle.getVehicleOwnerName(plate: string): string|nil
```

Queries the DB for the owner of a plate and returns their full name, or `nil`
if not found.

| Framework | Query path |
|-----------|-----------|
| ESX | `owned_vehicles.owner` → `users.firstname + lastname` |
| QBCore / QBX | `player_vehicles.citizenid` → `players.charinfo` (JSON decoded) |

---

## bridge.vehicle.* — Client Methods

### resolveModelHash

```lua
bridge.vehicle.resolveModelHash(model: string|number): number
```

Converts model name string to hash. If `model` is already a number or numeric
string, returns it as-is.

### spawnVehicle

```lua
bridge.vehicle.spawnVehicle(
    model: string|number,
    coords: vector3,
    heading: number,
    props?: table,
    plate?: string,
    cb?: fun(vehicle: number|nil)
): number|false
```

Loads model, creates vehicle, applies props, sets plate. Uses `GetGameTimer()`
for a 5-second wall-clock timeout (not frame-based). Calls `cb(nil)` on timeout.

Returns the vehicle entity handle or `false` on failure.

### getVehicleProperties

```lua
bridge.vehicle.getVehicleProperties(vehicle: number): table
```

Priority: `lib.getVehicleProperties` (ox_lib) → framework fallback.

| Framework | Fallback |
|-----------|---------|
| QBX | `exports['qb-core']:GetCoreObject().Functions.GetVehicleProperties` (compat shim) |
| ESX | `Bridge.FrameworkObject.Game.GetVehicleProperties` |
| QBCore | `Bridge.FrameworkObject.Functions.GetVehicleProperties` |

### setVehicleProperties

```lua
bridge.vehicle.setVehicleProperties(vehicle: number, props: table)
```

Priority: `lib.setVehicleProperties` (ox_lib) → framework fallback. Same fallback
chain as `getVehicleProperties`.

### getVehicleLabel

```lua
bridge.vehicle.getVehicleLabel(model: string|number): string
-- returns: human-readable name, 'Unknown' if not found
```

Uses `GetDisplayNameFromVehicleModel` + `GetLabelText`. Returns `'Unknown'` if
`CARNOTFOUND` or `'NULL'`.

---

## bridge.notify.*

### send (server)

```lua
bridge.notify.send(source: number, message: string, type: string)
-- type: 'success' | 'error' | 'info' | 'warning'
```

Fires a client event to show the notification on that player's screen.
Always use `send` from server-side code.

### show (client)

```lua
bridge.notify.show(message: string, type: string)
-- type: 'success' | 'error' | 'info' | 'warning'
```

Shows a notification on the local client. Detection order:

1. `ox_lib` — `exports.ox_lib:notify({ title, description, type, duration = 5000 })`
2. QBX (unreachable in standard setup — QBX always has ox_lib) — `exports.qbx_core:Notify`
3. ESX — `Bridge.FrameworkObject.ShowNotification(message)` (ignores type)
4. QBCore — `Bridge.FrameworkObject.Functions.Notify(message, type, 5000)`
5. GTA native — `DrawNotification` (ignores type)

**Note:** ESX's native notification does not support type/color. Use ox_lib for
consistent styled notifications across frameworks.

---

## bridge.callback.*

Simple request-response system for server callbacks. Built into nb-bridge — no
external dependency.

### register (server)

```lua
bridge.callback.register(name: string, cb: fun(source: number, respond: fun(...), ...: any))
```

Registers a server callback handler. `respond(...)` sends the result back to the
client. Always call `respond` — if you don't, the client will timeout after 15s
and receive `nil`.

```lua
bridge.callback.register('nb-garage:getVehicles', function(source, respond, filter)
    local vehicles = MyDB.getVehicles(source, filter)
    respond(vehicles)
end)
```

### trigger (client)

```lua
bridge.callback.trigger(name: string, cb: fun(...: any), ...: any)
```

Sends a request to the server callback. **GOTCHA:** If the server does not respond
within **15 seconds**, the timeout fires `cb(nil)`. Always nil-guard callback args:

```lua
bridge.callback.trigger('nb-garage:getVehicles', function(vehicles)
    if not vehicles then
        bridge.notify.show('Error loading vehicles', 'error')
        return
    end
    -- use vehicles
end, 'police')
```

**Implementation detail:** Uses resource-namespaced net events (`resourceName:bridge:triggerCallback`
and `resourceName:bridge:receiveCallback`) keyed by an auto-incrementing `requestId`.
This means callback names are scoped to the consumer resource — two resources can
use the same callback name without collision.

**GOTCHA:** Always namespace your callback names with your resource name to avoid
confusion and future conflicts: `'nb-mything:doSomething'`, not `'doSomething'`.

---

## bridge.license.* — Server Methods

License system detection runs ~500ms after boot. Detection order:

1. `bcs_licensemanager`
2. `okokLicenses`
3. `esx_license`
4. `qbcore` (QBX or QBCore without external system → uses `PlayerData.metadata.licences`)
5. `esx_default` (ESX without external system → uses `xPlayer.getLicenses()`)
6. `none`

**GOTCHA — QBX:** QBX uses the same `PlayerData.metadata.licences` path as
QBCore. The bridge detects both as `licenseSystem = 'qbcore'` — no separate
QBX branch needed.

### getIdentity

```lua
bridge.license.getIdentity(source: number): table|nil
-- returns: { firstname: string, lastname: string, dob: string|nil, sex: string|nil }
```

ESX: parses name from `xPlayer.getName()` — `dob` and `sex` are always `nil`
(ESX doesn't store them in the player object by default).

QBCore/QBX: reads `player.PlayerData.charinfo` — `sex` is `'M'` or `'F'`
(`charinfo.gender == 0` → `'M'`).

### getDriverLicense

```lua
bridge.license.getDriverLicense(source: number): table
-- returns: { hasLicense: boolean, label: string }
```

| System | Detection |
|--------|-----------|
| bcs_licensemanager | Checks `driver_car`, `driver_bike`, `driver_truck`, `driver_helicopter`, `driver_boat`, `driver_plane` — returns first found |
| okokLicenses | `exports.okokLicenses:getLicense(source, 'driver')` |
| esx_license / esx_default | iterates `xPlayer.getLicenses()` for type `'drive'`, `'driver'`, or `'dmv'` |
| qbcore (QBX + QBCore) | `player.PlayerData.metadata.licences.driver == true` |

### getWeaponLicense

```lua
bridge.license.getWeaponLicense(source: number): table
-- returns: { hasLicense: boolean, label: string }
```

Same structure as `getDriverLicense`. BCS checks `'weapon'` type.
ESX checks type `'weapon'` or `'firearms'`.

---

## bridge.progress.* — Client Methods

### show

```lua
bridge.progress.show(duration: number, label: string, anim?: table): boolean
-- anim: { dict = string, name = string }
-- returns: true if completed, false if cancelled (ox_lib only)
```

**Blocking call** — yields until done or cancelled.

| System | Behaviour |
|--------|-----------|
| ox_lib | `exports.ox_lib:progressBar(...)` — `canCancel = true`, disables move and car. Returns `false` when cancelled. |
| native fallback | Plays animation, waits with `GetGameTimer()`, then clears tasks. **Non-cancellable** — always returns `true`. |

**GOTCHA:** The native fallback is never cancellable. If your logic branches on
the return value (`if bridge.progress.show(...) then`), it will always enter the
`then` branch when ox_lib is absent. Design accordingly.

```lua
-- Safe pattern: works with and without ox_lib
local completed = bridge.progress.show(3000, 'Repairing...', {
    dict = 'mini@repair',
    name = 'fixing_a_player'
})
if completed then
    bridge.notify.show('Repair complete', 'success')
else
    bridge.notify.show('Cancelled', 'error')
end
```

---

## bridge.event.* — Lifecycle Hooks

Convenience namespace for resource and player lifecycle events. Methods are
available on both server and client, but the set of methods differs by side.

### Server-side methods (server only)

| Method | Signature | Description |
|--------|-----------|-------------|
| `onPlayerLoaded` | `fun(cb: fun(source: number))` | Fires when any player finishes loading. Delegates to `bridge.player.onPlayerLoaded`. |
| `onPlayerUnloaded` | `fun(cb: fun(source: number))` | Fires when any player unloads/disconnects. Delegates to `bridge.player.onPlayerUnloaded` (QBX: debounced 1s). |
| `onResourceStart` | `fun(cb: fun(resourceName: string))` | Fires when ANY resource starts. |
| `onResourceStop` | `fun(cb: fun(resourceName: string))` | Fires when ANY resource stops. |
| `onSelfStart` | `fun(cb: fun())` | Fires when the consumer resource itself starts. Captures `GetCurrentResourceName()` at call time. |
| `onSelfStop` | `fun(cb: fun())` | Fires when the consumer resource itself stops. |

### Client-side methods (client only)

| Method | Signature | Description |
|--------|-----------|-------------|
| `onPlayerLoaded` | `fun(cb: fun())` | Fires when local player finishes loading character. |
| `onPlayerUnloaded` | `fun(cb: fun())` | Fires when local player unloads character. |
| `onPlayerSpawned` | `fun(cb: fun())` | Fires when player spawns in world. ESX: `playerSpawned`. QBCore/QBX: `QBCore:Client:OnPlayerLoaded`. |
| `onResourceStart` | `fun(cb: fun(resourceName: string))` | Client-side: `onClientResourceStart`. |
| `onResourceStop` | `fun(cb: fun(resourceName: string))` | Client-side: `onClientResourceStop`. |

```lua
-- server
bridge.event.onPlayerLoaded(function(source)
    print('Player loaded:', source)
end)

bridge.event.onSelfStop(function()
    -- cleanup when this resource stops
end)

-- client
bridge.event.onPlayerSpawned(function()
    -- safe to access player data here
end)
```

**Note:** `bridge.event.onPlayerLoaded` and `bridge.event.onPlayerUnloaded` are
convenience wrappers around `bridge.player.onPlayerLoaded` /
`bridge.player.onPlayerUnloaded` — they are equivalent. The `bridge.event.*`
namespace is preferred for lifecycle code as it makes intent clearer.

---

## bridge.diagnostics()

Server-only. Returns a snapshot of the bridge's runtime state.

```lua
---@return BridgeDiagnosticsResult
```

| Field | Type | Description |
|-------|------|-------------|
| `version` | `string` | nb-bridge version (e.g. `'2.0.0'`) |
| `framework` | `'ESX'\|'QBCore'\|'QBX'\|nil` | Detected framework |
| `inventorySystem` | `string\|nil` | Detected inventory system |
| `side` | `'server'` | Always `'server'` — diagnostics is server-only |
| `uptime` | `number` | `GetGameTimer()` in milliseconds |
| `features` | `table<string, boolean>` | Presence of: `ox_lib`, `ox_inventory`, `oxmysql`, `qs_inventory`, `origen`, `qb_inventory` |
| `missing` | `string[]` | List of missing required dependencies |

### `/nbdiag` command

Admin or console only. Prints the full diagnostics table to the server console
and sends it to admin chat. No arguments.

### `exports['nb-bridge']:diagnostics()`

Callable directly from other resources — returns the same table without needing
a `bridge` reference.

```lua
-- from any resource
local diag = exports['nb-bridge']:diagnostics()
print(diag.framework, diag.inventorySystem)

-- or via bridge
local bridge = exports['nb-bridge']:get()
local diag = bridge.diagnostics()
```

---

## Inventory System Detection

Summary table for quick reference:

| `Bridge.InventorySystem` | Resource | Notes |
|--------------------------|----------|-------|
| `'ox_inventory'` | ox_inventory | Default on QBX — always present |
| `'qb-inventory'` | qb-inventory | QBCore default without ox |
| `'qs-inventory'` | qs-inventory | Has arg-order differences (see addItem) |
| `'origen_inventory'` | origen_inventory | Opens inventory client-side; skips framework for usable items |
| `'default'` | none | Falls back to framework native inventory methods |

---

## Common Patterns

### Server: gate an action on money, then reward

```lua
RegisterNetEvent('nb-mything:buyItem', function(itemName, price)
    local src = source
    if bridge.player.getMoney(src, 'bank') < price then
        bridge.notify.send(src, 'Not enough money', 'error')
        return
    end
    if not bridge.inventory.canCarry(src, itemName, 1) then
        bridge.notify.send(src, 'Inventory full', 'error')
        return
    end
    bridge.player.removeMoney(src, 'bank', price, 'shop-purchase')
    bridge.inventory.addItem(src, itemName, 1)
    bridge.notify.send(src, 'Purchase complete', 'success')
end)
```

### Server: job guard + admin gate

```lua
RegisterNetEvent('nb-mything:action', function()
    local src = source
    local job = bridge.player.getJob(src)
    if not job or job.name ~= 'police' then return end
    if not bridge.player.isAdmin(src) then return end
    -- proceed
end)
```

### Server: register a usable item

```lua
-- Called once at resource start (idempotent — safe to call multiple times)
bridge.inventory.registerUsableItem('bandage', function(src, item)
    -- item = { name = 'bandage', slot = number? }
    if not bridge.inventory.hasItem(src, 'bandage', 1) then return end
    bridge.inventory.removeItem(src, 'bandage', 1)
    TriggerClientEvent('nb-mything:useBandage', src)
    bridge.notify.send(src, 'Used a bandage', 'success')
end)
```

### Callback round-trip

```lua
-- server.lua
bridge.callback.register('nb-garage:getVehicles', function(source, respond, citizenid)
    local vehicles = exports.oxmysql:executeSync(
        'SELECT * FROM player_vehicles WHERE citizenid = ?', { citizenid }
    )
    respond(vehicles or {})
end)

-- client.lua
bridge.callback.trigger('nb-garage:getVehicles', function(vehicles)
    if not vehicles then return end  -- always nil-guard: 15s timeout fires cb(nil)
    for _, v in ipairs(vehicles) do
        print(v.plate)
    end
end, bridge.player.getIdentifier())
```

### Client: spawn vehicle with properties

```lua
local plate = 'TEST1234'
bridge.vehicle.spawnVehicle('adder', coords, heading, props, plate, function(veh)
    if not veh then
        bridge.notify.show('Failed to spawn vehicle', 'error')
        return
    end
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
end)
```

### Client: stash with progress bar

```lua
CreateThread(function()
    -- Wait for interaction trigger...
    local completed = bridge.progress.show(3000, 'Opening stash...', {
        dict = 'anim@heists@ornate_bank@hack',
        name = 'loop'
    })
    if completed then
        bridge.inventory.openStash('nb-myresource:mainStash')
    end
end)
```

### Client: react to job change

```lua
bridge.player.onJobUpdate(function(job)
    if job.name == 'police' then
        -- show police HUD
    else
        -- hide police HUD
    end
end)
```

---

## Anti-Patterns (Never Do This)

```lua
-- WRONG: reading Bridge.InventorySystem at file-load time (before 500ms detection)
local mySystem = Bridge.InventorySystem   -- may be nil

-- CORRECT: read inside an event/thread
CreateThread(function()
    Wait(600)   -- after bridge detection fires
    local mySystem = Bridge.InventorySystem
end)
-- OR: just call bridge methods — they call ResolveInventorySystem() internally
```

```lua
-- WRONG: double-registering usable items on origen_inventory
bridge.inventory.registerUsableItem('bandage', handler)  -- bridge already registers on origen
exports.origen_inventory:CreateUseableItem('bandage', handler)  -- DOUBLE FIRE

-- CORRECT: call registerUsableItem once, bridge handles the rest
bridge.inventory.registerUsableItem('bandage', handler)
```

```lua
-- WRONG: not nil-guarding callback results (timeout fires cb(nil))
bridge.callback.trigger('nb-x:getData', function(data)
    for _, v in ipairs(data) do  -- ERROR if data is nil
    end
end)

-- CORRECT:
bridge.callback.trigger('nb-x:getData', function(data)
    if not data then return end
    for _, v in ipairs(data) do end
end)
```

```lua
-- WRONG: using flat PascalCase API from v1.x
Bridge.GetJob(source)      -- does not exist in v2.0.0
Bridge.AddMoney(...)       -- does not exist in v2.0.0
Bridge.Notify(...)         -- does not exist in v2.0.0

-- CORRECT: namespaced camelCase API
local bridge = exports['nb-bridge']:get()
bridge.player.getJob(source)
bridge.player.addMoney(source, 'bank', 500)
bridge.notify.send(source, 'message', 'success')
```

```lua
-- WRONG: checking qb-core before qbx_core for framework detection
if GetResourceState('qb-core') == 'started' then ...  -- mis-detects QBX as QBCore

-- CORRECT: QBX must be checked first (already done by nb-bridge internally)
-- Don't re-detect framework — read Bridge.Framework
```

```lua
-- WRONG: using getAllPlayers on QBX expecting a source array from GetQBPlayers
local players = exports.qbx_core:GetQBPlayers()
for _, src in ipairs(players) do  -- WRONG: GetQBPlayers returns hash, not array

-- CORRECT: use the bridge method
local sources = bridge.player.getAllPlayers()   -- always returns number[]
for _, src in ipairs(sources) do
```

---

## Known Limitations & Gotchas

1. **QBX detection order:** `qbx_core` must be checked BEFORE `qb-core`. QBX ships
   a `qb-core` compatibility shim — checking `qb-core` first would misidentify QBX
   as QBCore. nb-bridge handles this correctly internally.

2. **ESX `addMoney` always returns `true`:** `addAccountMoney()` has no return value.
   Bridge returns `true` whenever `xPlayer` is non-nil. Cannot detect ESX add failures.

3. **ESX `removeMoney` pre-checks balance:** Bridge reads the account balance before
   calling `removeAccountMoney` and returns `false` if insufficient. This prevents
   silent overdraft since `removeAccountMoney` has no return value.

4. **`registerUsableItem` on `origen_inventory`:** Bridge registers ONLY through
   origen's export and skips the framework layer. Registering through the framework
   too would cause the callback to fire twice.

5. **`onPlayerUnloaded` on QBX is debounced 1s:** Both `QBCore:Server:OnPlayerUnload`
   and `qbx_core:server:playerLoggedOut` can fire for the same source on a clean
   character-select logout. Bridge debounces within a 1-second window.

6. **`getItemMetadata` is ox_inventory only:** Returns `nil` on all other systems.
   Do not call it and expect data on qb-inventory, qs-inventory, or origen.

7. **`ResolveInventorySystem()` is synchronous:** Safe to call at resource start.
   The 500ms async detection is an optimization; the sync fallback uses
   `GetResourceState` directly.

8. **`callback.trigger` 15s timeout:** If the server callback does not call
   `respond(...)` within 15 seconds, the bridge fires `cb(nil)` and cleans up the
   pending entry. Always nil-guard callback args on the client.

9. **QBX always uses ox_inventory:** No separate QBX branch in inventory code.
   `Bridge.InventorySystem` will always be `'ox_inventory'` on any QBX server.

10. **`getAllPlayers` on QBX:** Uses `GetQBPlayers()` (returns `source → Player` hash)
    not `GetPlayers()`. Bridge extracts keys to return a source number array.

11. **qs-inventory `addItem` arg order:** `(source, item, count, slot, metadata)` —
    slot before metadata. ox_inventory is `(source, item, count, metadata, slot)`.

12. **`qs-inventory` `removeItem` no return:** Bridge returns `true` unconditionally.
    Pre-validate with `hasItem` before calling `removeItem` on qs-inventory.

13. **`createBill` ESX requires `jobName`:** Refuses to bill `society_unknown` and
    returns `false` if `jobName` is nil. This is an explicit guard to prevent
    silent framework errors.

14. **origen_inventory v1 vs v2 image paths:** Default NUI path targets v2
    (`ui/images/`). Override `Config.InventoryImagePaths.origen_inventory` for v1
    servers (`html/images/`). No runtime way to auto-detect the origen branch.

15. **`progress.show` native fallback is non-cancellable:** Always returns `true`.
    If your code branches on the return value, the `else` branch is unreachable
    without ox_lib.

16. **Loader (`loader.lua`) is deprecated in v2.0.0:** Use `exports['nb-bridge']:get()`
    instead. Loader will be removed in a future major version.

---

## Migration from v1.x

The v2.0.0 API uses namespaced camelCase. The full replacement table:

| v1.x (removed) | v2.0.0 |
|----------------|--------|
| `Bridge.GetPlayer(src)` | `bridge.player.getPlayer(src)` |
| `Bridge.GetIdentifier(src)` | `bridge.player.getIdentifier(src)` |
| `Bridge.GetPlayerName(src)` | `bridge.player.getPlayerName(src)` |
| `Bridge.GetGroup(src)` | `bridge.player.getGroup(src)` |
| `Bridge.SetGroup(src, g)` | `bridge.player.setGroup(src, g)` |
| `Bridge.IsAdmin(src)` | `bridge.player.isAdmin(src)` |
| `Bridge.GetMoney(src, t)` | `bridge.player.getMoney(src, t)` |
| `Bridge.AddMoney(src, t, a, r)` | `bridge.player.addMoney(src, t, a, r)` |
| `Bridge.RemoveMoney(src, t, a, r)` | `bridge.player.removeMoney(src, t, a, r)` |
| `Bridge.SetMoney(src, t, a, r)` | `bridge.player.setMoney(src, t, a, r)` |
| `Bridge.GetAccounts(src)` | `bridge.player.getAccounts(src)` |
| `Bridge.GetJob(src)` | `bridge.player.getJob(src)` |
| `Bridge.SetJob(src, j, g)` | `bridge.player.setJob(src, j, g)` |
| `Bridge.GetGang(src)` | `bridge.player.getGang(src)` |
| `Bridge.GetAllPlayers()` | `bridge.player.getAllPlayers()` |
| `Bridge.GetPlayTime(src)` | `bridge.player.getPlayTime(src)` |
| `Bridge.GetCoords(src)` | `bridge.player.getCoords(src)` |
| `Bridge.SetCoords(src, c)` | `bridge.player.setCoords(src, c)` |
| `Bridge.TriggerClientEvent(src, e, ...)` | `bridge.player.triggerClientEvent(src, e, ...)` |
| `Bridge.SetMeta(src, i, v, s)` | `bridge.player.setMeta(src, i, v, s)` |
| `Bridge.GetMeta(src, i, s)` | `bridge.player.getMeta(src, i, s)` |
| `Bridge.ClearMeta(src, i, s)` | `bridge.player.clearMeta(src, i, s)` |
| `Bridge.AddItem(src, i, c)` | `bridge.inventory.addItem(src, i, c)` |
| `Bridge.RemoveItem(src, i, c)` | `bridge.inventory.removeItem(src, i, c)` |
| `Bridge.HasItem(src, i, c)` | `bridge.inventory.hasItem(src, i, c)` |
| `Bridge.CanCarry(src, i, c)` | `bridge.inventory.canCarry(src, i, c)` |
| `Bridge.RegisterStash(id, l, j)` | `bridge.inventory.registerStash(id, l, j)` |
| `Bridge.OpenStash(id)` *(client)* | `bridge.inventory.openStash(id)` |
| `Bridge.RegisterUsableItem(n, cb)` | `bridge.inventory.registerUsableItem(n, cb)` |
| `Bridge.GetItemCount(i)` *(client)* | `bridge.inventory.getItemCount(i)` |
| `Bridge.Notify(src, msg, t)` | `bridge.notify.send(src, msg, t)` *(server)* |
| `Bridge.ShowNotification(msg, t)` | `bridge.notify.show(msg, t)` *(client)* |
| `Bridge.CreateCallback(n, cb)` | `bridge.callback.register(n, cb)` |
| `Bridge.TriggerServerCallback(n, cb, ...)` | `bridge.callback.trigger(n, cb, ...)` |
| `Bridge.GetDriverLicense(src)` | `bridge.license.getDriverLicense(src)` |
| `Bridge.GetWeaponLicense(src)` | `bridge.license.getWeaponLicense(src)` |
| `Bridge.GetIdentity(src)` | `bridge.license.getIdentity(src)` |
| `Bridge.Progress(dur, lbl, anim)` | `bridge.progress.show(dur, lbl, anim)` |
| `Bridge.SpawnVehicle(...)` | `bridge.vehicle.spawnVehicle(...)` |
| `Bridge.GetVehicleProperties(veh)` | `bridge.vehicle.getVehicleProperties(veh)` |
| `Bridge.SetVehicleProperties(veh, p)` | `bridge.vehicle.setVehicleProperties(veh, p)` |
| `Bridge.GiveVehicle(src, m, p)` | `bridge.vehicle.giveVehicle(src, m, p)` |

### Migration steps

1. Remove `shared_scripts { '@nb-bridge/loader.lua' }` from `fxmanifest.lua`
2. Add `dependency 'nb-bridge'`
3. At the top of each script:
   ```lua
   local bridge = exports['nb-bridge']:get()
   ```
4. Replace all `Bridge.PascalCase(...)` calls using the table above
5. Remove any local framework detection code (`ESX = exports['es_extended']:getSharedObject()` etc.)
