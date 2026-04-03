-- ================================================
-- FRAMEWORK BRIDGE - SERVER
-- Provides unified player management API for
-- ESX and QBCore frameworks.
-- Source: nb-garages/bridge/framework.lua (superset)
-- ================================================

if not IsDuplicityVersion() then return end

local RESOURCE_NAME = GetCurrentResourceName()

-- ================================================
-- PLAYER MANAGEMENT
-- ================================================

---Get the xPlayer (ESX) or Player (QBCore) object for direct framework access
---@param source number Player server ID
---@return table|nil xPlayer or Player object
function Bridge.GetPlayer(source)
    if Bridge.Framework == 'ESX' then
        return Bridge.FrameworkObject.GetPlayerFromId(source)
    elseif Bridge.Framework == 'QBCore' then
        return Bridge.FrameworkObject.Functions.GetPlayer(source)
    end
    return nil
end

---Get player identifier (license for ESX, citizenid for QBCore)
---@param source number Player server ID
---@return string|nil identifier
function Bridge.GetIdentifier(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getIdentifier() or nil
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        return player and player.PlayerData.citizenid or nil
    end
    return nil
end

---Get player SSN (ESX only, returns nil for QBCore)
---@param source number Player server ID
---@return string|nil SSN in format XXX-XX-XXXX or nil
function Bridge.GetSSN(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getSSN() or nil
    end
    return nil
end

---Get player name
---@param source number Player server ID
---@return string name
function Bridge.GetPlayerName(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getName() or GetPlayerName(source)
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if player then
            local charInfo = player.PlayerData.charinfo
            return charInfo and (charInfo.firstname .. ' ' .. charInfo.lastname) or GetPlayerName(source)
        end
        return GetPlayerName(source)
    end
    return GetPlayerName(source)
end

-- ================================================
-- PERMISSIONS
-- ================================================

---Get player permission group
---@param source number Player server ID
---@return string group
function Bridge.GetGroup(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getGroup() or 'user'
    elseif Bridge.Framework == 'QBCore' then
        return Bridge.FrameworkObject.Functions.HasPermission(source, 'admin') and 'admin'
            or Bridge.FrameworkObject.Functions.HasPermission(source, 'god') and 'god'
            or 'user'
    end
    return 'user'
end

---Set player group (ESX only)
---@param source number Player server ID
---@param group string Group name (e.g. 'admin')
---@return boolean success
function Bridge.SetGroup(source, group)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.setGroup(group)
            return true
        end
    end
    return false
end

---Check if player is admin based on AdminGroups config
---Uses the consumer's Config.AdminGroups first, falls back to BridgeConfig.AdminGroups
---@param source number Player server ID
---@return boolean
function Bridge.IsAdmin(source)
    local adminGroups = (Config and Config.AdminGroups) or BridgeConfig.AdminGroups or {}
    local group = Bridge.GetGroup(source)
    for _, adminGroup in ipairs(adminGroups) do
        if group == adminGroup then
            return true
        end
    end
    -- QBCore: also check via ace permissions
    if Bridge.Framework == 'QBCore' then
        for _, adminGroup in ipairs(adminGroups) do
            if Bridge.FrameworkObject.Functions.HasPermission(source, adminGroup) then
                return true
            end
        end
    end
    return false
end

-- ================================================
-- MONEY
-- ================================================

---Add money to player
---@param source number Player server ID
---@param moneyType string 'cash' or 'bank'
---@param amount number Amount to add
---@param reason string|nil Reason for the transaction
---@return boolean success
function Bridge.AddMoney(source, moneyType, amount, reason)
    if amount <= 0 then return false end
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if not xPlayer then return false end
        local account = (moneyType == 'cash') and 'money' or 'bank'
        xPlayer.addAccountMoney(account, amount, reason or RESOURCE_NAME)
        return true
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return false end
        return player.Functions.AddMoney(moneyType, amount, reason or RESOURCE_NAME)
    end
    return false
end

---Remove money from player
---@param source number Player server ID
---@param moneyType string 'cash' or 'bank'
---@param amount number Amount to remove
---@param reason string|nil Reason for the transaction
---@return boolean success
function Bridge.RemoveMoney(source, moneyType, amount, reason)
    if amount <= 0 then return false end
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if not xPlayer then return false end
        local account = (moneyType == 'cash') and 'money' or 'bank'
        xPlayer.removeAccountMoney(account, amount, reason or RESOURCE_NAME)
        return true
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return false end
        return player.Functions.RemoveMoney(moneyType, amount, reason or RESOURCE_NAME)
    end
    return false
end

---Set account money
---@param source number Player server ID
---@param moneyType string 'cash' or 'bank'
---@param amount number Amount to set
---@param reason string|nil Reason for the transaction
---@return boolean success
function Bridge.SetMoney(source, moneyType, amount, reason)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if not xPlayer then return false end
        local account = (moneyType == 'cash') and 'money' or 'bank'
        xPlayer.setAccountMoney(account, amount, reason or RESOURCE_NAME)
        return true
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return false end
        return player.Functions.SetMoney(moneyType, amount, reason or RESOURCE_NAME)
    end
    return false
end

---Get player money
---@param source number Player server ID
---@param moneyType string 'cash' or 'bank'
---@return number amount
function Bridge.GetMoney(source, moneyType)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if not xPlayer then return 0 end
        local account = (moneyType == 'cash') and 'money' or 'bank'
        local acc = xPlayer.getAccount(account)
        return acc and acc.money or 0
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return 0 end
        return player.PlayerData.money[moneyType] or 0
    end
    return 0
end

---Get all player money accounts in normalized format
---@param source number Player server ID
---@return table accounts {cash = number, bank = number, ...}
function Bridge.GetAccounts(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if not xPlayer then return {} end
        local accounts = xPlayer.getAccounts()
        if not accounts then return {} end
        local result = {}
        for _, acc in ipairs(accounts) do
            local key = acc.name == 'money' and 'cash' or acc.name
            result[key] = acc.money or 0
        end
        return result
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return {} end
        return player.PlayerData.money or {}
    end
    return {}
end

-- ================================================
-- JOB
-- ================================================

---Get player job in canonical format
---@param source number Player server ID
---@return table|nil job {name, label, grade, grade_name, grade_label, grade_salary, onDuty}
function Bridge.GetJob(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if not xPlayer then return nil end
        local job = xPlayer.getJob()
        if not job then return nil end
        return {
            name         = job.name,
            label        = job.label,
            grade        = job.grade,
            grade_name   = job.grade_name or '',
            grade_label  = job.grade_label or job.grade_name or '',
            grade_salary = job.grade_salary or 0,
            onDuty       = job.onDuty ~= false,
        }
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return nil end
        local job = player.PlayerData.job
        if not job then return nil end
        return {
            name         = job.name,
            label        = job.label,
            grade        = job.grade and job.grade.level or 0,
            grade_name   = job.grade and job.grade.name or '',
            grade_label  = job.grade and job.grade.name or '',
            grade_salary = job.payment or 0,
            onDuty       = job.onduty or false,
        }
    end
    return nil
end

---Set player job
---@param source number Player server ID
---@param job string Job name
---@param grade number Job grade
---@param onDuty boolean? On duty flag
---@return boolean success
function Bridge.SetJob(source, job, grade, onDuty)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.setJob(job, grade, onDuty)
            return true
        end
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if player then
            return player.Functions.SetJob(job, grade)
        end
    end
    return false
end

---Get player gang in canonical format (QBCore only, returns nil for ESX)
---@param source number Player server ID
---@return table|nil gang {name, label, grade, grade_name, grade_label}
function Bridge.GetGang(source)
    if Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return nil end
        local gang = player.PlayerData.gang
        if not gang then return nil end
        return {
            name        = gang.name,
            label       = gang.label,
            grade       = gang.grade and gang.grade.level or 0,
            grade_name  = gang.grade and gang.grade.name or '',
            grade_label = gang.grade and gang.grade.name or '',
        }
    end
    return nil
end

-- ================================================
-- EXTENDED UTILITIES
-- Some functions have limited support on certain
-- frameworks. See docs for details.
-- ================================================

---Get player playtime in seconds (ESX only)
---@param source number Player server ID
---@return number|nil playtime
function Bridge.GetPlayTime(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getPlayTime() or nil
    end
    return nil
end

---Set player coords / teleport
---@param source number Player server ID
---@param coords vector3|vector4|table
---@return boolean success
function Bridge.SetCoords(source, coords)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer and xPlayer.setCoords then
            xPlayer.setCoords(coords)
            return true
        end
    elseif Bridge.Framework == 'QBCore' then
        local ped = GetPlayerPed(source)
        if ped and ped ~= 0 then
            SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
            return true
        end
    end
    return false
end

---Get player coords
---@param source number Player server ID
---@return vector3|nil coords
function Bridge.GetCoords(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.getCoords(true)
        end
    elseif Bridge.Framework == 'QBCore' then
        local ped = GetPlayerPed(source)
        if ped and ped ~= 0 then
            return GetEntityCoords(ped)
        end
    end
    return nil
end

---Trigger client event for player
---@param source number Player server ID
---@param eventName string Event name
---@vararg any Arguments to pass
function Bridge.TriggerClientEvent(source, eventName, ...)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer and xPlayer.triggerEvent then
            xPlayer.triggerEvent(eventName, ...)
        else
            TriggerClientEvent(eventName, source, ...)
        end
    else
        TriggerClientEvent(eventName, source, ...)
    end
end

---Get/set xPlayer variable (ESX only)
---@param source number Player server ID
---@param key string Variable key
---@param value any? If provided, sets the value; otherwise gets it
---@return any|nil value when getting, or true when setting
function Bridge.PlayerVar(source, key, value)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if not xPlayer then return nil end
        if value ~= nil then
            xPlayer.set(key, value)
            return true
        end
        return xPlayer.get(key)
    end
    return nil
end

---Set player metadata
---@param source number Player server ID
---@param index string Meta key
---@param value string|number|table Meta value
---@param subIndex string? Sub key for nested meta
---@return boolean success
function Bridge.SetMeta(source, index, value, subIndex)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer and xPlayer.setMeta then
            xPlayer.setMeta(index, value, subIndex)
            return true
        end
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return false end
        if subIndex then
            local current = player.PlayerData.metadata[index] or {}
            current[subIndex] = value
            player.Functions.SetMetaData(index, current)
        else
            player.Functions.SetMetaData(index, value)
        end
        return true
    end
    return false
end

---Get player metadata
---@param source number Player server ID
---@param index string? Meta key (nil = all metadata)
---@param subIndex string? Sub key for nested meta
---@return any metadata value
function Bridge.GetMeta(source, index, subIndex)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getMeta(index, subIndex) or nil
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return nil end
        local metadata = player.PlayerData.metadata
        if not index then return metadata end
        local value = metadata and metadata[index] or nil
        if subIndex and type(value) == 'table' then
            return value[subIndex]
        end
        return value
    end
    return nil
end

---Clear player metadata
---@param source number Player server ID
---@param index string Meta key
---@param subIndex string? Sub key for nested meta
---@return boolean success
function Bridge.ClearMeta(source, index, subIndex)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer and xPlayer.clearMeta then
            xPlayer.clearMeta(index, subIndex)
            return true
        end
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not player then return false end
        if subIndex then
            local current = player.PlayerData.metadata[index] or {}
            current[subIndex] = nil
            player.Functions.SetMetaData(index, current)
        else
            player.Functions.SetMetaData(index, nil)
        end
        return true
    end
    return false
end

---Execute command on behalf of player (ESX only)
---@param source number Player server ID
---@param command string Command to execute
---@return boolean success
function Bridge.ExecuteCommand(source, command)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer and xPlayer.executeCommand then
            xPlayer.executeCommand(command)
            return true
        end
    end
    return false
end

-- ================================================
-- BILLING
-- ================================================

---Create a bill/invoice using the framework's billing system
---@param src number Emitter source
---@param targetId number Target player source
---@param amount number Invoice amount
---@param description string|nil Invoice description
---@param jobName string|nil Job name for context
---@return boolean success
function Bridge.CreateBill(src, targetId, amount, description, jobName)
    if Bridge.Framework == 'ESX' then
        if GetResourceState('esx_billing') == 'started' then
            TriggerEvent('esx_billing:sendBill', targetId, 'society_' .. (jobName or 'unknown'), jobName or 'Job', amount, description or '')
            return true
        end
    elseif Bridge.Framework == 'QBCore' then
        if GetResourceState('qb-billing') == 'started' then
            local success = exports['qb-billing']:CreateBill(src, targetId, amount, description or '')
            return success ~= nil
        end
    end
    -- Fallback: try okokBilling
    if GetResourceState('okokBilling') == 'started' then
        local ok = pcall(function()
            exports['okokBilling']:CreateBill(src, targetId, amount, description or '', jobName or 'unknown')
        end)
        return ok
    end
    Debugger('Billing', 'No external billing system found')
    return false
end

-- ================================================
-- EVENTS
-- ================================================

---Register callback for when player data loads on server
---@param cb function Callback receiving (source, identifier)
function Bridge.OnPlayerLoaded(cb)
    if Bridge.Framework == 'ESX' then
        RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
            local identifier = xPlayer and (xPlayer.getIdentifier and xPlayer.getIdentifier() or xPlayer.identifier)
            cb(playerId, identifier)
        end)
    elseif Bridge.Framework == 'QBCore' then
        RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
            local src = source
            local player = Bridge.FrameworkObject.Functions.GetPlayer(src)
            if player then
                cb(src, player.PlayerData.citizenid)
            end
        end)
    end
end

-- ================================================
-- EXPORTS (for third-party scripts)
-- ================================================

if not _BRIDGE_LOADER then
    exports('GetPlayer', function(...) return Bridge.GetPlayer(...) end)
    exports('GetIdentifier', function(...) return Bridge.GetIdentifier(...) end)
    exports('GetSSN', function(...) return Bridge.GetSSN(...) end)
    exports('GetPlayerName', function(...) return Bridge.GetPlayerName(...) end)
    exports('GetGroup', function(...) return Bridge.GetGroup(...) end)
    exports('SetGroup', function(...) return Bridge.SetGroup(...) end)
    exports('IsAdmin', function(...) return Bridge.IsAdmin(...) end)
    exports('AddMoney', function(...) return Bridge.AddMoney(...) end)
    exports('RemoveMoney', function(...) return Bridge.RemoveMoney(...) end)
    exports('SetMoney', function(...) return Bridge.SetMoney(...) end)
    exports('GetMoney', function(...) return Bridge.GetMoney(...) end)
    exports('GetAccounts', function(...) return Bridge.GetAccounts(...) end)
    exports('GetJob', function(...) return Bridge.GetJob(...) end)
    exports('SetJob', function(...) return Bridge.SetJob(...) end)
    exports('GetGang', function(...) return Bridge.GetGang(...) end)
    exports('CreateBill', function(...) return Bridge.CreateBill(...) end)
    exports('OnPlayerLoaded', function(...) return Bridge.OnPlayerLoaded(...) end)
end
