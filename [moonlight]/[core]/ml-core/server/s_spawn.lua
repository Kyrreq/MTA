--[[
    Zasób: ml-core
    Plik: server/s_spawn.lua
    Opis: Logika spawnowania postaci
]]

local SPAWN_POS = {x = 1765.6, y = -1896.8, z = 13.6, rot = 270} -- Unity Station LS
local DEFAULT_SKIN = 26 -- Backpacker (neutralny skin cywilny)

function spawnCharacter(player)
    if not isElement(player) then return end
    
    -- Spawnowanie gracza
    spawnPlayer(player, SPAWN_POS.x, SPAWN_POS.y, SPAWN_POS.z, SPAWN_POS.rot, DEFAULT_SKIN)
    
    -- Wymagane, aby kamera podążała za graczem
    setCameraTarget(player, player)
    fadeCamera(player, true, 2.0) -- Płynne rozjaśnienie obrazu (2 sekundy)
    
    outputDebugString("[CORE] Zrespawniono gracza: " .. getPlayerName(player))
end

-- Event wywoływany przez ml-login po udanym zalogowaniu
addEvent("core:onPlayerJoinGame", true)
addEventHandler("core:onPlayerJoinGame", root, function()
    -- 'client' to gracz, który wysłał trigger
    spawnCharacter(client)
end)

-- Zapisywanie pozycji przy wyjściu (Fundament pod przyszły system)
addEventHandler("onPlayerQuit", root, function()
    local x, y, z = getElementPosition(source)
    -- TODO: W przyszłości tutaj dodamy: exports['ml-db']:exec("UPDATE users SET pos_x=?...", x)
    outputDebugString("[CORE] Gracz wyszedł na pozycji: " .. x .. ", " .. y)
end)