# nb-bridge Exports — v2.0.0

nb-bridge exposes a **single export**: `get()`.

```lua
local bridge = exports['nb-bridge']:get()
```

This returns the global `Bridge` table, which contains all namespaced methods. Call `get()` once at the top of each script file that needs the bridge.

---

## The get() Export

```lua
exports['nb-bridge']:get()
```

**Returns:** `table` — The `Bridge` table with all namespaces populated.

**Side:** Both client and server.

**When to call:** At file load time, before any method calls. nb-bridge must be started first (declare `dependency 'nb-bridge'` in your fxmanifest.lua).

```lua
-- server.lua
local bridge = exports['nb-bridge']:get()

AddEventHandler('playerConnecting', function(name)
    -- bridge is ready to use here
end)

-- client.lua
local bridge = exports['nb-bridge']:get()

CreateThread(function()
    bridge.player.onPlayerLoaded(function()
        local job = bridge.player.getJob()
        print('Job: ' .. job.name)
    end)
end)
```

---

## What get() Returns

The table has the following top-level namespaces:

| Namespace | Side | Contents |
|-----------|------|----------|
| `bridge.player` | Server + Client | Player, money, jobs, gangs, permissions, events |
| `bridge.inventory` | Server + Client | Items, stashes, usable items |
| `bridge.vehicle` | Server + Client | Plate tools, spawning, properties |
| `bridge.notify` | Server + Client | Notifications |
| `bridge.callback` | Server + Client | Server callbacks |
| `bridge.license` | Server only | Identity and license checks |
| `bridge.progress` | Client only | Progress bars |

Plus global properties on `Bridge` directly:

| Property | Type | Description |
|----------|------|-------------|
| `Bridge.Framework` | `string` | `'ESX'`, `'QBCore'`, or `'QBX'` |
| `Bridge.FrameworkObject` | `table` | Raw framework shared object |
| `Bridge.InventorySystem` | `string\|nil` | Active inventory system (set ~500ms after boot) |

---

## Removed in v2.0.0

In v1.x, every function was exported individually:

```lua
-- v1.x — NO LONGER VALID
exports['nb-bridge']:GetJob(source)
exports['nb-bridge']:AddMoney(source, 'bank', 500)
exports['nb-bridge']:Notify(source, 'Hello', 'info')
```

These per-method exports are gone. There is only `get()` now. Update any external scripts that were calling nb-bridge exports directly:

```lua
-- v2.0.0
local bridge = exports['nb-bridge']:get()
bridge.player.getJob(source)
bridge.player.addMoney(source, 'bank', 500)
bridge.notify.send(source, 'Hello', 'info')
```

---

## fxmanifest.lua Setup

```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

dependencies {
    'oxmysql',
    'nb-bridge',
}

-- No shared_scripts line for nb-bridge needed.
-- The dependency declaration is sufficient.
```

In `server.cfg`, `ensure nb-bridge` must appear after your framework and before this resource.

---

## Full Method List by Namespace

For complete signatures, parameters, and examples see [api.md](api.md).

### bridge.player.* — Server

`getPlayer`, `getIdentifier`, `getSSN`, `getPlayerName`, `getGroup`, `setGroup`, `isAdmin`, `getMoney`, `addMoney`, `removeMoney`, `setMoney`, `getAccounts`, `getJob`, `setJob`, `getGang`, `setGang`, `getAllPlayers`, `getPlayTime`, `getCoords`, `setCoords`, `triggerClientEvent`, `playerVar`, `getMeta`, `setMeta`, `clearMeta`, `executeCommand`, `registerCommand`, `createBill`, `onPlayerLoaded`, `onPlayerUnloaded`

### bridge.player.* — Client

`getPlayerData`, `getJob`, `getGang`, `getMoney`, `getAccounts`, `getIdentifier`, `getPlayerName`, `getGroup`, `onPlayerLoaded`, `onPlayerUnloaded`, `onJobUpdate`, `onGangUpdate`

### bridge.inventory.* — Server

`addItem`, `removeItem`, `hasItem`, `canCarry`, `getItemMetadata`, `getAllItems`, `registerStash`, `isStashRegistered`, `forceOpenStash`, `forceOpenPlayerInventory`, `registerUsableItem`, `isUsableItemRegistered`

### bridge.inventory.* — Client

`openStash`, `openPlayerInventory`, `getItemCount`, `getImagePath`

### bridge.vehicle.* — Shared

`normalizePlate`

### bridge.vehicle.* — Server

`generatePlate`, `giveVehicle`, `getVehicleOwnerName`

### bridge.vehicle.* — Client

`resolveModelHash`, `spawnVehicle`, `getVehicleProperties`, `setVehicleProperties`, `getVehicleLabel`

### bridge.notify.* — Server

`send`

### bridge.notify.* — Client

`show`

### bridge.callback.* — Server

`register`

### bridge.callback.* — Client

`trigger`

### bridge.license.* — Server

`getIdentity`, `getDriverLicense`, `getWeaponLicense`

### bridge.progress.* — Client

`show`

---

*Neenbyss Studios — nb-bridge v2.0.0*
