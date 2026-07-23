-- ================================================
-- INVENTORY BRIDGE - CLIENT
-- Client-side inventory operations.
-- All methods live under Bridge.inventory.*
-- ================================================

if IsDuplicityVersion() then return end

Bridge.inventory = Bridge.inventory or {}

local inventorySystem = nil

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

    -- Expose inventory type globally for compatibility
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

---Open a stash on client
---@param stashId string
function Bridge.inventory.openStash(stashId)
    local inv = ResolveInventorySystem()
    Debugger('Inventory', 'openStash:', stashId, '| system:', inv)
    if inv == 'ox_inventory' then
        exports.ox_inventory:openInventory('stash', stashId)
    elseif inv == 'nb-inventory' then
        -- Server resolves Inventory.OpenStash(stashId, source) and, on
        -- success, pushes containerSlots to us — the client's own
        -- containerSlots handler is what actually opens the NUI panel.
        TriggerServerEvent('nb-inventory:server:openStash', stashId)
    elseif inv == 'qb-inventory' or inv == 'qs-inventory' then
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId)
        TriggerEvent('inventory:client:SetCurrentStash', stashId)
    elseif inv == 'origen_inventory' then
        exports.origen_inventory:openInventory('stash', stashId)
    end
end

---Open another player's inventory on client
---@param targetServerId number
function Bridge.inventory.openPlayerInventory(targetServerId)
    local inv = ResolveInventorySystem()
    if inv == 'ox_inventory' then
        exports.ox_inventory:openInventory('player', targetServerId)
    elseif inv == 'nb-inventory' then
        -- nb-inventory's Admin.OpenInspect is server-export-only (no
        -- client-facing net event) and gated by its own admin-groups check —
        -- this only actually opens anything for a caller nb-inventory itself
        -- considers an admin. See nb-bridge:server:nbInventoryOpenPlayerInventory
        -- in modules/inventory/server.lua.
        TriggerServerEvent('nb-bridge:server:nbInventoryOpenPlayerInventory', targetServerId)
    elseif inv == 'qb-inventory' or inv == 'qs-inventory' then
        TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', targetServerId)
    elseif inv == 'origen_inventory' then
        exports.origen_inventory:openInventory('player', targetServerId)
    end
end

---Get item count on client side
---@param item string
---@return number count
function Bridge.inventory.getItemCount(item)
    local inv = ResolveInventorySystem()

    if inv == 'ox_inventory' then
        local count = exports.ox_inventory:GetItemCount(item)
        return count or 0
    elseif inv == 'nb-inventory' then
        -- nb-inventory exposes no client-side item-count query (its NUI
        -- reads slot state from its own Redux store, not a Lua export) —
        -- an explicit branch here is required, not just an omission: without
        -- it this would silently fall through to the Bridge.Framework
        -- branches below and return a count from the FRAMEWORK's own
        -- native inventory, which does not reflect nb-inventory's real
        -- state at all. Unsupported for now; always 0.
        return 0
    elseif inv == 'qs-inventory' then
        local result = exports['qs-inventory']:Search(item)
        return result or 0
    elseif inv == 'origen_inventory' then
        local result = exports.origen_inventory:Search('count', item)
        if type(result) == 'number' then return result end
        if type(result) == 'table' and result[item] then return result[item] end
        return 0
    elseif Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
        local playerData = Bridge.player.getPlayerData()
        if playerData and playerData.items then
            for _, v in pairs(playerData.items) do
                if v and v.name == item then
                    return v.amount or 0
                end
            end
        end
    elseif Bridge.Framework == 'ESX' then
        local playerData = Bridge.player.getPlayerData()
        if playerData and playerData.inventory then
            for _, v in ipairs(playerData.inventory) do
                if v.name == item then
                    return v.count or 0
                end
            end
        end
    end
    return 0
end

---Get the NUI image path for inventory items
---@return string imagePath format string with %s placeholder
function Bridge.inventory.getImagePath()
    local paths = BridgeConfig.InventoryImagePaths or {}
    return paths[inventorySystem] or paths['ox_inventory'] or 'nui://ox_inventory/web/images/%s.png'
end

-- ================================================
-- ORIGEN_INVENTORY: server-triggered force-open helper.
-- origen_inventory opens from the client, so server-side
-- forceOpenStash / forceOpenPlayerInventory fire this event
-- to route the request to the correct client.
-- ================================================
RegisterNetEvent('nb-bridge:client:origenOpenInventory', function(invType, id)
    if inventorySystem ~= 'origen_inventory' then return end
    exports.origen_inventory:openInventory(invType, id)
end)

