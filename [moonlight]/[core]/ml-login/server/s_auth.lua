--[[
    Zasób: ml-login
    Plik: server/s_auth.lua
    Opis: Logika autoryzacji (Sync Nickname + Accounts Table)
]]

-- EVENT: Logowanie
addEvent("auth:attemptLogin", true)
addEventHandler("auth:attemptLogin", resourceRoot, function(username, password)
    local client = client -- Zabezpieczenie zmiennej client
    
    outputDebugString("[AUTH] Próba logowania: " .. getPlayerName(client) .. " konto: " .. tostring(username))

    -- 1. Walidacja danych wejściowych
    if not username or not password then 
        triggerClientEvent(client, "auth:response", resourceRoot, "error", "Wpisz login i hasło.")
        return 
    end

    -- 2. Pobranie danych z bazy (Pobieramy też 'username' żeby mieć oryginalną pisownię!)
    local q = exports['ml-db']:query("SELECT id, username, password_hash, serial FROM accounts WHERE username=? LIMIT 1", username)

    if not q or #q == 0 then
        triggerClientEvent(client, "auth:response", resourceRoot, "error", "Takie konto nie istnieje.")
        return
    end

    local accountData = q[1]

    -- 3. Weryfikacja hasła (bcrypt)
    if passwordVerify(password, accountData.password_hash) then
        
        -- [[ NOWOŚĆ: Synchronizacja Nicku z Loginem ]] --
        -- Próbujemy zmienić nick gracza na ten z bazy danych
        local currentName = getPlayerName(client)
        local newName = accountData.username
        
        -- Zmieniamy tylko jeśli są różne (ignorując wielkość liter, żeby uniknąć błędów MTA przy zmianie 'nick' na 'Nick')
        if string.lower(currentName) ~= string.lower(newName) then
            local success = setPlayerName(client, newName)
            if not success then
                -- Jeśli nie udało się zmienić nicku (np. ktoś inny o takim nicku jest na serwerze)
                triggerClientEvent(client, "auth:response", resourceRoot, "error", "Ktoś o tym nicku jest już na serwerze!")
                return
            end
        else
            -- Jeśli nick jest ten sam, ale inna wielkość liter (np. gracz 'admin', w bazie 'Admin')
            -- MTA czasem wymaga tricku: zmiana na tymczasowy i powrót, ale zazwyczaj setPlayerName radzi sobie z case-fixem.
            if currentName ~= newName then
                setPlayerName(client, newName)
            end
        end

        -- Zabezpieczenie przed podwójnym zalogowaniem
        if getElementData(client, "account_id") then
            triggerClientEvent(client, "auth:response", resourceRoot, "error", "Jesteś już zalogowany na konto.")
            return
        end

        -- Aktualizacja ostatniego logowania
        exports['ml-db']:exec("UPDATE accounts SET last_login=NOW() WHERE id=?", accountData.id)

        -- Przypisanie danych KONTA
        setElementData(client, "account_id", accountData.id)
        setElementData(client, "account_username", accountData.username) -- Używamy pisowni z bazy
        
        -- UID (tymczasowo = ID konta)
        setElementData(client, "uid", accountData.id) 

        triggerClientEvent(client, "auth:response", resourceRoot, "success", "Zalogowano jako " .. accountData.username, accountData.id)
        outputServerLog("[AUTH] Zalogowano konto: " .. accountData.username .. " (ID: " .. accountData.id .. ")")
        
    else
        triggerClientEvent(client, "auth:response", resourceRoot, "error", "Nieprawidłowe hasło.")
    end
end)

-- EVENT: Rejestracja
addEvent("auth:attemptRegister", true)
addEventHandler("auth:attemptRegister", resourceRoot, function(username, password)
    local client = client
    local serial = getPlayerSerial(client)

    -- 1. Walidacja
    if string.len(username) < 3 or string.len(password) < 5 then
        triggerClientEvent(client, "auth:response", resourceRoot, "error", "Login (min 3) lub hasło (min 5) za krótkie.")
        return
    end

    -- 2. Sprawdzenie zajętości
    local check = exports['ml-db']:query("SELECT username, serial FROM accounts WHERE username=? OR serial=? LIMIT 1", username, serial)

    if check and #check > 0 then
        if check[1].serial == serial then
            triggerClientEvent(client, "auth:response", resourceRoot, "error", "Na tym serialu założono już konto.")
            return
        elseif check[1].username == username then
            triggerClientEvent(client, "auth:response", resourceRoot, "error", "Ten login jest zajęty.")
            return
        end
    end

    -- 3. Tworzenie konta
    local hash = passwordHash(password, "bcrypt", {}) 
    
    local success = exports['ml-db']:exec("INSERT INTO accounts (username, password_hash, serial, admin_level) VALUES (?, ?, ?, 0)", username, hash, serial)

    if success then
        triggerClientEvent(client, "auth:response", resourceRoot, "success", "Konto utworzone! Zaloguj się.")
        outputServerLog("[AUTH] Nowe konto: " .. username .. " (Serial: " .. serial .. ")")
    else
        triggerClientEvent(client, "auth:response", resourceRoot, "error", "Błąd bazy danych (SQL).")
    end
end)