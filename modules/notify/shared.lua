-- ================================================
-- NOTIFICATION BRIDGE (Shared: client + server)
-- Adapts notifications to different notification systems.
-- Supports: ox_lib, ESX default, QBCore default, GTA native
-- ================================================

Bridge = Bridge or {}

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
    function Bridge.Notify(source, message, type)
        TriggerClientEvent(NOTIFY_EVENT, source, message, type)
    end

else

    -- Client-side notification handler
    RegisterNetEvent(NOTIFY_EVENT, function(message, type)
        Bridge.ShowNotification(message, type)
    end)

    ---Show a notification on the client
    ---@param message string
    ---@param type string 'success'|'error'|'info'|'warning'
    function Bridge.ShowNotification(message, type)
        type = type or 'info'

        if notifySystem == 'ox_lib' then
            exports.ox_lib:notify({
                title = RESOURCE_NAME,
                description = message,
                type = type,
                duration = 5000,
            })
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

-- ================================================
-- EXPORTS
-- ================================================

if not _BRIDGE_LOADER then
    if isServer then
        exports('Notify', function(...) return Bridge.Notify(...) end)
    else
        exports('ShowNotification', function(...) return Bridge.ShowNotification(...) end)
    end
end
