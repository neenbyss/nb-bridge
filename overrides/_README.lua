--[[
    ================================================
    NB-BRIDGE OVERRIDES
    ================================================

    Place your custom override files in:
      - overrides/client/  (for client-side overrides)
      - overrides/server/  (for server-side overrides)

    Override files load LAST, so you can replace any
    Bridge function by redefining it.

    Example: overrides/server/custom_notify.lua
    -----------------------------------------------
    function Bridge.Notify(source, message, type)
        exports['my_notify']:SendNotification(source, message, type)
    end
    -----------------------------------------------

    Example: overrides/client/custom_progress.lua
    -----------------------------------------------
    function Bridge.Progress(duration, label, anim)
        -- Your custom progress bar logic
        Wait(duration)
        return true
    end
    -----------------------------------------------

    Any .lua file placed in these folders will be
    automatically loaded by nb-bridge.
]]
