fx_version 'cerulean'
game 'gta5'

author 'imaxidev - discord: imaxidev'
description ''
version '1.0.0'

dependencies {
    'ox_lib',
    'es_extended',
    'esx_vehicleshop',
    'esx_license',
    -- Jobs/Trabajos
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

shared_scripts {
    'config.lua',
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
}

lua54 'yes'