--[[
    Zasób: ml-scoreboard
    Plik: client/c_scoreboard.lua
    Opis: Autorska tablica wyników (CLIENT SIDE FIX)
]]

local screenW, screenH = guiGetScreenSize()
local baseX, baseY = 1920, 1080
local zoom = 1

local isVisible = false
local playerList = {}

-- Konfiguracja Wyglądu
local CONFIG = {
    width = 700,             
    headerHeight = 60,       
    columnHeight = 40,       
    rowHeight = 40,          
    
    colorHeader = {30, 30, 30, 250},
    colorBody = {20, 20, 20, 240},
    colorRowOdd = {25, 25, 25, 200},   
    colorRowEven = {30, 30, 30, 200},
    colorAccent = {114, 137, 218, 255},
    colorMe = {45, 50, 65, 230}
}

-- System czcionek (Fallback)
local function getSmartFont(name, size)
    local fontElement = nil
    if exports['ml-interface'] then
        local status, result = pcall(function() 
            return exports['ml-interface']:getFont(name, size) 
        end)
        if status and result and isElement(result) then
            fontElement = result
        end
    end

    if fontElement then return fontElement end
    if string.find(name, "Bold") then return "default-bold" end
    return "default"
end

local function calculateZoom()
    if screenW < baseX then 
        zoom = screenW / baseX 
        CONFIG.width = 700 * zoom
        CONFIG.headerHeight = 60 * zoom
        CONFIG.columnHeight = 40 * zoom
        CONFIG.rowHeight = 40 * zoom
    end
end

local function removeHex(text)
    if type(text) ~= "string" then return tostring(text) end
    return string.gsub(text, "#%x%x%x%x%x%x", "")
end

local function sortPlayers(a, b)
    if not isElement(a) or not isElement(b) then return false end
    
    local valA = getElementData(a, "playerid") or getElementData(a, "uid") or 999999
    local valB = getElementData(b, "playerid") or getElementData(b, "uid") or 999999
    
    return (tonumber(valA) or 999999) < (tonumber(valB) or 999999)
end

local function updatePlayerList()
    playerList = getElementsByType("player")
    if #playerList > 1 then
        table.sort(playerList, sortPlayers)
    end
end

local function renderScoreboard()
    if not isVisible then return end
    
    local fontHeader = getSmartFont("Montserrat-Bold", 18 * zoom)
    local fontColumn = getSmartFont("OpenSans-Bold", 10 * zoom)
    local fontRow = getSmartFont("OpenSans-Regular", 10 * zoom)
    local fontRowBold = getSmartFont("OpenSans-Bold", 11 * zoom)

    local rowsCount = #playerList
    local totalHeight = CONFIG.headerHeight + CONFIG.columnHeight + (rowsCount * CONFIG.rowHeight)
    
    local x = (screenW - CONFIG.width) / 2
    local y = (screenH - totalHeight) / 2
    if y < 50 then y = 50 end 

    -- 1. NAGŁÓWEK
    dxDrawRectangle(x, y, CONFIG.width, CONFIG.headerHeight, tocolor(CONFIG.colorHeader[1], CONFIG.colorHeader[2], CONFIG.colorHeader[3], CONFIG.colorHeader[4]))
    dxDrawText("MOONLIGHT RPG", x + (25 * zoom), y, x + CONFIG.width, y + CONFIG.headerHeight, tocolor(255, 255, 255, 255), 1.5, fontHeader, "left", "center")
    
    -- [[ FIX: Usunięto getMaxPlayers() (funkcja serwerowa) ]]
    -- Zastąpiono bezpiecznym pobieraniem danych lub stałą wartością
    local maxPlayers = getElementData(root, "max_players") or "32"
    local countText = "Graczy: " .. rowsCount .. " / " .. maxPlayers
    dxDrawText(countText, x, y, x + CONFIG.width - (25 * zoom), y + CONFIG.headerHeight, tocolor(180, 180, 180, 255), 1, fontColumn, "right", "center")

    dxDrawRectangle(x, y + CONFIG.headerHeight - 2, CONFIG.width, 2, tocolor(CONFIG.colorAccent[1], CONFIG.colorAccent[2], CONFIG.colorAccent[3], 255))

    -- 2. KOLUMNY
    local colY = y + CONFIG.headerHeight
    dxDrawRectangle(x, colY, CONFIG.width, CONFIG.columnHeight, tocolor(22, 22, 22, 250))
    
    local colID = x + (30 * zoom)            
    local colUID = x + (100 * zoom)          
    local colName = x + (200 * zoom)         
    local colPing = x + CONFIG.width - (80 * zoom) 

    local scale = (type(fontColumn) == "string") and 1.0 or 1

    dxDrawText("ID", colID, colY, colID + 50, colY + CONFIG.columnHeight, tocolor(150, 150, 150, 255), scale, fontColumn, "left", "center")
    dxDrawText("UID", colUID, colY, colUID + 50, colY + CONFIG.columnHeight, tocolor(150, 150, 150, 255), scale, fontColumn, "left", "center")
    dxDrawText("NAZWA POSTACI", colName, colY, colName + 200, colY + CONFIG.columnHeight, tocolor(150, 150, 150, 255), scale, fontColumn, "left", "center")
    dxDrawText("PING", colPing, colY, colPing + 50, colY + CONFIG.columnHeight, tocolor(150, 150, 150, 255), scale, fontColumn, "center", "center")

    -- 3. LISTA GRACZY (Kod tutaj wcześniej nie docierał przez błąd wyżej)
    local startY = colY + CONFIG.columnHeight
    
    for i, player in ipairs(playerList) do
        if isElement(player) then
            local rowY = startY + ((i-1) * CONFIG.rowHeight)
            
            local rowColor = (i % 2 == 0) and CONFIG.colorRowEven or CONFIG.colorRowOdd
            local isLocal = (player == localPlayer)
            
            if isLocal then 
                rowColor = CONFIG.colorMe 
            end
            
            dxDrawRectangle(x, rowY, CONFIG.width, CONFIG.rowHeight, tocolor(rowColor[1], rowColor[2], rowColor[3], rowColor[4]))

            if isLocal then
                dxDrawRectangle(x, rowY, 3 * zoom, CONFIG.rowHeight, tocolor(CONFIG.colorAccent[1], CONFIG.colorAccent[2], CONFIG.colorAccent[3], 255))
            end

            local id = tostring(getElementData(player, "playerid") or "-")
            local uid = tostring(getElementData(player, "uid") or "-")
            local name = removeHex(getPlayerName(player):gsub("_", " "))
            local ping = getPlayerPing(player)

            local pingColor = tocolor(200, 200, 200, 150)
            if ping > 100 then pingColor = tocolor(255, 200, 0, 200) end
            
            local scaleRow = (type(fontRow) == "string") and 1.0 or 1

            dxDrawText(id, colID, rowY, colID + 50, rowY + CONFIG.rowHeight, tocolor(150,150,150,255), scaleRow, fontRow, "left", "center")
            dxDrawText(uid, colUID, rowY, colUID + 50, rowY + CONFIG.rowHeight, tocolor(114,137,218,255), scaleRow, fontRowBold, "left", "center")
            dxDrawText(name, colName, rowY, colName + 300, rowY + CONFIG.rowHeight, tocolor(255,255,255,255), scaleRow, fontRowBold, "left", "center")
            dxDrawText(tostring(ping), colPing, rowY, colPing + 50, rowY + CONFIG.rowHeight, pingColor, scaleRow, fontRow, "center", "center")
        end
    end
end

bindKey("tab", "down", function()
    updatePlayerList()
    isVisible = true
end)

bindKey("tab", "up", function()
    isVisible = false
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    calculateZoom()
    addEventHandler("onClientRender", root, renderScoreboard)
end)