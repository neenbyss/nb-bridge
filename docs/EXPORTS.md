# NB-Bridge — API Reference (Exports)

> **Version:** 1.0.0
> **Frameworks:** ESX / QBCore (auto-detected)
> **Resource:** `nb-bridge`

This document lists **every function** available in nb-bridge. Each function can be called in two ways:

```lua
-- 1. Global table (for nb-* scripts that depend on nb-bridge)
Bridge.GetPlayer(source)

-- 2. FiveM export (for any external script)
exports['nb-bridge']:GetPlayer(source)
```

---

## Table of Contents

- [Global Properties](#global-properties)
- [Utilities — Shared](#utilities--shared)
  - [Debugger](#debugger)
- [Internal Events](#internal-events)
- [Framework — Server](#framework--server)
  - [Bridge.GetPlayer](#bridgegetplayer)
  - [Bridge.GetIdentifier](#bridgegetidentifier)
  - [Bridge.GetSSN](#bridgegetssn)
  - [Bridge.GetPlayerName](#bridgegetplayername)
  - [Bridge.GetGroup](#bridgegetgroup)
  - [Bridge.SetGroup](#bridgesetgroup)
  - [Bridge.IsAdmin](#bridgeisadmin)
  - [Bridge.AddMoney](#bridgeaddmoney)
  - [Bridge.RemoveMoney](#bridgeremovemoney)
  - [Bridge.SetMoney](#bridgesetmoney)
  - [Bridge.GetMoney](#bridgegetmoney)
  - [Bridge.GetAccounts](#bridgegetaccounts)
  - [Bridge.GetJob](#bridgegetjob)
  - [Bridge.SetJob](#bridgesetjob)
  - [Bridge.GetGang](#bridgegetgang)
  - [Bridge.GetPlayTime](#bridgegetplaytime)
  - [Bridge.SetCoords](#bridgesetcoords)
  - [Bridge.GetCoords](#bridgegetcoords)
  - [Bridge.TriggerClientEvent](#bridgetriggerclientevent)
  - [Bridge.PlayerVar](#bridgeplayervar)
  - [Bridge.SetMeta](#bridgesetmeta)
  - [Bridge.GetMeta](#bridgegetmeta)
  - [Bridge.ClearMeta](#bridgeclearmeta)
  - [Bridge.ExecuteCommand](#bridgeexecutecommand)
  - [Bridge.CreateBill](#bridgecreatebill)
  - [Bridge.OnPlayerLoaded (server)](#bridgeonplayerloaded-server)
- [Framework — Client](#framework--client)
  - [Bridge.GetPlayerData](#bridgegetplayerdata)
  - [Bridge.OnPlayerLoaded (client)](#bridgeonplayerloaded-client)
  - [Bridge.OnJobUpdate](#bridgeonjobupdate)
- [Notify — Server](#notify--server)
  - [Bridge.Notify](#bridgenotify)
- [Notify — Client](#notify--client)
  - [Bridge.ShowNotification](#bridgeshownotification)
- [Inventory — Server](#inventory--server)
  - [Bridge.AddItem](#bridgeadditem)
  - [Bridge.RemoveItem](#bridgeremoveitem)
  - [Bridge.HasItem](#bridgehasitem)
  - [Bridge.CanCarry](#bridgecancarry)
  - [Bridge.RegisterStash](#bridgeregisterstash)
  - [Bridge.IsStashRegistered](#bridgeisstashregistered)
  - [Bridge.ForceOpenStash](#bridgeforceopenstash)
  - [Bridge.ForceOpenPlayerInventory](#bridgeforceopenplayerinventory)
  - [Bridge.GetAllItems](#bridgegetallitems)
- [Inventory — Client](#inventory--client)
  - [Bridge.OpenStash](#bridgeopenstash)
  - [Bridge.OpenPlayerInventory](#bridgeopenplayerinventory)
  - [Bridge.GetItemCount](#bridgegetitemcount)
  - [Bridge.GetImagePath](#bridgegetimagepath)
- [Vehicle — Shared](#vehicle--shared)
  - [Bridge.NormalizePlate](#bridgenormalizeplate)
- [Vehicle — Server](#vehicle--server)
  - [Bridge.GeneratePlate](#bridgegenerateplate)
  - [Bridge.GiveVehicle](#bridgegivevehicle)
  - [Bridge.GetVehicleOwnerName](#bridgegetvehicleownername)
- [Vehicle — Client](#vehicle--client)
  - [Bridge.ResolveModelHash](#bridgeresolvemodelhash)
  - [Bridge.SpawnVehicle](#bridgespawnvehicle)
  - [Bridge.GetVehicleProperties](#bridgegetvehicleproperties)
  - [Bridge.SetVehicleProperties](#bridgesetvehicleproperties)
  - [Bridge.GetVehicleLabel](#bridgegetvehiclelabel)
- [Callbacks — Server](#callbacks--server)
  - [Bridge.CreateCallback](#bridgecreatecallback)
- [Callbacks — Client](#callbacks--client)
  - [Bridge.TriggerServerCallback](#bridgetriggerservercallback)
- [Licenses — Server](#licenses--server)
  - [Bridge.GetIdentity](#bridgegetidentity)
  - [Bridge.GetDriverLicense](#bridgegetdriverlicense)
  - [Bridge.GetWeaponLicense](#bridgegetweaponlicense)
- [Progress — Client](#progress--client)
  - [Bridge.Progress](#bridgeprogress)

---

## Global Properties

These are available on both client and server after nb-bridge loads.

| Property | Type | Description |
|----------|------|-------------|
| `Bridge.Framework` | `string` | `'ESX'` or `'QBCore'` — the detected framework |
| `Bridge.FrameworkObject` | `table` | The raw framework shared object (ESX object or QBCore object) for direct access |
| `Bridge.InventorySystem` | `string\|nil` | Detected inventory system: `'ox_inventory'`, `'qb-inventory'`, `'qs-inventory'`, or `'default'`. Set after 500ms |

---

## Utilities — Shared

> **Module:** `shared/init.lua`
> **Side:** Both (client and server)

---

### Debugger

Print formatted debug messages to the server/client console. Only prints when debug mode is enabled. This is a **global function** (not on the Bridge table).

```lua
Debugger(module, ...)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `module` | `string` | Yes | Module/category name for the log prefix |
| `...` | `any` | No | Values to print. Tables are auto-encoded to JSON. |

**Output format:**
```
[nb-bridge][SERVER][Inventory] Detected: ox_inventory
[nb-bridge][CLIENT][Vehicle] SpawnVehicle | hash: 418536135 | type: number
```

```lua
Debugger('MyModule', 'Player loaded:', source, 'identifier:', identifier)
-- [nb-bridge][SERVER][MyModule] Player loaded: 1 identifier: license:abc123

Debugger('Crafting', 'Recipe data:', { name = 'lockpick', level = 5 })
-- [nb-bridge][SERVER][Crafting] Recipe data: {"name":"lockpick","level":5}
```

**Debug enable priority:**
1. `BridgeConfig.Debug` (nb-bridge's own config) — if `true`, debug is enabled
2. `Config.Debug` (consumer script's config) — if `true`, debug is also enabled
3. If both are `false` or `nil`, nothing prints

> **Note:** `Debugger()` is a global function available everywhere after nb-bridge loads. Consumer scripts do **not** need their own `shared/debugger.lua` anymore.

---

## Internal Events

These are the network events registered by nb-bridge internally. You generally don't need to use them directly — they are documented here for debugging and advanced integration.

### Notification Event

| Event | Direction | Description |
|-------|-----------|-------------|
| `nb-bridge:client:notify` | Server → Client | Carries notification data when `Bridge.Notify()` is called |

**Payload:** `message` (string), `type` (string)

```lua
-- This is what Bridge.Notify does internally:
TriggerClientEvent('nb-bridge:client:notify', source, message, type)

-- On client, this event calls Bridge.ShowNotification(message, type)
```

> If you override `Bridge.Notify` on server but still want the client handler to work, trigger this event in your override.

### Callback Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `nb-bridge:bridge:triggerCallback` | Client → Server | Client requests a callback response |
| `nb-bridge:bridge:receiveCallback` | Server → Client | Server sends callback response back |

**triggerCallback payload:** `name` (string), `requestId` (number), `...` (additional args)
**receiveCallback payload:** `requestId` (number), `...` (response args)

```
Client                              Server
  |                                    |
  |-- triggerCallback(name, id, ...) ->|
  |                                    | callbacks[name](source, respond, ...)
  |<- receiveCallback(id, ...)---------|
  |                                    |
  cb(...)                              |
```

> `requestId` is an auto-incrementing integer managed by the client. Each concurrent callback gets a unique ID so responses never mix up.

### Framework Events (listened, not created)

nb-bridge **listens** to these framework events but does not create them. They are triggered by the framework itself.

| Event | Framework | Used by |
|-------|-----------|---------|
| `esx:playerLoaded` | ESX | `Bridge.OnPlayerLoaded` (server + client) |
| `QBCore:Server:OnPlayerLoaded` | QBCore | `Bridge.OnPlayerLoaded` (server) |
| `QBCore:Client:OnPlayerLoaded` | QBCore | `Bridge.OnPlayerLoaded` (client) |
| `esx:setJob` | ESX | `Bridge.OnJobUpdate` (client) |
| `QBCore:Client:OnJobUpdate` | QBCore | `Bridge.OnJobUpdate` (client) |

> These are standard framework events. nb-bridge wraps them so you don't need to check which framework is running.

---

## Framework — Server

> **Module:** `modules/framework/server.lua`
> **Side:** Server only
> **Source file:** `nb-bridge/modules/framework/server.lua`

---

### Bridge.GetPlayer

Get the raw framework player object for direct access.

```lua
Bridge.GetPlayer(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `table|nil` — xPlayer (ESX) or Player (QBCore) object, or `nil` if not found.

```lua
-- Example
local player = Bridge.GetPlayer(source)
if player then
    -- ESX: player is xPlayer, use player.getName(), player.getJob(), etc.
    -- QBCore: player is Player, use player.PlayerData, player.Functions, etc.
end
```

---

### Bridge.GetIdentifier

Get the player's unique identifier.

```lua
Bridge.GetIdentifier(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `string|nil` — ESX returns the `license` identifier, QBCore returns the `citizenid`.

```lua
local id = Bridge.GetIdentifier(source)
-- ESX:    "license:abc123..."
-- QBCore: "ABC12345"
```

---

### Bridge.GetSSN

Get the player's Social Security Number. **ESX only.**

```lua
Bridge.GetSSN(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `string|nil` — SSN in format `XXX-XX-XXXX`, or `nil` on QBCore.

---

### Bridge.GetPlayerName

Get the player's character full name.

```lua
Bridge.GetPlayerName(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `string` — Character name. Falls back to Steam/FiveM name if character name unavailable.

```lua
local name = Bridge.GetPlayerName(source)
-- "John Doe"
```

---

### Bridge.GetGroup

Get the player's permission group.

```lua
Bridge.GetGroup(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `string` — Group name (e.g. `'admin'`, `'god'`, `'user'`). Defaults to `'user'`.

```lua
local group = Bridge.GetGroup(source)
if group == 'admin' then
    -- player is admin
end
```

---

### Bridge.SetGroup

Set the player's permission group. **ESX only.**

```lua
Bridge.SetGroup(source, group)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `group` | `string` | Yes | Group name (e.g. `'admin'`) |

**Returns:** `boolean` — `true` if set successfully, `false` on QBCore or failure.

---

### Bridge.IsAdmin

Check if a player is admin. Checks against `Config.AdminGroups` (consumer script) or `BridgeConfig.AdminGroups` (default).

```lua
Bridge.IsAdmin(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `boolean` — `true` if the player's group matches any admin group. On QBCore, also checks ace permissions.

```lua
if not Bridge.IsAdmin(source) then
    Bridge.Notify(source, 'No permission', 'error')
    return
end
```

**Config priority:**
1. `Config.AdminGroups` (from consumer script)
2. `BridgeConfig.AdminGroups` (from nb-bridge config.lua)

---

### Bridge.AddMoney

Add money to a player's account.

```lua
Bridge.AddMoney(source, moneyType, amount, reason)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `moneyType` | `string` | Yes | `'cash'` or `'bank'` |
| `amount` | `number` | Yes | Amount to add (must be > 0) |
| `reason` | `string\|nil` | No | Transaction reason (defaults to resource name) |

**Returns:** `boolean` — `true` if successful.

```lua
Bridge.AddMoney(source, 'bank', 5000, 'salary_payment')
Bridge.AddMoney(source, 'cash', 200, 'item_sold')
```

> **Note:** ESX maps `'cash'` to account `'money'` internally.

---

### Bridge.RemoveMoney

Remove money from a player's account.

```lua
Bridge.RemoveMoney(source, moneyType, amount, reason)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `moneyType` | `string` | Yes | `'cash'` or `'bank'` |
| `amount` | `number` | Yes | Amount to remove (must be > 0) |
| `reason` | `string\|nil` | No | Transaction reason |

**Returns:** `boolean` — `true` if successful.

```lua
if Bridge.GetMoney(source, 'bank') >= 1000 then
    Bridge.RemoveMoney(source, 'bank', 1000, 'invoice_payment')
end
```

---

### Bridge.SetMoney

Set a player's account to an exact amount.

```lua
Bridge.SetMoney(source, moneyType, amount, reason)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `moneyType` | `string` | Yes | `'cash'` or `'bank'` |
| `amount` | `number` | Yes | Amount to set |
| `reason` | `string\|nil` | No | Transaction reason |

**Returns:** `boolean` — `true` if successful.

---

### Bridge.GetMoney

Get a player's current balance.

```lua
Bridge.GetMoney(source, moneyType)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `moneyType` | `string` | Yes | `'cash'` or `'bank'` |

**Returns:** `number` — Current balance. Returns `0` if player not found.

```lua
local cash = Bridge.GetMoney(source, 'cash')
local bank = Bridge.GetMoney(source, 'bank')
print('Total: $' .. (cash + bank))
```

---

### Bridge.GetAccounts

Get all player financial accounts. **ESX only.**

```lua
Bridge.GetAccounts(source, minimal)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `minimal` | `boolean\|nil` | No | If `true`, returns only amounts |

**Returns:** `table|nil` — Array of account objects, or `nil` on QBCore.

---

### Bridge.GetJob

Get the player's current job data.

```lua
Bridge.GetJob(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `table|nil` — Job table or `nil` if player not found.

```lua
local job = Bridge.GetJob(source)
if job then
    print(job.name)         -- "police"
    print(job.label)        -- "Law Enforcement"
    print(job.grade)        -- 3
    print(job.grade_name)   -- "sergeant"
    print(job.grade_label)  -- "Sergeant"
end
```

**Return structure:**
| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Job identifier (e.g. `'police'`) |
| `label` | `string` | Display name (e.g. `'Law Enforcement'`) |
| `grade` | `number` | Grade level (0-based) |
| `grade_name` | `string` | Grade identifier |
| `grade_label` | `string` | Grade display name |
| `grade_salary` | `number` | Grade salary (ESX) |
| `onDuty` | `boolean` | Whether on duty (if applicable) |

---

### Bridge.SetJob

Set a player's job.

```lua
Bridge.SetJob(source, job, grade, onDuty)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `job` | `string` | Yes | Job name (e.g. `'police'`) |
| `grade` | `number` | Yes | Grade level |
| `onDuty` | `boolean\|nil` | No | On duty flag (ESX only) |

**Returns:** `boolean` — `true` if successful.

```lua
Bridge.SetJob(source, 'police', 2, true)
```

---

### Bridge.GetGang

Get the player's gang data. **QBCore only.**

```lua
Bridge.GetGang(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `table|nil` — Gang data table, or `nil` on ESX.

---

### Bridge.GetPlayTime

Get the player's total playtime. **ESX only.**

```lua
Bridge.GetPlayTime(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `number|nil` — Playtime in seconds, or `nil` on QBCore.

---

### Bridge.SetCoords

Teleport a player to coordinates. **ESX only.**

```lua
Bridge.SetCoords(source, coords)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `coords` | `vector3\|vector4\|table` | Yes | Target coordinates |

**Returns:** `boolean` — `true` if successful.

---

### Bridge.GetCoords

Get a player's current position. **ESX only.**

```lua
Bridge.GetCoords(source, asVector)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `asVector` | `boolean\|nil` | No | If `true`, returns `vector3` |

**Returns:** `vector3|table|nil` — Player coordinates.

---

### Bridge.TriggerClientEvent

Send a client event to a player. Uses `xPlayer.triggerEvent` on ESX when available.

```lua
Bridge.TriggerClientEvent(source, eventName, ...)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `eventName` | `string` | Yes | Event name |
| `...` | `any` | No | Arguments to pass |

---

### Bridge.PlayerVar

Get or set an xPlayer variable. **ESX only.**

```lua
Bridge.PlayerVar(source, key, value)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `key` | `string` | Yes | Variable key |
| `value` | `any\|nil` | No | If provided, sets the value. If omitted, gets it. |

**Returns:** `any|nil` — The value when getting, `true` when setting. `nil` on QBCore.

```lua
-- Set
Bridge.PlayerVar(source, 'isDead', true)

-- Get
local isDead = Bridge.PlayerVar(source, 'isDead')
```

---

### Bridge.SetMeta

Set player metadata. **ESX only.**

```lua
Bridge.SetMeta(source, index, value, subIndex)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `index` | `string` | Yes | Meta key |
| `value` | `string\|number\|table` | Yes | Meta value |
| `subIndex` | `string\|nil` | No | Sub key for nested meta |

**Returns:** `boolean` — `true` if set successfully.

---

### Bridge.GetMeta

Get player metadata. **ESX only.**

```lua
Bridge.GetMeta(source, index, subIndex)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `index` | `string\|nil` | No | Meta key. `nil` returns all metadata. |
| `subIndex` | `string\|nil` | No | Sub key for nested meta |

**Returns:** `any` — The metadata value.

---

### Bridge.ClearMeta

Clear player metadata. **ESX only.**

```lua
Bridge.ClearMeta(source, index, subIndex)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `index` | `string` | Yes | Meta key to clear |
| `subIndex` | `string\|nil` | No | Sub key for nested meta |

**Returns:** `boolean` — `true` if cleared successfully.

---

### Bridge.ExecuteCommand

Execute a console command on behalf of a player. **ESX only.**

```lua
Bridge.ExecuteCommand(source, command)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `command` | `string` | Yes | Command to execute |

**Returns:** `boolean` — `true` if executed successfully.

---

### Bridge.CreateBill

Create a bill/invoice using the server's billing system. Auto-detects: esx_billing, qb-billing, okokBilling.

```lua
Bridge.CreateBill(src, targetId, amount, description, jobName)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `src` | `number` | Yes | Emitter player server ID |
| `targetId` | `number` | Yes | Target player server ID |
| `amount` | `number` | Yes | Invoice amount |
| `description` | `string\|nil` | No | Invoice description |
| `jobName` | `string\|nil` | No | Job name for society context |

**Returns:** `boolean` — `true` if the bill was created.

```lua
Bridge.CreateBill(source, targetSource, 500, 'Vehicle repair', 'mechanic')
```

---

### Bridge.OnPlayerLoaded (server)

Register a callback that fires when a player finishes loading.

```lua
Bridge.OnPlayerLoaded(cb)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cb` | `function(source, identifier)` | Yes | Callback function |

```lua
Bridge.OnPlayerLoaded(function(source, identifier)
    print('Player loaded: ' .. identifier)
end)
```

---

## Framework — Client

> **Module:** `modules/framework/client.lua`
> **Side:** Client only

---

### Bridge.GetPlayerData

Get the local player's data table.

```lua
Bridge.GetPlayerData()
```

**Returns:** `table|nil` — Player data object.

```lua
local data = Bridge.GetPlayerData()
-- ESX: data.job, data.inventory, data.accounts, etc.
-- QBCore: data.job, data.charinfo, data.money, data.items, etc.
```

---

### Bridge.OnPlayerLoaded (client)

Register a callback that fires when the local player finishes loading.

```lua
Bridge.OnPlayerLoaded(cb)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cb` | `function(playerData)` | Yes | Callback function |

```lua
Bridge.OnPlayerLoaded(function(playerData)
    print('I loaded! My job is: ' .. playerData.job.name)
end)
```

---

### Bridge.OnJobUpdate

Register a callback that fires when the local player's job changes.

```lua
Bridge.OnJobUpdate(cb)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cb` | `function(job)` | Yes | Callback receiving the new job table |

```lua
Bridge.OnJobUpdate(function(job)
    print('New job: ' .. job.name .. ' grade: ' .. job.grade)
end)
```

---

## Notify — Server

> **Module:** `modules/notify/shared.lua`
> **Side:** Server
> **Auto-detects:** ox_lib, ESX, QBCore, native GTA

---

### Bridge.Notify

Send a notification to a player from the server.

```lua
Bridge.Notify(source, message, type)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `message` | `string` | Yes | Notification text |
| `type` | `string` | Yes | `'success'`, `'error'`, `'info'`, or `'warning'` |

```lua
Bridge.Notify(source, 'Payment received!', 'success')
Bridge.Notify(source, 'Not enough money', 'error')
Bridge.Notify(source, 'Vehicle stored', 'info')
Bridge.Notify(source, 'License expired', 'warning')
```

---

## Notify — Client

> **Side:** Client

---

### Bridge.ShowNotification

Show a notification on the local client.

```lua
Bridge.ShowNotification(message, type)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | `string` | Yes | Notification text |
| `type` | `string` | No | `'success'`, `'error'`, `'info'`, or `'warning'`. Defaults to `'info'`. |

```lua
Bridge.ShowNotification('Item picked up', 'success')
```

**Detection priority:**
1. `ox_lib` — styled notification with title, description, type, 5000ms
2. ESX — `ESX.ShowNotification(message)`
3. QBCore — `QBCore.Functions.Notify(message, type, 5000)`
4. Native GTA — `SetNotificationTextEntry` / `DrawNotification`

---

## Inventory — Server

> **Module:** `modules/inventory/server.lua`
> **Side:** Server only
> **Auto-detects:** ox_inventory, qb-inventory, qs-inventory, framework default

---

### Bridge.AddItem

Add an item to a player's inventory.

```lua
Bridge.AddItem(source, item, count, metadata, slot)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `item` | `string` | Yes | Item name (e.g. `'water'`, `'weapon_pistol'`) |
| `count` | `number` | Yes | Amount to add (must be > 0) |
| `metadata` | `table\|string\|nil` | No | Item metadata (ox_inventory, QBCore) |
| `slot` | `number\|nil` | No | Target inventory slot |

**Returns:** `boolean` — `true` if item was added successfully.

```lua
Bridge.AddItem(source, 'bread', 3)
Bridge.AddItem(source, 'weapon_pistol', 1, { serial = 'ABC123' })
```

---

### Bridge.RemoveItem

Remove an item from a player's inventory.

```lua
Bridge.RemoveItem(source, item, count, metadata, slot)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `item` | `string` | Yes | Item name |
| `count` | `number` | Yes | Amount to remove (must be > 0) |
| `metadata` | `table\|string\|nil` | No | Item metadata to match |
| `slot` | `number\|nil` | No | Specific slot to remove from |

**Returns:** `boolean` — `true` if item was removed.

```lua
Bridge.RemoveItem(source, 'lockpick', 1)
```

---

### Bridge.HasItem

Check if a player has a specific item in sufficient quantity.

```lua
Bridge.HasItem(source, item, count)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `item` | `string` | Yes | Item name |
| `count` | `number\|nil` | No | Minimum quantity required. Defaults to `1`. |

**Returns:** `boolean` — `true` if player has at least `count` of the item.

```lua
if Bridge.HasItem(source, 'lockpick', 1) then
    Bridge.RemoveItem(source, 'lockpick', 1)
    -- proceed with lock picking
end
```

---

### Bridge.CanCarry

Check if a player can carry an item (weight/capacity check).

```lua
Bridge.CanCarry(source, item, count, metadata)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `item` | `string` | Yes | Item name |
| `count` | `number\|nil` | No | Quantity to check. Defaults to `1`. |
| `metadata` | `table\|string\|nil` | No | Item metadata (affects weight in ox_inventory) |

**Returns:** `boolean` — `true` if player can carry. Returns `true` by default for systems without weight checks.

```lua
if Bridge.CanCarry(source, 'water', 5) then
    Bridge.AddItem(source, 'water', 5)
end
```

---

### Bridge.RegisterStash

Register a stash container. Primarily used with ox_inventory.

```lua
Bridge.RegisterStash(stashId, label, jobName, coords)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `stashId` | `string` | Yes | Unique stash identifier |
| `label` | `string` | Yes | Display name |
| `jobName` | `string\|nil` | No | Restrict to job (creates group `{ [jobName] = 0 }`) |
| `coords` | `vector3\|nil` | No | Stash location |

```lua
Bridge.RegisterStash('police_evidence_1', 'Evidence Locker', 'police', vector3(440.0, -982.0, 30.0))
```

**Stash config priority:**
1. `Config.Stash.Slots` / `Config.Stash.MaxWeight` (consumer script)
2. `BridgeConfig.Stash.Slots` / `BridgeConfig.Stash.MaxWeight` (defaults: 50 / 100000)

> Calling this multiple times with the same `stashId` is safe — duplicates are ignored.

---

### Bridge.IsStashRegistered

Check if a stash has already been registered.

```lua
Bridge.IsStashRegistered(stashId)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `stashId` | `string` | Yes | Stash identifier |

**Returns:** `boolean`

---

### Bridge.ForceOpenStash

Force-open a stash inventory for a player from the server.

```lua
Bridge.ForceOpenStash(source, stashId)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `stashId` | `string` | Yes | Stash identifier (must be registered first) |

> Currently only supported with ox_inventory.

---

### Bridge.ForceOpenPlayerInventory

Force-open another player's inventory (e.g. for searching).

```lua
Bridge.ForceOpenPlayerInventory(source, targetServerId)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player who will see the inventory |
| `targetServerId` | `number` | Yes | Player whose inventory is opened |

**Returns:** `boolean` — `true` if successful.

```lua
-- Police searching a suspect
Bridge.ForceOpenPlayerInventory(officerSource, suspectSource)
```

**Supported systems:** ox_inventory, qb-inventory, qs-inventory.

---

### Bridge.GetAllItems

Get all registered items from the inventory system.

```lua
Bridge.GetAllItems()
```

**Returns:** `table` — Table of all item definitions. Structure depends on inventory system.

```lua
local items = Bridge.GetAllItems()
-- ox_inventory: returns exports.ox_inventory:Items()
-- QBCore: returns QBCore.Shared.Items
```

---

## Inventory — Client

> **Module:** `modules/inventory/client.lua`
> **Side:** Client only

---

### Bridge.OpenStash

Open a stash container UI on the client.

```lua
Bridge.OpenStash(stashId)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `stashId` | `string` | Yes | Stash identifier (must be registered on server) |

```lua
Bridge.OpenStash('police_evidence_1')
```

---

### Bridge.OpenPlayerInventory

Open another player's inventory on the client.

```lua
Bridge.OpenPlayerInventory(targetServerId)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `targetServerId` | `number` | Yes | Target player server ID |

---

### Bridge.GetItemCount

Get the count of a specific item in the local player's inventory.

```lua
Bridge.GetItemCount(item)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item` | `string` | Yes | Item name |

**Returns:** `number` — Item count. Returns `0` if not found.

```lua
local waterCount = Bridge.GetItemCount('water')
print('You have ' .. waterCount .. ' water bottles')
```

---

### Bridge.GetImagePath

Get the NUI image path pattern for the detected inventory system.

```lua
Bridge.GetImagePath()
```

**Returns:** `string` — Format string with `%s` placeholder for the item name.

```lua
local path = Bridge.GetImagePath()
-- "nui://ox_inventory/web/images/%s.png"

local waterImage = path:format('water')
-- "nui://ox_inventory/web/images/water.png"
```

**Paths per system:**
| System | Path |
|--------|------|
| ox_inventory | `nui://ox_inventory/web/images/%s.png` |
| qb-inventory | `nui://qb-inventory/html/images/%s.png` |
| ps-inventory | `nui://ps-inventory/html/images/%s.png` |
| lj-inventory | `nui://lj-inventory/html/images/%s.png` |
| qs-inventory | `nui://qs-inventory/html/images/%s.png` |
| origen_inventory | `nui://origen_inventory/ui/images/%s.png` |

---

## Vehicle — Shared

> **Module:** `modules/vehicle/shared.lua`
> **Side:** Both (client and server)

---

### Bridge.NormalizePlate

Trim trailing spaces from a GTA license plate. GTA pads plates to 8 characters with spaces.

```lua
Bridge.NormalizePlate(plate)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `plate` | `string\|nil` | Yes | Raw plate text |

**Returns:** `string` — Trimmed plate. Returns `''` if `nil`.

```lua
Bridge.NormalizePlate('ABC 123 ')  -- "ABC 123"
Bridge.NormalizePlate('ABCD1234')  -- "ABCD1234"
Bridge.NormalizePlate(nil)          -- ""
```

---

## Vehicle — Server

> **Side:** Server only

---

### Bridge.GeneratePlate

Generate a random 8-character license plate (uppercase letters + digits).

```lua
Bridge.GeneratePlate()
```

**Returns:** `string` — 8-character plate (e.g. `'X7KA92BF'`).

---

### Bridge.GiveVehicle

Give a vehicle to a player by inserting it into the framework's vehicle database.

```lua
Bridge.GiveVehicle(source, model, props)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |
| `model` | `string` | Yes | Vehicle model name (e.g. `'adder'`) |
| `props` | `table\|nil` | No | Vehicle properties to store |

**Returns:** `boolean` — `true` if inserted successfully.

```lua
Bridge.GiveVehicle(source, 'adder')
Bridge.GiveVehicle(source, 'sultan', { color1 = 1, color2 = 1 })
```

**Database tables used:**
| Framework | Table | Key columns |
|-----------|-------|-------------|
| ESX | `owned_vehicles` | `owner`, `plate`, `vehicle`, `type`, `stored` |
| QBCore | `player_vehicles` | `license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `state` |

> A random plate is auto-generated. The vehicle is inserted as `stored = 1` (in garage).

---

### Bridge.GetVehicleOwnerName

Look up the owner's character name from a license plate.

```lua
Bridge.GetVehicleOwnerName(plate)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `plate` | `string` | Yes | License plate to look up |

**Returns:** `string|nil` — Full name (e.g. `'John Doe'`), or `nil` if not found.

```lua
local owner = Bridge.GetVehicleOwnerName('ABC12345')
if owner then
    print('Vehicle owner: ' .. owner)
end
```

> Queries the vehicle table for the owner identifier, then resolves to character name via the users/players table.

---

## Vehicle — Client

> **Side:** Client only

---

### Bridge.ResolveModelHash

Convert a model name or string to a numeric hash.

```lua
Bridge.ResolveModelHash(model)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `model` | `string\|number` | Yes | Model name (`'adder'`), numeric string (`'418536135'`), or hash number |

**Returns:** `number` — Model hash.

```lua
Bridge.ResolveModelHash('adder')       -- returns GetHashKey('adder')
Bridge.ResolveModelHash('418536135')   -- returns 418536135 (number)
Bridge.ResolveModelHash(418536135)     -- returns 418536135 (passthrough)
```

---

### Bridge.SpawnVehicle

Spawn a vehicle entity at coordinates with optional properties and plate.

```lua
Bridge.SpawnVehicle(model, coords, heading, props, plate, cb)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `model` | `string\|number` | Yes | Model name or hash |
| `coords` | `vector3` | Yes | Spawn position |
| `heading` | `number` | Yes | Vehicle heading (0-360) |
| `props` | `table\|nil` | No | Vehicle properties to apply after spawn |
| `plate` | `string\|nil` | No | License plate to set |
| `cb` | `function\|nil` | No | Callback receiving `(vehicle)` or `(nil)` on failure |

```lua
Bridge.SpawnVehicle('adder', vector3(100.0, 200.0, 30.0), 90.0, nil, 'MYPLATE', function(vehicle)
    if vehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end
end)
```

> Has a 5-second timeout for model loading. Automatically calls `SetVehicleOnGroundProperly` and `SetEntityAsMissionEntity`.

---

### Bridge.GetVehicleProperties

Get all properties/mods from a vehicle entity. Wraps the framework function.

```lua
Bridge.GetVehicleProperties(vehicle)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `vehicle` | `number` | Yes | Vehicle entity handle |

**Returns:** `table` — Vehicle properties table (colors, mods, plate, etc.). Empty table `{}` if framework not detected.

```lua
local props = Bridge.GetVehicleProperties(vehicle)
-- Save props to database, transfer to another vehicle, etc.
```

---

### Bridge.SetVehicleProperties

Apply properties/mods to a vehicle entity. Wraps the framework function.

```lua
Bridge.SetVehicleProperties(vehicle, props)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `vehicle` | `number` | Yes | Vehicle entity handle |
| `props` | `table` | Yes | Properties table (from `GetVehicleProperties` or database) |

```lua
-- Restore a vehicle from saved properties
Bridge.SpawnVehicle(model, coords, heading, nil, nil, function(vehicle)
    if vehicle then
        Bridge.SetVehicleProperties(vehicle, savedProps)
    end
end)
```

---

### Bridge.GetVehicleLabel

Get the display name of a vehicle model.

```lua
Bridge.GetVehicleLabel(model)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `model` | `string\|number` | Yes | Model name or hash |

**Returns:** `string` — Display label (e.g. `'Adder'`, `'Sultan RS'`). Returns `'Unknown'` if not found.

```lua
Bridge.GetVehicleLabel('adder')    -- "Adder"
Bridge.GetVehicleLabel('sultan')   -- "Sultan"
```

---

## Callbacks — Server

> **Module:** `modules/callbacks/shared.lua`
> **Side:** Server

---

### Bridge.CreateCallback

Register a server callback that clients can invoke.

```lua
Bridge.CreateCallback(name, cb)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | `string` | Yes | Unique callback name. **Always namespace** with your resource: `'myresource:callbackName'` |
| `cb` | `function(source, respond, ...)` | Yes | Handler. Call `respond(...)` to send data back to client. |

```lua
Bridge.CreateCallback('nb-garages:getVehicles', function(source, respond, garageId)
    local identifier = Bridge.GetIdentifier(source)
    local vehicles = MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', { identifier })
    respond(vehicles)
end)

Bridge.CreateCallback('nb-actions:checkPermission', function(source, respond, action)
    local isAllowed = CheckPermission(source, action)
    respond(isAllowed)
end)
```

> If a client calls a callback name that doesn't exist, it receives `nil`.

---

## Callbacks — Client

> **Side:** Client

---

### Bridge.TriggerServerCallback

Call a registered server callback and receive the response.

```lua
Bridge.TriggerServerCallback(name, cb, ...)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | `string` | Yes | Callback name (must match a registered server callback) |
| `cb` | `function(...)` | Yes | Called with the server's response arguments |
| `...` | `any` | No | Additional arguments passed to the server handler |

```lua
Bridge.TriggerServerCallback('nb-garages:getVehicles', function(vehicles)
    if vehicles then
        for _, v in ipairs(vehicles) do
            print(v.plate)
        end
    end
end, garageId)
```

> Responses are matched by an auto-incrementing request ID. Multiple concurrent callbacks are safe.

---

## Licenses — Server

> **Module:** `modules/licenses/server.lua`
> **Side:** Server only
> **Auto-detects:** bcs_licensemanager, okokLicenses, esx_license, QBCore metadata, ESX default

---

### Bridge.GetIdentity

Get the full identity card of a player.

```lua
Bridge.GetIdentity(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `table|nil`

```lua
local id = Bridge.GetIdentity(source)
if id then
    print(id.firstname)  -- "John"
    print(id.lastname)   -- "Doe"
    print(id.dob)        -- "1990-01-15" (QBCore) or nil (ESX)
    print(id.sex)        -- "M" or "F" (QBCore) or nil (ESX)
end
```

**Return structure:**
| Field | Type | Description |
|-------|------|-------------|
| `firstname` | `string` | First name |
| `lastname` | `string` | Last name |
| `dob` | `string\|nil` | Date of birth (QBCore: `charinfo.birthdate`) |
| `sex` | `string\|nil` | `'M'` or `'F'` (QBCore: derived from `charinfo.gender`) |

---

### Bridge.GetDriverLicense

Check if a player has a driver license.

```lua
Bridge.GetDriverLicense(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `table`

| Field | Type | Description |
|-------|------|-------------|
| `hasLicense` | `boolean` | Whether the player has a driver license |
| `label` | `string` | License label/name (e.g. `'Driver License'`, `'driver_car'`). Empty string if no license. |

```lua
local driver = Bridge.GetDriverLicense(source)
if driver.hasLicense then
    print('Has license: ' .. driver.label)
else
    print('No driver license')
end
```

**Detection per system:**
| System | How it checks |
|--------|---------------|
| bcs_licensemanager | Checks: `driver_car`, `driver_bike`, `driver_truck`, `driver_helicopter`, `driver_boat`, `driver_plane` |
| okokLicenses | `exports.okokLicenses:getLicense(source, 'driver')` |
| esx_license / esx_default | `xPlayer.getLicenses()` — looks for type `'drive'`, `'driver'`, or `'dmv'` |
| qbcore | `PlayerData.metadata.licences.driver` |

---

### Bridge.GetWeaponLicense

Check if a player has a weapon/firearms license.

```lua
Bridge.GetWeaponLicense(source)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `number` | Yes | Player server ID |

**Returns:** `table`

| Field | Type | Description |
|-------|------|-------------|
| `hasLicense` | `boolean` | Whether the player has a weapon license |
| `label` | `string` | License label. Empty string if no license. |

```lua
local weapon = Bridge.GetWeaponLicense(source)
if not weapon.hasLicense then
    Bridge.Notify(source, 'You need a weapon license!', 'error')
end
```

**Detection per system:**
| System | How it checks |
|--------|---------------|
| bcs_licensemanager | Checks: `weapon` |
| okokLicenses | `exports.okokLicenses:getLicense(source, 'weapon')` |
| esx_license / esx_default | `xPlayer.getLicenses()` — looks for type `'weapon'` or `'firearms'` |
| qbcore | `PlayerData.metadata.licences.weapon` |

---

## Progress — Client

> **Module:** `modules/progress/client.lua`
> **Side:** Client only
> **Auto-detects:** ox_lib, native GTA fallback

---

### Bridge.Progress

Show a blocking progress bar. The function waits until the progress completes or is cancelled.

```lua
Bridge.Progress(duration, label, anim)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `duration` | `number` | Yes | Duration in **milliseconds** |
| `label` | `string` | Yes | Text displayed on the progress bar |
| `anim` | `table\|nil` | No | Animation to play: `{ dict = 'anim_dict', name = 'anim_name' }` |

**Returns:** `boolean` — `true` if completed normally, `false` if cancelled (ox_lib only).

```lua
-- Simple progress
local done = Bridge.Progress(5000, 'Searching vehicle...')
if done then
    print('Search complete')
end

-- With animation
local done = Bridge.Progress(3000, 'Repairing engine...', {
    dict = 'mini@repair',
    name = 'fixing_a_player',
})
if done then
    print('Repair complete')
end
```

**Behavior per system:**
| System | Features |
|--------|----------|
| ox_lib | Full progress bar UI, cancellable, disables movement + vehicle control |
| Native fallback | Plays animation (if provided), waits duration, **not cancellable** (always returns `true`) |

> Animation dict is auto-loaded with a 5-second timeout. After progress ends, `ClearPedTasks` is called to stop the animation.

---

*Neenbyss Studios — nb-bridge v1.0.0*
