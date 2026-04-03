-- ================================================
-- INVENTORY BRIDGE - SERVER
-- Unified inventory API for multiple systems.
-- Supports: ox_inventory, qb-inventory, qs-inventory,
--           framework defaults (ESX/QBCore)
-- ================================================

if not IsDuplicityVersion() then return end

local inventorySystem = nil
local registeredStashes = {}

-- Auto-detect inventory system
CreateThread(function()
    Wait(500)
    if GetResourceState('ox_inventory') == 'started' then
        inventorySystem = 'ox_inventory'
    elseif GetResourceState('qb-inventory') == 'started' then
        inventorySystem = 'qb-inventory'
    elseif GetResourceState('qs-inventory') == 'started' then
        inventorySystem = 'qs-inventory'
    else
        inventorySystem = 'default'
    end
    Debugger('Inventory', 'Detected:', inventorySystem)

    -- Expose inventory type globally for compatibility (nb-crafting uses Inventory.Type)
    Bridge.InventorySystem = inventorySystem
end)

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
function Bridge.AddItem(source, item, count, metadata, slot)
    if not source or not item or not count or count <= 0 then return false end

    if inventorySystem == 'ox_inventory' then
        return exports.ox_inventory:AddItem(source, item, count, metadata, slot)
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        if Bridge.Framework == 'QBCore' then
            local player = Bridge.GetPlayer(source)
            if player then
                return player.Functions.AddItem(item, count, slot, metadata)
            end
        end
        return false
    else
        local player = Bridge.GetPlayer(source)
        if player then
            if Bridge.Framework == 'ESX' then
                player.addInventoryItem(item, count)
                return true
            elseif Bridge.Framework == 'QBCore' then
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
function Bridge.RemoveItem(source, item, count, metadata, slot)
    if not source or not item or not count or count <= 0 then return false end

    if inventorySystem == 'ox_inventory' then
        local success = exports.ox_inventory:RemoveItem(source, item, count, metadata, slot)
        return success ~= false
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        if Bridge.Framework == 'QBCore' then
            local player = Bridge.GetPlayer(source)
            if player then
                return player.Functions.RemoveItem(item, count, slot)
            end
        end
        return false
    else
        local player = Bridge.GetPlayer(source)
        if player then
            if Bridge.Framework == 'ESX' then
                player.removeInventoryItem(item, count)
                return true
            elseif Bridge.Framework == 'QBCore' then
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
function Bridge.HasItem(source, item, count)
    count = count or 1

    if inventorySystem == 'ox_inventory' then
        local itemCount = exports.ox_inventory:GetItemCount(source, item)
        return itemCount and itemCount >= count or false
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        if Bridge.Framework == 'QBCore' then
            local player = Bridge.GetPlayer(source)
            if player then
                local itemData = player.Functions.GetItemByName(item)
                return itemData and itemData.amount >= count or false
            end
        end
        return false
    else
        local player = Bridge.GetPlayer(source)
        if player then
            if Bridge.Framework == 'ESX' then
                local itemData = player.getInventoryItem(item)
                return itemData and itemData.count >= count or false
            elseif Bridge.Framework == 'QBCore' then
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
function Bridge.CanCarry(source, item, count, metadata)
    count = count or 1

    if inventorySystem == 'ox_inventory' then
        return exports.ox_inventory:CanCarryItem(source, item, count, metadata)
    else
        local player = Bridge.GetPlayer(source)
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
function Bridge.RegisterStash(stashId, label, jobName, coords)
    if registeredStashes[stashId] then return end

    local groups = nil
    if jobName then
        groups = { [jobName] = 0 }
    end

    Debugger('Inventory', 'RegisterStash:', stashId, '| label:', label, '| job:', jobName, '| system:', inventorySystem)

    local stashCfg = (Config and Config.Stash) or BridgeConfig.Stash or {}
    local slots = stashCfg.Slots or 50
    local maxWeight = stashCfg.MaxWeight or 100000

    if inventorySystem == 'ox_inventory' then
        exports.ox_inventory:RegisterStash(
            stashId,
            label,
            slots,
            maxWeight,
            false,
            groups,
            coords
        )
    end

    registeredStashes[stashId] = true
end

---Check if a stash is registered
---@param stashId string
---@return boolean
function Bridge.IsStashRegistered(stashId)
    return registeredStashes[stashId] == true
end

---Force open a stash for a player
---@param source number
---@param stashId string
function Bridge.ForceOpenStash(source, stashId)
    if inventorySystem == 'ox_inventory' then
        exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
    end
end

---Force open another player's inventory from server
---@param source number The player who will see the inventory
---@param targetServerId number The player whose inventory is opened
---@return boolean success
function Bridge.ForceOpenPlayerInventory(source, targetServerId)
    Debugger('Inventory', 'ForceOpenPlayerInventory | source:', source, '| target:', targetServerId, '| system:', inventorySystem)

    if inventorySystem == 'ox_inventory' then
        local ok, err = pcall(function()
            exports.ox_inventory:forceOpenInventory(source, 'player', targetServerId)
        end)
        if not ok then
            Debugger('Inventory', 'forceOpenInventory failed:', err)
        end
        return ok
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        TriggerClientEvent('inventory:client:OpenInventory', source, {}, 'otherplayer', targetServerId)
        return true
    end

    Debugger('Inventory', 'No supported inventory system for ForceOpenPlayerInventory')
    return false
end

---Get all registered items from the inventory system
---@return table items
function Bridge.GetAllItems()
    if inventorySystem == 'ox_inventory' then
        return exports.ox_inventory:Items() or {}
    elseif Bridge.Framework == 'QBCore' then
        return Bridge.FrameworkObject.Shared.Items or {}
    end
    return {}
end

-- ================================================
-- EXPORTS
-- ================================================

if not _BRIDGE_LOADER then
    exports('AddItem', function(...) return Bridge.AddItem(...) end)
    exports('RemoveItem', function(...) return Bridge.RemoveItem(...) end)
    exports('HasItem', function(...) return Bridge.HasItem(...) end)
    exports('CanCarry', function(...) return Bridge.CanCarry(...) end)
    exports('RegisterStash', function(...) return Bridge.RegisterStash(...) end)
    exports('IsStashRegistered', function(...) return Bridge.IsStashRegistered(...) end)
    exports('ForceOpenStash', function(...) return Bridge.ForceOpenStash(...) end)
    exports('ForceOpenPlayerInventory', function(...) return Bridge.ForceOpenPlayerInventory(...) end)
    exports('GetAllItems', function(...) return Bridge.GetAllItems(...) end)
end
