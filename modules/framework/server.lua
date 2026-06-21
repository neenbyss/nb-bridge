-- ================================================
-- FRAMEWORK BRIDGE - SERVER
-- Provides unified player management API for
-- ESX, QBCore, and QBX frameworks.
-- All methods live under Bridge.player.*
-- ================================================

if not IsDuplicityVersion() then return end

Bridge.player = Bridge.player or {}

local RESOURCE_NAME = GetCurrentResourceName()

-- ================================================
-- PLAYER MANAGEMENT
-- ================================================

---Get the xPlayer (ESX) or Player (QBCore/QBX) object for direct framework access
---@param source number Player server ID
---@return table|nil xPlayer or Player object
function Bridge.player.getPlayer(source)
    if Bridge.Framework == 'ESX' then
        return Bridge.FrameworkObject.GetPlayerFromId(source)
    elseif Bridge.Framework == 'QBX' then
        return exports.qbx_core:GetPlayer(source)
    elseif Bridge.Framework == 'QBCore' then
        return Bridge.FrameworkObject.Functions.GetPlayer(source)
    end
    return nil
end

---Get player identifier (license for ESX, citizenid for QBCore/QBX)
---@param source number Player server ID
---@return string|nil identifier
function Bridge.player.getIdentifier(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getIdentifier() or nil
    elseif Bridge.Framework == 'QBX' then
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData.citizenid or nil
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        return player and player.PlayerData.citizenid or nil
    end
    return nil
end

---Get player SSN (ESX only, returns nil for QBCore/QBX)
---@param source number Player server ID
---@return string|nil SSN in format XXX-XX-XXXX or nil
function Bridge.player.getSSN(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getSSN() or nil
    end
    return nil
end

---Get player name
---@param source number Player server ID
---@return string name
function Bridge.player.getPlayerName(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getName() or GetPlayerName(source)
    elseif Bridge.Framework == 'QBX' then
        local player = exports.qbx_core:GetPlayer(source)
        if player then
            local ci = player.PlayerData.charinfo
            return ci and (ci.firstname .. ' ' .. ci.lastname) or GetPlayerName(source)
        end
        return GetPlayerName(source)
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
---@return string group ('god'|'superadmin'|'admin'|'mod'|'user')
function Bridge.player.getGroup(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        return xPlayer and xPlayer.getGroup() or 'user'
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
        -- Use configurable GroupMap so servers can customise their ACE ace names.
        -- BridgeConfig.GroupMap = { god = 'group.god', superadmin = 'group.superadmin', ... }
        local groupMap = (BridgeConfig and BridgeConfig.GroupMap) or {
            god        = 'group.god',
            superadmin = 'group.superadmin',
            admin      = 'group.admin',
            mod        = 'group.mod',
        }
        -- Check in priority order (highest privilege first)
        local order = { 'god', 'superadmin', 'admin', 'mod' }
        for _, groupName in ipairs(order) do
            local ace = groupMap[groupName]
            if ace and IsPlayerAceAllowed(source, ace) then
                return groupName
            end
        end
        return 'user'
    end
    return 'user'
end

---Set player group (ESX only)
---@param source number Player server ID
---@param group string Group name (e.g. 'admin')
---@return boolean success
function Bridge.player.setGroup(source, group)
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
---getGroup() already resolves ACE permissions for QBCore/QBX, so a single group
---comparison is sufficient across all frameworks.
---@param source number Player server ID
---@return boolean
function Bridge.player.isAdmin(source)
    local adminGroups = (Config and Config.AdminGroups) or BridgeConfig.AdminGroups or { 'god', 'superadmin', 'admin' }
    local group = Bridge.player.getGroup(source)
    for _, adminGroup in ipairs(adminGroups) do
        if group == adminGroup then
            return true
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
function Bridge.player.addMoney(source, moneyType, amount, reason)
    if not amount or amount <= 0 then return false end
    if Bridge.Framework == 'QBX' then
        return exports.qbx_core:AddMoney(source, moneyType, amount, reason or RESOURCE_NAME) == true
    elseif Bridge.Framework == 'ESX' then
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
function Bridge.player.removeMoney(source, moneyType, amount, reason)
    if not amount or amount <= 0 then return false end
    if Bridge.Framework == 'QBX' then
        return exports.qbx_core:RemoveMoney(source, moneyType, amount, reason or RESOURCE_NAME) == true
    elseif Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if not xPlayer then return false end
        local account = (moneyType == 'cash') and 'money' or moneyType
        -- ESX removeAccountMoney has no return value; pre-check balance to detect
        -- insufficient funds before deducting (prevents silent overdraft).
        local acc = xPlayer.getAccount(account)
        local current = acc and acc.money or 0
        if current < amount then return false end
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
function Bridge.player.setMoney(source, moneyType, amount, reason)
    if Bridge.Framework == 'QBX' then
        return exports.qbx_core:SetMoney(source, moneyType, amount, reason or RESOURCE_NAME) == true
    elseif Bridge.Framework == 'ESX' then
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
function Bridge.player.getMoney(source, moneyType)
    if Bridge.Framework == 'QBX' then
        return exports.qbx_core:GetMoney(source, moneyType) or 0
    elseif Bridge.Framework == 'ESX' then
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
function Bridge.player.getAccounts(source)
    if Bridge.Framework == 'QBX' then
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return {} end
        return player.PlayerData.money or {}
    elseif Bridge.Framework == 'ESX' then
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
function Bridge.player.getJob(source)
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
    elseif Bridge.Framework == 'QBX' then
        local player = exports.qbx_core:GetPlayer(source)
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
function Bridge.player.setJob(source, job, grade, onDuty)
    if Bridge.Framework == 'QBX' then
        local ok = exports.qbx_core:SetJob(source, job, grade)
        return ok == true
    elseif Bridge.Framework == 'ESX' then
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

---Get player gang in canonical format (QBCore/QBX only, returns nil for ESX)
---@param source number Player server ID
---@return table|nil gang {name, label, grade, grade_name, grade_label}
function Bridge.player.getGang(source)
    if Bridge.Framework == 'QBX' then
        local player = exports.qbx_core:GetPlayer(source)
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
    elseif Bridge.Framework == 'QBCore' then
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
function Bridge.player.getPlayTime(source)
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
function Bridge.player.setCoords(source, coords)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer and xPlayer.setCoords then
            xPlayer.setCoords(coords)
            return true
        end
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
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
function Bridge.player.getCoords(source)
    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.FrameworkObject.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.getCoords(true)
        end
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
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
function Bridge.player.triggerClientEvent(source, eventName, ...)
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
function Bridge.player.playerVar(source, key, value)
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
function Bridge.player.setMeta(source, index, value, subIndex)
    if Bridge.Framework == 'QBX' then
        if subIndex then
            exports.qbx_core:SetMetadata(source, index .. '.' .. subIndex, value)
        else
            exports.qbx_core:SetMetadata(source, index, value)
        end
        return true
    elseif Bridge.Framework == 'ESX' then
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
function Bridge.player.getMeta(source, index, subIndex)
    if Bridge.Framework == 'QBX' then
        if index then
            local key = subIndex and (index .. '.' .. subIndex) or index
            return exports.qbx_core:GetMetadata(source, key)
        end
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData.metadata or nil
    elseif Bridge.Framework == 'ESX' then
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
function Bridge.player.clearMeta(source, index, subIndex)
    if Bridge.Framework == 'QBX' then
        if subIndex then
            exports.qbx_core:SetMetadata(source, index .. '.' .. subIndex, nil)
        else
            exports.qbx_core:SetMetadata(source, index, nil)
        end
        return true
    elseif Bridge.Framework == 'ESX' then
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
function Bridge.player.executeCommand(source, command)
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
function Bridge.player.createBill(src, targetId, amount, description, jobName)
    if Bridge.Framework == 'ESX' then
        if not jobName then
            Debugger('Framework', 'createBill: jobName is nil — refusing to bill society_unknown')
            return false
        end
        if GetResourceState('esx_billing') == 'started' then
            TriggerEvent('esx_billing:sendBill', targetId, 'society_' .. jobName, jobName, amount, description or '')
            return true
        end
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
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
function Bridge.player.onPlayerLoaded(cb)
    if Bridge.Framework == 'ESX' then
        AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
            local src = playerId or source
            -- Defensively resolve xPlayer — ESX versions differ in payload shape
            local resolvedPlayer = xPlayer
            if not resolvedPlayer then
                resolvedPlayer = Bridge.FrameworkObject.GetPlayerFromId(src)
            end
            local identifier = resolvedPlayer and (
                (resolvedPlayer.getIdentifier and resolvedPlayer.getIdentifier())
                or resolvedPlayer.identifier
            ) or nil
            cb(src, identifier)
        end)
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
        -- QBX fires the same event name as QBCore
        AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
            local src = source
            -- Player arg is the Player object in newer QBCore/QBX
            local resolvedPlayer = Player or Bridge.player.getPlayer(src)
            local citizenid = resolvedPlayer and resolvedPlayer.PlayerData and resolvedPlayer.PlayerData.citizenid or nil
            cb(src, citizenid)
        end)
    end
end

