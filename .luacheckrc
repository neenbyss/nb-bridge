-- .luacheckrc
std = "lua54"
max_line_length = false
ignore = {
    "211", -- unused variable (common in FiveM event handlers)
    "212", -- unused argument
    "213", -- unused loop variable
}
globals = {
    -- FiveM natives
    "exports",
    "AddEventHandler",
    "RegisterNetEvent",
    "TriggerEvent",
    "TriggerClientEvent",
    "TriggerServerEvent",
    "RegisterCommand",
    "GetCurrentResourceName",
    "IsDuplicityVersion",
    "GetPlayerName",
    "GetPlayerIdentifierByType",
    "GetPlayerIdentifier",
    "IsPlayerAceAllowed",
    "GetResourceState",
    "GetNumResources",
    "GetResourceByFindIndex",
    "Wait",
    "CreateThread",
    "SetTimeout",
    "GetGameTimer",
    "NetworkGetEntityFromNetworkId",
    "CreateVehicle",
    "SetVehicleNumberPlateText",
    "SetVehicleOnGroundProperly",
    "SetEntityAsMissionEntity",
    "SetModelAsNoLongerNeeded",
    "RequestModel",
    "HasModelLoaded",
    "GetHashKey",
    "GetDisplayNameFromVehicleModel",
    "GetLabelText",
    "SetNotificationTextEntry",
    "AddTextComponentString",
    "DrawNotification",
    "source",
    -- nb-bridge globals
    "Bridge",
    "BridgeConfig",
    "Config",
    "Debugger",
    "_BRIDGE_LOADER",
    -- Third-party globals
    "json",
    "MySQL",
    "lib",
    "vector3",
    "vector4",
    "qbx",
}
files["overrides/"] = { ignore = { "111", "112", "113" } }
