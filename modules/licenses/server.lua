-- ================================================
-- LICENSES BRIDGE (Server-only)
-- Resolves player identity, driver license, and
-- weapon license data from your license system.
--
-- Supports: bcs_licensemanager, okokLicenses, esx_license,
--           QBCore metadata, ESX default
-- Auto-detected at startup.
-- ================================================

if not IsDuplicityVersion() then return end

local licenseSystem = nil

CreateThread(function()
    Wait(500)
    if GetResourceState('bcs_licensemanager') == 'started' then
        licenseSystem = 'bcs_licensemanager'
    elseif GetResourceState('okokLicenses') == 'started' then
        licenseSystem = 'okokLicenses'
    elseif GetResourceState('esx_license') == 'started' then
        licenseSystem = 'esx_license'
    elseif Bridge.Framework == 'QBCore' then
        licenseSystem = 'qbcore'
    elseif Bridge.Framework == 'ESX' then
        licenseSystem = 'esx_default'
    else
        licenseSystem = 'none'
    end
    Debugger('Licenses', 'Detected:', licenseSystem)
end)

-- ================================================
-- BCS HELPER
-- bcs_licensemanager uses granular license names
-- (e.g. driver_car, driver_bike) instead of a single
-- "driver" type. We check all known variants.
-- ================================================

local BCS_LICENSE_NAMES = {
    driver = { 'driver_car', 'driver_bike', 'driver_truck', 'driver_helicopter', 'driver_boat', 'driver_plane' },
    weapon = { 'weapon' },
}

---@param source number
---@param group string Key in BCS_LICENSE_NAMES ('driver', 'weapon')
---@return string|nil licenseName The first matching license, or nil
local function BCS_FindLicense(source, group)
    local names = BCS_LICENSE_NAMES[group]
    if not names then return nil end

    for i = 1, #names do
        local ok, hasIt = pcall(function()
            return exports.bcs_licensemanager:CheckLicense(source, names[i])
        end)
        if ok and hasIt then
            return names[i]
        elseif not ok then
            Debugger('Licenses', 'BCS CheckLicense error for "' .. names[i] .. '":', tostring(hasIt))
        end
    end
    return nil
end

-- ================================================
-- GET IDENTITY
-- ================================================

---Get the full identity of a player
---@param source number
---@return table|nil {firstname, lastname, dob, sex}
function Bridge.GetIdentity(source)
    Debugger('Licenses', 'GetIdentity | source:', source)

    if Bridge.Framework == 'ESX' then
        local xPlayer = Bridge.GetPlayer(source)
        if not xPlayer then return nil end

        local name = xPlayer.getName()
        local firstname, lastname = name:match('^(%S+)%s+(.+)$')

        return {
            firstname = firstname or name,
            lastname  = lastname or '',
            dob       = nil,
            sex       = nil,
        }
    elseif Bridge.Framework == 'QBCore' then
        local player = Bridge.GetPlayer(source)
        if not player then return nil end

        local charinfo = player.PlayerData.charinfo
        if not charinfo then return nil end

        return {
            firstname = charinfo.firstname or '?',
            lastname  = charinfo.lastname or '?',
            dob       = charinfo.birthdate or nil,
            sex       = charinfo.gender == 0 and 'M' or 'F',
        }
    end

    return nil
end

-- ================================================
-- GET DRIVER LICENSE
-- ================================================

---Get driver license status for a player
---@param source number
---@return table {hasLicense: boolean, label: string}
function Bridge.GetDriverLicense(source)
    Debugger('Licenses', 'GetDriverLicense | source:', source, '| system:', licenseSystem)

    if licenseSystem == 'bcs_licensemanager' then
        local found = BCS_FindLicense(source, 'driver')
        if found then
            return { hasLicense = true, label = found }
        end
        return { hasLicense = false, label = '' }
    end

    if licenseSystem == 'okokLicenses' then
        local ok, result = pcall(function()
            return exports.okokLicenses:getLicense(source, 'driver')
        end)
        if ok and result then
            return { hasLicense = true, label = result.label or 'Driver License' }
        end
        return { hasLicense = false, label = '' }
    end

    if licenseSystem == 'esx_license' or licenseSystem == 'esx_default' then
        local xPlayer = Bridge.GetPlayer(source)
        if xPlayer then
            local licenses = xPlayer.getLicenses and xPlayer.getLicenses() or nil
            if licenses then
                for _, lic in ipairs(licenses) do
                    if lic.type == 'drive' or lic.type == 'driver' or lic.type == 'dmv' then
                        return { hasLicense = true, label = lic.label or 'Driver License' }
                    end
                end
            end
        end
        return { hasLicense = false, label = '' }
    end

    if licenseSystem == 'qbcore' then
        local player = Bridge.GetPlayer(source)
        if player then
            local metadata = player.PlayerData.metadata
            if metadata and metadata.licences then
                local hasIt = metadata.licences.driver or metadata.licences['driver'] or false
                return { hasLicense = hasIt == true, label = 'Driver License' }
            end
        end
        return { hasLicense = false, label = '' }
    end

    return { hasLicense = false, label = '' }
end

-- ================================================
-- GET WEAPON LICENSE
-- ================================================

---Get weapon/firearms license status for a player
---@param source number
---@return table {hasLicense: boolean, label: string}
function Bridge.GetWeaponLicense(source)
    Debugger('Licenses', 'GetWeaponLicense | source:', source, '| system:', licenseSystem)

    if licenseSystem == 'bcs_licensemanager' then
        local found = BCS_FindLicense(source, 'weapon')
        if found then
            return { hasLicense = true, label = found }
        end
        return { hasLicense = false, label = '' }
    end

    if licenseSystem == 'okokLicenses' then
        local ok, result = pcall(function()
            return exports.okokLicenses:getLicense(source, 'weapon')
        end)
        if ok and result then
            return { hasLicense = true, label = result.label or 'Weapon License' }
        end
        return { hasLicense = false, label = '' }
    end

    if licenseSystem == 'esx_license' or licenseSystem == 'esx_default' then
        local xPlayer = Bridge.GetPlayer(source)
        if xPlayer then
            local licenses = xPlayer.getLicenses and xPlayer.getLicenses() or nil
            if licenses then
                for _, lic in ipairs(licenses) do
                    if lic.type == 'weapon' or lic.type == 'firearms' then
                        return { hasLicense = true, label = lic.label or 'Weapon License' }
                    end
                end
            end
        end
        return { hasLicense = false, label = '' }
    end

    if licenseSystem == 'qbcore' then
        local player = Bridge.GetPlayer(source)
        if player then
            local metadata = player.PlayerData.metadata
            if metadata and metadata.licences then
                local hasIt = metadata.licences.weapon or metadata.licences['weapon'] or false
                return { hasLicense = hasIt == true, label = 'Weapon License' }
            end
        end
        return { hasLicense = false, label = '' }
    end

    return { hasLicense = false, label = '' }
end

-- ================================================
-- EXPORTS
-- ================================================

if not _BRIDGE_LOADER then
    exports('GetIdentity', function(...) return Bridge.GetIdentity(...) end)
    exports('GetDriverLicense', function(...) return Bridge.GetDriverLicense(...) end)
    exports('GetWeaponLicense', function(...) return Bridge.GetWeaponLicense(...) end)
end
