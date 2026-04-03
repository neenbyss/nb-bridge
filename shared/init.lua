-- ================================================
-- NB-BRIDGE INITIALIZATION (Shared: client + server)
-- Creates the global Bridge table, detects the
-- framework, and provides the Debugger utility.
-- This file MUST load before any module.
-- ================================================

Bridge = Bridge or {}
Bridge.Framework = nil
Bridge.FrameworkObject = nil

local isServer = IsDuplicityVersion()
local RESOURCE_NAME = GetCurrentResourceName()

-- ================================================
-- DEBUGGER
-- Prints formatted debug messages when debug is enabled.
-- Checks both BridgeConfig.Debug and the consumer's Config.Debug.
-- Usage: Debugger('ModuleName', 'message', var1, var2)
-- ================================================

local side = isServer and 'SERVER' or 'CLIENT'

function Debugger(module, ...)
    local debugEnabled = BridgeConfig and BridgeConfig.Debug or false
    if not debugEnabled and Config and Config.Debug then
        debugEnabled = true
    end
    if not debugEnabled then return end

    local args = { ... }
    local parts = {}
    for i = 1, #args do
        local v = args[i]
        if type(v) == 'table' then
            parts[i] = json.encode(v)
        else
            parts[i] = tostring(v)
        end
    end
    print(('[%s][%s][%s] %s'):format(RESOURCE_NAME, side, module, table.concat(parts, ' ')))
end

-- ================================================
-- FRAMEWORK DETECTION
-- Auto-detects ESX or QBCore at startup.
-- ================================================

local function DetectFramework()
    if GetResourceState('es_extended') == 'started' then
        Bridge.Framework = 'ESX'
        Bridge.FrameworkObject = exports['es_extended']:getSharedObject()
        print('[' .. RESOURCE_NAME .. '] Framework detected: ESX')
    elseif GetResourceState('qb-core') == 'started' then
        Bridge.Framework = 'QBCore'
        Bridge.FrameworkObject = exports['qb-core']:GetCoreObject()
        print('[' .. RESOURCE_NAME .. '] Framework detected: QBCore')
    else
        print('[' .. RESOURCE_NAME .. '] ^1ERROR: No compatible framework detected (ESX or QBCore required)^0')
    end
end

DetectFramework()
