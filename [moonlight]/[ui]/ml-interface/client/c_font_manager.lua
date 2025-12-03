--[[
    Zasób: ml-interface
    Plik: client/c_font_manager.lua
    Opis: System zarządzania czcionkami (Caching)
]]

local fontsCache = {}

-- Mapa nazw na ścieżki plików w ml-ui-assets
-- Upewnij się, że nazwy plików tutaj zgadzają się z tymi, które pobrałeś!
local fontPaths = {
    ["Montserrat-Bold"]    = ":ml-ui-assets/fonts/Montserrat-Bold.ttf",
    ["Montserrat-Regular"] = ":ml-ui-assets/fonts/Montserrat-Regular.ttf",
    ["Montserrat-Light"]   = ":ml-ui-assets/fonts/Montserrat-Light.ttf",
    ["OpenSans-Bold"]      = ":ml-ui-assets/fonts/OpenSans-Bold.ttf",
    ["OpenSans-Regular"]   = ":ml-ui-assets/fonts/OpenSans-Regular.ttf",
}

--[[
    Funkcja: getFont
    Argumenty: name (string), size (int)
    Opis: Zwraca element dxFont. Tworzy go tylko jeśli nie istnieje w cache.
]]
function getFont(name, size)
    if not name then return "default" end
    size = size or 10
    
    -- Klucz unikalny dla kombinacji nazwy i rozmiaru, np. "Montserrat-Bold12"
    local cacheKey = name .. size
    
    -- 1. Jeśli mamy czcionkę w cache i jest poprawna, zwracamy ją
    if fontsCache[cacheKey] and isElement(fontsCache[cacheKey]) then
        return fontsCache[cacheKey]
    end
    
    -- 2. Jeśli nie mamy, sprawdzamy czy znamy taką nazwę
    local path = fontPaths[name]
    if not path then
        outputDebugString("[ml-interface] BŁĄD: Nieznana czcionka: " .. tostring(name), 2)
        return "default"
    end
    
    -- 3. Tworzymy nową czcionkę
    local newFont = dxCreateFont(path, size)
    if newFont then
        fontsCache[cacheKey] = newFont
        return newFont
    else
        outputDebugString("[ml-interface] BŁĄD: Nie udało się stworzyć czcionki: " .. path, 1)
        return "default"
    end
end