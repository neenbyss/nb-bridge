# NB-Bridge

Centralized framework abstraction layer for all NB resources. Provides a unified API to interact with ESX, QBCore, inventory systems, notifications, vehicles, licenses, and more — from a single dependency.

**Compatible with:** ESX / QBCore
**Lua version:** 5.4

---

## Table of Contents

- [Why nb-bridge?](#why-nb-bridge)
- [Installation](#installation)
- [File Structure](#file-structure)
- [Dependencies](#dependencies)
- [Modules](#modules)
  - [Framework](#framework)
  - [Notify](#notify)
  - [Inventory](#inventory)
  - [Vehicle](#vehicle)
  - [Callbacks](#callbacks)
  - [Licenses](#licenses)
  - [Progress](#progress)
- [Configuration](#configuration)
- [Using nb-bridge in your script](#using-nb-bridge-in-your-script)
- [Exports (for third-party scripts)](#exports)
- [Overrides (customization)](#overrides)
- [Migration Guide](#migration-guide)
- [Troubleshooting](#troubleshooting)

---

## Why nb-bridge?

Before nb-bridge, every NB resource shipped its own `bridge/` folder with duplicated code for framework detection, notifications, inventory, etc. This caused:

- **Inconsistencies** when one script was updated but others weren't
- **Maintenance overhead** — fixing a bug meant patching 7+ scripts
- **Wasted disk space** — the same 500+ lines copied everywhere

Now, all NB resources depend on a single `nb-bridge` resource. One update benefits every script.

---

## Installation

1. Place the `nb-bridge` folder in your server's `resources/` directory
2. Add `ensure nb-bridge` to your `server.cfg` **before** any `nb-*` resource
3. Done. All NB resources will automatically use the global `Bridge` table

```cfg
# server.cfg
ensure oxmysql
ensure es_extended   # or qb-core
ensure nb-bridge     # MUST be before any nb-* resource
ensure nb-garages
ensure nb-actions
# ... etc
```

---

## File Structure

```
nb-bridge/
├── fxmanifest.lua
├── config.lua                        # Default configuration
├── shared/
│   └── init.lua                      # Bridge table, framework detection, Debugger()
├── modules/
│   ├── framework/
│   │   ├── server.lua                # Player management, money, jobs, permissions
│   │   └── client.lua                # Player data, events
│   ├── notify/
│   │   └── shared.lua                # Notifications (server + client)
│   ├── inventory/
│   │   ├── server.lua                # Items, stashes
│   │   └── client.lua                # Open stash, item count
│   ├── vehicle/
│   │   └── shared.lua                # Plates, spawning, properties
│   ├── callbacks/
│   │   └── shared.lua                # Server callbacks system
│   ├── licenses/
│   │   └── server.lua                # Identity, driver/weapon licenses
│   └── progress/
│       └── client.lua                # Progress bars
└── overrides/
    ├── client/                       # Drop client-side overrides here
    ├── server/                       # Drop server-side overrides here
    └── _README.lua                   # Instructions
```

---

## Dependencies

| Resource | Required | Notes |
|----------|----------|-------|
| `es_extended` or `qb-core` | Yes | Auto-detected at startup |
| `oxmysql` | Yes | For vehicle DB operations |
| `ox_lib` | No | Enhanced notifications and progress bars |
| `ox_inventory` | No | One of the supported inventory systems |
| `qb-inventory` | No | Alternative inventory system |
| `qs-inventory` | No | Alternative inventory system |

---

## Modules

### Framework

Auto-detects ESX or QBCore and provides a unified player management API.

#### Server Functions

```lua
-- Player
Bridge.GetPlayer(source)              -- Get xPlayer (ESX) or Player (QBCore) object
Bridge.GetIdentifier(source)          -- Get license (ESX) or citizenid (QBCore)
Bridge.GetSSN(source)                 -- Get SSN (ESX only)
Bridge.GetPlayerName(source)          -- Get character full name

-- Permissions
Bridge.GetGroup(source)               -- Get permission group ('admin', 'user', etc.)
Bridge.SetGroup(source, group)        -- Set group (ESX only)
Bridge.IsAdmin(source)                -- Check if admin (uses Config.AdminGroups)

-- Money
Bridge.AddMoney(source, type, amount, reason)     -- type: 'cash' or 'bank'
Bridge.RemoveMoney(source, type, amount, reason)
Bridge.SetMoney(source, type, amount, reason)
Bridge.GetMoney(source, type)                      -- Returns number
Bridge.GetAccounts(source, minimal)                -- All accounts (ESX only)

-- Job
Bridge.GetJob(source)                 -- Returns {name, label, grade, grade_name, ...}
Bridge.SetJob(source, job, grade, onDuty)
Bridge.GetGang(source)                -- QBCore only

-- Events
Bridge.OnPlayerLoaded(cb)             -- cb(source, identifier) on player login

-- ESX Utilities (return nil on QBCore)
Bridge.GetPlayTime(source)            -- Seconds played
Bridge.SetCoords(source, coords)      -- Teleport
Bridge.GetCoords(source, asVector)    -- Get position
Bridge.TriggerClientEvent(source, event, ...)
Bridge.PlayerVar(source, key, value)  -- Get/set xPlayer variables
Bridge.SetMeta(source, index, value, subIndex)
Bridge.GetMeta(source, index, subIndex)
Bridge.ClearMeta(source, index, subIndex)
Bridge.ExecuteCommand(source, command)

-- Billing
Bridge.CreateBill(src, targetId, amount, desc, jobName)
```

#### Client Functions

```lua
Bridge.GetPlayerData()                -- Get local player data
Bridge.OnPlayerLoaded(cb)             -- cb(playerData) when player loads
Bridge.OnJobUpdate(cb)                -- cb(job) when job changes
```

#### Examples

```lua
-- Server: Give money and notify
RegisterCommand('givemoney', function(source)
    local name = Bridge.GetPlayerName(source)
    Bridge.AddMoney(source, 'bank', 5000, 'bonus')
    Bridge.Notify(source, 'You received $5,000!', 'success')
    print(name .. ' received a bonus')
end)

-- Server: Check if player is police
RegisterCommand('checkjob', function(source)
    local job = Bridge.GetJob(source)
    if job and job.name == 'police' then
        print('Player is police, grade: ' .. job.grade)
    end
end)

-- Client: React to job change
Bridge.OnJobUpdate(function(job)
    print('New job: ' .. job.name)
end)
```

---

### Notify

Unified notification system. Auto-detects ox_lib, ESX, QBCore, or falls back to GTA native.

```lua
-- Server: send notification to a player
Bridge.Notify(source, 'Invoice paid!', 'success')
Bridge.Notify(source, 'Not enough money', 'error')

-- Client: show local notification
Bridge.ShowNotification('Item received', 'info')
```

**Supported types:** `'success'`, `'error'`, `'info'`, `'warning'`

---

### Inventory

Multi-inventory abstraction. Auto-detects ox_inventory, qb-inventory, qs-inventory, or framework defaults.

#### Server Functions

```lua
-- Item management
Bridge.AddItem(source, 'water', 3)                     -- Add 3 water bottles
Bridge.AddItem(source, 'weapon_pistol', 1, metadata)   -- With metadata
Bridge.RemoveItem(source, 'bread', 1)
Bridge.HasItem(source, 'lockpick', 1)                   -- Returns boolean
Bridge.CanCarry(source, 'water', 5)                      -- Weight check

-- Stash management
Bridge.RegisterStash('police_evidence', 'Evidence Locker', 'police')
Bridge.IsStashRegistered('police_evidence')              -- Returns boolean
Bridge.ForceOpenStash(source, 'police_evidence')

-- Player inventory
Bridge.ForceOpenPlayerInventory(source, targetServerId)

-- All items
Bridge.GetAllItems()                                     -- Returns all registered items
```

#### Client Functions

```lua
Bridge.OpenStash('police_evidence')
Bridge.OpenPlayerInventory(targetServerId)
Bridge.GetItemCount('water')                             -- Returns number
Bridge.GetImagePath()                                    -- Returns NUI image path pattern
```

---

### Vehicle

Vehicle utilities for plates, spawning, properties, and database insertion.

#### Shared

```lua
Bridge.NormalizePlate('ABC 123 ')   -- Returns 'ABC 123'
```

#### Server

```lua
Bridge.GeneratePlate()                          -- Returns random 8-char plate
Bridge.GiveVehicle(source, 'adder', props)      -- Insert into player's owned vehicles
Bridge.GetVehicleOwnerName('ABC12345')          -- Returns 'John Doe' or nil
```

#### Client

```lua
Bridge.ResolveModelHash('adder')                -- Returns hash number

Bridge.SpawnVehicle('adder', coords, heading, props, plate, function(vehicle)
    if vehicle then
        print('Spawned vehicle: ' .. vehicle)
    end
end)

local props = Bridge.GetVehicleProperties(vehicle)
Bridge.SetVehicleProperties(vehicle, props)

Bridge.GetVehicleLabel('adder')                 -- Returns 'Adder'
```

---

### Callbacks

Simple request/response system between client and server without needing exports.

> **Important:** Always namespace your callback names with your resource name to avoid collisions.

#### Server

```lua
-- Register a callback
Bridge.CreateCallback('nb-garages:getVehicles', function(source, respond, garageId)
    local vehicles = GetVehiclesForPlayer(source, garageId)
    respond(vehicles)
end)
```

#### Client

```lua
-- Call the server callback
Bridge.TriggerServerCallback('nb-garages:getVehicles', function(vehicles)
    print('Got ' .. #vehicles .. ' vehicles')
end, garageId)
```

---

### Licenses

Server-only. Retrieves player identity and license data. Auto-detects: bcs_licensemanager, okokLicenses, esx_license, QBCore metadata, ESX default.

```lua
-- Get player identity card
local identity = Bridge.GetIdentity(source)
-- Returns: { firstname = 'John', lastname = 'Doe', dob = '1990-01-15', sex = 'M' }

-- Check driver license
local driver = Bridge.GetDriverLicense(source)
-- Returns: { hasLicense = true, label = 'Driver License' }

-- Check weapon license
local weapon = Bridge.GetWeaponLicense(source)
-- Returns: { hasLicense = false, label = '' }
```

---

### Progress

Client-only progress bar. Uses ox_lib if available, otherwise falls back to native GTA animation.

```lua
-- Simple progress bar
local completed = Bridge.Progress(5000, 'Searching...')
if completed then
    print('Search complete')
end

-- With animation
local completed = Bridge.Progress(3000, 'Repairing...', {
    dict = 'mini@repair',
    name = 'fixing_a_player',
})
```

**Returns:** `true` if completed, `false` if cancelled (ox_lib only supports cancellation).

---

## Configuration

`config.lua` provides default values. Consumer scripts can override these through their own `Config` table.

```lua
BridgeConfig = {
    Debug = false,                    -- Enable debug prints

    AdminGroups = {                   -- Used when consumer has no Config.AdminGroups
        'admin', 'superadmin', 'god'
    },

    Stash = {                         -- Default stash settings
        Slots = 50,
        MaxWeight = 100000,
    },

    InventoryImagePaths = {           -- NUI image paths per inventory system
        ox_inventory = 'nui://ox_inventory/web/images/%s.png',
        -- ... etc
    },
}
```

### Config priority

Most Bridge functions check the **consumer script's** `Config` first, then fall back to `BridgeConfig`:

| Function | Checks | Then falls back to |
|----------|--------|--------------------|
| `Bridge.IsAdmin()` | `Config.AdminGroups` | `BridgeConfig.AdminGroups` |
| `Bridge.RegisterStash()` | `Config.Stash` | `BridgeConfig.Stash` |
| `Debugger()` | `Config.Debug` | `BridgeConfig.Debug` |

---

## Using nb-bridge in your script

### Step 1: Add dependency

In your script's `fxmanifest.lua`:

```lua
dependencies {
    'oxmysql',
    'nb-bridge',
}
```

### Step 2: Remove old bridge files

Delete these from your `fxmanifest.lua` and optionally from disk:

```lua
-- REMOVE these lines:
'shared/debugger.lua',
'bridge/framework.lua',
'bridge/notify.lua',
'bridge/inventory.lua',
'bridge/vehicle.lua',
'bridge/callbacks.lua',
'bridge/licenses.lua',
'bridge/progress.lua',
```

### Step 3: Use the Bridge table

No code changes needed. The global `Bridge` table is already populated before your script loads:

```lua
-- This works exactly the same as before
local job = Bridge.GetJob(source)
Bridge.AddMoney(source, 'bank', 1000, 'salary')
Bridge.Notify(source, 'Salary received!', 'success')
```

### Step 4: Keep script-specific bridges

Files like `bridge/database.lua`, `bridge/garage.lua`, `bridge/keys.lua`, etc. contain business logic specific to your script. **Keep them** in your script — they are not part of nb-bridge.

---

## Exports

Every Bridge function is also available as a FiveM export for third-party scripts:

```lua
-- From any other resource (not just nb-* scripts)
local name = exports['nb-bridge']:GetPlayerName(source)
local job  = exports['nb-bridge']:GetJob(source)
exports['nb-bridge']:AddMoney(source, 'bank', 500, 'reward')
exports['nb-bridge']:Notify(source, 'Hello!', 'info')
```

### Full export list

| Export | Side | Module |
|--------|------|--------|
| `GetPlayer` | Server | Framework |
| `GetIdentifier` | Server | Framework |
| `GetSSN` | Server | Framework |
| `GetPlayerName` | Server | Framework |
| `GetGroup` | Server | Framework |
| `SetGroup` | Server | Framework |
| `IsAdmin` | Server | Framework |
| `AddMoney` | Server | Framework |
| `RemoveMoney` | Server | Framework |
| `SetMoney` | Server | Framework |
| `GetMoney` | Server | Framework |
| `GetAccounts` | Server | Framework |
| `GetJob` | Server | Framework |
| `SetJob` | Server | Framework |
| `GetGang` | Server | Framework |
| `CreateBill` | Server | Framework |
| `GetPlayerData` | Client | Framework |
| `Notify` | Server | Notify |
| `ShowNotification` | Client | Notify |
| `AddItem` | Server | Inventory |
| `RemoveItem` | Server | Inventory |
| `HasItem` | Server | Inventory |
| `CanCarry` | Server | Inventory |
| `RegisterStash` | Server | Inventory |
| `IsStashRegistered` | Server | Inventory |
| `ForceOpenStash` | Server | Inventory |
| `ForceOpenPlayerInventory` | Server | Inventory |
| `GetAllItems` | Server | Inventory |
| `OpenStash` | Client | Inventory |
| `OpenPlayerInventory` | Client | Inventory |
| `GetItemCount` | Client | Inventory |
| `GetImagePath` | Client | Inventory |
| `NormalizePlate` | Both | Vehicle |
| `GeneratePlate` | Server | Vehicle |
| `GiveVehicle` | Server | Vehicle |
| `GetVehicleOwnerName` | Server | Vehicle |
| `ResolveModelHash` | Client | Vehicle |
| `SpawnVehicle` | Client | Vehicle |
| `GetVehicleProperties` | Client | Vehicle |
| `SetVehicleProperties` | Client | Vehicle |
| `GetVehicleLabel` | Client | Vehicle |
| `CreateCallback` | Server | Callbacks |
| `TriggerServerCallback` | Client | Callbacks |
| `GetIdentity` | Server | Licenses |
| `GetDriverLicense` | Server | Licenses |
| `GetWeaponLicense` | Server | Licenses |
| `Progress` | Client | Progress |

---

## Overrides

Users can customize any Bridge function without modifying nb-bridge files. Place `.lua` files in the `overrides/` folders:

### Example: Custom notification system

`overrides/client/custom_notify.lua`:
```lua
function Bridge.ShowNotification(message, type)
    exports['mythic_notify']:DoHudText(type, message)
end
```

`overrides/server/custom_notify.lua`:
```lua
function Bridge.Notify(source, message, type)
    TriggerClientEvent('nb-bridge:client:notify', source, message, type)
end
```

### Example: Custom inventory system

`overrides/server/custom_inventory.lua`:
```lua
function Bridge.AddItem(source, item, count, metadata, slot)
    return exports['my_inventory']:AddItem(source, item, count, metadata)
end

function Bridge.RemoveItem(source, item, count, metadata, slot)
    return exports['my_inventory']:RemoveItem(source, item, count)
end

function Bridge.HasItem(source, item, count)
    return exports['my_inventory']:HasItem(source, item, count or 1)
end
```

### Example: Gang system override (for nb-crafting)

`overrides/server/gang_system.lua`:
```lua
-- Override GetJob to return gang data from origen_ilegal
local originalGetJob = Bridge.GetJob

function Bridge.GetJob(source)
    local gangData = exports['origen_ilegal']:getPlayerGang(source)
    if gangData and gangData.id then
        return {
            name = tostring(gangData.id),
            label = gangData.name or 'Unknown',
            grade = gangData.level or 0,
            grade_name = tostring(gangData.level or 0),
            grade_label = 'Level ' .. (gangData.level or 0),
        }
    end
    return originalGetJob(source)
end
```

> Override files load **after** all modules, so they simply replace the function on the `Bridge` table.

---

## Migration Guide

### From embedded bridge to nb-bridge

| Step | Action |
|------|--------|
| 1 | Install nb-bridge in your server |
| 2 | Add `'nb-bridge'` to your `dependencies {}` in fxmanifest.lua |
| 3 | Remove `'shared/debugger.lua'` from shared_scripts (Debugger is now in nb-bridge) |
| 4 | Remove all generic bridge files from shared_scripts: `framework.lua`, `notify.lua`, `inventory.lua`, `vehicle.lua`, `callbacks.lua` |
| 5 | Keep script-specific bridges: `database.lua`, `garage.lua`, `keys.lua`, etc. |
| 6 | Test — all `Bridge.*` calls work unchanged |

### Before / After example

**Before** (`nb-garages/fxmanifest.lua`):
```lua
dependencies { 'oxmysql' }

shared_scripts {
    'shared/config.lua',
    'shared/debugger.lua',
    'shared/locale.lua',
    'bridge/framework.lua',
    'bridge/notify.lua',
    'bridge/vehicle.lua',
    'bridge/callbacks.lua',
}

client_scripts {
    'bridge/garage.lua',       -- keep (script-specific)
    'bridge/keys.lua',         -- keep (script-specific)
    'client/keys.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/database.lua',     -- keep (script-specific)
    'bridge/garage.lua',       -- keep (script-specific)
    'bridge/keys.lua',         -- keep (script-specific)
    'server/keys.lua',
    'server/main.lua',
}
```

**After:**
```lua
dependencies { 'oxmysql', 'nb-bridge' }

shared_scripts {
    'shared/config.lua',
    'shared/locale.lua',
}

client_scripts {
    'bridge/garage.lua',
    'bridge/keys.lua',
    'client/keys.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/database.lua',
    'bridge/garage.lua',
    'bridge/keys.lua',
    'server/keys.lua',
    'server/main.lua',
}
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `Bridge is nil` | nb-bridge not started or started after your script | Ensure `ensure nb-bridge` is before your script in server.cfg and it's in `dependencies {}` |
| `No compatible framework detected` | Neither ESX nor QBCore is running | Ensure your framework starts before nb-bridge |
| `Notify not showing` | Notification system not detected yet (500ms delay) | This is normal on first tick — notifications work after the detection thread runs |
| `Inventory functions return false` | Inventory system not detected | Wait 500ms after startup, or check that your inventory resource is started |
| `Callback never responds` | Callback name mismatch | Ensure the name in `CreateCallback` matches `TriggerServerCallback` exactly |
| `Override not loading` | File in wrong folder | Client overrides go in `overrides/client/`, server in `overrides/server/` |
| `Bridge.IsAdmin returns false` | AdminGroups not configured | Set `Config.AdminGroups` in your script's config, or edit `BridgeConfig.AdminGroups` in nb-bridge |

---

*Neenbyss Studios - nb-bridge v1.0.0*
