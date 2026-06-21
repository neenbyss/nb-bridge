-- ================================================
-- DIAGNOSTICS (Server-side)
-- Returns a snapshot of nb-bridge runtime state.
-- Admin command: /nbdiag
-- ================================================

if not IsDuplicityVersion() then return end

local RESOURCE_NAME = GetCurrentResourceName()
local VERSION = '2.0.0'

---Return a diagnostics snapshot of nb-bridge runtime state
---@return table
function Bridge.diagnostics()
    local features = {
        ox_lib       = GetResourceState('ox_lib') == 'started',
        ox_inventory = GetResourceState('ox_inventory') == 'started',
        oxmysql      = GetResourceState('oxmysql') == 'started',
        qs_inventory = GetResourceState('qs-inventory') == 'started',
        origen       = GetResourceState('origen_inventory') == 'started',
        qb_inventory = GetResourceState('qb-inventory') == 'started',
    }

    local missing = {}
    if not features.oxmysql then missing[#missing + 1] = 'oxmysql (required)' end
    if Bridge.Framework == 'QBX' and not features.ox_inventory then
        missing[#missing + 1] = 'ox_inventory (required by QBX)'
    end
    if Bridge.Framework == 'QBX' and not features.ox_lib then
        missing[#missing + 1] = 'ox_lib (required by QBX)'
    end

    return {
        version         = VERSION,
        framework       = Bridge.Framework or 'none',
        inventorySystem = Bridge.InventorySystem or 'not yet resolved',
        side            = 'server',
        uptime          = GetGameTimer(),
        features        = features,
        missing         = missing,
    }
end

-- /nbdiag — prints diagnostics to server console and notifies the admin
RegisterCommand('nbdiag', function(source, args, rawCommand)
    -- Allow: console (source 0) or in-game admin
    if source ~= 0 and not Bridge.player.isAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                args = {'nb-bridge', 'You do not have permission to run /nbdiag.'}
            })
        end
        return
    end

    local diag = Bridge.diagnostics()
    local lines = {
        '^3[nb-bridge] Diagnostics^0',
        ('  Version:    %s'):format(diag.version),
        ('  Framework:  %s'):format(diag.framework),
        ('  Inventory:  %s'):format(diag.inventorySystem),
        ('  Uptime:     %.1fs'):format(diag.uptime / 1000),
        '  Features:',
    }
    for k, v in pairs(diag.features) do
        local icon = v and '^2✓^0' or '^1✗^0'
        lines[#lines + 1] = ('    %s %s'):format(icon, k)
    end
    if #diag.missing > 0 then
        lines[#lines + 1] = '^1  Missing dependencies:^0'
        for _, m in ipairs(diag.missing) do
            lines[#lines + 1] = ('    - %s'):format(m)
        end
    else
        lines[#lines + 1] = '^2  No missing dependencies.^0'
    end

    local output = table.concat(lines, '\n')
    print(output)

    if source ~= 0 then
        -- Also send to in-game admin's chat
        for _, line in ipairs(lines) do
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 215, 0},
                args = {'nb-bridge', line}
            })
        end
    end
end, true)

-- Also register as export so other resources can call bridge.diagnostics()
if not _BRIDGE_LOADER then
    exports('diagnostics', function()
        return Bridge.diagnostics()
    end)
end
