-- ================================================
-- FRAMEWORK BRIDGE - CLIENT
-- Provides unified player data API for
-- ESX, QBCore, and QBX frameworks.
-- All methods live under Bridge.player.*
-- ================================================

if IsDuplicityVersion() then return end

Bridge.player = Bridge.player or {}

-- ================================================
-- RAW PLAYER DATA (framework-specific)
-- ================================================

---Get raw player data from framework (not normalized)
---@return table|nil playerData
function Bridge.player.getPlayerData()
    if Bridge.Framework == 'ESX' then
        return Bridge.FrameworkObject.GetPlayerData()
    elseif Bridge.Framework == 'QBX' then
        return exports.qbx_core:GetPlayerData()
    elseif Bridge.Framework == 'QBCore' then
        return Bridge.FrameworkObject.Functions.GetPlayerData()
    end
    return nil
end

-- ================================================
-- NORMALIZED GETTERS
-- These mirror server-side functions and always
-- return the same canonical format regardless
-- of framework.
-- ================================================

---Get player job in canonical format
---@return table|nil job {name, label, grade, grade_name, grade_label, grade_salary, onDuty}
function Bridge.player.getJob()
    local pd = Bridge.player.getPlayerData()
    if not pd then return nil end

    if Bridge.Framework == 'ESX' then
        local job = pd.job
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
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
        -- QBX PlayerData.job has the same structure as QBCore
        local job = pd.job
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

---Get player gang in canonical format (QBCore/QBX only, returns nil for ESX)
---@return table|nil gang {name, label, grade, grade_name, grade_label}
function Bridge.player.getGang()
    if Bridge.Framework ~= 'QBCore' and Bridge.Framework ~= 'QBX' then return nil end
    local pd = Bridge.player.getPlayerData()
    if not pd or not pd.gang then return nil end
    local gang = pd.gang
    return {
        name        = gang.name,
        label       = gang.label,
        grade       = gang.grade and gang.grade.level or 0,
        grade_name  = gang.grade and gang.grade.name or '',
        grade_label = gang.grade and gang.grade.name or '',
    }
end

---Get player money for a specific account
---@param moneyType string 'cash' or 'bank'
---@return number amount
function Bridge.player.getMoney(moneyType)
    local pd = Bridge.player.getPlayerData()
    if not pd then return 0 end

    if Bridge.Framework == 'ESX' then
        local account = (moneyType == 'cash') and 'money' or moneyType
        if pd.accounts then
            for _, acc in ipairs(pd.accounts) do
                if acc.name == account then
                    return acc and acc.money or 0
                end
            end
        end
        return 0
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
        return pd.money and pd.money[moneyType] or 0
    end
    return 0
end

---Get all player money accounts in normalized format
---@return table accounts {cash = number, bank = number, ...}
function Bridge.player.getAccounts()
    local pd = Bridge.player.getPlayerData()
    if not pd then return {} end

    if Bridge.Framework == 'ESX' then
        local result = {}
        if pd.accounts then
            for _, acc in ipairs(pd.accounts) do
                local key = acc.name == 'money' and 'cash' or acc.name
                result[key] = acc.money or 0
            end
        end
        return result
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
        return pd.money or {}
    end
    return {}
end

---Get player identifier (license for ESX, citizenid for QBCore/QBX)
---@return string|nil identifier
function Bridge.player.getIdentifier()
    local pd = Bridge.player.getPlayerData()
    if not pd then return nil end

    if Bridge.Framework == 'ESX' then
        return pd.identifier
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
        return pd.citizenid
    end
    return nil
end

---Get player character name
---@return string name
function Bridge.player.getPlayerName()
    local pd = Bridge.player.getPlayerData()
    if not pd then return GetPlayerName(PlayerId()) end

    if Bridge.Framework == 'ESX' then
        return pd.firstName and (pd.firstName .. ' ' .. (pd.lastName or '')) or GetPlayerName(PlayerId())
    elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
        local ci = pd.charinfo
        return ci and (ci.firstname .. ' ' .. ci.lastname) or GetPlayerName(PlayerId())
    end
    return GetPlayerName(PlayerId())
end

---Get player permission group (informational on client — use server callback for reliable checks)
---@return string group
function Bridge.player.getGroup()
    local pd = Bridge.player.getPlayerData()
    if not pd then return 'user' end

    if Bridge.Framework == 'ESX' then
        return pd.group or 'user'
    end
    return 'user'
end

-- ================================================
-- EVENT HANDLERS
-- ================================================

---Register a callback for when the local player unloads/logs out (client)
---Callback receives no arguments
---@param cb function
function Bridge.player.onPlayerUnloaded(cb)
    if Bridge.Framework == 'ESX' then
        RegisterNetEvent('esx:onPlayerLogout', function()
            cb()
        end)
    elseif Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
        -- QBX fires the same event name as QBCore
        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
            cb()
        end)
    end
end

---Register callback for when player data is loaded on client
---Callback receives no arguments — use Bridge.player.getJob() etc. to read data
---@param cb function
function Bridge.player.onPlayerLoaded(cb)
    if Bridge.Framework == 'ESX' then
        RegisterNetEvent('esx:playerLoaded', function()
            cb()
        end)
    elseif Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
        -- QBX fires the same event name as QBCore
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            cb()
        end)
    end
end

---Register callback for when player job changes on client
---Callback receives normalized job table
---@param cb function(job) where job = {name, label, grade, grade_name, grade_label, grade_salary, onDuty}
function Bridge.player.onJobUpdate(cb)
    if Bridge.Framework == 'ESX' then
        RegisterNetEvent('esx:setJob', function(job)
            cb({
                name         = job.name,
                label        = job.label,
                grade        = job.grade,
                grade_name   = job.grade_name or '',
                grade_label  = job.grade_label or job.grade_name or '',
                grade_salary = job.grade_salary or 0,
                onDuty       = job.onDuty ~= false,
            })
        end)
    elseif Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
        -- QBX fires the same event name as QBCore
        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
            cb({
                name         = job.name,
                label        = job.label,
                grade        = job.grade and job.grade.level or 0,
                grade_name   = job.grade and job.grade.name or '',
                grade_label  = job.grade and job.grade.name or '',
                grade_salary = job.payment or 0,
                onDuty       = job.onduty or false,
            })
        end)
    end
end

---Register callback for when player gang changes on client (QBCore/QBX only)
---@param cb function(gang) where gang = {name, label, grade, grade_name, grade_label}
function Bridge.player.onGangUpdate(cb)
    if Bridge.Framework == 'QBCore' or Bridge.Framework == 'QBX' then
        -- QBX fires the same event name as QBCore
        RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
            cb({
                name        = gang.name,
                label       = gang.label,
                grade       = gang.grade and gang.grade.level or 0,
                grade_name  = gang.grade and gang.grade.name or '',
                grade_label = gang.grade and gang.grade.name or '',
            })
        end)
    end
end

