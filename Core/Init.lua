local addonName, ns = ...

ns.name = "PuchiAssists"
ns.version = "1.0.0"

local addon = CreateFrame("Frame")
ns.addon = addon

local DEFAULT_CONFIG = {
  showWorldMapButton = true,
  showBossTooltip = true,
}

local function Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPuchiAssists|r: " .. tostring(message))
end

ns.Print = Print

local function EnsureConfig()
  PuchiAssistsDB = PuchiAssistsDB or {}
  PuchiAssistsDB.config = PuchiAssistsDB.config or {}

  for key, value in pairs(DEFAULT_CONFIG) do
    if PuchiAssistsDB.config[key] == nil then
      PuchiAssistsDB.config[key] = value
    end
  end

  ns.config = PuchiAssistsDB.config
end

local function PrintStatus()
  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  local debug = ns.MapHubMenu and ns.MapHubMenu.GetDebugStatus and ns.MapHubMenu:GetDebugStatus() or {}

  Print("Addon: " .. tostring(ns.name) .. " v" .. tostring(ns.version))
  Print("Clase: " .. tostring(classData.classDisplayName or "N/D") .. " (" .. tostring(classData.classToken or "N/D") .. ")")
  Print("Spec: " .. tostring(classData.specName or "N/D"))
  Print("WorldMap visible: " .. ((debug.worldMapShown and "SI") or "NO"))
  Print("Boton creado: " .. ((debug.buttonExists and "SI") or "NO") .. " | visible: " .. ((debug.buttonShown and "SI") or "NO"))
end

local function OpenEntryById(entryId)
  local entry = ns.Instances and ns.Instances:GetByID(entryId)
  if not entry then
    Print("Instancia no reconocida: " .. tostring(entryId))
    return
  end

  if ns.MapHubMenu and ns.MapHubMenu.OpenEntry then
    ns.MapHubMenu:OpenEntry(entry)
  end
end

local function PrintHelp()
  Print("Comandos disponibles:")
  Print("  /puchi status          - Muestra clase/spec y estado de modulos")
  Print("  /puchi open <id>       - Abre ventana de loot de la instancia")
  Print("  /puchi mapbutton       - Reinicia boton del mapa")
  Print("  /puchi pines on|off    - Activa/desactiva boton en el mapa")
  Print("  /puchi tooltip on|off  - Activa/desactiva tooltip BiS en bosses")
  Print("  /puchi mapid           - Muestra MapID actual e info de instancia")
  Print("  /puchi testpin on|off  - Crea/elimina un pin de prueba en el mapa")
end

addon:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local loadedAddonName = ...
    if loadedAddonName ~= addonName and loadedAddonName ~= "Blizzard_WorldMap" then
      return
    end

    if loadedAddonName == addonName then
      EnsureConfig()
      if ns.ClassResolver and ns.ClassResolver.Init then
        ns.ClassResolver:Init()
      end
      if ns.BossTooltip and ns.BossTooltip.Init then
        ns.BossTooltip:Init()
      end
    end

    if loadedAddonName == "Blizzard_WorldMap" and ns.MapHubMenu and ns.MapHubMenu.Init then
      ns.MapHubMenu:Init()
    end
  elseif event == "PLAYER_LOGIN" then
    if ns.ClassResolver and ns.ClassResolver.Refresh then
      ns.ClassResolver:Refresh()
    end

    if IsAddOnLoaded and IsAddOnLoaded("Blizzard_WorldMap") and ns.MapHubMenu and ns.MapHubMenu.Init then
      ns.MapHubMenu:Init()
    end
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    local unit = ...
    if unit == "player" and ns.ClassResolver and ns.ClassResolver.Refresh then
      ns.ClassResolver:Refresh()
    end
    if ns.BossTooltip and ns.BossTooltip.InvalidateCache then
      ns.BossTooltip:InvalidateCache()
    end
  end
end)

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

SLASH_PUCHIASSIST1 = "/puchi"
SlashCmdList.PUCHIASSIST = function(msg)
  local rawText = tostring(msg or "")
  local command, rest = string.match(rawText, "^(%S+)%s*(.*)$")
  command = command and string.lower(command) or "status"
  rest = rest or ""

  if command == "status" then
    PrintStatus()
    return
  end

  if command == "open" then
    OpenEntryById(string.lower(rest))
    return
  end

  if command == "mapbutton" then
    if ns.MapHubMenu and ns.MapHubMenu.Init then
      ns.MapHubMenu:Init()
    end
    if ns.MapHubMenu and ns.MapHubMenu.RefreshVisibility then
      ns.MapHubMenu:RefreshVisibility()
    end
    PrintStatus()
    return
  end

  if command == "pines" then
    local value = string.lower(rest or "")
    if value == "on" then
      ns.config.showWorldMapButton = true
      Print("Pines en mapa: ACTIVADO")
    elseif value == "off" then
      ns.config.showWorldMapButton = false
      Print("Pines en mapa: DESACTIVADO")
    else
      Print("Uso: /puchi pines on|off")
    end
    if ns.MapHubMenu and ns.MapHubMenu.RefreshVisibility then
      ns.MapHubMenu:RefreshVisibility()
    end
    return
  end

  if command == "tooltip" then
    local value = string.lower(rest or "")
    if value == "on" then
      ns.config.showBossTooltip = true
      Print("Tooltip BiS en bosses: ACTIVADO")
    elseif value == "off" then
      ns.config.showBossTooltip = false
      Print("Tooltip BiS en bosses: DESACTIVADO")
    else
      Print("Uso: /puchi tooltip on|off")
    end
    return
  end

  if command == "mapid" then
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
    Print("MapID actual: " .. tostring(mapID or "N/D"))
    if mapID and ns.Instances then
      for _, entry in ipairs(ns.Instances:GetAll()) do
        if entry.uiMapID == mapID then
          Print("Instancia detectada: " .. tostring(ns.Instances:GetLocalizedName(entry)) .. " (" .. tostring(entry.id) .. ")")
        end
      end
    end
    return
  end

  if command == "testpin" then
    local value = string.lower(rest or "")
    if value == "on" then
      if ns.MapHubMenu and ns.MapHubMenu.SetTestPin then
        ns.MapHubMenu:SetTestPin(true)
        Print("Pin de prueba: ACTIVADO")
      else
        Print("Funcion de pin de prueba no disponible.")
      end
    elseif value == "off" then
      if ns.MapHubMenu and ns.MapHubMenu.SetTestPin then
        ns.MapHubMenu:SetTestPin(false)
        Print("Pin de prueba: DESACTIVADO")
      else
        Print("Funcion de pin de prueba no disponible.")
      end
    else
      Print("Uso: /puchi testpin on|off")
    end
    return
  end

  PrintHelp()
end
