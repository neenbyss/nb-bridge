-- ================================================
-- NOTIFICATION BRIDGE (Shared: client + server)
-- Adapts notifications to different notification systems.
-- Supports: ox_lib, QBX, ESX default, QBCore default, GTA native
-- All methods live under Bridge.notify.*
-- ================================================

Bridge = Bridge or {}
Bridge.notify = Bridge.notify or {}

local isServer = IsDuplicityVersion()
local RESOURCE_NAME = GetCurrentResourceName()
local NOTIFY_EVENT = RESOURCE_NAME .. ':client:notify'
local notifySystem = nil

-- Auto-detect notification system
CreateThread(function()
    Wait(500)
    if GetResourceState('ox_lib') == 'started' then
        notifySystem = 'ox_lib'
    else
        notifySystem = 'default'
    end
end)

if isServer then

    ---Send a notification to a player from server
    ---@param source number Player server ID
    ---@param message string
    ---@param type string 'success'|'error'|'info'|'warning'
    function Bridge.notify.send(source, message, type)
        TriggerClientEvent(NOTIFY_EVENT, source, message, type)
    end

else

    -- Client-side notification handler (routes to Bridge.notify.show)
    RegisterNetEvent(NOTIFY_EVENT, function(message, type)
        Bridge.notify.show(message, type)
    end)

    ---Show a notification on the client
    ---@param message string
    ---@param type string 'success'|'error'|'info'|'warning'
    function Bridge.notify.show(message, type)
        type = type or 'info'

        if notifySystem == 'ox_lib' then
            exports.ox_lib:notify({
                title = RESOURCE_NAME,
                description = message,
                type = type,
                duration = 5000,
            })
        elseif Bridge.Framework == 'QBX' then
            -- QBX requires ox_lib, so this branch is unreachable in standard
            -- QBX deployments. Kept as an explicit safety-net for edge cases
            -- where ox_lib is present but not yet started at call time.
            exports.qbx_core:Notify(message, type, 5000)
        elseif Bridge.Framework == 'ESX' then
            Bridge.FrameworkObject.ShowNotification(message)
        elseif Bridge.Framework == 'QBCore' then
            Bridge.FrameworkObject.Functions.Notify(message, type, 5000)
        else
            SetNotificationTextEntry('STRING')
            AddTextComponentString(message)
            DrawNotification(false, false)
        end
    end

end

