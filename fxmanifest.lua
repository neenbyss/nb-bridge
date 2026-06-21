fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Neenbyss Studios'
description 'NB Bridge - Centralized framework abstraction layer for all NB resources'
version '2.0.0'

file 'loader.lua'

shared_scripts {
    'config.lua',
    'shared/init.lua',
    'modules/notify/shared.lua',
    'modules/vehicle/shared.lua',
    'modules/callbacks/shared.lua',
    'modules/events/shared.lua',
}

client_scripts {
    'modules/framework/client.lua',
    'modules/inventory/client.lua',
    'modules/progress/client.lua',
    'overrides/client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/framework/server.lua',
    'modules/inventory/server.lua',
    'modules/licenses/server.lua',
    'modules/diagnostics/server.lua',
    'overrides/server/*.lua',
}
