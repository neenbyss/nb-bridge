-- ================================================
-- INVENTORY BRIDGE - CLIENT
-- Client-side inventory operations.
-- ================================================

if IsDuplicityVersion() then return end

local inventorySystem = nil

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

    -- Expose inventory type globally for compatibility
    Bridge.InventorySystem = inventorySystem
end)

---Open a stash on client
---@param stashId string
function Bridge.OpenStash(stashId)
    Debugger('Inventory', 'OpenStash:', stashId, '| system:', inventorySystem)
    if inventorySystem == 'ox_inventory' then
        exports.ox_inventory:openInventory('stash', stashId)
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId)
        TriggerEvent('inventory:client:SetCurrentStash', stashId)
    end
end

---Open another player's inventory on client
---@param targetServerId number
function Bridge.OpenPlayerInventory(targetServerId)
    if inventorySystem == 'ox_inventory' then
        exports.ox_inventory:openInventory('player', targetServerId)
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', targetServerId)
    end
end

---Get item count on client side
---@param item string
---@return number count
function Bridge.GetItemCount(item)
    if inventorySystem == 'ox_inventory' then
        local count = exports.ox_inventory:GetItemCount(item)
        return count or 0
    elseif inventorySystem == 'qs-inventory' then
        local result = exports['qs-inventory']:Search(item)
        return result or 0
    elseif Bridge.Framework == 'QBCore' then
        local playerData = Bridge.GetPlayerData()
        if playerData and playerData.items then
            for _, v in pairs(playerData.items) do
                if v and v.name == item then
                    return v.amount or 0
                end
            end
        end
    elseif Bridge.Framework == 'ESX' then
        local playerData = Bridge.GetPlayerData()
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
function Bridge.GetImagePath()
    local paths = BridgeConfig.InventoryImagePaths or {}
    return paths[inventorySystem] or paths['ox_inventory'] or 'nui://ox_inventory/web/images/%s.png'
end

-- ================================================
-- EXPORTS
-- ================================================

if not _BRIDGE_LOADER then
    exports('OpenStash', function(...) return Bridge.OpenStash(...) end)
    exports('OpenPlayerInventory', function(...) return Bridge.OpenPlayerInventory(...) end)
    exports('GetItemCount', function(...) return Bridge.GetItemCount(...) end)
    exports('GetImagePath', function(...) return Bridge.GetImagePath(...) end)
end
