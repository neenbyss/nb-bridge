# nb-bridge Migration Guide: v1.x to v2.0.0

v2.0.0 is a breaking release. All flat `Bridge.Fn()` calls are gone. The API is now fully namespaced under `Bridge.player.*`, `Bridge.inventory.*`, etc., accessed via a single export.

---

## What Changed

| Area | v1.x | v2.0.0 |
|------|------|--------|
| Consumer access | `shared_scripts { '@nb-bridge/loader.lua' }` | `local bridge = exports['nb-bridge']:get()` |
| API style | `Bridge.GetJob(source)` | `bridge.player.getJob(source)` |
| Method naming | PascalCase: `GetJob`, `AddMoney` | camelCase: `getJob`, `addMoney` |
| Exports | Per-method: `exports['nb-bridge']:GetJob(...)` | Single: `exports['nb-bridge']:get()` |
| Frameworks | ESX, QBCore | ESX, QBCore, **QBX** (new) |
| New methods | — | `setGang`, `getAllPlayers`, `registerCommand`, `onPlayerUnloaded`, `getItemMetadata` |

---

## Step-by-Step Migration

### 1. Update fxmanifest.lua

**Before:**
```lua
dependencies {
    'oxmysql',
    'nb-bridge',
}

shared_scripts {
    '@nb-bridge/loader.lua',   -- REMOVE THIS LINE
    'config.lua',
}
```

**After:**
```lua
dependencies {
    'oxmysql',
    'nb-bridge',
}

shared_scripts {
    'config.lua',
}
```

Remove the `'@nb-bridge/loader.lua'` line. The dependency declaration is sufficient.

### 2. Add the get() call to each script file

At the top of every server and client script file that uses the bridge:

```lua
local bridge = exports['nb-bridge']:get()
```

This gives you the `bridge` local table for the rest of that file. You can name the variable anything, but `bridge` is the convention.

### 3. Replace all Bridge.Fn() calls

Use the method equivalence table below to find the new call for each v1 method. The method body does not change — only the call site.

### 4. Update overrides

If you have files in `overrides/client/` or `overrides/server/` that redefine v1 methods, update them to redefine the v2 methods:

**Before:**
```lua
function Bridge.Notify(source, message, type)
    -- custom
end
```

**After:**
```lua
function Bridge.notify.send(source, message, type)
    -- custom
end
```

---

## Full Method Equivalence Table

### Framework — Server

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.GetPlayer(source)` | `bridge.player.getPlayer(source)` | |
| `Bridge.GetIdentifier(source)` | `bridge.player.getIdentifier(source)` | |
| `Bridge.GetSSN(source)` | `bridge.player.getSSN(source)` | ESX only |
| `Bridge.GetPlayerName(source)` | `bridge.player.getPlayerName(source)` | |
| `Bridge.GetGroup(source)` | `bridge.player.getGroup(source)` | QBCore/QBX now also returns `'superadmin'` and `'mod'` |
| `Bridge.SetGroup(source, group)` | `bridge.player.setGroup(source, group)` | ESX only |
| `Bridge.IsAdmin(source)` | `bridge.player.isAdmin(source)` | |
| `Bridge.AddMoney(source, type, amount, reason)` | `bridge.player.addMoney(source, type, amount, reason)` | |
| `Bridge.RemoveMoney(source, type, amount, reason)` | `bridge.player.removeMoney(source, type, amount, reason)` | ESX now returns real `false` when insufficient funds |
| `Bridge.SetMoney(source, type, amount, reason)` | `bridge.player.setMoney(source, type, amount, reason)` | |
| `Bridge.GetMoney(source, type)` | `bridge.player.getMoney(source, type)` | |
| `Bridge.GetAccounts(source)` | `bridge.player.getAccounts(source)` | |
| `Bridge.GetJob(source)` | `bridge.player.getJob(source)` | Same return shape |
| `Bridge.SetJob(source, job, grade, onDuty)` | `bridge.player.setJob(source, job, grade, onDuty)` | |
| `Bridge.GetGang(source)` | `bridge.player.getGang(source)` | QBCore/QBX only |
| `Bridge.GetPlayTime(source)` | `bridge.player.getPlayTime(source)` | ESX only |
| `Bridge.GetCoords(source)` | `bridge.player.getCoords(source)` | |
| `Bridge.SetCoords(source, coords)` | `bridge.player.setCoords(source, coords)` | |
| `Bridge.TriggerClientEvent(source, event, ...)` | `bridge.player.triggerClientEvent(source, event, ...)` | |
| `Bridge.PlayerVar(source, key, value)` | `bridge.player.playerVar(source, key, value)` | ESX only |
| `Bridge.GetMeta(source, index, subIndex)` | `bridge.player.getMeta(source, index, subIndex)` | |
| `Bridge.SetMeta(source, index, value, subIndex)` | `bridge.player.setMeta(source, index, value, subIndex)` | |
| `Bridge.ClearMeta(source, index, subIndex)` | `bridge.player.clearMeta(source, index, subIndex)` | |
| `Bridge.ExecuteCommand(source, command)` | `bridge.player.executeCommand(source, command)` | ESX only |
| `Bridge.CreateBill(src, targetId, amount, desc, jobName)` | `bridge.player.createBill(src, targetId, amount, desc, jobName)` | |
| `Bridge.OnPlayerLoaded(cb)` *(server)* | `bridge.player.onPlayerLoaded(cb)` | |
| — | `bridge.player.setGang(source, gangName, grade)` | New in v2.0.0 |
| — | `bridge.player.getAllPlayers()` | New in v2.0.0 |
| — | `bridge.player.registerCommand(name, group, cb, suggestion)` | New in v2.0.0 |
| — | `bridge.player.onPlayerUnloaded(cb)` | New in v2.0.0 |

### Framework — Client

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.GetPlayerData()` | `bridge.player.getPlayerData()` | |
| `Bridge.OnPlayerLoaded(cb)` *(client)* | `bridge.player.onPlayerLoaded(cb)` | |
| `Bridge.OnJobUpdate(cb)` | `bridge.player.onJobUpdate(cb)` | |
| — | `bridge.player.getJob()` | New client getter in v2.0.0 |
| — | `bridge.player.getGang()` | New in v2.0.0 |
| — | `bridge.player.getMoney(type)` | New client getter in v2.0.0 |
| — | `bridge.player.getAccounts()` | New client getter in v2.0.0 |
| — | `bridge.player.getIdentifier()` | New client getter in v2.0.0 |
| — | `bridge.player.getPlayerName()` | New client getter in v2.0.0 |
| — | `bridge.player.getGroup()` | New client getter in v2.0.0 |
| — | `bridge.player.onPlayerUnloaded(cb)` | New in v2.0.0 |
| — | `bridge.player.onGangUpdate(cb)` | New in v2.0.0 |

### Notifications

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.Notify(source, message, type)` | `bridge.notify.send(source, message, type)` | Server |
| `Bridge.ShowNotification(message, type)` | `bridge.notify.show(message, type)` | Client |

### Inventory — Server

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.AddItem(source, item, count, metadata, slot)` | `bridge.inventory.addItem(source, item, count, metadata, slot)` | |
| `Bridge.RemoveItem(source, item, count, metadata, slot)` | `bridge.inventory.removeItem(source, item, count, metadata, slot)` | |
| `Bridge.HasItem(source, item, count)` | `bridge.inventory.hasItem(source, item, count)` | |
| `Bridge.CanCarry(source, item, count, metadata)` | `bridge.inventory.canCarry(source, item, count, metadata)` | |
| `Bridge.RegisterStash(id, label, job, coords)` | `bridge.inventory.registerStash(id, label, job, coords)` | |
| `Bridge.IsStashRegistered(id)` | `bridge.inventory.isStashRegistered(id)` | |
| `Bridge.ForceOpenStash(source, id)` | `bridge.inventory.forceOpenStash(source, id)` | |
| `Bridge.ForceOpenPlayerInventory(source, targetId)` | `bridge.inventory.forceOpenPlayerInventory(source, targetId)` | |
| `Bridge.GetAllItems()` | `bridge.inventory.getAllItems()` | |
| `Bridge.RegisterUsableItem(name, cb)` | `bridge.inventory.registerUsableItem(name, cb)` | |
| `Bridge.IsUsableItemRegistered(name)` | `bridge.inventory.isUsableItemRegistered(name)` | |
| — | `bridge.inventory.getItemMetadata(source, itemName)` | New in v2.0.0; ox_inventory only |

### Inventory — Client

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.OpenStash(id)` | `bridge.inventory.openStash(id)` | |
| `Bridge.OpenPlayerInventory(targetId)` | `bridge.inventory.openPlayerInventory(targetId)` | |
| `Bridge.GetItemCount(item)` | `bridge.inventory.getItemCount(item)` | |
| `Bridge.GetImagePath()` | `bridge.inventory.getImagePath()` | |

### Vehicle — Shared

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.NormalizePlate(plate)` | `bridge.vehicle.normalizePlate(plate)` | |

### Vehicle — Server

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.GeneratePlate()` | `bridge.vehicle.generatePlate()` | |
| `Bridge.GiveVehicle(source, model, props)` | `bridge.vehicle.giveVehicle(source, model, props)` | |
| `Bridge.GetVehicleOwnerName(plate)` | `bridge.vehicle.getVehicleOwnerName(plate)` | |

### Vehicle — Client

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.ResolveModelHash(model)` | `bridge.vehicle.resolveModelHash(model)` | |
| `Bridge.SpawnVehicle(model, coords, heading, props, plate, cb)` | `bridge.vehicle.spawnVehicle(model, coords, heading, props, plate, cb)` | Uses wall-clock timeout in v2 |
| `Bridge.GetVehicleProperties(vehicle)` | `bridge.vehicle.getVehicleProperties(vehicle)` | |
| `Bridge.SetVehicleProperties(vehicle, props)` | `bridge.vehicle.setVehicleProperties(vehicle, props)` | |
| `Bridge.GetVehicleLabel(model)` | `bridge.vehicle.getVehicleLabel(model)` | |

### Callbacks

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.CreateCallback(name, cb)` | `bridge.callback.register(name, cb)` | |
| `Bridge.TriggerServerCallback(name, cb, ...)` | `bridge.callback.trigger(name, cb, ...)` | Now has 15s timeout with `cb(nil)` |

### Licenses — Server

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.GetIdentity(source)` | `bridge.license.getIdentity(source)` | |
| `Bridge.GetDriverLicense(source)` | `bridge.license.getDriverLicense(source)` | |
| `Bridge.GetWeaponLicense(source)` | `bridge.license.getWeaponLicense(source)` | |

### Progress — Client

| v1.x | v2.0.0 | Notes |
|------|--------|-------|
| `Bridge.Progress(duration, label, anim)` | `bridge.progress.show(duration, label, anim)` | |

---

## Removed: Per-Method Exports

In v1.x, every function was available as a named export:

```lua
-- v1.x only — no longer works
exports['nb-bridge']:GetJob(source)
exports['nb-bridge']:AddMoney(source, 'bank', 500)
```

In v2.0.0, the **only** export is `get()`:

```lua
-- v2.0.0
local bridge = exports['nb-bridge']:get()
bridge.player.getJob(source)
bridge.player.addMoney(source, 'bank', 500)
```

If you were calling nb-bridge exports from a third-party resource that is not itself an nb-bridge consumer, you now need to call `get()` first and use the returned table.

---

## Removed: loader.lua

`shared_scripts { '@nb-bridge/loader.lua' }` is deprecated. The file still exists and still works for backward compatibility, but it will be removed in a future major version.

Migrate now: remove the `shared_scripts` line and add `local bridge = exports['nb-bridge']:get()` to each file.

---

## Behavior Changes

| Change | Impact |
|--------|--------|
| `bridge.player.removeMoney` on ESX now pre-checks balance | Now returns real `false` when funds are insufficient, instead of always returning `true` |
| `bridge.inventory.registerUsableItem` on origen_inventory | No longer double-fires. Registers only through origen's registry, not both origen and the framework. |
| `bridge.vehicle.spawnVehicle` | Uses `GetGameTimer()` wall-clock timeout instead of a frame counter. No longer times out prematurely under server load. |
| `bridge.callback.trigger` | 15-second cleanup timeout. Pending callbacks are released with `cb(nil)` if the server never responds, preventing memory leaks. |
| `bridge.player.onPlayerUnloaded` on QBX | QBX fires two events on logout. The bridge debounces within 1 second so your callback fires only once. |
| `bridge.player.getGroup` on QBCore/QBX | Now also returns `'superadmin'` and `'mod'`. Customize via `BridgeConfig.GroupMap`. |
| Inventory detection | `ResolveInventorySystem()` now has a synchronous fallback. Early callers before the 500ms detection thread no longer silently fail. |

---

## Example: Before and After

### Server script (v1.x)

```lua
-- v1.x: loader.lua populates global Bridge
RegisterNetEvent('myshop:buy', function(item, price)
    local src = source
    if Bridge.GetMoney(src, 'bank') < price then
        Bridge.Notify(src, 'Not enough money', 'error')
        return
    end
    Bridge.RemoveMoney(src, 'bank', price, 'shop_purchase')
    Bridge.AddItem(src, item, 1)
    Bridge.Notify(src, 'Purchase complete!', 'success')
end)

Bridge.CreateCallback('myshop:getStock', function(source, respond, category)
    local stock = GetStockForCategory(category)
    respond(stock)
end)
```

### Server script (v2.0.0)

```lua
local bridge = exports['nb-bridge']:get()

RegisterNetEvent('myshop:buy', function(item, price)
    local src = source
    if bridge.player.getMoney(src, 'bank') < price then
        bridge.notify.send(src, 'Not enough money', 'error')
        return
    end
    bridge.player.removeMoney(src, 'bank', price, 'shop_purchase')
    bridge.inventory.addItem(src, item, 1)
    bridge.notify.send(src, 'Purchase complete!', 'success')
end)

bridge.callback.register('myshop:getStock', function(source, respond, category)
    local stock = GetStockForCategory(category)
    respond(stock)
end)
```

### Client script (v1.x)

```lua
-- v1.x
Bridge.OnPlayerLoaded(function()
    local job = Bridge.GetPlayerData().job
    print('Loaded: ' .. job.name)
end)

Bridge.OnJobUpdate(function(job)
    print('Job changed to: ' .. job.name)
end)

Bridge.TriggerServerCallback('myshop:getStock', function(stock)
    ShowShopUI(stock)
end, 'food')
```

### Client script (v2.0.0)

```lua
local bridge = exports['nb-bridge']:get()

bridge.player.onPlayerLoaded(function()
    local job = bridge.player.getJob()
    print('Loaded: ' .. job.name)
end)

bridge.player.onJobUpdate(function(job)
    print('Job changed to: ' .. job.name)
end)

bridge.callback.trigger('myshop:getStock', function(stock)
    ShowShopUI(stock)
end, 'food')
```

---

*Neenbyss Studios — nb-bridge v2.0.0*
