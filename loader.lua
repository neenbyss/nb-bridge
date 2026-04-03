-- ================================================
-- NB-BRIDGE LOADER
-- Include in consumer fxmanifest.lua:
--   shared_scripts { '@nb-bridge/loader.lua' }
--
-- Creates the global Bridge table by loading
-- nb-bridge modules directly into the consumer's
-- environment (same pattern as ox_lib/init.lua).
-- ================================================

if not _VERSION:find('5.4') then
    error('Lua 5.4 must be enabled in the resource manifest!', 2)
end

local resourceName = GetCurrentResourceName()
local bridgeResource = 'nb-bridge'

-- Don't load inside nb-bridge itself
if resourceName == bridgeResource then return end

if Bridge and Bridge._loaded then
    error(("nb-bridge loader already loaded.\n\tRemove duplicate '@nb-bridge/loader.lua' from '@%s/fxmanifest.lua'"):format(resourceName))
end

if GetResourceState(bridgeResource) ~= 'started' then
    error('^1nb-bridge must be started before this resource.^0', 0)
end

local context = IsDuplicityVersion() and 'server' or 'client'
local LoadResourceFile = LoadResourceFile

-- ================================================
-- LOAD MODULE FILE
-- ================================================

local function loadModule(path)
    local chunk = LoadResourceFile(bridgeResource, path)
    if not chunk then return end

    local fn, err = load(chunk, ('@@%s/%s'):format(bridgeResource, path))
    if not fn then
        error(('\n^1Error loading nb-bridge module (%s): %s^0'):format(path, err), 3)
    end

    fn()
end

-- ================================================
-- BOOTSTRAP
-- ================================================

-- 1. Config (BridgeConfig defaults)
loadModule('config.lua')

-- 2. Shared init (creates Bridge global + Debugger + framework detection)
loadModule('shared/init.lua')

-- 3. Modules: shared files first, then context-specific
local modules = {
    'modules/notify/shared.lua',
    'modules/vehicle/shared.lua',
    'modules/callbacks/shared.lua',
    ('modules/framework/%s.lua'):format(context),
    ('modules/inventory/%s.lua'):format(context),
}

-- Client-only modules
if context == 'client' then
    modules[#modules + 1] = 'modules/progress/client.lua'
end

-- Server-only modules
if context == 'server' then
    modules[#modules + 1] = 'modules/licenses/server.lua'
end

-- Flag to skip export registration in modules (they'd register under consumer name)
_BRIDGE_LOADER = true

for i = 1, #modules do
    loadModule(modules[i])
end

_BRIDGE_LOADER = nil

-- Mark as loaded to prevent double-loading
Bridge._loaded = true
