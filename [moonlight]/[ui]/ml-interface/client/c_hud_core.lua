--[[
    Zasób: ml-interface
    Plik: client/c_hud_core.lua
    Opis: Zarządzanie widocznością HUD (Ukrywanie standardowego GTA)
]]

local visible = false

local disabledHUD = {
    "ammo",
    "area_name",
    "armour",
    "breath",
    "clock",
    "health",
    "money",
    "radar",
    "vehicle_name",
    "weapon",
    "radio",
    "wanted"
}

function setHUDVisible(state)
    visible = state
    -- Jeśli state to true -> pokazujemy NASZ hud (w przyszłości)
    -- Ale standardowy z GTA zawsze chcemy mieć ukryty na serwerze RP
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Ukrywamy standardowe elementy GTA
    for _, component in ipairs(disabledHUD) do
        setPlayerHudComponentVisible(component, false)
    end
    
    -- Wyłączamy też standardowy chat (bo napiszemy własny w ml-chat), 
    -- ale na razie zostawmy go włączonego do debugowania błędów!
    -- showChat(false) 
end)

-- Zabezpieczenie: Przy wyłączeniu zasobu, przywróć HUD (przydatne przy deweloperce)
addEventHandler("onClientResourceStop", resourceRoot, function()
    for _, component in ipairs(disabledHUD) do
        setPlayerHudComponentVisible(component, true)
    end
end)