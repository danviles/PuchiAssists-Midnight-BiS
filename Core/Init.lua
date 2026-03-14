local addonName, ns = ...

ns.name = addonName
ns.version = "0.1.0"

local addon = CreateFrame("Frame")
ns.addon = addon

local DEFAULT_CONFIG = {
  mapPinsEnabled = false,
  bossTooltipEnabled = true,
  debugCurrentMapPin = false,
  debugCursorMapTooltip = false,
  debugTooltip = false,
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

  if ns.CursorMapTooltip and ns.CursorMapTooltip.SetEnabled then
    ns.CursorMapTooltip:SetEnabled(ns.config.debugCursorMapTooltip)
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
  Print("Debug cursor map tooltip: " .. (ns.config.debugCursorMapTooltip and "ON" or "OFF"))
  Print("Debug tooltip POI mapa: " .. (ns.config.debugTooltip and "ON" or "OFF"))
end

local function PrintHelp()
  Print("Uso: /puchi status")
  Print("Uso: /puchi pines on|off")
  Print("Uso: /puchi tooltip on|off")
  Print("Uso: /puchi mapid")
  Print("Uso: /puchi testpin on|off")
  Print("Uso: /puchi cursorcoords on|off")
  Print("Uso: /puchi debugtooltip on|off")
  Print("Uso: /puchi tooltipcheck")
  Print("Uso: /puchi poitest [instance_id]")
  Print("Uso: /puchi poitestcenter [instance_id]")
  Print("Uso: /puchi ejscan")
  Print("Uso: /puchi ejfind <texto>")
  Print("Uso: /puchi ejmidnight")
  Print("Uso: /puchi ejid <journalInstanceID> [difficultyID]")
  Print("Uso: /puchi bosscheck")
  Print("Uso: /puchi bosspanel")
  Print("Uso: /puchi pinstats")
  Print("Uso: /puchi hnfix")
  Print("Uso: /puchi mapbutton")
  Print("Uso: /puchi ejmd <instancia_id|nombre> [difficultyID]")
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

    if loadedAddonName == "Blizzard_WorldMap" then
      if ns.Tooltip and ns.Tooltip.OnWorldMapLoaded then
        ns.Tooltip:OnWorldMapLoaded()
      end

      if ns.InstanceHotspots and ns.InstanceHotspots.OnWorldMapLoaded then
        ns.InstanceHotspots:OnWorldMapLoaded()
      end
      return
    end

    if loadedAddonName ~= addonName then
      return
    end

    EnsureConfig()

    if ns.ClassResolver and ns.ClassResolver.Init then
      ns.ClassResolver:Init()
    end

    if ns.config.mapPinsEnabled and ns.MapPins and ns.MapPins.Init then
      ns.MapPins:Init()
    end

    if ns.MapPoiTooltip and ns.MapPoiTooltip.Init then
      ns.MapPoiTooltip:Init()
    end

    if ns.Tooltip and ns.Tooltip.Init then
      ns.Tooltip:Init()
    end

    if ns.MapHubMenu and ns.MapHubMenu.Init then
      ns.MapHubMenu:Init()
    end

    if ns.InstanceHotspots and ns.InstanceHotspots.Init then
      ns.InstanceHotspots:Init()
    end

    if ns.CursorMapTooltip and ns.CursorMapTooltip.Init then
      ns.CursorMapTooltip:Init()
    end

    ApplyConfig()
  elseif event == "PLAYER_LOGIN" then
    if ns.ClassResolver and ns.ClassResolver.Refresh then
      ns.ClassResolver:Refresh()
    end

    if ns.config.mapPinsEnabled and ns.MapPins and ns.MapPins.Refresh then
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
  local rawText = tostring(msg or "")
  local commandRaw, restRaw = string.match(rawText, "^(%S+)%s*(.*)$")
  local command = commandRaw and string.lower(commandRaw) or "status"
  local value = string.lower(restRaw or "")
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
    if enabled and ns.MapPins and ns.MapPins.Init and not ns.MapPins.initialized then
      ns.MapPins:Init()
    end

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

  if command == "cursorcoords" then
    local enabled = ParseToggle(value)
    if enabled == nil then
      Print("Valor invalido para cursorcoords. Usa on|off")
      return
    end

    ns.config.debugCursorMapTooltip = enabled
    if ns.CursorMapTooltip and ns.CursorMapTooltip.SetEnabled then
      ns.CursorMapTooltip:SetEnabled(enabled)
    end

    Print("Debug cursor map tooltip: " .. (enabled and "ON" or "OFF"))
    return
  end

  if command == "debugtooltip" then
    local enabled = ParseToggle(value)
    if enabled == nil then
      Print("Valor invalido para debugtooltip. Usa on|off")
      return
    end

    ns.config.debugTooltip = enabled
    Print("Debug tooltip POI mapa: " .. (enabled and "ON" or "OFF"))
    return
  end

  if command == "tooltipcheck" then
    Print("Tooltip modulo: " .. ((ns.Tooltip and "OK") or "NO"))
    Print("MapPoiTooltip modulo: " .. ((ns.MapPoiTooltip and "OK") or "NO"))

    local ready = ns.MapPoiTooltip and ns.MapPoiTooltip.IsReady and ns.MapPoiTooltip:IsReady()
    Print("MapPoiTooltip frame: " .. ((ready and "READY") or "NO"))

    local wmLoaded = _G.WorldMapFrame and "SI" or "NO"
    Print("WorldMapFrame cargado: " .. wmLoaded)
    return
  end

  if command == "poitest" then
    local instanceId = (restRaw and restRaw ~= "") and string.lower(restRaw) or "windrunner_spire"
    if not ns.MapPoiTooltip or not ns.MapPoiTooltip.DebugShowTest then
      Print("MapPoiTooltip no disponible.")
      return
    end

    ns.MapPoiTooltip:DebugShowTest(instanceId)
    Print("Test tooltip ejecutado para: " .. tostring(instanceId))
    return
  end

  if command == "poitestcenter" then
    local instanceId = (restRaw and restRaw ~= "") and string.lower(restRaw) or "windrunner_spire"
    if not ns.MapPoiTooltip or not ns.MapPoiTooltip.ShowCentered then
      Print("MapPoiTooltip no disponible.")
      return
    end

    ns.MapPoiTooltip:ShowCentered(instanceId)
    Print("Test tooltip centrado ejecutado para: " .. tostring(instanceId))
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

  if command == "mapbutton" then
    if not ns.MapHubMenu or not ns.MapHubMenu.GetDebugStatus then
      Print("MapHubMenu no disponible.")
      return
    end

    if ns.MapHubMenu.Init and not ns.MapHubMenu.initialized then
      ns.MapHubMenu:Init()
    end

    if ns.MapHubMenu.RefreshVisibility then
      ns.MapHubMenu:RefreshVisibility()
    end

    local s = ns.MapHubMenu:GetDebugStatus()
    Print("WorldMap visible: " .. (s.worldMapShown and "SI" or "NO"))
    Print("WorldMap:GetMapID(): " .. tostring(s.worldMapMapID or "N/D"))
    Print("MapID activo: " .. tostring(s.activeMapID or "N/D") .. " (" .. tostring(s.activeMapName or "N/D") .. ")")
    Print("MapID jugador: " .. tostring(s.playerMapID or "N/D"))
    Print("Mapa permitido: " .. (s.allowed and "SI" or "NO"))
    Print("Boton creado: " .. (s.buttonExists and "SI" or "NO") .. " | visible: " .. (s.buttonShown and "SI" or "NO"))
    return
  end

  if command == "ejmd" then
    if not ns.EJProvider or not ns.EJProvider.ExportMarkdownToSavedVariables then
      Print("EJProvider no disponible.")
      return
    end

    local instanceArg, difficultyArg = string.match(value, "^(%S+)%s*(%S*)$")
    instanceArg = instanceArg or "windrunner_spire"
    local difficultyID = tonumber(difficultyArg) or 16

    local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
    local classID = classData.classId or 0
    local specID = classData.specId or 0

    local instanceName = ns.EJProvider:ResolveInstanceName(instanceArg) or instanceArg
    local key, resultOrError = ns.EJProvider:ExportMarkdownToSavedVariables(instanceName, {
      classID = classID,
      specID = specID,
      difficultyID = difficultyID,
    })

    if not key then
      Print("Error EJ export: " .. tostring(resultOrError))
      return
    end

    local lineCount = 0
    for _ in string.gmatch(resultOrError or "", "\n") do
      lineCount = lineCount + 1
    end

    Print("Export EJ generado para " .. tostring(instanceName) .. " (" .. tostring(lineCount + 1) .. " lineas).")
    Print("Guardado en SavedVariables: PuchiAssistsMidnightBiSDB.ejExports[\"" .. tostring(key) .. "\"]")
    return
  end

  if command == "ejscan" then
    if not ns.EJProvider or not ns.EJProvider.ExportScanToSavedVariables then
      Print("EJProvider no disponible.")
      return
    end

    local scan = ns.EJProvider:ExportScanToSavedVariables()
    Print("EJ scan completado. Instancias: " .. tostring(scan and #scan or 0))
    Print("Guardado en SavedVariables: PuchiAssistsMidnightBiSDB.ejScan.instances")
    return
  end

  if command == "ejfind" then
    if not ns.EJProvider or not ns.EJProvider.SearchSavedScan then
      Print("EJProvider no disponible.")
      return
    end

    if not restRaw or restRaw == "" then
      Print("Uso: /puchi ejfind <texto>")
      return
    end

    local matches, err = ns.EJProvider:SearchSavedScan(restRaw)
    if not matches then
      Print(tostring(err))
      return
    end

    Print("Coincidencias EJ para '" .. tostring(restRaw) .. "': " .. tostring(#matches))
    for i = 1, math.min(#matches, 12) do
      local e = matches[i]
      Print(string.format("- %s | id=%s | tier=%s | raid=%s | mapID=%s", tostring(e.name), tostring(e.journalInstanceID), tostring(e.tier), tostring(e.isRaid and "SI" or "NO"), tostring(e.dungeonAreaMapID or "N/D")))
    end
    return
  end

  if command == "ejmidnight" then
    if not ns.EJProvider or not ns.EJProvider.FindMidnightCandidatesInSavedScan then
      Print("EJProvider no disponible.")
      return
    end

    local matches, err = ns.EJProvider:FindMidnightCandidatesInSavedScan()
    if not matches then
      Print(tostring(err))
      return
    end

    Print("Candidatos Midnight en EJ scan: " .. tostring(#matches))
    for i = 1, math.min(#matches, 20) do
      local e = matches[i]
      Print(string.format("- %s | id=%s | tier=%s | raid=%s | mapID=%s", tostring(e.name), tostring(e.journalInstanceID), tostring(e.tier), tostring(e.isRaid and "SI" or "NO"), tostring(e.dungeonAreaMapID or "N/D")))
    end
    return
  end

  if command == "ejid" then
    if not ns.EJProvider or not ns.EJProvider.CollectLootForJournalInstance then
      Print("EJProvider no disponible.")
      return
    end

    local idArg, difficultyArg = string.match(restRaw or "", "^(%S+)%s*(%S*)$")
    local journalInstanceID = tonumber(idArg)
    if not journalInstanceID then
      Print("Uso: /puchi ejid <journalInstanceID> [difficultyID]")
      return
    end

    local difficultyID = tonumber(difficultyArg)
    local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
    local lootData, err = ns.EJProvider:CollectLootForJournalInstance(journalInstanceID, {
      classID = classData.classId or 0,
      specID = classData.specId or 0,
      difficultyID = difficultyID,
    })

    if not lootData then
      Print("Error EJ ID: " .. tostring(err))
      return
    end

    if ns.UI and ns.UI.InstanceWindow and ns.UI.InstanceWindow.OpenEncounterJournal then
      ns.UI.InstanceWindow:OpenEncounterJournal(lootData, lootData.instanceName or tostring(journalInstanceID))
    end

    local instanceCount = lootData.instanceLoot and #lootData.instanceLoot or 0
    local encounterCount = lootData.encounters and #lootData.encounters or 0
    Print("EJ abierto por ID " .. tostring(journalInstanceID) .. " | dificultad=" .. tostring(lootData.difficultyID or "N/D") .. " | items instancia=" .. tostring(instanceCount) .. " | encounters=" .. tostring(encounterCount))
    return
  end

  if command == "bosscheck" then
    local targetName = UnitExists("target") and UnitName("target") or "nil"
    local mouseoverName = UnitExists("mouseover") and UnitName("mouseover") or "nil"
    Print("Target: " .. tostring(targetName))
    Print("Mouseover: " .. tostring(mouseoverName))

    if ns.Tooltip and ns.Tooltip.GetCurrentInstanceContext then
      local context = ns.Tooltip:GetCurrentInstanceContext()
      Print("Instancia detectada: " .. tostring(context and context.instanceId or "nil"))
      Print("Dificultad detectada: " .. tostring(context and context.difficultyID or "nil"))
    else
      Print("Tooltip context: no disponible")
    end

    local panelShown = ns.Tooltip and ns.Tooltip.bossPanel and ns.Tooltip.bossPanel.IsShown and ns.Tooltip.bossPanel:IsShown()
    Print("Boss panel visible: " .. tostring(panelShown and "SI" or "NO"))
    return
  end

  if command == "bosspanel" then
    if ns.Tooltip and ns.Tooltip.ShowBossPanelTest then
      ns.Tooltip:ShowBossPanelTest()
      Print("Panel de boss forzado.")
    else
      Print("Tooltip no disponible.")
    end
    return
  end

  PrintHelp()
end
