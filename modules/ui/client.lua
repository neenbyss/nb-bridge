-- ================================================
-- UI BRIDGE (Client-only)
-- Framework-agnostic UI lifecycle hooks so menu
-- resources never branch on the framework in their
-- open/close code. Consumers call these around any
-- full-screen NUI, and can redefine them via the
-- overrides/ folder for server-specific behavior.
-- All methods live under Bridge.ui.*
-- ================================================

if IsDuplicityVersion() then return end

Bridge.ui = Bridge.ui or {}

---Call before opening a full-screen NUI menu.
---Blocks the inventory/other menus (statebag) and closes ox_inventory if present.
---@param uiType string|nil Optional label for the UI being opened
---@return boolean ok always true (hook point for overrides)
function Bridge.ui.beforeOpening(uiType)
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('invBusy', true, true)
    end
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:closeInventory()
    end
    return true
end

---Call after a menu closes — MUST be run from BOTH the NUI close callback
---(user pressed ESC/X) AND any server/forced close (death, jail, distance),
---so focus-side effects set by beforeOpening are always released.
---@param uiType string|nil
---@return boolean ok
function Bridge.ui.afterClosing(uiType)
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('invBusy', false, true)
    end
    return true
end

---Call before a menu action that should be gated. Override to add checks;
---return false to veto the action before it runs.
---@param action string
---@return boolean allowed default true
function Bridge.ui.beforeAction(action)
    return true
end

---Call after a menu action completes. Passthrough hook for logging/cleanup.
---@param action string
---@param ok boolean Whether the action succeeded
---@return boolean ok passthrough of ok
function Bridge.ui.afterAction(action, ok)
    return ok
end
