-- ================================================
-- CALLBACKS BRIDGE (Shared: client + server)
-- Simple server callback system for requesting data
-- from the server without needing exports.
--
-- NOTE: Callback names should be namespaced by the
-- consumer script to avoid collisions, e.g.:
--   Bridge.CreateCallback('nb-garages:getVehicles', ...)
--   Bridge.TriggerServerCallback('nb-garages:getVehicles', ...)
-- ================================================

Bridge = Bridge or {}

local isServer = IsDuplicityVersion()
local RESOURCE_NAME = GetCurrentResourceName()
local TRIGGER_EVENT = RESOURCE_NAME .. ':bridge:triggerCallback'
local RECEIVE_EVENT = RESOURCE_NAME .. ':bridge:receiveCallback'

if isServer then

    local callbacks = {}

    ---Register a server callback
    ---@param name string Unique callback name (namespace with your resource name)
    ---@param cb function(source, respond, ...) Handler that calls respond(...) with the result
    function Bridge.CreateCallback(name, cb)
        callbacks[name] = cb
    end

    RegisterNetEvent(TRIGGER_EVENT, function(name, requestId, ...)
        local src = source
        local cb = callbacks[name]
        if cb then
            cb(src, function(...)
                TriggerClientEvent(RECEIVE_EVENT, src, requestId, ...)
            end, ...)
        else
            TriggerClientEvent(RECEIVE_EVENT, src, requestId, nil)
        end
    end)

    if not _BRIDGE_LOADER then
        exports('CreateCallback', function(...) return Bridge.CreateCallback(...) end)
    end

else

    local requestId = 0
    local pending = {}

    ---Trigger a server callback from client
    ---@param name string Callback name (must match a registered server callback)
    ---@param cb function(...) Called with the server's response
    ---@vararg any Arguments to pass to the server callback
    function Bridge.TriggerServerCallback(name, cb, ...)
        requestId = requestId + 1
        pending[requestId] = cb
        TriggerServerEvent(TRIGGER_EVENT, name, requestId, ...)
    end

    RegisterNetEvent(RECEIVE_EVENT, function(reqId, ...)
        local cb = pending[reqId]
        if cb then
            pending[reqId] = nil
            cb(...)
        end
    end)

    if not _BRIDGE_LOADER then
        exports('TriggerServerCallback', function(...) return Bridge.TriggerServerCallback(...) end)
    end

end
