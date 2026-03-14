local _, ns = ...

ns.MapHubMenu = ns.MapHubMenu or {}

local LOCALE = GetLocale and GetLocale() or "enUS"

local I18N = {
  enUS = {
    MENU_TITLE = "PuchiAssists: Midnight",
    MENU_DUNGEONS = DUNGEONS or "Dungeons",
    MENU_RAIDS = RAIDS or "Raids",
    LABEL_DUNGEON = "Dungeon",
    LABEL_RAID = "Raid",
    TOOLTIP_SETTINGS = "Adjust display settings",
  },
  esMX = {
    MENU_TITLE = "PuchiAssists: Midnight",
    MENU_DUNGEONS = DUNGEONS or "Mazmorras",
    MENU_RAIDS = RAIDS or "Bandas",
    LABEL_DUNGEON = "Mazmorra",
    LABEL_RAID = "Banda",
    TOOLTIP_SETTINGS = "Ajustar opciones de visualizacion",
  },
  esES = {
    MENU_TITLE = "PuchiAssists: Midnight",
    MENU_DUNGEONS = DUNGEONS or "Mazmorras",
    MENU_RAIDS = RAIDS or "Bandas",
    LABEL_DUNGEON = "Mazmorra",
    LABEL_RAID = "Banda",
    TOOLTIP_SETTINGS = "Ajustar opciones de visualizacion",
  },
}

local ALLOWED_MAP_IDS = {
  [2395] = true,
  [2424] = true,
  [2405] = true,
  [2437] = true,
  [2413] = true,
  [2393] = true,
  [2537] = true,
}

local MENU_ITEMS = {
  dungeons = {
    { id = "windrunner_spire", name = "Windrunner Spire", kind = "dungeon" },
    { id = "voidscar_arena", name = "Voidscar Arena", kind = "dungeon" },
    { id = "magisters_terrace", name = "Magisters' Terrace", kind = "dungeon" },
    { id = "maisara_caverns", name = "Maisara Caverns", kind = "dungeon" },
    { id = "murder_row", name = "Murder Row", kind = "dungeon" },
    { id = "the_blinding_vale", name = "The Blinding Vale", kind = "dungeon" },
    { id = "den_of_nalorakk", name = "Den of Nalorakk", kind = "dungeon" },
    { id = "nexus_point_xenas", name = "Nexus-Point Xenas", kind = "dungeon" },
  },
  raids = {
    { id = "the_dreamrift", name = "The Dreamrift", kind = "raid" },
    { id = "the_voidspire", name = "The Voidspire", kind = "raid" },
  },
}

local ENTRY_MANUAL_LOCATIONS = {
  murder_row = { mapID = 2393, x = 0.56, y = 0.60 },
  windrunner_spire = { mapID = 2395, x = 0.35, y = 0.78 },
  maisara_caverns = { mapID = 2437, x = 0.43, y = 0.39 },
  den_of_nalorakk = { mapID = 2437, x = 0.29, y = 0.83 },
  voidscar_arena = { mapID = 2444, x = 0.53, y = 0.33 },
  nexus_point_xenas = { mapID = 2405, x = 0.65, y = 0.61 },
  the_voidspire = { mapID = 2405, x = 0.45, y = 0.64 },
  the_dreamrift = { mapID = 2413, x = 0.60, y = 0.62 },
  the_blinding_vale = { mapID = 2413, x = 0.26, y = 0.77 },
  magisters_terrace = { mapID = 2424, x = 0.63, y = 0.15 },
}

local INSTANCE_LOCALE_FALLBACK = {
  esMX = {
    windrunner_spire = "Aguja Brisaveloz",
    voidscar_arena = "Arena Rajavacio",
    magisters_terrace = "Bancal del Magister",
    maisara_caverns = "Cavernas de Maisara",
    murder_row = "El Frontal de la Muerte",
    the_blinding_vale = "El Valle Enceguecedor",
    den_of_nalorakk = "Guarida de Nalorakk",
    nexus_point_xenas = "Punto del Nexo Xenas",
    midnight = "Midnight",
    the_dreamrift = "La Onirifalla",
    the_voidspire = "La Aguja del Vacio",
    march_on_queldanas = "Marcha sobre Quel'Danas",
  },
  esES = {
    windrunner_spire = "Aguja Brisaveloz",
    voidscar_arena = "Arena Rajavacio",
    magisters_terrace = "Bancal del Magister",
    maisara_caverns = "Cavernas de Maisara",
    murder_row = "El Frontal de la Muerte",
    the_blinding_vale = "El Valle Enceguecedor",
    den_of_nalorakk = "Guarida de Nalorakk",
    nexus_point_xenas = "Punto del Nexo Xenas",
    midnight = "Midnight",
    the_dreamrift = "La Onirifalla",
    the_voidspire = "La Aguja del Vacio",
    march_on_queldanas = "Marcha sobre Quel'Danas",
  },
}

local WORLD_MAP_BUTTON_ICON = [[Interface\Icons\INV_Misc_TreasureChest03]]

local localizedInstanceNameCache = {}
local ejNameByMapIDCache
local searchMapIDsCache

local function T(key)
  local localeTable = I18N[LOCALE] or I18N.enUS
  return (localeTable and localeTable[key]) or I18N.enUS[key] or key
end

local function GetMapParentFrame()
  if not WorldMapFrame then
    return nil
  end

  if WorldMapFrame.GetCanvasContainer then
    local canvas = WorldMapFrame:GetCanvasContainer()
    if canvas then
      return canvas
    end
  end

  if WorldMapFrame.ScrollContainer then
    return WorldMapFrame.ScrollContainer
  end

  return WorldMapFrame
end

local function GetActiveWorldMapID()
  if WorldMapFrame and WorldMapFrame.GetMapID then
    local mapID = WorldMapFrame:GetMapID()
    if mapID then
      return mapID
    end
  end

  return C_Map.GetBestMapForUnit("player")
end

local function IsAllowedMap(mapID)
  return mapID and ALLOWED_MAP_IDS[mapID] or false
end

local function GetValidMapID(...)
  for i = 1, select("#", ...) do
    local mapID = tonumber((select(i, ...)))
    if mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID) then
      return mapID
    end
  end

  return nil
end

local function BuildEncounterJournalMapCache()
  if ejNameByMapIDCache then
    return ejNameByMapIDCache
  end

  ejNameByMapIDCache = {}

  local tierCount = EJ_GetNumTiers and EJ_GetNumTiers() or 0
  if tierCount <= 0 then
    tierCount = 1
  end

  for tier = tierCount, 1, -1 do
    if EJ_SelectTier then
      EJ_SelectTier(tier)
    end

    for _, isRaid in ipairs({ false, true }) do
      local index = 1
      while true do
        local journalInstanceID = EJ_GetInstanceByIndex(index, isRaid)
        if not journalInstanceID then
          break
        end

        local ejName, _, _, _, _, dungeonAreaMapID = EJ_GetInstanceInfo(journalInstanceID)
        local mapID = tonumber(dungeonAreaMapID)
        if mapID and ejName and ejName ~= "" and not ejNameByMapIDCache[mapID] then
          ejNameByMapIDCache[mapID] = ejName
        end

        index = index + 1
      end
    end
  end

  return ejNameByMapIDCache
end

local function ResolveLocalizedInstanceName(entry)
  if not entry then
    return nil
  end

  local cacheKey = entry.id or entry.name
  if cacheKey and localizedInstanceNameCache[cacheKey] then
    return localizedInstanceNameCache[cacheKey]
  end

  local localizedName
  local resolvedFromApi = false

  if entry.id and ns.BiSData and ns.BiSData.GetInstance then
    local instance = ns.BiSData:GetInstance(entry.id)
    if instance and instance.uiMapID then
      local mapInfo = C_Map.GetMapInfo(instance.uiMapID)
      if mapInfo and mapInfo.name and mapInfo.name ~= "" then
        localizedName = mapInfo.name
        resolvedFromApi = true
      end

      if (not localizedName or localizedName == "") and EJ_GetInstanceInfo and EJ_GetInstanceByIndex then
        local ejMapCache = BuildEncounterJournalMapCache()
        local ejName = ejMapCache and ejMapCache[tonumber(instance.uiMapID)]
        if ejName and ejName ~= "" then
          localizedName = ejName
          resolvedFromApi = true
        end
      end
    end
  end

  if not localizedName and entry.uiMapID then
    local mapInfo = C_Map.GetMapInfo(entry.uiMapID)
    if mapInfo and mapInfo.name and mapInfo.name ~= "" then
      localizedName = mapInfo.name
      resolvedFromApi = true
    end

    if (not localizedName or localizedName == "") and EJ_GetInstanceInfo and EJ_GetInstanceByIndex then
      local ejMapCache = BuildEncounterJournalMapCache()
      local ejName = ejMapCache and ejMapCache[tonumber(entry.uiMapID)]
      if ejName and ejName ~= "" then
        localizedName = ejName
        resolvedFromApi = true
      end
    end
  end

  if (not localizedName or localizedName == "") and LOCALE ~= "enUS" then
    local byLocale = INSTANCE_LOCALE_FALLBACK[LOCALE]
    if byLocale then
      local fallback = byLocale[entry.id or ""]
      if fallback and fallback ~= "" then
        localizedName = fallback
      end
    end
  end

  if not localizedName and entry.name then
    localizedName = entry.name
  end

  if cacheKey and localizedName and resolvedFromApi then
    localizedInstanceNameCache[cacheKey] = localizedName
  end

  return localizedName
end

local function NormalizeName(value)
  if not value then
    return ""
  end

  local lowered = tostring(value):lower()
  lowered = lowered:gsub("[%s%p]", "")
  return lowered
end

local function BuildSearchMapIDs()
  if searchMapIDsCache then
    return searchMapIDsCache
  end

  searchMapIDsCache = {}
  local seen = {}

  local function addMapID(mapID)
    mapID = tonumber(mapID)
    if not mapID or seen[mapID] then
      return
    end

    seen[mapID] = true
    searchMapIDsCache[#searchMapIDsCache + 1] = mapID
  end

  for mapID in pairs(ALLOWED_MAP_IDS) do
    addMapID(mapID)

    if C_Map and C_Map.GetMapChildrenInfo then
      local children = C_Map.GetMapChildrenInfo(mapID, nil, true)
      if not children and Enum and Enum.UIMapType then
        children = C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone, true)
      end

      for _, child in ipairs(children or {}) do
        addMapID(child.mapID)
      end
    end
  end

  return searchMapIDsCache
end

local function FindMatchingAreaPoi(entry, localizedName, preferredMapID)
  if not C_AreaPoiInfo or not C_AreaPoiInfo.GetAreaPOIForMap or not C_AreaPoiInfo.GetAreaPOIInfo then
    return nil, nil, nil
  end

  local candidateMaps = {}
  if preferredMapID then
    candidateMaps[#candidateMaps + 1] = preferredMapID
  end

  for _, mapID in ipairs(BuildSearchMapIDs()) do
    if tonumber(mapID) ~= tonumber(preferredMapID) then
      candidateMaps[#candidateMaps + 1] = mapID
    end
  end

  local targetLocalized = NormalizeName(localizedName)
  local targetEnglish = NormalizeName(entry and entry.name)

  for _, mapID in ipairs(candidateMaps) do
    local poiIDs = C_AreaPoiInfo.GetAreaPOIForMap(mapID)
    for _, poiID in ipairs(poiIDs or {}) do
      local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
      if poiInfo and poiInfo.name then
        local poiName = NormalizeName(poiInfo.name)
        if poiName ~= "" and (
          poiName == targetLocalized or
          poiName == targetEnglish or
          (targetLocalized ~= "" and string.find(poiName, targetLocalized, 1, true)) or
          (targetLocalized ~= "" and string.find(targetLocalized, poiName, 1, true)) or
          (targetEnglish ~= "" and string.find(poiName, targetEnglish, 1, true)) or
          (targetEnglish ~= "" and string.find(targetEnglish, poiName, 1, true))
        ) then
          local x = poiInfo.position and poiInfo.position.x or poiInfo.x
          local y = poiInfo.position and poiInfo.position.y or poiInfo.y
          if x and y then
            return mapID, x, y
          end
        end
      end
    end
  end

  return nil, nil, nil
end

local function ResolveEntryLocation(entry, localizedName)
  if entry and entry.id and ENTRY_MANUAL_LOCATIONS[entry.id] then
    local manual = ENTRY_MANUAL_LOCATIONS[entry.id]
    local manualMapID = GetValidMapID(manual.mapID)
    if manualMapID and manual.x and manual.y then
      return manualMapID, manual.x, manual.y
    end
  end

  local mapID = nil
  local x, y = nil, nil
  local fallbackDisplayMapID = nil

  if entry and entry.id and ns.BiSData and ns.BiSData.GetInstance then
    local instance = ns.BiSData:GetInstance(entry.id)
    if instance then
      mapID = instance.uiMapID or mapID
      fallbackDisplayMapID = instance.displayMapID or fallbackDisplayMapID
      x = instance.x
      y = instance.y
    end
  end

  if entry and entry.uiMapID then
    mapID = entry.uiMapID
  end

  mapID = GetValidMapID(mapID, fallbackDisplayMapID, GetActiveWorldMapID(), 2393)

  local poiMapID, poiX, poiY = FindMatchingAreaPoi(entry, localizedName, mapID)
  if GetValidMapID(poiMapID) and poiX and poiY then
    return poiMapID, poiX, poiY
  end

  if mapID and x and y then
    return mapID, x, y
  end

  if mapID then
    return mapID, 0.5, 0.5
  end

  local fallbackMap = GetActiveWorldMapID() or 2393
  return fallbackMap, 0.5, 0.5
end

local function ShowPulseAt(mapID, x, y)
  if not WorldMapFrame or not WorldMapFrame.GetCanvasContainer then
    return
  end

  if not x or not y then
    return
  end

  local canvas = WorldMapFrame:GetCanvasContainer()
  if not canvas then
    return
  end

  local pulse = ns.MapHubMenu.pulseFrame
  if not pulse then
    pulse = CreateFrame("Frame", nil, canvas)
    pulse:SetSize(36, 36)
    pulse.texture = pulse:CreateTexture(nil, "OVERLAY")
    pulse.texture:SetAllPoints()
    pulse.texture:SetAtlas("Waypoint-MapPin-Untracked")
    pulse.texture:SetAlpha(1)

    pulse.anim = pulse:CreateAnimationGroup()
    pulse.anim:SetLooping("REPEAT")

    local alphaOut = pulse.anim:CreateAnimation("Alpha")
    alphaOut:SetFromAlpha(1)
    alphaOut:SetToAlpha(0.2)
    alphaOut:SetDuration(0.45)
    alphaOut:SetOrder(1)

    local alphaIn = pulse.anim:CreateAnimation("Alpha")
    alphaIn:SetFromAlpha(0.2)
    alphaIn:SetToAlpha(1)
    alphaIn:SetDuration(0.45)
    alphaIn:SetOrder(2)

    ns.MapHubMenu.pulseFrame = pulse
  end

  C_Timer.After(0, function()
    if not ns.MapHubMenu or not ns.MapHubMenu.pulseFrame or not ns.MapHubMenu.pulseFrame:IsShown() then
      ns.MapHubMenu.pulseFrame = pulse
    end

    pulse:ClearAllPoints()
    pulse:SetPoint("CENTER", canvas, "TOPLEFT", x * canvas:GetWidth(), -y * canvas:GetHeight())
    pulse:Show()
    pulse.anim:Play()

    C_Timer.After(2.2, function()
      if ns.MapHubMenu and ns.MapHubMenu.pulseFrame then
        ns.MapHubMenu.pulseFrame.anim:Stop()
        ns.MapHubMenu.pulseFrame:Hide()
      end
    end)
  end)
end

function ns.MapHubMenu:NavigateToEntry(entry, localizedName)
  if not entry then
    return
  end

  if not WorldMapFrame then
    if ToggleWorldMap then
      ToggleWorldMap()
    end
  elseif not WorldMapFrame:IsShown() and ToggleWorldMap then
    ToggleWorldMap()
  end

  local mapID, x, y = ResolveEntryLocation(entry, localizedName)
  mapID = GetValidMapID(mapID, GetActiveWorldMapID(), 2393)

  if WorldMapFrame and WorldMapFrame.SetMapID and mapID then
    WorldMapFrame:SetMapID(mapID)
  end

  if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint and x and y and mapID then
    local waypoint = UiMapPoint.CreateFromCoordinates(mapID, x, y)
    if waypoint then
      C_Map.SetUserWaypoint(waypoint)
      if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
      end
    end
  end

  ShowPulseAt(mapID, x, y)
end

local function BuildMenu()
  local menu = {
    {
      text = T("MENU_TITLE"),
      isTitle = true,
      notCheckable = true,
    },
    {
      text = T("MENU_DUNGEONS"),
      isTitle = true,
      notCheckable = true,
    },
  }

  for _, entry in ipairs(MENU_ITEMS.dungeons) do
    local localizedName = ResolveLocalizedInstanceName(entry) or entry.name
    menu[#menu + 1] = {
      text = localizedName,
      notCheckable = true,
      func = function()
        if ns.MapHubMenu and ns.MapHubMenu.NavigateToEntry then
          ns.MapHubMenu:NavigateToEntry(entry, localizedName)
        end
        if ns.EJProvider and ns.EJProvider.CollectLootForAddonEntry and ns.UI and ns.UI.InstanceWindow and ns.UI.InstanceWindow.OpenEncounterJournal then
          local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
          local lootData = ns.EJProvider:CollectLootForAddonEntry(entry.id, {
            classID = classData.classId or 0,
            specID = classData.specId or 0,
            difficultyID = 23,
          })
          if lootData then
            ns.UI.InstanceWindow:OpenEncounterJournal(lootData, localizedName)
          end
        end
        if ns.Print then
          ns.Print(T("LABEL_DUNGEON") .. ": " .. tostring(localizedName))
        end
      end,
    }
  end

  menu[#menu + 1] = {
    text = " ",
    disabled = true,
    notCheckable = true,
  }

  menu[#menu + 1] = {
    text = T("MENU_RAIDS"),
    isTitle = true,
    notCheckable = true,
  }

  for _, entry in ipairs(MENU_ITEMS.raids) do
    local localizedName = ResolveLocalizedInstanceName(entry) or entry.name
    menu[#menu + 1] = {
      text = localizedName,
      notCheckable = true,
      func = function()
        if ns.MapHubMenu and ns.MapHubMenu.NavigateToEntry then
          ns.MapHubMenu:NavigateToEntry(entry, localizedName)
        end
        if ns.EJProvider and ns.EJProvider.CollectLootForAddonEntry and ns.UI and ns.UI.InstanceWindow and ns.UI.InstanceWindow.OpenEncounterJournal then
          local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
          local lootData = ns.EJProvider:CollectLootForAddonEntry(entry.id, {
            classID = classData.classId or 0,
            specID = classData.specId or 0,
            difficultyID = 16,
          })
          if lootData then
            ns.UI.InstanceWindow:OpenEncounterJournal(lootData, localizedName)
          end
        end
        if ns.Print then
          ns.Print(T("LABEL_RAID") .. ": " .. tostring(localizedName))
        end
      end,
    }
  end

  return menu
end

local function FindHandyNotesAnchorButton(parent)
  for i = 1, 30 do
    local frame = _G["Krowi_WorldMapButtons" .. i]
    if frame and frame.IsShown and frame:IsShown() then
      return frame
    end
  end

  if parent and parent.GetChildren then
    for _, child in ipairs({ parent:GetChildren() }) do
      local name = child and child.GetName and child:GetName() or nil
      if name and string.find(name, "Krowi_WorldMapButtons", 1, true) then
        return child
      end
    end
  end

  return nil
end

local function UpdateButtonAnchor(button)
  if not button or not button.GetParent then
    return
  end

  local parent = button:GetParent()
  local anchor = FindHandyNotesAnchorButton(parent)
  local fallbackAnchor = (WorldMapFrame and WorldMapFrame.GetCanvasContainer and WorldMapFrame:GetCanvasContainer()) or parent

  button:ClearAllPoints()
  if anchor and anchor.IsShown and anchor:IsShown() then
    button:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
  else
    button:SetPoint("TOPRIGHT", fallbackAnchor, "TOPRIGHT", -68, -2)
  end
end

local function CreateMapButton()
  if ns.MapHubMenu.button or not WorldMapFrame then
    return
  end

  local parent = WorldMapFrame or GetMapParentFrame()
  local button = CreateFrame("Button", "PuchiAssistsMidnightMapButton", parent)
  button:SetSize(32, 32)
  button:SetFrameStrata("HIGH")
  button:SetFrameLevel((WorldMapFrame:GetFrameLevel() or 1) + 20)
  button:Hide()

  button.Background = button:CreateTexture(nil, "BACKGROUND")
  button.Background:SetPoint("TOPLEFT", 2, -4)
  button.Background:SetSize(25, 25)
  button.Background:SetTexture([[Interface\Minimap\UI-Minimap-Background]])

  button.Icon = button:CreateTexture(nil, "ARTWORK")
  button.Icon:SetTexture(WORLD_MAP_BUTTON_ICON)
  button.Icon:SetSize(20, 20)
  button.Icon:SetPoint("TOPLEFT", 6, -5)

  button.Border = button:CreateTexture(nil, "OVERLAY", nil, -1)
  button.Border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
  button.Border:SetSize(54, 54)
  button.Border:SetPoint("TOPLEFT")

  button:SetHighlightTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]], "ADD")

  UpdateButtonAnchor(button)

  local dropDown = CreateFrame("Frame", "PuchiAssistsMidnightMapDropDown", UIParent, "UIDropDownMenuTemplate")
  UIDropDownMenu_Initialize(dropDown, function(_, level)
    if level ~= 1 then
      return
    end

    for _, item in ipairs(BuildMenu()) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = item.text
      info.isTitle = item.isTitle
      info.notCheckable = item.notCheckable ~= false
      info.disabled = item.disabled
      info.func = item.func
      UIDropDownMenu_AddButton(info, level)
    end
  end, "MENU")

  button:SetScript("OnMouseDown", function(self)
    self.Icon:SetPoint("TOPLEFT", 8, -8)
    self.Icon:SetAlpha(0.5)
  end)

  button:SetScript("OnMouseUp", function(self)
    self.Icon:SetPoint("TOPLEFT", 6, -5)
    self.Icon:SetAlpha(1)
    ToggleDropDownMenu(1, nil, dropDown, self, 0, 0)
  end)

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, T("MENU_TITLE"))
    GameTooltip_AddNormalLine(GameTooltip, T("TOOLTIP_SETTINGS"))
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", GameTooltip_Hide)

  ns.MapHubMenu.button = button
  ns.MapHubMenu.dropDown = dropDown
end

function ns.MapHubMenu:GetDebugStatus()
  local worldMapShown = WorldMapFrame and WorldMapFrame:IsShown() or false
  local worldMapMapID = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() or nil
  local playerMapID = C_Map.GetBestMapForUnit("player")
  local activeMapID = GetActiveWorldMapID()
  local allowed = IsAllowedMap(activeMapID)
  local buttonExists = self.button ~= nil
  local buttonShown = buttonExists and self.button:IsShown() or false

  local mapName = "N/D"
  if activeMapID then
    local info = C_Map.GetMapInfo(activeMapID)
    mapName = info and info.name or mapName
  end

  return {
    worldMapShown = worldMapShown,
    worldMapMapID = worldMapMapID,
    playerMapID = playerMapID,
    activeMapID = activeMapID,
    activeMapName = mapName,
    allowed = allowed,
    buttonExists = buttonExists,
    buttonShown = buttonShown,
  }
end

local function HookMapEventsOnce()
  if ns.MapHubMenu.hooksInstalled or not WorldMapFrame then
    return
  end

  ns.MapHubMenu.hooksInstalled = true

  WorldMapFrame:HookScript("OnShow", function()
    ns.MapHubMenu:RefreshVisibility()
  end)
  WorldMapFrame:HookScript("OnHide", function()
    ns.MapHubMenu:RefreshVisibility()
  end)

  if type(WorldMapFrame.OnMapChanged) == "function" then
    hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
      ns.MapHubMenu:RefreshVisibility()
    end)
  end

  if type(WorldMapFrame.SetMapID) == "function" then
    hooksecurefunc(WorldMapFrame, "SetMapID", function()
      ns.MapHubMenu:RefreshVisibility()
    end)
  end
end

function ns.MapHubMenu:RefreshVisibility()
  if not self.button and WorldMapFrame then
    CreateMapButton()
  end

  if not self.button then
    return
  end

  UpdateButtonAnchor(self.button)

  if not WorldMapFrame or not WorldMapFrame:IsShown() then
    self.button:Hide()
    return
  end

  local mapID = GetActiveWorldMapID()
  if IsAllowedMap(mapID) then
    self.button:Show()
  else
    self.button:Hide()
  end
end

function ns.MapHubMenu:Init()
  if self.initialized then
    return
  end

  self.initialized = true

  if WorldMapFrame then
    CreateMapButton()
    self:RefreshVisibility()
    HookMapEventsOnce()
  else
    if IsAddOnLoaded and IsAddOnLoaded("Blizzard_WorldMap") then
      if _G.WorldMapFrame then
        CreateMapButton()
        self:RefreshVisibility()
        HookMapEventsOnce()
      end
    end

    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(_, _, addonName)
      if addonName == "Blizzard_WorldMap" then
        CreateMapButton()
        ns.MapHubMenu:RefreshVisibility()
        HookMapEventsOnce()
      end
    end)

    self.loader = loader
  end

  local zoneWatcher = CreateFrame("Frame")
  zoneWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
  zoneWatcher:RegisterEvent("ZONE_CHANGED")
  zoneWatcher:RegisterEvent("ZONE_CHANGED_INDOORS")
  zoneWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  zoneWatcher:SetScript("OnEvent", function()
    ns.MapHubMenu:RefreshVisibility()
  end)

  self.zoneWatcher = zoneWatcher
end

do
  local bootstrap = CreateFrame("Frame")
  bootstrap:RegisterEvent("PLAYER_LOGIN")
  bootstrap:RegisterEvent("ADDON_LOADED")
  bootstrap:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
      if ns.MapHubMenu and ns.MapHubMenu.Init and not ns.MapHubMenu.initialized then
        ns.MapHubMenu:Init()
      elseif ns.MapHubMenu and ns.MapHubMenu.RefreshVisibility then
        ns.MapHubMenu:RefreshVisibility()
      end
      return
    end

    if event == "ADDON_LOADED" and arg1 == "Blizzard_WorldMap" then
      if ns.MapHubMenu and ns.MapHubMenu.Init and not ns.MapHubMenu.initialized then
        ns.MapHubMenu:Init()
      elseif ns.MapHubMenu and ns.MapHubMenu.RefreshVisibility then
        ns.MapHubMenu:RefreshVisibility()
      end
    end
  end)
end
