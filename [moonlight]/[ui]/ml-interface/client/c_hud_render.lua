--[[
    Zasób: ml-interface
    Plik: client/c_hud_render.lua
    Opis: Renderowanie HUD (Prawa strona: Góra - Nick/ID, Dół - Kasa/Status)
]]

local screenW, screenH = guiGetScreenSize()
local baseX, baseY = 1920, 1080
local zoom = 1

-- Konfiguracja
local HUD_CONFIG = {
    -- Prawy Dolny (Kółka)
    iconSize = 50,
    spacing = 10,
    rightMargin = 40,   -- Wspólny margines dla dołu i góry
    bottomMargin = 40,  -- Odstęp kółek od dołu
    
    -- Prawy Górny (Nick/ID)
    topMargin = 30,

    ringThickness = 0.12
}

local ringShader = nil

-- Cache statusów
local statusItems = {
    { type="health", val=100, color={118, 209, 118}, icon=":ml-ui-assets/images/hud_heart.png" },
    { type="armor",  val=0,   color={100, 149, 237}, icon=":ml-ui-assets/images/hud_shield.png" },
    { type="hunger", val=100, color={244, 164, 96},  icon=":ml-ui-assets/images/hud_burger.png" },
    { type="thirst", val=100, color={100, 180, 255}, icon=":ml-ui-assets/images/hud_drop.png" },
    { type="voice",  val=0,   color={150, 150, 150}, icon=":ml-ui-assets/images/hud_mic.png" }
}

local function calculateZoom()
    if screenW < baseX then zoom = screenW / baseX end
end

-- Helpery
local function formatMoney(amount)
    local left, num, right = string.match(tostring(amount), '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

local function formatName(name)
    return string.gsub(name, "_", " ")
end

local function getPlayerID()
    local id = getElementData(localPlayer, "playerid") or getElementData(localPlayer, "uid") or "-"
    return id
end

local function renderStatusHUD()
    if not getElementData(localPlayer, "uid") or isPlayerMapVisible() then return end

    if not ringShader then
        ringShader = dxCreateShader("fx/ring.fx")
        if not ringShader then return end 
    end

    -- Fonty
    local fontName = exports['ml-interface']:getFont("Montserrat-Bold", 16 * zoom) -- Nick powiększony
    local fontID = exports['ml-interface']:getFont("Montserrat-Regular", 12 * zoom) 
    local fontMoney = exports['ml-interface']:getFont("Montserrat-Bold", 24 * zoom) -- Kasa duża

    local rightX = screenW - (HUD_CONFIG.rightMargin * zoom)

    -- [[ 1. SEKCJA GÓRNA (NICK + ID) ]] --
    local name = formatName(getPlayerName(localPlayer))
    local id = "ID: " .. getPlayerID()
    
    local topY = HUD_CONFIG.topMargin * zoom
    
    -- Imię
    dxDrawText(name, 0, topY + 2, rightX + 2, 0, tocolor(0, 0, 0, 100), 1, fontName, "right", "top")
    dxDrawText(name, 0, topY, rightX, 0, tocolor(255, 255, 255, 255), 1, fontName, "right", "top")
    
    -- ID (pod imieniem)
    local idY = topY + (30 * zoom)
    dxDrawText(id, 0, idY + 2, rightX + 2, 0, tocolor(0, 0, 0, 100), 1, fontID, "right", "top")
    dxDrawText(id, 0, idY, rightX, 0, tocolor(200, 200, 200, 200), 1, fontID, "right", "top")


    -- [[ 2. SEKCJA DOLNA (STATUSY + PIENIĄDZE NAD NIMI) ]] --
    
    -- Aktualizacja danych statusów
    statusItems[1].val = getElementHealth(localPlayer)
    statusItems[2].val = getPedArmor(localPlayer)
    
    local visibleItems = {}
    for _, item in ipairs(statusItems) do
        if item.type ~= "armor" or item.val > 0 then
            table.insert(visibleItems, item)
        end
    end

    -- Obliczenia pozycji kółek
    local totalWidth = (#visibleItems * HUD_CONFIG.iconSize * zoom) + ((#visibleItems - 1) * HUD_CONFIG.spacing * zoom)
    
    -- Start rysowania kółek (wyrównane do prawej)
    local startX = rightX - totalWidth
    local startY = screenH - (HUD_CONFIG.bottomMargin * zoom) - (HUD_CONFIG.iconSize * zoom)

    -- PIENIĄDZE (Rysujemy NAD kółkami, wyrównane do prawej krawędzi kółek)
    local money = getPlayerMoney(localPlayer)
    local moneyText = "$ " .. formatMoney(money)
    local moneyY = startY - (50 * zoom) -- 50px nad kółkami
    
    dxDrawText(moneyText, 0, moneyY + 2, rightX + 2, moneyY + 2, tocolor(0, 0, 0, 100), 1, fontMoney, "right", "bottom")
    dxDrawText(moneyText, 0, moneyY, rightX, moneyY, tocolor(118, 209, 118, 255), 1, fontMoney, "right", "bottom")


    -- KÓŁKA
    for i, item in ipairs(visibleItems) do
        local x = startX + ((i-1) * (HUD_CONFIG.iconSize + HUD_CONFIG.spacing) * zoom)
        local size = HUD_CONFIG.iconSize * zoom
        
        local maxVal = 100
        if item.type == "health" and getPedStat(localPlayer, 24) == 1000 then maxVal = 200 end
        local progress = math.min(item.val / maxVal, 1.0)

        dxSetShaderValue(ringShader, "progress", progress)
        dxSetShaderValue(ringShader, "thickness", HUD_CONFIG.ringThickness)
        dxSetShaderValue(ringShader, "color", {item.color[1]/255, item.color[2]/255, item.color[3]/255, 1})
        
        dxDrawImage(x, startY, size, size, ringShader)

        local iconSize = size * 0.5
        local iconOffset = (size - iconSize) / 2
        
        dxDrawImage(x + iconOffset + 1, startY + iconOffset + 1, iconSize, iconSize, item.icon, 0, 0, 0, tocolor(0,0,0,100))
        dxDrawImage(x + iconOffset, startY + iconOffset, iconSize, iconSize, item.icon, 0, 0, 0, tocolor(255,255,255,255))
    end
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    calculateZoom()
    addEventHandler("onClientRender", root, renderStatusHUD)
end)