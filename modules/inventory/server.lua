-- ================================================
-- INVENTORY BRIDGE - SERVER
-- Unified inventory API for multiple systems.
-- Supports: ox_inventory, nb-inventory, qb-inventory, qs-inventory,
--           origen_inventory, framework defaults (ESX/QBCore/QBX)
-- All methods live under Bridge.inventory.*
-- ================================================

if not IsDuplicityVersion() then return end

Bridge.inventory = Bridge.inventory or {}

local inventorySystem = nil
local registeredStashes = {}

-- Auto-detect inventory system (fires ~500ms after boot to let resources settle)
CreateThread(function()
    Wait(500)
    if GetResourceState('ox_inventory') == 'started' then
        inventorySystem = 'ox_inventory'
    elseif GetResourceState('nb-inventory') == 'started' then
        inventorySystem = 'nb-inventory'
    elseif GetResourceState('qb-inventory') == 'started' then
        inventorySystem = 'qb-inventory'
    elseif GetResourceState('qs-inventory') == 'started' then
        inventorySystem = 'qs-inventory'
    elseif GetResourceState('origen_inventory') == 'started' then
        inventorySystem = 'origen_inventory'
    else
        inventorySystem = 'default'
    end
    Debugger('Inventory', 'Detected:', inventorySystem)

    -- Expose inventory type globally for compatibility (nb-crafting uses Inventory.Type)
    Bridge.InventorySystem = inventorySystem
end)

-- Synchronous fallback: resolves inventorySystem immediately via GetResourceState.
-- Called at the top of every public method so early callers (before the 500ms
-- detection thread fires) still get a valid system string.
local function ResolveInventorySystem()
    if inventorySystem then return inventorySystem end
    if GetResourceState('ox_inventory') == 'started' then
        inventorySystem = 'ox_inventory'
    elseif GetResourceState('nb-inventory') == 'started' then
        inventorySystem = 'nb-inventory'
    elseif GetResourceState('qb-inventory') == 'started' then
        inventorySystem = 'qb-inventory'
    elseif GetResourceState('qs-inventory') == 'started' then
        inventorySystem = 'qs-inventory'
    elseif GetResourceState('origen_inventory') == 'started' then
        inventorySystem = 'origen_inventory'
    else
        inventorySystem = 'default'
    end
    Bridge.InventorySystem = inventorySystem
    return inventorySystem
end

-- ================================================
-- NOTE ON QBX:
-- QBX requires ox_inventory, so Bridge.InventorySystem
-- will always resolve to 'ox_inventory' on a QBX server.
-- No separate QBX branch is needed — the ox_inventory
-- path handles it automatically.
-- ================================================

-- ================================================
-- ITEM MANAGEMENT
-- ================================================

---Add item to player inventory
---@param source number
---@param item string
---@param count number
---@param metadata? table|string
---@param slot? number
---@return boolean success
function Bridge.inventory.addItem(source, item, count, metadata, slot)
    if not source or not item or not count or count <= 0 then return false end
    local inv = ResolveInventorySystem()

    if inv == 'ox_inventory' then
        return exports.ox_inventory:AddItem(source, item, count, metadata, slot)
    elseif inv == 'nb-inventory' then
        local success = exports['nb-inventory']:AddItem(source, item, count, metadata, slot)
        return success == true
    elseif inv == 'qs-inventory' then
        return exports['qs-inventory']:AddItem(source, item, count, slot, metadata)
    elseif inv == 'origen_inventory' then
        local ok = exports.origen_inventory:addItem(source, item, count, metadata, slot, false)
        return ok == true
    elseif inv == 'qb-inventory' then
        if Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
            local player = Bridge.player.getPlayer(source)
            if player then
                return player.Functions.AddItem(item, count, slot, metadata)
            end
        end
        return false
    else
        local player = Bridge.player.getPlayer(source)
        if player then
            if Bridge.Framework == 'ESX' then
                player.addInventoryItem(item, count)
                return true
            elseif Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
                return player.Functions.AddItem(item, count, slot, metadata)
            end
        end
    end
    return false
end

---Remove item from player inventory
---@param source number
---@param item string
---@param count number
---@param metadata? table|string
---@param slot? number
---@return boolean success
function Bridge.inventory.removeItem(source, item, count, metadata, slot)
    if not source or not item or not count or count <= 0 then return false end
    local inv = ResolveInventorySystem()

    if inv == 'ox_inventory' then
        local success = exports.ox_inventory:RemoveItem(source, item, count, metadata, slot)
        return success ~= false
    elseif inv == 'nb-inventory' then
        local success = exports['nb-inventory']:RemoveItem(source, item, count, metadata, slot)
        return success == true
    elseif inv == 'qs-inventory' then
        exports['qs-inventory']:RemoveItem(source, item, count, slot, metadata)
        return true
    elseif inv == 'origen_inventory' then
        local ok = exports.origen_inventory:removeItem(source, item, count, metadata, slot, false)
        return ok == true
    elseif inv == 'qb-inventory' then
        if Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
            local player = Bridge.player.getPlayer(source)
            if player then
                return player.Functions.RemoveItem(item, count, slot)
            end
        end
        return false
    else
        local player = Bridge.player.getPlayer(source)
        if player then
            if Bridge.Framework == 'ESX' then
                player.removeInventoryItem(item, count)
                return true
            elseif Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
                return player.Functions.RemoveItem(item, count, slot)
            end
        end
    end
    return false
end

---Check if player has item(s)
---@param source number
---@param item string
---@param count? number
---@return boolean
function Bridge.inventory.hasItem(source, item, count)
    count = count or 1
    local inv = ResolveInventorySystem()

    if inv == 'ox_inventory' then
        local itemCount = exports.ox_inventory:GetItemCount(source, item)
        return itemCount and itemCount >= count or false
    elseif inv == 'nb-inventory' then
        return exports['nb-inventory']:HasItem(source, item, count) == true
    elseif inv == 'qs-inventory' then
        local totalAmount = exports['qs-inventory']:GetItemTotalAmount(source, item)
        return totalAmount and totalAmount >= count or false
    elseif inv == 'origen_inventory' then
        local itemCount = exports.origen_inventory:getItemCount(source, item, false, false)
        return type(itemCount) == 'number' and itemCount >= count or false
    elseif inv == 'qb-inventory' then
        if Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
            local player = Bridge.player.getPlayer(source)
            if player then
                local itemData = player.Functions.GetItemByName(item)
                return itemData and itemData.amount >= count or false
            end
        end
        return false
    else
        local player = Bridge.player.getPlayer(source)
        if player then
            if Bridge.Framework == 'ESX' then
                local itemData = player.getInventoryItem(item)
                return itemData and itemData.count >= count or false
            elseif Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
                local itemData = player.Functions.GetItemByName(item)
                return itemData and itemData.amount >= count or false
            end
        end
    end
    return false
end

---Check if player can carry item(s)
---@param source number
---@param item string
---@param count? number
---@param metadata? table|string
---@return boolean
function Bridge.inventory.canCarry(source, item, count, metadata)
    count = count or 1
    local inv = ResolveInventorySystem()

    if inv == 'ox_inventory' then
        return exports.ox_inventory:CanCarryItem(source, item, count, metadata)
    elseif inv == 'nb-inventory' then
        return exports['nb-inventory']:CanCarryItem(source, item, count, metadata) == true
    elseif inv == 'qs-inventory' then
        return exports['qs-inventory']:CanCarryItem(source, item, count)
    elseif inv == 'origen_inventory' then
        local ok = exports.origen_inventory:canCarryItem(source, item, count, metadata)
        return ok == true
    else
        local player = Bridge.player.getPlayer(source)
        if player then
            if Bridge.Framework == 'ESX' then
                return player.canCarryItem(item, count)
            end
        end
    end
    return true
end

-- ================================================
-- STASH MANAGEMENT
-- ================================================

---Register a stash (primarily for ox_inventory)
---@param stashId string
---@param label string
---@param jobName? string
---@param coords? vector3
function Bridge.inventory.registerStash(stashId, label, jobName, coords)
    if registeredStashes[stashId] then return end

    local groups = nil
    if jobName then
        groups = { [jobName] = 0 }
    end

    local inv = ResolveInventorySystem()
    Debugger('Inventory', 'registerStash:', stashId, '| label:', label, '| job:', jobName, '| system:', inv)

    local stashCfg = (Config and Config.Stash) or BridgeConfig.Stash or {}
    local slots = stashCfg.Slots or 50
    local maxWeight = stashCfg.MaxWeight or 100000

    if inv == 'ox_inventory' then
        exports.ox_inventory:RegisterStash(
            stashId,
            label,
            slots,
            maxWeight,
            false,
            groups,
            coords
        )
    elseif inv == 'nb-inventory' then
        -- nb-inventory v0.6.0+ added native `groups` gating on RegisterStash
        -- (Stash.CanAccess, checked before proximity — server/stashes.lua),
        -- checked against Bridge.Framework.GetGroups (job AND gang names).
        -- Earlier nb-inventory versions (< v0.6.0) have no such option and
        -- silently ignore an unknown `groups` field — jobName has no effect
        -- on those, same as passing nil.
        exports['nb-inventory']:RegisterStash(stashId, {
            label = label,
            slots = slots,
            maxWeight = maxWeight,
            coords = coords,
            groups = jobName and { jobName } or nil,
        })
    elseif inv == 'qs-inventory' then
        exports['qs-inventory']:RegisterStash(stashId, slots, maxWeight)
    elseif inv == 'origen_inventory' then
        exports.origen_inventory:registerStash(stashId, {
            label  = label or stashId,
            slots  = slots,
            weight = maxWeight,
        })
    end

    registeredStashes[stashId] = true
end

---Check if a stash is registered
---@param stashId string
---@return boolean
function Bridge.inventory.isStashRegistered(stashId)
    return registeredStashes[stashId] == true
end

---Force open a stash for a player
---@param source number
---@param stashId string
function Bridge.inventory.forceOpenStash(source, stashId)
    local inv = ResolveInventorySystem()
    if inv == 'ox_inventory' then
        exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
    elseif inv == 'nb-inventory' then
        -- Inventory.OpenStash is always proximity-gated server-side — there
        -- is no ignore-security-checks parameter like ox_inventory's
        -- forceOpenInventory. This call is a no-op (no client push, no error)
        -- if `source` isn't actually near the stash's registered coords;
        -- "force" here only means skipping the normal keybind/command trigger.
        exports['nb-inventory']:OpenStash(stashId, source)
    elseif inv == 'qs-inventory' then
        TriggerClientEvent('inventory:server:OpenInventory', source, 'stash', stashId)
    elseif inv == 'origen_inventory' then
        -- origen_inventory opens from the client side
        TriggerClientEvent('nb-bridge:client:origenOpenInventory', source, 'stash', stashId)
    end
end

---Force open another player's inventory from server
---@param source number The player who will see the inventory
---@param targetServerId number The player whose inventory is opened
---@return boolean success
function Bridge.inventory.forceOpenPlayerInventory(source, targetServerId)
    local inv = ResolveInventorySystem()
    Debugger('Inventory', 'forceOpenPlayerInventory | source:', source, '| target:', targetServerId, '| system:', inv)

    if inv == 'ox_inventory' then
        local ok, err = pcall(function()
            exports.ox_inventory:forceOpenInventory(source, 'player', targetServerId)
        end)
        if not ok then
            Debugger('Inventory', 'forceOpenInventory failed:', err)
        end
        return ok
    elseif inv == 'nb-inventory' then
        -- nb-inventory has no generic "view any player's inventory"
        -- primitive — only Admin.OpenInspect (server/admin.lua), gated by
        -- Config.AdminGroups via nb-inventory's OWN Bridge.Framework.
        -- GetPermissionGroups (a different admin-group source than
        -- nb-bridge's own BridgeConfig.AdminGroups). A caller using this for
        -- a non-admin use case (e.g. "police search a suspect") will simply
        -- get `false` back if `source` isn't in nb-inventory's own admin groups.
        return exports['nb-inventory']:OpenInspect(source, targetServerId) == true
    elseif inv == 'qb-inventory' then
        -- qb-inventory uses a specific event with proper args
        TriggerClientEvent('inventory:client:OpenInventory', source, {}, 'otherplayer', targetServerId)
        return true
    elseif inv == 'qs-inventory' then
        -- qs-inventory: use the server export if available; fall back to client event
        -- with the correct (source, targetId) shape (no leading '{}' placeholder)
        if exports['qs-inventory'] and exports['qs-inventory'].forceOpenInventory then
            exports['qs-inventory']:forceOpenInventory(source, 'player', targetServerId or source)
        else
            TriggerClientEvent('qsinv:openOtherInventory', source, targetServerId or source)
        end
        return true
    elseif inv == 'origen_inventory' then
        TriggerClientEvent('nb-bridge:client:origenOpenInventory', source, 'player', targetServerId)
        return true
    end

    Debugger('Inventory', 'No supported inventory system for forceOpenPlayerInventory')
    return false
end

---Get all registered items from the inventory system
---@return table items
function Bridge.inventory.getAllItems()
    local inv = ResolveInventorySystem()

    if inv == 'ox_inventory' then
        return exports.ox_inventory:Items() or {}
    elseif inv == 'nb-inventory' then
        -- Field names differ from ox_inventory's shape (nb-inventory uses
        -- `stackable`/`closeOnUse`, not `stack`/`close`) — callers that
        -- branch on specific field names must account for this per system,
        -- same as they already do for qs-inventory/origen_inventory below.
        return exports['nb-inventory']:GetItems() or {}
    elseif inv == 'qs-inventory' then
        return exports['qs-inventory']:GetItemList() or {}
    elseif inv == 'origen_inventory' then
        return exports.origen_inventory:Items() or {}
    elseif Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
        -- QBX: items are in ox_inventory (always ox on QBX), but QBCore compat path
        if Bridge.Framework == 'QBCore' then
            return Bridge.FrameworkObject.Shared.Items or {}
        end
    end
    return {}
end

-- ================================================
-- USABLE ITEMS
-- ================================================

local registeredUsable = {}

---Register a usable item handler. Callback receives (source, item) where
---`item` is framework-provided metadata (at minimum { name = string, slot = number? }).
---@param itemName string
---@param cb fun(source: number, item: table)
---@return boolean success
function Bridge.inventory.registerUsableItem(itemName, cb)
    if not itemName or type(cb) ~= 'function' then return false end

    -- Idempotency guard: only register once
    if registeredUsable[itemName] then
        Debugger('Inventory', 'registerUsableItem: already registered, skipping:', itemName)
        return true
    end
    registeredUsable[itemName] = cb

    local inv = ResolveInventorySystem()

    -- origen_inventory has its own usable-item registry. Register ONLY through
    -- origen and skip the framework layer to prevent double-fire.
    if inv == 'origen_inventory' then
        local ok = pcall(function()
            exports.origen_inventory:CreateUseableItem(itemName, function(source, item)
                cb(source, item or { name = itemName })
            end)
        end)
        if not ok then
            Debugger('Inventory', 'origen_inventory:CreateUseableItem failed for', itemName)
        end
        -- Do NOT fall through to ESX/QBCore registration on origen
        return ok
    end

    -- nb-inventory has no per-item callback registry — 'use' is a single
    -- generic hook event (server/hooks.lua) filtered by item name, firing
    -- POST-consume (item already decremented), matching the same
    -- post-consume contract every framework branch below follows. NOTE:
    -- unlike ESX/QBCore/QBX, nb-inventory ALSO fires this same 'use'
    -- post-hook for weapon-equip and container-open "uses" (Inventory.
    -- UseItem treats those as special cases of the same call) — a callback
    -- registered here for a weapon or container-kind item will fire even
    -- though nothing was actually consumed.
    if inv == 'nb-inventory' then
        local ok = pcall(function()
            exports['nb-inventory']:RegisterPostHook('use', function(payload)
                cb(payload.source, { name = payload.itemName, slot = payload.slot })
            end, { item = itemName })
        end)
        if not ok then
            Debugger('Inventory', 'nb-inventory:RegisterPostHook failed for', itemName)
        end
        return ok
    end

    if Bridge.Framework == 'ESX' then
        Bridge.FrameworkObject.RegisterUsableItem(itemName, function(source, itemSlot)
            cb(source, { name = itemName, slot = itemSlot })
        end)
        return true
    elseif Bridge.Framework == 'QBX' then
        -- QBX: items are managed by ox_inventory. The usable-item handler is
        -- registered through qbx_core's CreateUseableItem (which bridges to ox).
        local ok = pcall(function()
            exports.qbx_core:CreateUseableItem(itemName, function(source, item)
                cb(source, item or { name = itemName })
            end)
        end)
        return ok
    elseif Bridge.Framework == 'QBCore' then
        Bridge.FrameworkObject.Functions.CreateUseableItem(itemName, function(source, item)
            cb(source, item or { name = itemName })
        end)
        return true
    end
    return false
end

---Check if an item is registered as usable through the bridge
---@param itemName string
---@return boolean
function Bridge.inventory.isUsableItemRegistered(itemName)
    return registeredUsable[itemName] ~= nil
end

---Get item metadata from player inventory
---Only ox_inventory exposes per-slot metadata via the bridge.
---Returns nil when the inventory system does not support metadata or the item is not found.
---@param source number Player server ID
---@param itemName string Item name
---@return table|nil metadata Item metadata table, or nil
function Bridge.inventory.getItemMetadata(source, itemName)
    local inv = ResolveInventorySystem()

    if inv == 'ox_inventory' then
        -- GetSlotWithItem(inv, itemName, metadata, strict) returns the first matching
        -- SlotWithItem, which carries the real per-slot .metadata. GetItem's 4th param
        -- is `returnsCount`, not a slot selector — it never exposes slot metadata.
        local slotData = exports.ox_inventory:GetSlotWithItem(source, itemName)
        return slotData and slotData.metadata or nil
    elseif inv == 'nb-inventory' then
        -- No "find by item name" export exists (only GetSlots/GetSlot by
        -- exact slot number) — scan the full slot table for the first match,
        -- same first-match semantics as ox_inventory's GetSlotWithItem above.
        local slots = exports['nb-inventory']:GetSlots(source) or {}
        for _, item in pairs(slots) do
            if item.name == itemName then
                return item.metadata
            end
        end
        return nil
    end

    -- Other inventory systems don't expose per-slot item metadata via the bridge
    return nil
end

-- ================================================
-- NB-INVENTORY: server-triggered player-inspect helper.
-- nb-inventory's Admin.OpenInspect is server-export-only (no client-facing
-- net event of its own) — bridge.inventory.openPlayerInventory (client)
-- routes through this event so a client-initiated request still reaches
-- Admin.OpenInspect's own admin check server-side.
-- ================================================
RegisterNetEvent('nb-bridge:server:nbInventoryOpenPlayerInventory', function(targetServerId)
    if ResolveInventorySystem() ~= 'nb-inventory' then return end
    exports['nb-inventory']:OpenInspect(source, targetServerId)
end)

