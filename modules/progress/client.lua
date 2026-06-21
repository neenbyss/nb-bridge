-- ================================================
-- PROGRESS BRIDGE (Client-only)
-- Progress bar abstraction.
-- Supports: ox_lib, native GTA animation fallback
-- All methods live under Bridge.progress.*
-- ================================================

if IsDuplicityVersion() then return end

Bridge.progress = Bridge.progress or {}

local useOxLib = false

CreateThread(function()
    Wait(500)
    useOxLib = GetResourceState('ox_lib') == 'started'
end)

---Show a progress bar (blocking, returns when done)
---@param duration number Duration in milliseconds
---@param label string Display text
---@param anim? table {dict: string, name: string} Animation to play
---@return boolean completed true if finished, false if cancelled
function Bridge.progress.show(duration, label, anim)
    if useOxLib then
        local result = exports.ox_lib:progressBar({
            duration = duration,
            label = label or 'Wait...',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true },
            anim = anim and { dict = anim.dict, clip = anim.name } or nil,
        })
        return result ~= false
    end

    -- Native fallback
    if anim and anim.dict and anim.name then
        if not HasAnimDictLoaded(anim.dict) then
            RequestAnimDict(anim.dict)
            local timeout = 0
            while not HasAnimDictLoaded(anim.dict) and timeout < 50 do
                Wait(100)
                timeout = timeout + 1
            end
        end
        if HasAnimDictLoaded(anim.dict) then
            TaskPlayAnim(PlayerPedId(), anim.dict, anim.name, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end

    local endTime = GetGameTimer() + duration
    while GetGameTimer() < endTime do
        Wait(100)
    end

    if anim then
        ClearPedTasks(PlayerPedId())
    end
    return true
end

