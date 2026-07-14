-- ================================================
-- LOG BRIDGE - SERVER
-- Unified audit-logging API that dispatches to the
-- server's existing logging pipeline:
--   1. qb-log (QBCore/QBX ecosystem) when present
--   2. a Discord webhook (any framework, incl. ESX)
--      configured in BridgeConfig.Logs.Webhooks
--   3. Debugger fallback when nothing is configured
-- This is a PRODUCTION audit trail — it is NOT gated
-- behind Debug (unlike Debugger()).
-- All methods live under Bridge.log.*
-- ================================================

if not IsDuplicityVersion() then return end

Bridge.log = Bridge.log or {}

local RESOURCE_NAME = GetCurrentResourceName()

-- Exported functions execute inside nb-bridge's OWN Lua environment, even when
-- called from another resource — a bare `Config` global read here can NEVER see
-- the calling resource's `Config` table (FX resources are globally isolated;
-- exports are cross-VM calls, not shared_script includes). Per-resource config
-- is therefore tracked explicitly, keyed by GetInvokingResource().
local perResourceLogConfig = {}

---Register this resource's own Logs config so bridge.log.createLog can find it.
---Call this ONCE at resource start (e.g. top of your server main.lua):
---  bridge.log.configure(Config.Logs)
---Without calling this, createLog() falls back to nb-bridge's own BridgeConfig.Logs.
---@param logsConfig table  -- same shape as BridgeConfig.Logs (DefaultColor, QbLogColor, Webhooks)
function Bridge.log.configure(logsConfig)
    local resourceName = GetInvokingResource() or GetCurrentResourceName()
    perResourceLogConfig[resourceName] = logsConfig
end

local function getLogConfig()
    local invoking = GetInvokingResource()
    if invoking and perResourceLogConfig[invoking] then
        return perResourceLogConfig[invoking]
    end
    return (BridgeConfig and BridgeConfig.Logs) or {}
end

---Resolve the webhook URL for a category: per-category override → default → none.
---@param category string
---@return string url empty string when no webhook is configured
local function resolveWebhook(category)
    local logs = getLogConfig()
    local hooks = logs.Webhooks or {}
    return hooks[category] or hooks.default or ''
end

---Send an audit log entry to the server's logging pipeline.
---Dispatch priority: qb-log → Discord webhook (BridgeConfig.Logs.Webhooks) → Debugger.
---Production audit trail — NOT gated behind Debug.
---@param category string Log category / channel key (e.g. 'banking', 'admin')
---@param title string Short log title
---@param message string Human-readable message body
---@param data table|nil Optional structured fields (rendered as Discord embed fields)
---@param mention boolean|nil Ping (qb-log @everyone / webhook @here) — default false
---@return boolean dispatched true when a real sink handled it, false on Debugger fallback
function Bridge.log.createLog(category, title, message, data, mention)
    category = category or 'general'
    title = title or RESOURCE_NAME
    message = message or ''

    -- 1) qb-log — native to the QBCore/QBX ecosystem
    if GetResourceState('qb-log') == 'started' then
        local color = getLogConfig().QbLogColor or 'default'
        TriggerEvent('qb-log:server:CreateLog', category, title, color, message, mention == true)
        return true
    end

    -- 2) Discord webhook — framework-agnostic (works on ESX, which has no native log resource)
    local webhook = resolveWebhook(category)
    if webhook ~= '' then
        local embed = {
            title = title,
            description = message,
            color = tonumber(getLogConfig().DefaultColor) or 3447003,
            footer = { text = RESOURCE_NAME .. ' - ' .. category },
            fields = {},
        }
        if type(data) == 'table' then
            for k, v in pairs(data) do
                embed.fields[#embed.fields + 1] = {
                    name = tostring(k),
                    value = '```' .. (type(v) == 'table' and json.encode(v) or tostring(v)) .. '```',
                    inline = true,
                }
            end
        end
        PerformHttpRequest(webhook, function() end, 'POST', json.encode({
            username = RESOURCE_NAME,
            content = (mention == true) and '@here' or nil,
            embeds = { embed },
        }), { ['Content-Type'] = 'application/json' })
        return true
    end

    -- 3) Fallback — no sink configured
    Debugger('Log', category, title, message, data)
    return false
end
