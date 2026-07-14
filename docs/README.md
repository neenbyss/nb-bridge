# nb-bridge Documentation

**Version:** 2.2.0
**Frameworks:** ESX Legacy, QBCore, QBX (qbx_core)
**Lua:** 5.4

This directory contains the reference documentation for nb-bridge.

---

## Documents

| File | Description |
|------|-------------|
| [api.md](api.md) | Complete API reference — every method in every namespace with signatures, parameters, return values, and per-framework behavior |
| [migration-v1-to-v2.md](migration-v1-to-v2.md) | Step-by-step migration guide from v1.x to v2.0.0, including the full method equivalence table |

For installation, quick start, and a high-level overview see the root [README.md](../README.md).

For the full version history see [CHANGELOG.md](../CHANGELOG.md).

---

## Quick Reference

```lua
-- Consume nb-bridge in any script
local bridge = exports['nb-bridge']:get()

-- Server
bridge.player.getJob(source)                         -- {name, label, grade, ...}
bridge.player.addMoney(source, 'bank', 500, 'pay')
bridge.player.removeMoney(source, 'bank', 100)
bridge.player.isAdmin(source)                        -- boolean
bridge.inventory.addItem(source, 'water', 3)
bridge.inventory.hasItem(source, 'lockpick')         -- boolean
bridge.inventory.registerUsableItem('bandage', function(src, item)
    bridge.inventory.removeItem(src, 'bandage', 1)
end)
bridge.notify.send(source, 'Done!', 'success')
bridge.callback.register('myresource:getData', function(source, respond, arg)
    respond({ ok = true })
end)

-- Client
bridge.player.onPlayerLoaded(function()
    local job = bridge.player.getJob()
end)
bridge.player.onJobUpdate(function(job) end)
bridge.notify.show('Item received', 'info')
bridge.callback.trigger('myresource:getData', function(res)
    print(res.ok)
end, someArg)
bridge.progress.show(3000, 'Working...', { dict = 'mini@repair', name = 'fixing_a_player' })
```

---

## Namespace Overview

| Namespace | Side | Contents |
|-----------|------|----------|
| `bridge.player.*` | Server + Client | Player management, money, jobs, gangs, permissions, events |
| `bridge.inventory.*` | Server + Client | Items, stashes, usable items, item count |
| `bridge.vehicle.*` | Server + Client | Plate management, spawning, properties, DB insertion |
| `bridge.notify.*` | Server + Client | Notification system (auto-detects ox_lib) |
| `bridge.callback.*` | Server + Client | Server callback system |
| `bridge.license.*` | Server only | Identity, driver license, weapon license |
| `bridge.progress.*` | Client only | Progress bars (auto-detects ox_lib) |
| `bridge.event.*` | Server + Client | Lifecycle hooks (player/resource) — v2.1.0 |
| `bridge.log.*` | Server only | Audit logging (qb-log / webhook / Debugger) — v2.2.0 |
| `bridge.ui.*` | Client only | UI lifecycle hooks (open/close/action) — v2.2.0 |

Plus `bridge.diagnostics()` (server) — runtime snapshot; see [api.md](api.md).

---

*Neenbyss Studios — nb-bridge v2.2.0*
