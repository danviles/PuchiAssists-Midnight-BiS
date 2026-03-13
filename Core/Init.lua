local addonName, ns = ...

ns.name = addonName
ns.version = "0.1.0"

local addon = CreateFrame("Frame")
ns.addon = addon

local DEFAULT_CONFIG = {
  mapPinsEnabled = true,
  bossTooltipEnabled = true,
  debugCurrentMapPin = false,
}

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPuchiAssists|r: " .. tostring(msg))
end

ns.Print = Print

local function EnsureConfig()
  PuchiAssistsMidnightBiSDB = PuchiAssistsMidnightBiSDB or {}
  PuchiAssistsMidnightBiSDB.config = PuchiAssistsMidnightBiSDB.config or {}

  local config = PuchiAssistsMidnightBiSDB.config
  for key, value in pairs(DEFAULT_CONFIG) do
    if config[key] == nil then
      config[key] = value
    end
  end

  ns.config = config
end

local function ApplyConfig()
  if ns.MapPins and ns.MapPins.SetEnabled then
    ns.MapPins:SetEnabled(ns.config.mapPinsEnabled)
  end

  if ns.Tooltip and ns.Tooltip.SetEnabled then
    ns.Tooltip:SetEnabled(ns.config.bossTooltipEnabled)
  end
end

local function PrintStatus()
  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  local className = classData.classDisplayName or "N/D"
  local classToken = classData.classToken or "N/D"
  local specName = classData.specName or "Sin especializacion"

  Print("Clase: " .. className .. " (" .. classToken .. ")")
  Print("Spec: " .. specName)
  Print("Pines de mapa: " .. (ns.config.mapPinsEnabled and "ON" or "OFF"))
  Print("Tooltip de boss: " .. (ns.config.bossTooltipEnabled and "ON" or "OFF"))
  Print("Debug test pin: " .. (ns.config.debugCurrentMapPin and "ON" or "OFF"))
end

local function PrintHelp()
  Print("Uso: /puchi status")
  Print("Uso: /puchi pines on|off")
  Print("Uso: /puchi tooltip on|off")
  Print("Uso: /puchi mapid")
  Print("Uso: /puchi testpin on|off")
  Print("Uso: /puchi pinstats")
  Print("Uso: /puchi hnfix")
end

local function ParseToggle(value)
  if value == "on" or value == "1" then
    return true
  end

  if value == "off" or value == "0" then
    return false
  end

  return nil
end

addon:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local loadedAddonName = ...
    if loadedAddonName ~= addonName then
      return
    end

    EnsureConfig()

    if ns.ClassResolver and ns.ClassResolver.Init then
      ns.ClassResolver:Init()
    end

    if ns.MapPins and ns.MapPins.Init then
      ns.MapPins:Init()
    end

    if ns.Tooltip and ns.Tooltip.Init then
      ns.Tooltip:Init()
    end

    ApplyConfig()
  elseif event == "PLAYER_LOGIN" then
    if ns.ClassResolver and ns.ClassResolver.Refresh then
      ns.ClassResolver:Refresh()
    end

    if ns.MapPins and ns.MapPins.Refresh then
      ns.MapPins:Refresh()
    end
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    local unit = ...
    if unit == "player" and ns.ClassResolver and ns.ClassResolver.Refresh then
      ns.ClassResolver:Refresh()
    end
  end
end)

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

SLASH_PUCHIASSIST1 = "/puchi"
SlashCmdList.PUCHIASSIST = function(msg)
  local text = tostring(msg or ""):lower()
  local command, value = string.match(text, "^(%S+)%s*(%S*)$")
  command = command or "status"

  if not ns.config then
    Print("Configuracion aun no disponible.")
    return
  end

  if command == "status" then
    PrintStatus()
    return
  end

  if command == "pines" then
    local enabled = ParseToggle(value)
    if enabled == nil then
      Print("Valor invalido para pines. Usa on|off")
      return
    end

    ns.config.mapPinsEnabled = enabled
    if ns.MapPins and ns.MapPins.SetEnabled then
      ns.MapPins:SetEnabled(enabled)
    end

    Print("Pines de mapa: " .. (enabled and "ON" or "OFF"))
    return
  end

  if command == "tooltip" then
    local enabled = ParseToggle(value)
    if enabled == nil then
      Print("Valor invalido para tooltip. Usa on|off")
      return
    end

    ns.config.bossTooltipEnabled = enabled
    if ns.Tooltip and ns.Tooltip.SetEnabled then
      ns.Tooltip:SetEnabled(enabled)
    end

    Print("Tooltip de boss: " .. (enabled and "ON" or "OFF"))
    return
  end

  if command == "mapid" then
    local mapID = C_Map.GetBestMapForUnit("player")
    local instanceName, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID = GetInstanceInfo()
    Print("MapID jugador: " .. tostring(mapID or "N/D"))
    Print("Instancia: " .. tostring(instanceName or "N/D") .. " | tipo: " .. tostring(instanceType or "N/D"))
    Print("InstanceMapID: " .. tostring(instanceMapID or "N/D") .. " | dificultad: " .. tostring(difficultyName or difficultyID or "N/D"))
    return
  end

  if command == "testpin" then
    local enabled = ParseToggle(value)
    if enabled == nil then
      Print("Valor invalido para testpin. Usa on|off")
      return
    end

    ns.config.debugCurrentMapPin = enabled
    if ns.MapPins and ns.MapPins.SetDebugCurrentMapPin then
      ns.MapPins:SetDebugCurrentMapPin(enabled)
    end

    Print("Debug test pin: " .. (enabled and "ON" or "OFF"))
    return
  end

  if command == "pinstats" then
    local mapID = C_Map.GetBestMapForUnit("player")
    if not ns.MapPins or not ns.MapPins.GetStatsForMap then
      Print("MapPins no disponible.")
      return
    end

    local stats = ns.MapPins:GetStatsForMap(mapID)
    Print("HandyNotes: " .. (stats.hasHandyNotes and "OK" or "NO"))
    Print("MapPins enabled: " .. (stats.enabled and "ON" or "OFF"))
    Print("MapID actual: " .. tostring(stats.mapID or "N/D"))
    Print("Mapas con nodos: " .. tostring(stats.totalMaps))
    Print("Nodos en mapa actual: " .. tostring(stats.nodesOnMap))
    return
  end

  if command == "hnfix" then
    if not ns.MapPins then
      Print("MapPins no disponible.")
      return
    end

    local changed = false
    if ns.MapPins.EnsureHandyNotesPluginEnabled then
      changed = ns.MapPins:EnsureHandyNotesPluginEnabled()
    end

    if ns.MapPins.Refresh then
      ns.MapPins:Refresh()
    end

    Print("HandyNotes plugin PuchiAssists: " .. (changed and "activado" or "ya estaba activo"))
    return
  end

  PrintHelp()
end
