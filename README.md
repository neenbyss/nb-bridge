# nb-bridge

Centralized framework abstraction layer for FiveM (Lua 5.4). Provides a single unified API across ESX Legacy, QBCore, and QBX (qbx_core) — covering players, money, jobs, gangs, inventory, vehicles, notifications, callbacks, licenses, and progress bars.

---

## Supported Frameworks

| Framework | Resource | Minimum |
|-----------|----------|---------|
| ESX Legacy | `es_extended` | any modern version |
| QBCore | `qb-core` | any modern version |
| QBX | `qbx_core` | any modern version |

Detection order at boot: **QBX → ESX → QBCore**. QBX is checked first because qbx_core also exposes a `qb-core` compatibility bridge that would otherwise cause a false positive.

---

## Supported Inventory Systems

| System | Resource | Notes |
|--------|----------|-------|
| `ox_inventory` | `ox_inventory` | Full support including per-slot metadata |
| `qb-inventory` | `qb-inventory` | Full support |
| `qs-inventory` | `qs-inventory` | Full support |
| `origen_inventory` | `origen_inventory` | Full support; image path defaults to v2 layout |
| `default` | — | Falls back to framework item API |

Auto-detected at startup (~500 ms after boot). Do not read `Bridge.InventorySystem` at file-load time.

---

## Installation

1. Place the `nb-bridge` folder inside your server's `resources/` directory (or a subdirectory of it).
2. In `server.cfg`, ensure nb-bridge **after** your framework and **before** any consumer resource:

```cfg
ensure oxmysql
ensure es_extended      # or qb-core / qbx_core
ensure nb-bridge
ensure nb-garages
ensure nb-actions
# ... other nb-* resources
```

3. In each consumer resource's `fxmanifest.lua`, declare the dependency:

```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

dependencies {
    'oxmysql',
    'nb-bridge',
}
```

---

## Basic Usage

The only public export is `get()`. Call it once at the top of each script file that needs the bridge:

```lua
local bridge = exports['nb-bridge']:get()

-- Server example
RegisterNetEvent('myresource:buyItem', function(item, price)
    local src = source
    if bridge.player.getMoney(src, 'bank') < price then
        bridge.notify.send(src, 'Not enough money', 'error')
        return
    end
    bridge.player.removeMoney(src, 'bank', price, 'item_purchase')
    bridge.inventory.addItem(src, item, 1)
    bridge.notify.send(src, 'Purchase complete', 'success')
end)

-- Client example
local bridge = exports['nb-bridge']:get()

bridge.player.onPlayerLoaded(function()
    local job = bridge.player.getJob()
    print('Loaded as: ' .. job.name)
end)
```

---

## Global Properties

Available on both client and server after nb-bridge starts.

| Property | Type | Value |
|----------|------|-------|
| `Bridge.Framework` | `string` | `'ESX'`, `'QBCore'`, or `'QBX'` |
| `Bridge.FrameworkObject` | `table` | Raw framework shared object |
| `Bridge.InventorySystem` | `string\|nil` | Set ~500ms after boot |

`Bridge` is the global table. `local bridge = exports['nb-bridge']:get()` returns the same table. Either reference works after the export call.

---

## Debugger Utility

A global function available everywhere after nb-bridge loads. Tables are auto-encoded to JSON.

```lua
Debugger('ModuleName', 'message', value1, value2)
-- Output: [nb-bridge][SERVER][ModuleName] message value1 value2
```

Enabled when `BridgeConfig.Debug == true` or the consumer's `Config.Debug == true`.

---

## API Reference

Full signatures and parameter tables are in [docs/api.md](docs/api.md). Below is the namespace overview.

### bridge.player.* — Server

| Method | Returns | Notes |
|--------|---------|-------|
| `getPlayer(source)` | `table\|nil` | Raw framework player object |
| `getIdentifier(source)` | `string\|nil` | License (ESX) or citizenid (QBCore/QBX) |
| `getSSN(source)` | `string\|nil` | ESX only |
| `getPlayerName(source)` | `string` | Character full name |
| `getGroup(source)` | `string` | Permission group |
| `setGroup(source, group)` | `boolean` | ESX only; returns `false` on QBCore/QBX |
| `isAdmin(source)` | `boolean` | Checks against AdminGroups config |
| `getMoney(source, type)` | `number` | `type`: `'cash'` or `'bank'` |
| `addMoney(source, type, amount, reason?)` | `boolean` | |
| `removeMoney(source, type, amount, reason?)` | `boolean` | ESX pre-checks balance |
| `setMoney(source, type, amount, reason?)` | `boolean` | |
| `getAccounts(source)` | `table` | `{cash=n, bank=n, ...}` |
| `getJob(source)` | `table\|nil` | Canonical job table |
| `setJob(source, job, grade, onDuty?)` | `boolean` | |
| `getGang(source)` | `table\|nil` | QBCore/QBX only |
| `setGang(source, gangName, grade)` | `boolean` | QBCore/QBX only |
| `getAllPlayers()` | `number[]` | Online source IDs |
| `getPlayTime(source)` | `number\|nil` | Seconds; ESX only |
| `getCoords(source)` | `vector3\|nil` | |
| `setCoords(source, coords)` | `boolean` | |
| `triggerClientEvent(source, event, ...)` | — | |
| `playerVar(source, key, value?)` | `any\|nil` | ESX only |
| `getMeta(source, index?, subIndex?)` | `any` | |
| `setMeta(source, index, value, subIndex?)` | `boolean` | |
| `clearMeta(source, index, subIndex?)` | `boolean` | |
| `executeCommand(source, command)` | `boolean` | ESX only |
| `registerCommand(name, group?, cb, suggestion?)` | — | ACE-gated on QBCore/QBX |
| `createBill(src, targetId, amount, desc?, jobName?)` | `boolean` | Auto-detects billing system |
| `onPlayerLoaded(cb)` | — | `cb(source, identifier)` |
| `onPlayerUnloaded(cb)` | — | `cb(source)`; QBX debounces double-fire |

### bridge.player.* — Client

| Method | Returns | Notes |
|--------|---------|-------|
| `getPlayerData()` | `table\|nil` | Raw framework player data |
| `getJob()` | `table\|nil` | Canonical job table |
| `getGang()` | `table\|nil` | QBCore/QBX only |
| `getMoney(type)` | `number` | |
| `getAccounts()` | `table` | |
| `getIdentifier()` | `string\|nil` | |
| `getPlayerName()` | `string` | |
| `getGroup()` | `string` | Informational; use server-side for secure checks |
| `onPlayerLoaded(cb)` | — | `cb()` — use getters inside |
| `onPlayerUnloaded(cb)` | — | `cb()` |
| `onJobUpdate(cb)` | — | `cb(job)` normalized job table |
| `onGangUpdate(cb)` | — | `cb(gang)` QBCore/QBX only |

Canonical job table shape:

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

### bridge.inventory.* — Server

| Method | Returns | Notes |
|--------|---------|-------|
| `addItem(source, item, count, metadata?, slot?)` | `boolean` | |
| `removeItem(source, item, count, metadata?, slot?)` | `boolean` | |
| `hasItem(source, item, count?)` | `boolean` | Default count: 1 |
| `canCarry(source, item, count?, metadata?)` | `boolean` | Returns `true` for systems without weight |
| `getItemMetadata(source, itemName)` | `table\|nil` | ox_inventory only |
| `getAllItems()` | `table` | Item definitions from active system |
| `registerStash(stashId, label, jobName?, coords?)` | — | Idempotent |
| `isStashRegistered(stashId)` | `boolean` | |
| `forceOpenStash(source, stashId)` | — | |
| `forceOpenPlayerInventory(source, targetServerId)` | `boolean` | |
| `registerUsableItem(itemName, cb)` | `boolean` | `cb(source, {name, slot?})` |
| `isUsableItemRegistered(itemName)` | `boolean` | |

### bridge.inventory.* — Client

| Method | Returns | Notes |
|--------|---------|-------|
| `openStash(stashId)` | — | |
| `openPlayerInventory(targetServerId)` | — | |
| `getItemCount(item)` | `number` | |
| `getImagePath()` | `string` | Format string: `path:format('itemname')` |

### bridge.vehicle.* — Shared (both sides)

| Method | Returns | Notes |
|--------|---------|-------|
| `normalizePlate(plate)` | `string` | Trims trailing GTA padding spaces |

### bridge.vehicle.* — Server

| Method | Returns | Notes |
|--------|---------|-------|
| `generatePlate()` | `string` | Random 8-char plate |
| `giveVehicle(source, model, props?)` | `boolean` | Inserts into framework DB |
| `getVehicleOwnerName(plate)` | `string\|nil` | DB lookup → character name |

### bridge.vehicle.* — Client

| Method | Returns | Notes |
|--------|---------|-------|
| `resolveModelHash(model)` | `number` | Accepts string, numeric string, or number |
| `spawnVehicle(model, coords, heading, props?, plate?, cb?)` | `number\|false` | 5s model-load timeout |
| `getVehicleProperties(vehicle)` | `table` | Wraps ox_lib / framework function |
| `setVehicleProperties(vehicle, props)` | — | |
| `getVehicleLabel(model)` | `string` | Returns `'Unknown'` if not found |

### bridge.notify.* — Server

| Method | Notes |
|--------|-------|
| `send(source, message, type)` | Types: `'success'` `'error'` `'info'` `'warning'` |

### bridge.notify.* — Client

| Method | Notes |
|--------|-------|
| `show(message, type)` | Auto-detects: ox_lib → ESX → QBCore → GTA native |

### bridge.callback.* — Server

| Method | Notes |
|--------|-------|
| `register(name, cb)` | `cb(source, respond, ...)` — call `respond(...)` to reply |

### bridge.callback.* — Client

| Method | Notes |
|--------|-------|
| `trigger(name, cb, ...)` | `cb(...)` receives server response; 15s timeout → `cb(nil)` |

Always namespace callback names with your resource: `'nb-garages:getVehicles'`.

### bridge.license.* — Server only

| Method | Returns | Notes |
|--------|---------|-------|
| `getIdentity(source)` | `table\|nil` | `{firstname, lastname, dob?, sex?}` |
| `getDriverLicense(source)` | `table` | `{hasLicense, label}` |
| `getWeaponLicense(source)` | `table` | `{hasLicense, label}` |

Auto-detects: `bcs_licensemanager` → `okokLicenses` → `esx_license` → `esx_default` → `qbcore`.

### bridge.progress.* — Client only

| Method | Returns | Notes |
|--------|---------|-------|
| `show(duration, label, anim?)` | `boolean` | `true` = completed, `false` = cancelled (ox_lib only) |

`anim`: `{ dict = string, name = string }`

---

## Configuration (BridgeConfig)

Defined in `config.lua`. Consumer scripts can override via their own `Config` table — most bridge functions check the consumer's `Config` first.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `BridgeConfig.Debug` | `boolean` | `false` | Enable debug prints |
| `BridgeConfig.AdminGroups` | `string[]` | `{'admin','superadmin','god'}` | Groups treated as admin |
| `BridgeConfig.Stash.Slots` | `number` | `50` | Default stash slot count |
| `BridgeConfig.Stash.MaxWeight` | `number` | `100000` | Default stash max weight |
| `BridgeConfig.InventoryImagePaths` | `table` | See config.lua | NUI image paths per inventory system |
| `BridgeConfig.GroupMap` | `table\|nil` | See server.lua | ACE → group name mapping for QBCore/QBX |

Config priority:

| Behavior | Reads first | Falls back to |
|----------|-------------|---------------|
| Admin check | `Config.AdminGroups` | `BridgeConfig.AdminGroups` |
| Stash size | `Config.Stash` | `BridgeConfig.Stash` |
| Debug output | `Config.Debug` | `BridgeConfig.Debug` |
| Image paths | `Config.InventoryImagePaths` | `BridgeConfig.InventoryImagePaths` |

### origen_inventory v1 override

origen_inventory ships in two NUI layouts. The default image path targets v2 (`ui/images/`). If your server runs the legacy v1 build (`html/images/`), add this to your consumer script's `Config`:

```lua
Config.InventoryImagePaths = {
    origen_inventory = 'nui://origen_inventory/html/images/%s.png',
}
```

---

## Overrides

Drop `.lua` files into `overrides/client/` or `overrides/server/` to replace any bridge function without editing the core. Override files load after all modules.

```lua
-- overrides/server/custom_notify.lua
function Bridge.notify.send(source, message, type)
    exports['mythic_notify']:DoHudText(type, message)
end
```

---

## Migration from v1.x

See [docs/migration-v1-to-v2.md](docs/migration-v1-to-v2.md) for the full equivalence table and step-by-step guide.

**Quick summary of breaking changes in v2.0.0:**

- All flat `Bridge.Fn()` calls are gone. Use `bridge.namespace.method()`.
- The consumer API changed: use `local bridge = exports['nb-bridge']:get()` instead of `shared_scripts { '@nb-bridge/loader.lua' }`.
- No per-method exports (`exports['nb-bridge']:GetJob`). The only export is `get()`.
- Method names are now camelCase: `addMoney`, `getJob`, `spawnVehicle`.
- QBX (qbx_core) is now a first-class supported framework.

---

## Known Limitations

| Limitation | Details |
|-----------|---------|
| `bridge.player.addMoney` on ESX | ESX Legacy's `addAccountMoney` has no return value. The bridge returns `true` whenever the player object is found, regardless of whether the operation actually succeeded internally. |
| `bridge.player.onPlayerUnloaded` on QBX | Two events (`QBCore:Server:OnPlayerUnload` and `qbx_core:server:playerLoggedOut`) can fire for the same player on a clean logout. The bridge debounces within a 1-second window so the callback fires at most once. |
| `bridge.inventory.getItemMetadata` | Only supported on `ox_inventory`. Returns `nil` on all other inventory systems. |
| `bridge.player.getSSN` | ESX only. Returns `nil` on QBCore and QBX. |
| `bridge.player.setGroup` | ESX only. Returns `false` on QBCore and QBX. |
| `bridge.player.getPlayTime` | ESX only. Returns `nil` on QBCore and QBX. |
| `bridge.player.executeCommand` | ESX only. Returns `false` on QBCore and QBX. |
| `bridge.player.playerVar` | ESX only. Returns `nil` on QBCore and QBX. |
| `bridge.player.getGang` / `setGang` | QBCore and QBX only. Returns `nil`/`false` on ESX. |
| `bridge.inventory.canCarry` | `qb-inventory` and framework defaults do not expose weight checks. Returns `true` by default for those systems. |
| `Bridge.InventorySystem` | Set ~500 ms after boot. Do not read at file-load time; use it inside callbacks or after startup. |

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `No compatible framework detected` | Framework not running or started after nb-bridge | Ensure framework ensures before nb-bridge in server.cfg |
| `bridge` is nil | `exports['nb-bridge']:get()` called before nb-bridge starts | Declare `dependency 'nb-bridge'` in your fxmanifest.lua |
| Notifications not showing | ox_lib detection delay (500ms) | Normal on first tick; works after the detection thread fires |
| Inventory functions return `false` | Inventory system not yet detected | The synchronous fallback handles most cases; if it still fails, verify the inventory resource is running |
| Callback never fires | Name mismatch between `register` and `trigger` | Names must match exactly, including namespace prefix |
| `Bridge.InventorySystem` is `nil` | Read too early (before 500ms detection) | Move the read inside an event handler or `CreateThread` with a brief `Wait` |

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

*Neenbyss Studios — nb-bridge v2.0.0*
