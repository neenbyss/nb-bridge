-- ================================================
-- VEHICLE BRIDGE (Shared: client + server)
-- Reusable vehicle utilities: plate management,
-- spawning, properties get/set, vehicle insertion.
-- All methods live under Bridge.vehicle.*
-- ================================================

Bridge = Bridge or {}
Bridge.vehicle = Bridge.vehicle or {}

local isServer = IsDuplicityVersion()

---Normalize a GTA plate (trim trailing spaces)
---@param plate string|nil
---@return string
function Bridge.vehicle.normalizePlate(plate)
    if not plate then return '' end
    return plate:match('^(.-)%s*$') or plate
end

if isServer then

    ---Generate a random 8-character plate
    ---@return string
    function Bridge.vehicle.generatePlate()
        local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        local plate = ''
        for _ = 1, 8 do
            local idx = math.random(1, #chars)
            plate = plate .. chars:sub(idx, idx)
        end
        return plate
    end

    ---Give a vehicle to a player (inserts into framework DB)
    ---@param source number Player server ID
    ---@param model string Vehicle model name
    ---@param props table|nil Optional vehicle properties
    ---@return boolean success
    function Bridge.vehicle.giveVehicle(source, model, props)
        if not source or not model then return false end

        local identifier = Bridge.player.getIdentifier(source)
        if not identifier then return false end

        local plate = Bridge.vehicle.generatePlate()
        local vehicleProps = props or {}
        vehicleProps.model = GetHashKey(model)
        vehicleProps.plate = plate

        local propsJson = json.encode(vehicleProps)

        if Bridge.Framework == 'ESX' then
            MySQL.insert.await(
                'INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored, parking) VALUES (?, ?, ?, ?, ?, ?)',
                { identifier, plate, propsJson, 'car', 1, 'default' }
            )
            return true
        elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
            -- QBX uses the same player_vehicles schema as QBCore (citizenid column)
            MySQL.insert.await(
                'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                {
                    GetPlayerIdentifierByType(source, 'license') or '',
                    identifier,
                    model,
                    GetHashKey(model),
                    propsJson,
                    plate,
                    'pillboxgarage',
                    1,
                }
            )
            return true
        end
        return false
    end

    ---Get the full name of a vehicle's owner from the plate
    ---@param plate string
    ---@return string|nil fullName
    function Bridge.vehicle.getVehicleOwnerName(plate)
        if not plate or plate == '' then return nil end

        local owner = nil

        if Bridge.Framework == 'ESX' then
            owner = MySQL.scalar.await(
                'SELECT owner FROM owned_vehicles WHERE plate = ?',
                { plate }
            )
        elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
            -- QBX uses the same player_vehicles/citizenid schema as QBCore
            owner = MySQL.scalar.await(
                'SELECT citizenid FROM player_vehicles WHERE plate = ?',
                { plate }
            )
        end

        if not owner then return nil end

        if Bridge.Framework == 'ESX' then
            local result = MySQL.single.await(
                'SELECT firstname, lastname FROM users WHERE identifier = ?',
                { owner }
            )
            if result then
                return result.firstname .. ' ' .. result.lastname
            end
        elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
            local result = MySQL.single.await(
                'SELECT charinfo FROM players WHERE citizenid = ?',
                { owner }
            )
            if result and result.charinfo then
                local charinfo = type(result.charinfo) == 'string'
                    and json.decode(result.charinfo)
                    or result.charinfo
                if charinfo then
                    return (charinfo.firstname or '?') .. ' ' .. (charinfo.lastname or '?')
                end
            end
        end

        return nil
    end


-- ================================================
-- CLIENT-SIDE VEHICLE FUNCTIONS
-- ================================================
else

    ---Resolve a model string/number to a valid hash
    ---@param model string|number Model name or hash
    ---@return number hash
    function Bridge.vehicle.resolveModelHash(model)
        if type(model) == 'string' then
            local numModel = tonumber(model)
            if numModel then
                return numModel
            else
                return GetHashKey(model)
            end
        end
        return model
    end

    ---Spawn a vehicle at coords with optional properties
    ---Uses GetGameTimer() for wall-clock accurate timeout (not a frame counter).
    ---@param model string|number Model name or hash
    ---@param coords vector3 Spawn position
    ---@param heading number Heading/rotation
    ---@param props table|nil Vehicle properties to apply
    ---@param plate string|nil Plate text to set
    ---@param cb function|nil Callback receiving (vehicle) or (nil) on fail
    function Bridge.vehicle.spawnVehicle(model, coords, heading, props, plate, cb)
        model = Bridge.vehicle.resolveModelHash(model)
        Debugger('Vehicle', 'spawnVehicle | hash:', model, '| type:', type(model))

        RequestModel(model)
        local deadline = GetGameTimer() + 5000
        while not HasModelLoaded(model) and GetGameTimer() < deadline do
            Wait(10)
        end

        if not HasModelLoaded(model) then
            Debugger('Vehicle', 'spawnVehicle | model failed to load:', model)
            if cb then cb(nil) end
            return false
        end

        local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
        SetModelAsNoLongerNeeded(model)

        if props and next(props) then
            Bridge.vehicle.setVehicleProperties(vehicle, props)
        end

        if plate then
            SetVehicleNumberPlateText(vehicle, plate)
        end

        SetVehicleOnGroundProperly(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)

        Debugger('Vehicle', 'spawnVehicle | plate: [' .. (plate or 'nil') .. '] | spawned at:', coords)
        if cb then cb(vehicle) end
        return vehicle
    end

    ---Get vehicle properties (wraps framework function)
    ---@param vehicle number Vehicle entity
    ---@return table properties
    function Bridge.vehicle.getVehicleProperties(vehicle)
        -- ox_lib provides lib.getVehicleProperties; use it when available (QBX always has it)
        if GetResourceState('ox_lib') == 'started' and lib and lib.getVehicleProperties then
            return lib.getVehicleProperties(vehicle)
        elseif Bridge.Framework == 'QBX' then
            -- QBX fallback: use QBCore compat bridge (qbx_core provides qb-core)
            local QB = exports['qb-core']:GetCoreObject()
            if QB and QB.Functions then
                return QB.Functions.GetVehicleProperties(vehicle)
            end
        elseif Bridge.Framework == 'ESX' then
            return Bridge.FrameworkObject.Game.GetVehicleProperties(vehicle)
        elseif Bridge.Framework == 'QBCore' then
            return Bridge.FrameworkObject.Functions.GetVehicleProperties(vehicle)
        end
        return {}
    end

    ---Set vehicle properties (wraps framework function)
    ---@param vehicle number Vehicle entity
    ---@param props table Properties to apply
    function Bridge.vehicle.setVehicleProperties(vehicle, props)
        -- ox_lib provides lib.setVehicleProperties; use it when available (QBX always has it)
        if GetResourceState('ox_lib') == 'started' and lib and lib.setVehicleProperties then
            lib.setVehicleProperties(vehicle, props)
        elseif Bridge.Framework == 'QBX' then
            -- QBX fallback: use QBCore compat bridge
            local QB = exports['qb-core']:GetCoreObject()
            if QB and QB.Functions then
                QB.Functions.SetVehicleProperties(vehicle, props)
            end
        elseif Bridge.Framework == 'ESX' then
            Bridge.FrameworkObject.Game.SetVehicleProperties(vehicle, props)
        elseif Bridge.Framework == 'QBCore' then
            Bridge.FrameworkObject.Functions.SetVehicleProperties(vehicle, props)
        end
    end

    ---Get a vehicle's display label from its model
    ---@param model string|number Model name or hash
    ---@return string label
    function Bridge.vehicle.getVehicleLabel(model)
        if type(model) == 'string' then
            model = GetHashKey(model)
        end
        if not model or model == 0 then return 'Unknown' end
        local displayName = GetDisplayNameFromVehicleModel(model)
        if not displayName or displayName == 'CARNOTFOUND' then return 'Unknown' end
        local label = GetLabelText(displayName)
        if not label or label == 'NULL' then return displayName end
        return label
    end


end
