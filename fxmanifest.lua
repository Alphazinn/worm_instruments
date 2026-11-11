fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Wormhole Studios"
description "worm_instruments"
version "0.1.0"

shared_scripts { -- Don't change the order
    "@ox_lib/init.lua",
    "Shared/Config.lua",
    "Shared/Derived.lua",
    "Shared/Bridge.lua",
    "Locales/*.lua",
    "Shared/Language.lua"
}

server_scripts {
    "Server/*.lua"
}

client_scripts {
    "Client/*.lua"
}

ui_page "UI/dist/index.html"

files {
    "UI/dist/index.html",
    "UI/dist/assets/*.js",
    "UI/dist/assets/*.css",
    "Assets/**"
}

dependencies {
    "/onesync",
    "ox_lib",
    "worm_lib",
    "worm_instruments_assets"
}

escrow_ignore {
    "Shared/Config.lua",
    "Locales/*.lua"
}
