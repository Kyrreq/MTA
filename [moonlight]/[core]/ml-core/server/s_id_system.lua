--[[
    Zasób: ml-core
    Plik: server/s_id_system.lua
    Opis: System przydzielania tymczasowego ID sesji (1..MaxPlayers)
]]

local idCache = {} -- Tablica: [ID] = Gracz

-- Funkcja szukająca najniższego wolnego ID
local function findFreeID()
    local maxPlayers = getMaxPlayers()
    for i = 1, maxPlayers do
        if not idCache[i] then
            return i
        end
    end
    return false
end

local function assignPlayerID(player)
    local newID = findFreeID()
    if newID then
        idCache[newID] = player
        setElementData(player, "playerid", newID) -- To dane, które czyta Scoreboard!
        -- Ustawiamy też ID w nazwie gracza (opcjonalne, przydatne przy debugu)
        -- setPlayerName(player, "["..newID.."]"..getPlayerName(player)) 
        outputDebugString("[CORE] Przydzielono ID sesji: " .. newID .. " dla " .. getPlayerName(player))
    else
        outputDebugString("[CORE] BŁĄD: Brak wolnych slotów ID!", 1)
    end
end

local function freePlayerID(player)
    local id = getElementData(player, "playerid")
    if id and idCache[id] == player then
        idCache[id] = nil
        removeElementData(player, "playerid")
        outputDebugString("[CORE] Zwolniono ID sesji: " .. id)
    end
end

-- EVENT: Wejście gracza (Join)
addEventHandler("onPlayerJoin", root, function()
    assignPlayerID(source)
end)

-- EVENT: Wyjście gracza (Quit)
addEventHandler("onPlayerQuit", root, function()
    freePlayerID(source)
end)

-- EVENT: Start zasobu (Dla graczy, którzy już są na serwerze - np. po restarcie skryptu)
addEventHandler("onResourceStart", resourceRoot, function()
    -- Czyścimy cache
    idCache = {}
    
    -- Przydzielamy ID wszystkim obecnym graczom
    for _, player in ipairs(getElementsByType("player")) do
        assignPlayerID(player)
    end
end)