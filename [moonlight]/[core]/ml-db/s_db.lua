--[[
    Zasób: ml-db (FIXED & DEBUG)
    Opis: Moduł bazy danych z wymuszaniem wyboru bazy
]]

local DB_CONFIG = {
    host = "127.0.0.1",
    username = "root",
    password = "",
    database = "moonlight_rpg",
    port = 3306
}

local dbConnection = nil

addEventHandler("onResourceStart", resourceRoot, function()
    -- Tworzymy DSN
    local dsn = string.format("mysql:dbname=%s;host=%s;port=%d;charset=utf8mb4", 
        DB_CONFIG.database, 
        DB_CONFIG.host, 
        DB_CONFIG.port
    )
    
    -- DEBUG: Pokaż co dokładnie wysyłamy do MySQL
    outputDebugString("[ml-db] Próba połączenia DSN: " .. dsn, 3)

    dbConnection = dbConnect("mysql", dsn, DB_CONFIG.username, DB_CONFIG.password, "share=1")

    if dbConnection then
        outputDebugString("[ml-db] Połączono z serwerem MySQL.", 3)
        
        -- TEST: Próba wejścia do bazy ręcznie, aby sprawdzić czy istnieje
        local qH = dbQuery(dbConnection, "USE " .. DB_CONFIG.database)
        local result, _, _ = dbPoll(qH, -1)
        
        if not result then
            outputDebugString("[ml-db] BŁĄD KRYTYCZNY: Baza '"..DB_CONFIG.database.."' NIE ISTNIEJE lub brak dostępu!", 1)
            outputDebugString("[ml-db] Sprawdź phpMyAdmin i upewnij się, że taka baza jest utworzona.", 1)
        else
            outputDebugString("[ml-db] Sukces! Wybrano bazę: " .. DB_CONFIG.database, 3)
        end
    else
        outputDebugString("[ml-db] BŁĄD: Nie udało się nawiązać połączenia z serwerem!", 1)
    end
end)

function query(str, ...)
    if not dbConnection then return nil end
    local qH = dbQuery(dbConnection, str, ...)
    local result, num_rows, last_id = dbPoll(qH, -1)
    
    if not result then
        -- Logowanie błędów SQL
        local errCode, errMsg = num_rows, last_id
        if errCode then
            outputDebugString("[SQL ERROR QUERY] " .. tostring(errMsg), 1)
        end
        return nil
    end
    
    return result, num_rows, last_id
end

function exec(str, ...)
    if not dbConnection then return false end
    
    local qH = dbQuery(dbConnection, str, ...)
    local result, num_affected, last_id = dbPoll(qH, -1)

    if not result then
        local errCode, errMsg = num_affected, last_id
        if errCode then
             outputDebugString("========================================", 1)
             outputDebugString("[SQL ERROR EXEC] Zapytanie: " .. str, 1)
             outputDebugString("[SQL ERROR INFO] " .. tostring(errMsg), 1)
             outputDebugString("========================================", 1)
             return false
        end
    end
    
    return true
end

function getConnection()
    return dbConnection
end