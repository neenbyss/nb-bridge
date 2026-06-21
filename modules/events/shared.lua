-- ================================================
-- EVENTS BRIDGE (Shared: client + server)
-- Unified lifecycle hooks across ESX / QBCore / QBX.
-- All methods live under Bridge.event.*
-- ================================================

Bridge = Bridge or {}
Bridge.event = Bridge.event or {}

local isServer = IsDuplicityVersion()

if isServer then

    ---Fire cb(source) whenever any player finishes loading
    ---@param cb fun(source: number)
    function Bridge.event.onPlayerLoaded(cb)
        -- delegates to existing framework/server.lua implementation
        Bridge.player.onPlayerLoaded(cb)
    end

    ---Fire cb(source) whenever any player unloads or disconnects
    ---@param cb fun(source: number)
    function Bridge.event.onPlayerUnloaded(cb)
        Bridge.player.onPlayerUnloaded(cb)
    end

    ---Fire cb(resourceName) when a resource starts
    ---@param cb fun(resourceName: string)
    function Bridge.event.onResourceStart(cb)
        AddEventHandler('onResourceStart', function(resourceName)
            cb(resourceName)
        end)
    end

    ---Fire cb(resourceName) when a resource stops
    ---@param cb fun(resourceName: string)
    function Bridge.event.onResourceStop(cb)
        AddEventHandler('onResourceStop', function(resourceName)
            cb(resourceName)
        end)
    end

    ---Fire cb() when THIS resource (the consumer calling get()) starts
    ---Uses GetCurrentResourceName() at the time of the call.
    ---@param cb fun()
    function Bridge.event.onSelfStart(cb)
        local name = GetCurrentResourceName()
        AddEventHandler('onResourceStart', function(resourceName)
            if resourceName == name then cb() end
        end)
    end

    ---Fire cb() when THIS resource stops
    ---@param cb fun()
    function Bridge.event.onSelfStop(cb)
        local name = GetCurrentResourceName()
        AddEventHandler('onResourceStop', function(resourceName)
            if resourceName == name then cb() end
        end)
    end

else -- CLIENT

    ---Fire cb() when the local player finishes loading their character
    ---@param cb fun()
    function Bridge.event.onPlayerLoaded(cb)
        Bridge.player.onPlayerLoaded(cb)
    end

    ---Fire cb() when the local player unloads their character
    ---@param cb fun()
    function Bridge.event.onPlayerUnloaded(cb)
        Bridge.player.onPlayerUnloaded(cb)
    end

    ---Fire cb() when the player spawns in the world (after character select)
    ---@param cb fun()
    function Bridge.event.onPlayerSpawned(cb)
        if Bridge.Framework == 'ESX' then
            AddEventHandler('playerSpawned', function()
                cb()
            end)
        elseif Bridge.Framework == 'QBX' or Bridge.Framework == 'QBCore' then
            AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
                cb()
            end)
        end
    end

    ---Fire cb(resourceName) when a resource starts (client-side)
    ---@param cb fun(resourceName: string)
    function Bridge.event.onResourceStart(cb)
        AddEventHandler('onClientResourceStart', function(resourceName)
            cb(resourceName)
        end)
    end

    ---Fire cb(resourceName) when a resource stops (client-side)
    ---@param cb fun(resourceName: string)
    function Bridge.event.onResourceStop(cb)
        AddEventHandler('onClientResourceStop', function(resourceName)
            cb(resourceName)
        end)
    end

end
