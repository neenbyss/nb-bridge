# nb-bridge API Reference — v2.0.0

All methods are accessed through the bridge table returned by the single export:

```lua
local bridge = exports['nb-bridge']:get()
```

Call `get()` at the top of each script file that needs the bridge. The returned table is the global `Bridge` table — both references point to the same object.

---

## Table of Contents

- [Global Properties](#global-properties)
- [Debugger](#debugger)
- [bridge.player.* (Server)](#bridgeplayer-server)
- [bridge.player.* (Client)](#bridgeplayer-client)
- [bridge.inventory.* (Server)](#bridgeinventory-server)
- [bridge.inventory.* (Client)](#bridgeinventory-client)
- [bridge.vehicle.* (Shared)](#bridgevehicle-shared)
- [bridge.vehicle.* (Server)](#bridgevehicle-server)
- [bridge.vehicle.* (Client)](#bridgevehicle-client)
- [bridge.notify.*](#bridgenotify)
- [bridge.callback.*](#bridgecallback)
- [bridge.license.*](#bridgelicense)
- [bridge.progress.*](#bridgeprogress)
- [bridge.event.*](#bridgeevent)
- [bridge.diagnostics()](#bridgediagnostics)
- [Internal Events](#internal-events)

---

## Global Properties

Available on both client and server after nb-bridge starts.

| Property | Type | Description |
|----------|------|-------------|
| `Bridge.Framework` | `string` | `'ESX'`, `'QBCore'`, or `'QBX'` |
| `Bridge.FrameworkObject` | `table` | Raw framework shared object |
| `Bridge.InventorySystem` | `string\|nil` | `'ox_inventory'`, `'qb-inventory'`, `'qs-inventory'`, `'origen_inventory'`, or `'default'`. Set ~500 ms after boot. |

---

## Debugger

Global function (not on the `Bridge` table). Available after nb-bridge loads.

```lua
Debugger(module, ...)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `module` | `string` | Category label for the log prefix |
| `...` | `any` | Values to print. Tables are auto-encoded to JSON. |

Output format: `[nb-bridge][SERVER|CLIENT][module] message`

Enabled when `BridgeConfig.Debug == true` or the consumer's `Config.Debug == true`.

```lua
Debugger('Shop', 'Player bought item:', source, { name = 'water', count = 3 })
-- [nb-bridge][SERVER][Shop] Player bought item: 1 {"name":"water","count":3}
```

---

## bridge.player.* (Server)

Module: `modules/framework/server.lua`

---

### bridge.player.getPlayer

Get the raw framework player object.

```lua
bridge.player.getPlayer(source)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |

**Returns:** `table|nil` — xPlayer (ESX) or Player (QBCore/QBX) object.

| Framework | Object type |
|-----------|-------------|
| ESX | xPlayer — use `xPlayer.getName()`, `xPlayer.getJob()`, etc. |
| QBCore | Player — use `Player.PlayerData`, `Player.Functions`, etc. |
| QBX | Player — same structure as QBCore |

```lua
local player = bridge.player.getPlayer(source)
if player then
    -- direct framework access when the bridge doesn't have a wrapper
end
```

---

### bridge.player.getIdentifier

Get the player's unique persistent identifier.

```lua
bridge.player.getIdentifier(source)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |

**Returns:** `string|nil`

| Framework | Format |
|-----------|--------|
| ESX | `'license:abc123...'` |
| QBCore | citizenid string, e.g. `'ABC12345'` |
| QBX | citizenid string |

---

### bridge.player.getSSN

Get the player's Social Security Number. **ESX only.**

```lua
bridge.player.getSSN(source)
```

**Returns:** `string|nil` — Format `'XXX-XX-XXXX'`. Returns `nil` on QBCore and QBX.

---

### bridge.player.getPlayerName

Get the player's character full name.

```lua
bridge.player.getPlayerName(source)
```

**Returns:** `string` — Character first + last name. Falls back to `GetPlayerName(source)` if character data is unavailable.

---

### bridge.player.getGroup

Get the player's permission group.

```lua
bridge.player.getGroup(source)
```

**Returns:** `string` — One of `'god'`, `'superadmin'`, `'admin'`, `'mod'`, `'user'`. Defaults to `'user'`.

| Framework | How it resolves |
|-----------|----------------|
| ESX | `xPlayer.getGroup()` |
| QBCore / QBX | ACE permission check using `BridgeConfig.GroupMap`. Checks in order: god → superadmin → admin → mod. |

Default `GroupMap`:
```lua
{
    god        = 'group.god',
    superadmin = 'group.superadmin',
    admin      = 'group.admin',
    mod        = 'group.mod',
}
```

---

### bridge.player.setGroup

Set the player's permission group. **ESX only.**

```lua
bridge.player.setGroup(source, group)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `group` | `string` | Group name, e.g. `'admin'` |

**Returns:** `boolean` — `true` on ESX if player is found. `false` on QBCore and QBX.

---

### bridge.player.isAdmin

Check if a player is admin, using the configured admin groups.

```lua
bridge.player.isAdmin(source)
```

**Returns:** `boolean`

Config priority: `Config.AdminGroups` (consumer script) → `BridgeConfig.AdminGroups` (default: `{'admin','superadmin','god'}`).

```lua
if not bridge.player.isAdmin(source) then
    bridge.notify.send(source, 'No permission', 'error')
    return
end
```

---

### bridge.player.getMoney

Get the player's balance for a specific account.

```lua
bridge.player.getMoney(source, moneyType)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `moneyType` | `string` | `'cash'` or `'bank'` |

**Returns:** `number` — Balance. Returns `0` if player not found.

Note: ESX maps `'cash'` to the internal `'money'` account.

---

### bridge.player.addMoney

Add money to a player's account.

```lua
bridge.player.addMoney(source, moneyType, amount, reason)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `moneyType` | `string` | `'cash'` or `'bank'` |
| `amount` | `number` | Amount (must be > 0) |
| `reason` | `string\|nil` | Transaction reason. Defaults to resource name. |

**Returns:** `boolean`

**ESX note:** `addAccountMoney` has no return value. The bridge returns `true` whenever the player object is found — actual success cannot be verified from outside the framework.

---

### bridge.player.removeMoney

Remove money from a player's account.

```lua
bridge.player.removeMoney(source, moneyType, amount, reason)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `moneyType` | `string` | `'cash'` or `'bank'` |
| `amount` | `number` | Amount (must be > 0) |
| `reason` | `string\|nil` | Transaction reason |

**Returns:** `boolean` — `false` if player not found or (ESX only) if balance is insufficient.

**ESX:** The bridge pre-checks the balance via `xPlayer.getAccount()` before deducting, so it returns real `false` when funds are insufficient.

---

### bridge.player.setMoney

Set a player's account to an exact amount.

```lua
bridge.player.setMoney(source, moneyType, amount, reason)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `moneyType` | `string` | `'cash'` or `'bank'` |
| `amount` | `number` | New balance |
| `reason` | `string\|nil` | Transaction reason |

**Returns:** `boolean`

---

### bridge.player.getAccounts

Get all player money accounts in a normalized `{key = amount}` format.

```lua
bridge.player.getAccounts(source)
```

**Returns:** `table` — `{cash = number, bank = number, ...}`. Returns `{}` if player not found.

| Framework | Source |
|-----------|--------|
| ESX | `xPlayer.getAccounts()` normalized; ESX `'money'` account mapped to key `'cash'` |
| QBCore / QBX | `PlayerData.money` table directly |

---

### bridge.player.getJob

Get the player's current job in a normalized format.

```lua
bridge.player.getJob(source)
```

**Returns:** `table|nil`

```lua
{
    name         = string,   -- "police"
    label        = string,   -- "Law Enforcement"
    grade        = number,   -- 3
    grade_name   = string,   -- "sergeant"
    grade_label  = string,   -- "Sergeant"
    grade_salary = number,   -- 4000
    onDuty       = boolean,
}
```

Returns `nil` if player is not found.

---

### bridge.player.setJob

Set the player's job.

```lua
bridge.player.setJob(source, job, grade, onDuty)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `job` | `string` | Job name, e.g. `'police'` |
| `grade` | `number` | Grade level |
| `onDuty` | `boolean\|nil` | On duty flag (used by ESX) |

**Returns:** `boolean`

---

### bridge.player.getGang

Get the player's gang data. **QBCore and QBX only.**

```lua
bridge.player.getGang(source)
```

**Returns:** `table|nil` — Returns `nil` on ESX.

```lua
{
    name        = string,
    label       = string,
    grade       = number,
    grade_name  = string,
    grade_label = string,
}
```

---

### bridge.player.setGang

Set the player's gang. **QBCore and QBX only.**

```lua
bridge.player.setGang(source, gangName, grade)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `gangName` | `string` | Gang name |
| `grade` | `number` | Gang rank/grade |

**Returns:** `boolean` — `false` on ESX.

---

### bridge.player.getAllPlayers

Get all online player source IDs.

```lua
bridge.player.getAllPlayers()
```

**Returns:** `number[]` — Array of source IDs.

---

### bridge.player.getPlayTime

Get the player's total playtime. **ESX only.**

```lua
bridge.player.getPlayTime(source)
```

**Returns:** `number|nil` — Seconds played. Returns `nil` on QBCore and QBX.

---

### bridge.player.getCoords

Get the player's current position.

```lua
bridge.player.getCoords(source)
```

**Returns:** `vector3|nil`

| Framework | Implementation |
|-----------|---------------|
| ESX | `xPlayer.getCoords(true)` |
| QBCore / QBX | `GetEntityCoords(GetPlayerPed(source))` |

---

### bridge.player.setCoords

Teleport the player to coordinates.

```lua
bridge.player.setCoords(source, coords)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `coords` | `vector3\|vector4\|table` | Target position (`{x, y, z}`) |

**Returns:** `boolean`

---

### bridge.player.triggerClientEvent

Send a client event to a player.

```lua
bridge.player.triggerClientEvent(source, eventName, ...)
```

Uses `xPlayer.triggerEvent` on ESX when available; falls back to `TriggerClientEvent`.

---

### bridge.player.playerVar

Get or set an xPlayer variable. **ESX only.**

```lua
bridge.player.playerVar(source, key, value)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `key` | `string` | Variable key |
| `value` | `any\|nil` | Omit to get; provide to set |

**Returns:** `any|nil` when getting, `true` when setting. Returns `nil` on QBCore and QBX.

---

### bridge.player.getMeta / setMeta / clearMeta

Read, write, or clear player metadata.

```lua
bridge.player.getMeta(source, index, subIndex)
bridge.player.setMeta(source, index, value, subIndex)
bridge.player.clearMeta(source, index, subIndex)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `index` | `string\|nil` | Meta key. `nil` returns all metadata (`getMeta` only). |
| `value` | `string\|number\|table` | Value to set (`setMeta` only) |
| `subIndex` | `string\|nil` | Sub-key for nested metadata |

**Returns:** `getMeta` → `any`; `setMeta`/`clearMeta` → `boolean`

| Framework | Implementation |
|-----------|---------------|
| ESX | `xPlayer.getMeta` / `xPlayer.setMeta` / `xPlayer.clearMeta` |
| QBCore | `player.Functions.SetMetaData` / `player.PlayerData.metadata` |
| QBX | `exports.qbx_core:GetMetadata` / `SetMetadata` |

---

### bridge.player.executeCommand

Execute a console command on behalf of a player. **ESX only.**

```lua
bridge.player.executeCommand(source, command)
```

**Returns:** `boolean` — `false` on QBCore and QBX.

---

### bridge.player.registerCommand

Register a chat command with optional permission gating.

```lua
bridge.player.registerCommand(name, group, cb, suggestion)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | `string` | Command name without slash |
| `group` | `string\|nil` | Required group (`'admin'`, `'mod'`, `'god'`, nil = unrestricted) |
| `cb` | `function(source, args, rawCommand)` | Command handler |
| `suggestion` | `table\|nil` | `{ help = string, params = { { name, help } } }` |

| Framework | Implementation |
|-----------|---------------|
| ESX | `ESX.RegisterCommand` with group gating |
| QBX | `lib.addCommand` (ox_lib) with ACE; falls back to `RegisterCommand` + ACE check |
| QBCore | `RegisterCommand` + `IsPlayerAceAllowed` |

```lua
bridge.player.registerCommand('givecash', 'admin', function(source, args)
    local amount = tonumber(args[1]) or 0
    bridge.player.addMoney(source, 'cash', amount, 'admin_give')
end, {
    help = 'Give cash to yourself',
    params = { { name = 'amount', help = 'Amount' } },
})
```

---

### bridge.player.createBill

Create a bill using the server's billing system.

```lua
bridge.player.createBill(src, targetId, amount, description, jobName)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `src` | `number` | Emitter player server ID |
| `targetId` | `number` | Target player server ID |
| `amount` | `number` | Invoice amount |
| `description` | `string\|nil` | Invoice description |
| `jobName` | `string\|nil` | Job name for society context (required on ESX) |

**Returns:** `boolean`

Detection order: `esx_billing` (ESX) → `qb-billing` (QBCore/QBX) → `okokBilling` (fallback).

---

### bridge.player.onPlayerLoaded (Server)

Register a callback that fires when a player finishes loading their character.

```lua
bridge.player.onPlayerLoaded(cb)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cb` | `function(source, identifier)` | `identifier` is license (ESX) or citizenid (QBCore/QBX) |

```lua
bridge.player.onPlayerLoaded(function(source, identifier)
    print('Player ' .. source .. ' loaded: ' .. tostring(identifier))
end)
```

---

### bridge.player.onPlayerUnloaded (Server)

Register a callback for player logout or disconnect.

```lua
bridge.player.onPlayerUnloaded(cb)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cb` | `function(source)` | Called when player unloads |

**QBX note:** Two framework events (`QBCore:Server:OnPlayerUnload` + `qbx_core:server:playerLoggedOut`) can fire for the same player on a clean logout. The bridge debounces within a 1-second window so `cb` fires at most once per player.

---

## bridge.player.* (Client)

Module: `modules/framework/client.lua`

---

### bridge.player.getPlayerData

Get the local player's raw framework data.

```lua
bridge.player.getPlayerData()
```

**Returns:** `table|nil`

| Framework | Contents |
|-----------|----------|
| ESX | `pd.job`, `pd.accounts`, `pd.inventory`, `pd.group`, etc. |
| QBCore / QBX | `pd.job`, `pd.gang`, `pd.charinfo`, `pd.money`, `pd.items`, etc. |

---

### bridge.player.getJob (Client)

Get the local player's job in normalized format. Same shape as the server-side method.

```lua
bridge.player.getJob()
```

**Returns:** `table|nil` — Same canonical shape as the server method.

---

### bridge.player.getGang (Client)

Get the local player's gang. **QBCore and QBX only.**

```lua
bridge.player.getGang()
```

**Returns:** `table|nil` — Returns `nil` on ESX.

---

### bridge.player.getMoney (Client)

Get the local player's balance for an account.

```lua
bridge.player.getMoney(moneyType)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `moneyType` | `string` | `'cash'` or `'bank'` |

**Returns:** `number`

---

### bridge.player.getAccounts (Client)

Get all accounts in normalized format.

```lua
bridge.player.getAccounts()
```

**Returns:** `table` — `{cash = number, bank = number, ...}`

---

### bridge.player.getIdentifier (Client)

Get the local player's identifier.

```lua
bridge.player.getIdentifier()
```

**Returns:** `string|nil` — License (ESX) or citizenid (QBCore/QBX).

---

### bridge.player.getPlayerName (Client)

Get the local player's character name.

```lua
bridge.player.getPlayerName()
```

**Returns:** `string`

---

### bridge.player.getGroup (Client)

Get the local player's group. Informational only — do not use for security checks on the client.

```lua
bridge.player.getGroup()
```

**Returns:** `string` — `pd.group` (ESX) or `'user'` (QBCore/QBX, always).

---

### bridge.player.onPlayerLoaded (Client)

Register a callback for when the local player's character data is loaded.

```lua
bridge.player.onPlayerLoaded(cb)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cb` | `function()` | No arguments — use `bridge.player.getJob()` etc. inside |

---

### bridge.player.onPlayerUnloaded (Client)

Register a callback for when the local player logs out.

```lua
bridge.player.onPlayerUnloaded(cb)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cb` | `function()` | No arguments |

---

### bridge.player.onJobUpdate

Register a callback that fires when the local player's job changes.

```lua
bridge.player.onJobUpdate(cb)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cb` | `function(job)` | Receives normalized job table |

```lua
bridge.player.onJobUpdate(function(job)
    if job.name == 'police' then
        -- enable police UI
    end
end)
```

---

### bridge.player.onGangUpdate

Register a callback that fires when the local player's gang changes. **QBCore and QBX only.**

```lua
bridge.player.onGangUpdate(cb)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cb` | `function(gang)` | Receives normalized gang table |

Does nothing on ESX (no event fires).

---

## bridge.inventory.* (Server)

Module: `modules/inventory/server.lua`

Auto-detected inventory system. `ResolveInventorySystem()` is called inside every method, so the correct system is always used even if called before the 500ms detection thread completes.

**QBX note:** QBX requires ox_inventory, so `Bridge.InventorySystem` will always be `'ox_inventory'` on QBX servers. No separate QBX branch is needed.

---

### bridge.inventory.addItem

Add an item to a player's inventory.

```lua
bridge.inventory.addItem(source, item, count, metadata, slot)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `item` | `string` | Item name |
| `count` | `number` | Quantity (must be > 0) |
| `metadata` | `table\|string\|nil` | Item metadata |
| `slot` | `number\|nil` | Target slot |

**Returns:** `boolean`

```lua
bridge.inventory.addItem(source, 'water', 3)
bridge.inventory.addItem(source, 'weapon_pistol', 1, { serial = 'ABC123' })
```

---

### bridge.inventory.removeItem

Remove an item from a player's inventory.

```lua
bridge.inventory.removeItem(source, item, count, metadata, slot)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `item` | `string` | Item name |
| `count` | `number` | Quantity (must be > 0) |
| `metadata` | `table\|string\|nil` | Metadata to match (ox_inventory) |
| `slot` | `number\|nil` | Specific slot to remove from |

**Returns:** `boolean`

---

### bridge.inventory.hasItem

Check if a player has at least `count` of an item.

```lua
bridge.inventory.hasItem(source, item, count)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `item` | `string` | Item name |
| `count` | `number\|nil` | Minimum quantity. Defaults to `1`. |

**Returns:** `boolean`

```lua
if bridge.inventory.hasItem(source, 'lockpick') then
    bridge.inventory.removeItem(source, 'lockpick', 1)
end
```

---

### bridge.inventory.canCarry

Check if a player can carry additional items (weight/capacity check).

```lua
bridge.inventory.canCarry(source, item, count, metadata)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `item` | `string` | Item name |
| `count` | `number\|nil` | Quantity. Defaults to `1`. |
| `metadata` | `table\|string\|nil` | Affects weight in ox_inventory |

**Returns:** `boolean` — Returns `true` for systems without weight checks (`qb-inventory` and framework default).

---

### bridge.inventory.getItemMetadata

Get item metadata for a player's inventory slot. **ox_inventory only.**

```lua
bridge.inventory.getItemMetadata(source, itemName)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `itemName` | `string` | Item name |

**Returns:** `table|nil` — Metadata table for the first matching slot, or `nil` if not found or on non-ox_inventory systems.

---

### bridge.inventory.getAllItems

Get all registered item definitions from the active inventory system.

```lua
bridge.inventory.getAllItems()
```

**Returns:** `table` — Structure depends on inventory system.

| System | Source |
|--------|--------|
| ox_inventory | `exports.ox_inventory:Items()` |
| qs-inventory | `exports['qs-inventory']:GetItemList()` |
| origen_inventory | `exports.origen_inventory:Items()` |
| QBCore (default) | `QBCore.Shared.Items` |

---

### bridge.inventory.registerStash

Register a stash container. Idempotent — calling with the same `stashId` twice is safe.

```lua
bridge.inventory.registerStash(stashId, label, jobName, coords)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `stashId` | `string` | Unique stash identifier |
| `label` | `string` | Display name |
| `jobName` | `string\|nil` | Restrict to job (ox_inventory: creates group `{ [jobName] = 0 }`) |
| `coords` | `vector3\|nil` | Stash location (ox_inventory) |

Slot count and max weight come from `Config.Stash` (consumer) or `BridgeConfig.Stash` (defaults: 50 slots, 100000 weight).

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:RegisterStash` |
| qs-inventory | `exports['qs-inventory']:RegisterStash` |
| origen_inventory | `exports.origen_inventory:registerStash` |
| qb-inventory / default | No-op (stashes are handled differently) |

---

### bridge.inventory.isStashRegistered

Check if a stash has been registered through the bridge.

```lua
bridge.inventory.isStashRegistered(stashId)
```

**Returns:** `boolean`

---

### bridge.inventory.forceOpenStash

Force-open a stash inventory UI for a player from the server.

```lua
bridge.inventory.forceOpenStash(source, stashId)
```

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)` |
| qs-inventory | `TriggerClientEvent('inventory:server:OpenInventory', ...)` |
| origen_inventory | Relayed to client via `nb-bridge:client:origenOpenInventory` |

---

### bridge.inventory.forceOpenPlayerInventory

Force-open another player's inventory (e.g. for police searching a suspect).

```lua
bridge.inventory.forceOpenPlayerInventory(source, targetServerId)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player who will see the inventory |
| `targetServerId` | `number` | Player whose inventory is opened |

**Returns:** `boolean`

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:forceOpenInventory(source, 'player', targetServerId)` |
| qb-inventory | `TriggerClientEvent('inventory:client:OpenInventory', ...)` |
| qs-inventory | Server export or client event fallback |
| origen_inventory | Relayed to client via `nb-bridge:client:origenOpenInventory` |

---

### bridge.inventory.registerUsableItem

Register a usable item handler. Idempotent — only registers once per `itemName`.

```lua
bridge.inventory.registerUsableItem(itemName, cb)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `itemName` | `string` | Item name |
| `cb` | `function(source, item)` | `item = { name = string, slot = number? }` |

**Returns:** `boolean`

| Framework / System | Implementation |
|-------------------|----------------|
| ESX | `ESX.RegisterUsableItem` |
| QBCore | `QBCore.Functions.CreateUseableItem` |
| QBX | `exports.qbx_core:CreateUseableItem` |
| origen_inventory | `exports.origen_inventory:CreateUseableItem` (registers only through origen, not the framework layer, to prevent double-fire) |

```lua
bridge.inventory.registerUsableItem('bandage', function(src, item)
    bridge.inventory.removeItem(src, 'bandage', 1)
    -- apply healing
end)
```

---

### bridge.inventory.isUsableItemRegistered

Check if an item has been registered as usable through the bridge.

```lua
bridge.inventory.isUsableItemRegistered(itemName)
```

**Returns:** `boolean`

---

## bridge.inventory.* (Client)

Module: `modules/inventory/client.lua`

---

### bridge.inventory.openStash

Open a stash inventory UI on the local client.

```lua
bridge.inventory.openStash(stashId)
```

The stash must be registered on the server before opening.

| System | Implementation |
|--------|---------------|
| ox_inventory | `exports.ox_inventory:openInventory('stash', stashId)` |
| qb-inventory / qs-inventory | Server event + `SetCurrentStash` |
| origen_inventory | `exports.origen_inventory:openInventory('stash', stashId)` |

---

### bridge.inventory.openPlayerInventory

Open another player's inventory on the local client.

```lua
bridge.inventory.openPlayerInventory(targetServerId)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `targetServerId` | `number` | Target player server ID |

---

### bridge.inventory.getItemCount

Get the count of an item in the local player's inventory.

```lua
bridge.inventory.getItemCount(item)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `item` | `string` | Item name |

**Returns:** `number` — Returns `0` if not found.

---

### bridge.inventory.getImagePath

Get the NUI image path format string for the active inventory system.

```lua
bridge.inventory.getImagePath()
```

**Returns:** `string` — Format string with `%s` placeholder.

```lua
local path = bridge.inventory.getImagePath()
local img = path:format('water')
-- "nui://ox_inventory/web/images/water.png"
```

| System | Path |
|--------|------|
| ox_inventory | `nui://ox_inventory/web/images/%s.png` |
| qb-inventory | `nui://qb-inventory/html/images/%s.png` |
| qs-inventory | `nui://qs-inventory/html/images/%s.png` |
| origen_inventory | `nui://origen_inventory/ui/images/%s.png` (v2 default) |

Falls back to ox_inventory path if the system is not in the map.

---

## bridge.vehicle.* (Shared)

Module: `modules/vehicle/shared.lua` — available on both client and server.

---

### bridge.vehicle.normalizePlate

Trim trailing spaces from a GTA license plate. GTA pads all plates to 8 characters with spaces.

```lua
bridge.vehicle.normalizePlate(plate)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `plate` | `string\|nil` | Raw plate text |

**Returns:** `string` — Trimmed plate. Returns `''` for `nil` input.

```lua
bridge.vehicle.normalizePlate('ABC 123 ')  -- "ABC 123"
bridge.vehicle.normalizePlate(nil)          -- ""
```

---

## bridge.vehicle.* (Server)

---

### bridge.vehicle.generatePlate

Generate a random 8-character license plate (uppercase letters and digits).

```lua
bridge.vehicle.generatePlate()
```

**Returns:** `string` — e.g. `'X7KA92BF'`

---

### bridge.vehicle.giveVehicle

Give a vehicle to a player by inserting it into the framework's vehicle database.

```lua
bridge.vehicle.giveVehicle(source, model, props)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `model` | `string` | Vehicle model name, e.g. `'adder'` |
| `props` | `table\|nil` | Vehicle properties to store |

**Returns:** `boolean` — `true` if inserted. `false` if player identifier could not be resolved.

A random plate is auto-generated. The vehicle is inserted as stored (in garage).

| Framework | Table | Key columns |
|-----------|-------|-------------|
| ESX | `owned_vehicles` | `owner`, `plate`, `vehicle`, `type`, `stored`, `parking` |
| QBCore / QBX | `player_vehicles` | `license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `state` |

---

### bridge.vehicle.getVehicleOwnerName

Look up the owner's character name from a license plate via database query.

```lua
bridge.vehicle.getVehicleOwnerName(plate)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `plate` | `string` | License plate |

**Returns:** `string|nil` — Full name (e.g. `'John Doe'`), or `nil` if not found.

Uses `MySQL.scalar.await` + `MySQL.single.await` (requires oxmysql).

---

## bridge.vehicle.* (Client)

---

### bridge.vehicle.resolveModelHash

Convert a model name or string representation to a numeric hash.

```lua
bridge.vehicle.resolveModelHash(model)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `model` | `string\|number` | Model name, numeric string, or hash number |

**Returns:** `number`

```lua
bridge.vehicle.resolveModelHash('adder')       -- GetHashKey('adder')
bridge.vehicle.resolveModelHash('418536135')   -- 418536135
bridge.vehicle.resolveModelHash(418536135)     -- 418536135 (passthrough)
```

---

### bridge.vehicle.spawnVehicle

Spawn a vehicle entity at the given position.

```lua
bridge.vehicle.spawnVehicle(model, coords, heading, props, plate, cb)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `model` | `string\|number` | Model name or hash |
| `coords` | `vector3` | Spawn position |
| `heading` | `number` | Vehicle heading (0–360) |
| `props` | `table\|nil` | Vehicle properties to apply after spawn |
| `plate` | `string\|nil` | Plate text to set |
| `cb` | `function\|nil` | `cb(vehicle)` on success, `cb(nil)` on failure |

**Returns:** `number|false` — Vehicle entity handle, or `false` if model failed to load.

- Model loading has a 5-second wall-clock timeout (`GetGameTimer()`).
- `SetVehicleOnGroundProperly` and `SetEntityAsMissionEntity` are called automatically.

```lua
bridge.vehicle.spawnVehicle('adder', coords, 90.0, savedProps, 'MYPLATE', function(vehicle)
    if vehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end
end)
```

---

### bridge.vehicle.getVehicleProperties

Get all properties from a vehicle entity.

```lua
bridge.vehicle.getVehicleProperties(vehicle)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `vehicle` | `number` | Vehicle entity handle |

**Returns:** `table` — Properties table (colors, mods, plate, etc.). Returns `{}` if framework is not detected.

| Framework | Implementation |
|-----------|---------------|
| ox_lib present | `lib.getVehicleProperties(vehicle)` |
| QBX (no ox_lib) | `QB.Functions.GetVehicleProperties` via qb-core compat bridge |
| ESX | `ESX.Game.GetVehicleProperties(vehicle)` |
| QBCore | `QBCore.Functions.GetVehicleProperties(vehicle)` |

---

### bridge.vehicle.setVehicleProperties

Apply properties to a vehicle entity.

```lua
bridge.vehicle.setVehicleProperties(vehicle, props)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `vehicle` | `number` | Vehicle entity handle |
| `props` | `table` | Properties from `getVehicleProperties` or database |

Same implementation fallback order as `getVehicleProperties`.

---

### bridge.vehicle.getVehicleLabel

Get the display name of a vehicle model.

```lua
bridge.vehicle.getVehicleLabel(model)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `model` | `string\|number` | Model name or hash |

**Returns:** `string` — Display label. Returns `'Unknown'` if the model is not found or the label is `'NULL'`.

```lua
bridge.vehicle.getVehicleLabel('adder')   -- "Adder"
bridge.vehicle.getVehicleLabel('sultan')  -- "Sultan"
```

---

## bridge.notify.*

Module: `modules/notify/shared.lua` — shared file; server and client methods live here.

---

### bridge.notify.send (Server)

Send a notification to a player from the server.

```lua
bridge.notify.send(source, message, type)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |
| `message` | `string` | Notification text |
| `type` | `string` | `'success'`, `'error'`, `'info'`, or `'warning'` |

Internally triggers the `nb-bridge:client:notify` event, which calls `bridge.notify.show` on the client.

```lua
bridge.notify.send(source, 'Vehicle stored successfully', 'success')
bridge.notify.send(source, 'Not enough money', 'error')
```

---

### bridge.notify.show (Client)

Show a notification on the local client.

```lua
bridge.notify.show(message, type)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `message` | `string` | Notification text |
| `type` | `string` | `'success'`, `'error'`, `'info'`, or `'warning'`. Defaults to `'info'`. |

Detection priority:

| Priority | System | Implementation |
|----------|--------|---------------|
| 1 | ox_lib | `exports.ox_lib:notify(...)` — styled with title, type, 5000ms |
| 2 | QBX (no ox_lib) | `exports.qbx_core:Notify(message, type, 5000)` |
| 3 | ESX | `ESX.ShowNotification(message)` |
| 4 | QBCore | `QBCore.Functions.Notify(message, type, 5000)` |
| 5 | Fallback | `SetNotificationTextEntry` / `DrawNotification` |

---

## bridge.callback.*

Module: `modules/callbacks/shared.lua` — shared file; server and client portions live here.

Always namespace callback names with your resource name to avoid collisions across scripts.

---

### bridge.callback.register (Server)

Register a server callback that clients can invoke.

```lua
bridge.callback.register(name, cb)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | `string` | Unique callback name, e.g. `'nb-garages:getVehicles'` |
| `cb` | `function(source, respond, ...)` | Call `respond(...)` to send the response to the client |

If the client calls an unregistered name, it receives `nil`.

```lua
bridge.callback.register('nb-garages:getVehicles', function(source, respond, garageId)
    local identifier = bridge.player.getIdentifier(source)
    local vehicles = MySQL.query.await(
        'SELECT * FROM owned_vehicles WHERE owner = ? AND garage = ?',
        { identifier, garageId }
    )
    respond(vehicles)
end)
```

---

### bridge.callback.trigger (Client)

Call a registered server callback and receive the response asynchronously.

```lua
bridge.callback.trigger(name, cb, ...)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | `string` | Callback name (must match a registered server callback) |
| `cb` | `function(...)` | Called with the server's response, or `cb(nil)` on timeout |
| `...` | `any` | Additional arguments passed to the server handler |

- Responses are matched by an auto-incrementing request ID. Multiple concurrent calls are safe.
- 15-second timeout: if the server never responds, `cb(nil)` is called and the pending entry is freed.

```lua
bridge.callback.trigger('nb-garages:getVehicles', function(vehicles)
    if not vehicles then return end
    for _, v in ipairs(vehicles) do
        print(v.plate)
    end
end, garageId)
```

---

## bridge.license.*

Module: `modules/licenses/server.lua` — server only.

Auto-detects the license system at startup (~500ms). Detection order: `bcs_licensemanager` → `okokLicenses` → `esx_license` → `esx_default` → `qbcore`.

---

### bridge.license.getIdentity

Get the player's identity card data.

```lua
bridge.license.getIdentity(source)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `source` | `number` | Player server ID |

**Returns:** `table|nil`

| Field | Type | Description |
|-------|------|-------------|
| `firstname` | `string` | First name |
| `lastname` | `string` | Last name |
| `dob` | `string\|nil` | Date of birth (QBCore/QBX: `charinfo.birthdate`; ESX: `nil`) |
| `sex` | `string\|nil` | `'M'` or `'F'` (QBCore/QBX: derived from `charinfo.gender`; ESX: `nil`) |

```lua
local id = bridge.license.getIdentity(source)
if id then
    print(id.firstname .. ' ' .. id.lastname)
end
```

---

### bridge.license.getDriverLicense

Check if a player has a driver license.

```lua
bridge.license.getDriverLicense(source)
```

**Returns:** `table` — Always returns a table (never nil).

| Field | Type | Description |
|-------|------|-------------|
| `hasLicense` | `boolean` | Whether the player has a driver license |
| `label` | `string` | License label or name. Empty string if no license. |

| System | How it checks |
|--------|---------------|
| bcs_licensemanager | Checks: `driver_car`, `driver_bike`, `driver_truck`, `driver_helicopter`, `driver_boat`, `driver_plane` |
| okokLicenses | `exports.okokLicenses:getLicense(source, 'driver')` |
| esx_license | `xPlayer.getLicenses()` — type `'drive'`, `'driver'`, or `'dmv'` |
| esx_default | Same as esx_license |
| qbcore (QBCore/QBX) | `PlayerData.metadata.licences.driver` |

---

### bridge.license.getWeaponLicense

Check if a player has a weapon/firearms license.

```lua
bridge.license.getWeaponLicense(source)
```

**Returns:** `table` — Same shape as `getDriverLicense`.

| System | How it checks |
|--------|---------------|
| bcs_licensemanager | Checks: `weapon` |
| okokLicenses | `exports.okokLicenses:getLicense(source, 'weapon')` |
| esx_license | `xPlayer.getLicenses()` — type `'weapon'` or `'firearms'` |
| esx_default | Same as esx_license |
| qbcore (QBCore/QBX) | `PlayerData.metadata.licences.weapon` |

```lua
local weapon = bridge.license.getWeaponLicense(source)
if not weapon.hasLicense then
    bridge.notify.send(source, 'You need a weapon license', 'error')
    return
end
```

---

## bridge.progress.*

Module: `modules/progress/client.lua` — client only.

---

### bridge.progress.show

Show a blocking progress bar. The call yields until the progress completes or the player cancels.

```lua
bridge.progress.show(duration, label, anim)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `duration` | `number` | Duration in milliseconds |
| `label` | `string` | Text displayed on the progress bar |
| `anim` | `table\|nil` | `{ dict = string, name = string }` — animation to play |

**Returns:** `boolean` — `true` if completed normally, `false` if cancelled (ox_lib only).

| System | Features |
|--------|----------|
| ox_lib | Full UI, cancellable, disables movement and vehicle control |
| Native fallback | Plays animation if provided. Waits the full duration. Always returns `true`. |

Animation dict is loaded with a 5-second timeout. `ClearPedTasks` is called when done.

```lua
-- Simple
local done = bridge.progress.show(5000, 'Searching vehicle...')
if done then
    -- continue
end

-- With animation
local done = bridge.progress.show(3000, 'Repairing engine...', {
    dict = 'mini@repair',
    name = 'fixing_a_player',
})
if done then
    -- repair complete
end
```

---

## bridge.event.*

Module: `modules/events/shared.lua` — shared file; server and client methods live here.

Convenience lifecycle hooks that wrap the underlying framework events. Use these instead of `AddEventHandler` directly to keep your code framework-agnostic.

`onPlayerLoaded` and `onPlayerUnloaded` are thin wrappers over `bridge.player.onPlayerLoaded` / `bridge.player.onPlayerUnloaded` — they share the same underlying implementation, including the QBX double-fire debounce.

---

### bridge.event.* (Server)

| Method | Signature | Description |
|--------|-----------|-------------|
| `onPlayerLoaded` | `cb: fun(source: number)` | Fires when a player finishes loading their character. Delegates to `bridge.player.onPlayerLoaded`. |
| `onPlayerUnloaded` | `cb: fun(source: number)` | Fires when a player disconnects or logs out. Delegates to `bridge.player.onPlayerUnloaded`. QBX debounces double-fire within 1 second. |
| `onResourceStart` | `cb: fun(resourceName: string)` | Fires when any resource starts (`onResourceStart`). |
| `onResourceStop` | `cb: fun(resourceName: string)` | Fires when any resource stops (`onResourceStop`). |
| `onSelfStart` | `cb: fun()` | Fires when the consumer resource itself starts. Captures `GetCurrentResourceName()` at registration time. |
| `onSelfStop` | `cb: fun()` | Fires when the consumer resource itself stops. |

---

### bridge.event.* (Client)

| Method | Signature | Description |
|--------|-----------|-------------|
| `onPlayerLoaded` | `cb: fun()` | Fires when the local player finishes loading their character. Delegates to `bridge.player.onPlayerLoaded`. |
| `onPlayerUnloaded` | `cb: fun()` | Fires when the local player logs out. Delegates to `bridge.player.onPlayerUnloaded`. |
| `onPlayerSpawned` | `cb: fun()` | Fires when the player spawns in the world after character select. ESX: `playerSpawned`; QBCore/QBX: `QBCore:Client:OnPlayerLoaded`. |
| `onResourceStart` | `cb: fun(resourceName: string)` | Fires when a resource starts on the client (`onClientResourceStart`). |
| `onResourceStop` | `cb: fun(resourceName: string)` | Fires when a resource stops on the client (`onClientResourceStop`). |

---

### Example

```lua
local bridge = exports['nb-bridge']:get()

-- Server: react to any player loading
bridge.event.onPlayerLoaded(function(source)
    print('Player ' .. source .. ' loaded')
end)

-- Server: detect when your own resource restarts
bridge.event.onSelfStart(function()
    print('nb-myresource restarted — re-registering stashes')
    bridge.inventory.registerStash('myresource:mainStash', 'Main Stash')
end)

bridge.event.onSelfStop(function()
    print('nb-myresource stopping — cleanup')
end)

-- Server: watch for another specific resource
bridge.event.onResourceStart(function(name)
    if name == 'ox_inventory' then
        print('ox_inventory came online')
    end
end)

-- Client: fire when the player spawns in the world
bridge.event.onPlayerSpawned(function()
    local job = bridge.player.getJob()
    print('Spawned as: ' .. job.name)
end)

-- Client: track resource lifecycle from the client
bridge.event.onResourceStop(function(name)
    if name == 'nb-myresource' then
        -- hide any open UI
    end
end)
```

---

## bridge.diagnostics()

Module: `modules/diagnostics/server.lua` — server only.

Returns a runtime snapshot of nb-bridge state. Useful for debugging framework detection, dependency issues, and inventory system resolution.

### Signature

```lua
bridge.diagnostics(): BridgeDiagnosticsResult
```

Also callable as `exports['nb-bridge']:diagnostics()` from any other resource.

### Return value

| Field | Type | Description |
|-------|------|-------------|
| `version` | `string` | nb-bridge version, e.g. `'2.0.0'` |
| `framework` | `'ESX'\|'QBCore'\|'QBX'\|'none'` | Detected framework |
| `inventorySystem` | `string\|nil` | Active inventory system, or `'not yet resolved'` if called before the 500ms detection completes |
| `side` | `string` | Always `'server'` |
| `uptime` | `number` | `GetGameTimer()` value in milliseconds since server start |
| `features` | `table<string, boolean>` | Presence of key optional resources |
| `missing` | `string[]` | Required dependencies that are not running |

`features` keys:

| Key | Resource checked |
|-----|-----------------|
| `ox_lib` | `ox_lib` |
| `ox_inventory` | `ox_inventory` |
| `oxmysql` | `oxmysql` |
| `qs_inventory` | `qs-inventory` |
| `origen` | `origen_inventory` |
| `qb_inventory` | `qb-inventory` |

`missing` is populated when:
- `oxmysql` is not running (required by all frameworks)
- `ox_inventory` is not running on a QBX server (required by QBX)
- `ox_lib` is not running on a QBX server (required by QBX)

### /nbdiag command

Registered automatically at nb-bridge startup. Prints formatted diagnostics to the server console and, if called by an in-game admin, also sends output to their chat.

**Access:**
- Server console: always allowed
- In-game: requires the caller to pass `bridge.player.isAdmin(source)`

```
/nbdiag
```

```
[nb-bridge] Diagnostics
  Version:    2.0.0
  Framework:  QBX
  Inventory:  ox_inventory
  Uptime:     142.3s
  Features:
    ✓ ox_lib
    ✓ ox_inventory
    ✓ oxmysql
    ✗ qs_inventory
    ✗ origen
    ✗ qb_inventory
  No missing dependencies.
```

### Example

```lua
-- From another resource (server-side only)
local diag = exports['nb-bridge']:diagnostics()

print('Framework:', diag.framework)
print('Inventory:', diag.inventorySystem)
print('Uptime (s):', diag.uptime / 1000)

if #diag.missing > 0 then
    for _, dep in ipairs(diag.missing) do
        print('MISSING:', dep)
    end
end

-- Conditional logic based on detected framework
if diag.framework == 'QBX' and not diag.features.ox_inventory then
    error('QBX requires ox_inventory but it is not running')
end
```

---

## Internal Events

These events are registered by nb-bridge internally. You do not need to use them directly.

### Notification

| Event | Direction | Description |
|-------|-----------|-------------|
| `nb-bridge:client:notify` | Server → Client | Carries notification data from `bridge.notify.send` |

Payload: `message (string)`, `type (string)`. On the client, this calls `bridge.notify.show`.

### Callbacks

| Event | Direction | Description |
|-------|-----------|-------------|
| `{resourceName}:bridge:triggerCallback` | Client → Server | Client requests callback |
| `{resourceName}:bridge:receiveCallback` | Server → Client | Server sends response |

The event name prefix is the **consuming resource's name**, not `nb-bridge`. This means callback events are scoped per-resource and cannot collide across resources.

Payload for trigger: `name (string)`, `requestId (number)`, `...args`
Payload for receive: `requestId (number)`, `...response`

### origen_inventory relay

| Event | Direction | Description |
|-------|-----------|-------------|
| `nb-bridge:client:origenOpenInventory` | Server → Client | Routes `forceOpenStash` / `forceOpenPlayerInventory` to client for origen_inventory (which opens from the client side) |

### Framework events (listened, not created)

| Event | Framework | Consumed by |
|-------|-----------|-------------|
| `esx:playerLoaded` | ESX | `onPlayerLoaded` server + client |
| `esx:playerDropped` | ESX | `onPlayerUnloaded` server |
| `esx:onPlayerLogout` | ESX | `onPlayerUnloaded` client |
| `esx:setJob` | ESX | `onJobUpdate` client |
| `QBCore:Server:PlayerLoaded` | QBCore / QBX | `onPlayerLoaded` server |
| `QBCore:Server:OnPlayerUnload` | QBCore / QBX | `onPlayerUnloaded` server |
| `qbx_core:server:playerLoggedOut` | QBX | `onPlayerUnloaded` server (debounced with above) |
| `QBCore:Client:OnPlayerLoaded` | QBCore / QBX | `onPlayerLoaded` client |
| `QBCore:Client:OnPlayerUnload` | QBCore / QBX | `onPlayerUnloaded` client |
| `QBCore:Client:OnJobUpdate` | QBCore / QBX | `onJobUpdate` client |
| `QBCore:Client:OnGangUpdate` | QBCore / QBX | `onGangUpdate` client |

---

*Neenbyss Studios — nb-bridge v2.0.0*
