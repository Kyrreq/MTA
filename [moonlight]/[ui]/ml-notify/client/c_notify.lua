--[[
    Zasób: ml-notify
    Plik: client/c_notify.lua
    Opis: System powiadomień (High Priority Fix)
]]

local screenW, screenH = guiGetScreenSize()
local baseX, baseY = 1920, 1080
local zoom = 1

local notifications = {}

-- Konfiguracja wyglądu
local CONFIG = {
    x = 20,              
    startY = 350,        
    width = 300,         
    height = 60,         
    spacing = 10,        
    fadeTime = 300,      -- Przyspieszyłem animację dla lepszej dynamiki
    displayTime = 5000   
}

local TYPES = {
    ["success"] = {118, 209, 118},
    ["error"]   = {214, 86, 86},
    ["info"]    = {100, 149, 237},
    ["warning"] = {255, 193, 7},
}

local function calculateZoom()
    if screenW < baseX then 
        zoom = screenW / baseX 
        CONFIG.x = 20 * zoom
        CONFIG.width = 300 * zoom
        CONFIG.height = 60 * zoom
        CONFIG.spacing = 10 * zoom
        CONFIG.startY = 350 * zoom 
    end
end

function addNotification(type, message)
    if not type or not message then return end
    if not TYPES[type] then type = "info" end
    
    table.insert(notifications, 1, {
        type = type,
        message = message,
        alpha = 0,
        tick = getTickCount(),
        state = "fadeIn"
    })
    
    playSoundFrontEnd(11) 
end

function add(type, message)
    addNotification(type, message)
end

-- Wydzielona funkcja renderująca
local function renderNotifications()
    if #notifications == 0 then return end
    
    -- Pobieranie fontów (Cache'owane przez ml-interface, więc bezpieczne w pętli)
    local fontTitle = exports['ml-interface']:getFont("Montserrat-Bold", 12 * zoom)
    local fontMsg = exports['ml-interface']:getFont("OpenSans-Regular", 10 * zoom)
    
    local currentY = screenH - CONFIG.startY

    for i, notify in ipairs(notifications) do
        local now = getTickCount()
        local timeElapsed = now - notify.tick
        
        if notify.state == "fadeIn" then
            local progress = timeElapsed / CONFIG.fadeTime
            notify.alpha = math.min(progress * 255, 255)
            if progress >= 1 then notify.state = "display" end
            
        elseif notify.state == "display" then
            notify.alpha = 255
            if timeElapsed > (CONFIG.displayTime + CONFIG.fadeTime) then
                notify.state = "fadeOut"
                notify.fadeOutStart = now
            end
            
        elseif notify.state == "fadeOut" then
            local fadeProgress = (now - notify.fadeOutStart) / CONFIG.fadeTime
            notify.alpha = math.max(255 - (fadeProgress * 255), 0)
            if fadeProgress >= 1 then
                notify.remove = true
            end
        end
        
        if notify.alpha > 0 then
            local typeColor = TYPES[notify.type]
            
            -- Używamy postGUI = true (ostatni argument), aby rysować ponad panelem logowania
            
            -- Tło (Bardziej nieprzezroczyste dla lepszego kontrastu: 240 zamiast alpha*0.9)
            dxDrawRectangle(CONFIG.x, currentY, CONFIG.width, CONFIG.height, tocolor(30, 30, 30, notify.alpha), true)
            
            -- Pasek koloru
            dxDrawRectangle(CONFIG.x, currentY, 5 * zoom, CONFIG.height, tocolor(typeColor[1], typeColor[2], typeColor[3], notify.alpha), true)
            
            -- Tytuł
            local titleText = string.upper(notify.type)
            if notify.type == "error" then titleText = "BŁĄD" end
            if notify.type == "info" then titleText = "INFO" end
            if notify.type == "success" then titleText = "SUKCES" end
            
            dxDrawText(titleText, CONFIG.x + (15 * zoom), currentY + (5 * zoom), CONFIG.x + CONFIG.width, currentY + (25 * zoom), tocolor(200, 200, 200, notify.alpha), 1, fontTitle, "left", "top", false, false, true)
            
            -- Wiadomość
            dxDrawText(notify.message, CONFIG.x + (15 * zoom), currentY + (25 * zoom), CONFIG.x + CONFIG.width - (10 * zoom), currentY + CONFIG.height - (5 * zoom), tocolor(255, 255, 255, notify.alpha), 1, fontMsg, "left", "top", true, true, true)
        end
        
        if not notify.remove then
            currentY = currentY - (CONFIG.height + CONFIG.spacing)
        end
    end
    
    for i = #notifications, 1, -1 do
        if notifications[i].remove then
            table.remove(notifications, i)
        end
    end
end

-- Event Handler z PRIORYTETEM
-- "high+100" oznacza: Rysuj to po wszystkim innym (nawet po 'high')
addEventHandler("onClientResourceStart", resourceRoot, function()
    calculateZoom()
    addEventHandler("onClientRender", root, renderNotifications, true, "high+100")
end)