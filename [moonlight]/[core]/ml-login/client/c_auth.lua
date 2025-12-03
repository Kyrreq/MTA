--[[
    Zasób: ml-login
    Plik: client/c_auth.lua
    Opis: Panel logowania (Show Pass + Remember Me + Backspace Hold)
]]

local screenW, screenH = guiGetScreenSize()
local baseX, baseY = 1920, 1080
local zoom = 1

-- Zmienne Stanu
local isInterfaceVisible = false
local currentTab = "login" -- "login" | "register"
local isHoveringAction = false 
local showPassword = false -- Czy pokazywać hasło?
local rememberMe = false   -- Czy zapamiętać dane?

-- Timer do backspace
local backspaceTimer = nil

-- Pola tekstowe
local inputs = {
    login = {text = "", active = false, placeholder = "Login"},
    pass = {text = "", active = false, placeholder = "Hasło", masked = true},
    pass2 = {text = "", active = false, placeholder = "Powtórz hasło", masked = true}
}

-- Funkcja pomocnicza: Czy myszka jest na elemencie?
local function isMouseInPosition(x, y, width, height)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    local cx, cy = (cx * screenW), (cy * screenH)
    return ((cx >= x and cx <= x + width) and (cy >= y and cy <= y + height))
end

local function calculateZoom()
    if screenW < baseX then 
        zoom = screenW / baseX 
    end
end

-- [[ SYSTEM ZAPISU DANYCH (XML) ]] --
local function loadCredentials()
    local xml = xmlLoadFile("@credentials.xml")
    if xml then
        local username = xmlNodeGetAttribute(xml, "username")
        local password = xmlNodeGetAttribute(xml, "password") -- W przyszłości warto to zaszyfrować base64
        
        if username and password then
            inputs.login.text = username
            inputs.pass.text = password
            rememberMe = true
        end
        xmlUnloadFile(xml)
    end
end

local function saveCredentials()
    if rememberMe then
        local xml = xmlCreateFile("@credentials.xml", "login_data")
        if xml then
            xmlNodeSetAttribute(xml, "username", inputs.login.text)
            xmlNodeSetAttribute(xml, "password", inputs.pass.text)
            xmlSaveFile(xml)
            xmlUnloadFile(xml)
        end
    else
        -- Jeśli odznaczono, usuwamy plik
        if fileExists("@credentials.xml") then
            fileDelete("@credentials.xml")
        end
    end
end

-- Rysowanie inputa
local function renderInputBox(key, x, y, w, h, font)
    local inputData = inputs[key]
    local isHover = isMouseInPosition(x, y, w, h)
    
    if isHover then isHoveringAction = true end
    
    local borderColor = inputData.active and tocolor(114, 137, 218, 255) or tocolor(60, 60, 60, 200)
    if isHover and not inputData.active then borderColor = tocolor(90, 90, 90, 200) end

    dxDrawRectangle(x, y, w, h, tocolor(40, 40, 40, 200)) 
    dxDrawRectangle(x, y + h - 2, w, 2, borderColor)

    local textToDraw = inputData.text
    local textColor = tocolor(255, 255, 255, 255)

    if string.len(textToDraw) == 0 and not inputData.active then
        textToDraw = inputData.placeholder
        textColor = tocolor(150, 150, 150, 150)
    elseif inputData.masked and not showPassword then
        -- Pokazuj kropki tylko jeśli masked=true ORAZ showPassword=false
        textToDraw = string.rep("•", string.len(textToDraw))
    end

    if inputData.active and (getTickCount() % 1000 < 500) then
        local textWidth = dxGetTextWidth(textToDraw, 1, font)
        dxDrawLine(x + 10 + textWidth, y + 10, x + 10 + textWidth, y + h - 10, tocolor(255, 255, 255, 200), 2)
    end

    dxDrawText(textToDraw, x + 10, y, x + w - 30, y + h, textColor, 1, font, "left", "center", true)
    
    -- Ikona oka (Show Password) dla pól hasła
    if inputData.masked then
        local eyeX = x + w - 30
        local eyeSize = 20 * zoom
        local eyeY = y + (h - eyeSize) / 2
        
        local eyeHover = isMouseInPosition(eyeX, eyeY, eyeSize, eyeSize)
        if eyeHover then isHoveringAction = true end
        
        local eyeAlpha = (showPassword or eyeHover) and 255 or 100
        dxDrawText(showPassword and "👁️" or "🔒", eyeX, y, x + w, y + h, tocolor(255, 255, 255, eyeAlpha), 1, font, "center", "center")
    end

    return isHover
end

-- RENDER GŁÓWNY
local function renderLoginPanel()
    isHoveringAction = false
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(20, 20, 20, 245))

    local fontHeader = exports['ml-interface']:getFont("Montserrat-Bold", 35 * zoom)
    local fontButton = exports['ml-interface']:getFont("Montserrat-Bold", 12 * zoom)
    local fontInput = exports['ml-interface']:getFont("OpenSans-Regular", 12 * zoom)
    local fontSmall = exports['ml-interface']:getFont("OpenSans-Regular", 10 * zoom)

    local panelW, panelH = 500 * zoom, 580 * zoom -- Zwiększono wysokość dla checkboxa
    local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2

    dxDrawText("MOONLIGHT", panelX, panelY - 80 * zoom, panelX + panelW, panelY, tocolor(255, 255, 255, 255), 1, fontHeader, "center", "bottom")
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(30, 30, 30, 255))

    -- Zakładki
    local tabW, tabH = panelW / 2, 50 * zoom
    if isMouseInPosition(panelX, panelY, tabW, tabH) then isHoveringAction = true end
    if isMouseInPosition(panelX + tabW, panelY, tabW, tabH) then isHoveringAction = true end

    local colorLogin = currentTab == "login" and tocolor(114, 137, 218, 255) or tocolor(50, 50, 50, 255)
    dxDrawRectangle(panelX, panelY, tabW, tabH, colorLogin)
    dxDrawText("LOGOWANIE", panelX, panelY, panelX + tabW, panelY + tabH, tocolor(255, 255, 255), 1, fontButton, "center", "center")

    local colorReg = currentTab == "register" and tocolor(114, 137, 218, 255) or tocolor(50, 50, 50, 255)
    dxDrawRectangle(panelX + tabW, panelY, tabW, tabH, colorReg)
    dxDrawText("REJESTRACJA", panelX + tabW, panelY, panelX + panelW, panelY + tabH, tocolor(255, 255, 255), 1, fontButton, "center", "center")

    -- Inputy
    local startY = panelY + 100 * zoom
    local inputH = 50 * zoom
    local margin = 20 * zoom
    
    renderInputBox("login", panelX + margin, startY, panelW - margin*2, inputH, fontInput)
    renderInputBox("pass", panelX + margin, startY + inputH + margin, panelW - margin*2, inputH, fontInput)

    if currentTab == "register" then
        renderInputBox("pass2", panelX + margin, startY + (inputH + margin)*2, panelW - margin*2, inputH, fontInput)
    else
        -- Checkbox "Zapamiętaj mnie" (Tylko w logowaniu)
        local checkY = startY + (inputH + margin) * 1.8
        local checkSize = 20 * zoom
        local checkX = panelX + margin
        
        -- Hover Checkboxa
        if isMouseInPosition(checkX, checkY, 150 * zoom, checkSize) then isHoveringAction = true end

        -- Kwadracik
        dxDrawRectangle(checkX, checkY, checkSize, checkSize, tocolor(50, 50, 50, 255))
        if rememberMe then
            dxDrawText("✓", checkX, checkY, checkX + checkSize, checkY + checkSize, tocolor(114, 137, 218, 255), 1, fontSmall, "center", "center")
        end
        
        -- Tekst
        dxDrawText("Zapamiętaj mnie", checkX + checkSize + 10, checkY, checkX + 200, checkY + checkSize, tocolor(200, 200, 200, 255), 1, fontSmall, "left", "center")
    end

    -- Przycisk
    local btnY = panelY + panelH - 80 * zoom
    local btnHover = isMouseInPosition(panelX + margin, btnY, panelW - margin*2, 60 * zoom)
    if btnHover then isHoveringAction = true end 

    local btnColor = btnHover and tocolor(134, 157, 238, 255) or tocolor(114, 137, 218, 255)
    dxDrawRectangle(panelX + margin, btnY, panelW - margin*2, 60 * zoom, btnColor)
    dxDrawText(currentTab == "login" and "ZALOGUJ SIĘ" or "ZAŁÓŻ KONTO", panelX + margin, btnY, panelX + panelW - margin, btnY + 60 * zoom, tocolor(255, 255, 255), 1, fontButton, "center", "center")
end

local function submitForm()
    if currentTab == "login" then
        triggerServerEvent("auth:attemptLogin", resourceRoot, inputs.login.text, inputs.pass.text)
    else
        if inputs.pass.text ~= inputs.pass2.text then
            if exports['ml-notify'] then
                exports['ml-notify']:addNotification("error", "Hasła nie są takie same!")
            else
                outputChatBox("Hasła nie są takie same!", 255, 0, 0)
            end
            return
        end
        triggerServerEvent("auth:attemptRegister", resourceRoot, inputs.login.text, inputs.pass.text)
    end
end

-- [[ LOGIKA USUWANIA ZNAKÓW ]] --
local function handleBackspace()
    for k, v in pairs(inputs) do
        if v.active and string.len(v.text) > 0 then
            -- Obsługa UTF-8 podstawowa (usuwanie ostatniego bajtu)
            -- MTA Lua stringi są jednobajtowe, więc to wystarczy dla podstawowych znaków.
            -- Dla pełnego UTF-8 należałoby użyć biblioteki utf8.
            v.text = string.sub(v.text, 1, -2) 
        end
    end
end

-- KLIKNIĘCIA
addEventHandler("onClientClick", root, function(button, state)
    if not isInterfaceVisible or button ~= "left" or state ~= "down" then return end

    local panelW, panelH = 500 * zoom, 580 * zoom
    local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2
    local margin = 20 * zoom
    local startY = panelY + 100 * zoom
    local inputH = 50 * zoom
    local tabW = panelW / 2

    -- Zakładki
    if isMouseInPosition(panelX, panelY, tabW, 50 * zoom) then
        currentTab = "login"; inputs.pass2.active = false; return
    elseif isMouseInPosition(panelX + tabW, panelY, tabW, 50 * zoom) then
        currentTab = "register"; return
    end

    -- Dezaktywacja inputów
    inputs.login.active = false
    inputs.pass.active = false
    inputs.pass2.active = false

    -- Sprawdzanie kliknięcia w inputy i ikonkę oka
    local eyeSize = 20 * zoom
    
    -- Login
    if isMouseInPosition(panelX + margin, startY, panelW - margin*2, inputH) then inputs.login.active = true end
    
    -- Hasło
    local passY = startY + inputH + margin
    if isMouseInPosition(panelX + margin, passY, panelW - margin*2, inputH) then
        -- Sprawdź czy kliknięto w oko
        local eyeX = panelX + margin + (panelW - margin*2) - 30
        local eyeY = passY + (inputH - eyeSize) / 2
        if isMouseInPosition(eyeX, eyeY, eyeSize, eyeSize) then
            showPassword = not showPassword
        else
            inputs.pass.active = true
        end
    end

    -- Hasło 2 (Rejestracja)
    local pass2Y = startY + (inputH + margin)*2
    if currentTab == "register" and isMouseInPosition(panelX + margin, pass2Y, panelW - margin*2, inputH) then 
        local eyeX = panelX + margin + (panelW - margin*2) - 30
        local eyeY = pass2Y + (inputH - eyeSize) / 2
        if isMouseInPosition(eyeX, eyeY, eyeSize, eyeSize) then
            showPassword = not showPassword
        else
            inputs.pass2.active = true 
        end
    end

    -- Checkbox "Zapamiętaj mnie" (tylko login)
    if currentTab == "login" then
        local checkY = startY + (inputH + margin) * 1.8
        local checkX = panelX + margin
        if isMouseInPosition(checkX, checkY, 150 * zoom, 20 * zoom) then
            rememberMe = not rememberMe
        end
    end

    -- Przycisk Submit
    local btnY = panelY + panelH - 80 * zoom
    if isMouseInPosition(panelX + margin, btnY, panelW - margin*2, 60 * zoom) then
        submitForm()
    end
end)

-- WPISYWANIE
addEventHandler("onClientCharacter", root, function(char)
    if not isInterfaceVisible then return end
    for k, v in pairs(inputs) do
        if v.active and string.len(v.text) < 30 then
            v.text = v.text .. char
        end
    end
end)

-- KLAWISZE (Enter, Backspace Hold, Tab)
addEventHandler("onClientKey", root, function(button, press)
    if not isInterfaceVisible then return end
    
    if button == "enter" or button == "num_enter" then
        if press then
            cancelEvent()
            submitForm()
        end
        return
    end

    if button == "backspace" then
        if press then
            handleBackspace() -- Usuń pierwszy znak od razu
            -- Uruchom timer powtarzający usuwanie
            backspaceTimer = setTimer(function()
                if getKeyState("backspace") then
                    handleBackspace()
                end
            end, 100, 0) -- Powtarzaj co 100ms
        else
            -- Klawisz puszczony - zabij timer
            if isTimer(backspaceTimer) then killTimer(backspaceTimer) end
        end
    end

    if button == "tab" and press then
        if inputs.login.active then inputs.login.active = false; inputs.pass.active = true
        elseif inputs.pass.active and currentTab == "register" then inputs.pass.active = false; inputs.pass2.active = true
        end
    end
end)

addEvent("auth:response", true)
addEventHandler("auth:response", resourceRoot, function(type, message, uid)
    if exports['ml-notify'] then
        exports['ml-notify']:addNotification(type, message)
    else
        outputChatBox("["..type.."] " .. message)
    end
    
    if type == "success" and uid then
        -- Jeśli sukces i zaznaczono checkbox, zapisz dane
        saveCredentials()
        
        isInterfaceVisible = false
        removeEventHandler("onClientRender", root, renderLoginPanel)
        showCursor(false)
        guiSetInputMode("allow_binds")
        triggerServerEvent("core:onPlayerJoinGame", resourceRoot)
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    if getElementData(localPlayer, "account_id") then -- Używamy nowego account_id
        return 
    end

    calculateZoom()
    showCursor(true)
    isInterfaceVisible = true
    guiSetInputMode("no_binds")
    
    -- Wczytaj zapamiętane dane
    loadCredentials()
    
    addEventHandler("onClientRender", root, renderLoginPanel)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    guiSetInputMode("allow_binds")
end)