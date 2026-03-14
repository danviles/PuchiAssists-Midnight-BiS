local _, ns = ...

-- ============================================================
--  Tooltip
--  - Hover sobre swirl de dungeon/raid en mapa mundial:
--    muestra ventana secundaria via MapPoiTooltip (datos del EJ)
--  - Hover sobre boss dentro de instancia:
--    anade lineas al GameTooltip con datos de BiSData
-- ============================================================

local Tooltip = {}
ns.Tooltip = Tooltip
Tooltip._hookedFrames = {}
Tooltip._mapLabelTicker = nil
Tooltip._lastMapLabelText = nil
Tooltip._lastHoverInstanceId = nil
Tooltip._unitEventFrame = nil
Tooltip._bossPanelTicker = nil
Tooltip._lastBossPanelKey = nil
Tooltip._bossEventFrame = nil

-- Nombres alternativos (español + ingles) para reconocer remolinos del mapa.
-- Clave: instanceId en BiSData.  Valores: posibles titulos del tooltip.
local MANUAL_POI_NAMES = {
  windrunner_spire  = { "Aguja Brisaveloz",        "Windrunner Spire"                          },
  voidscar_arena    = { "Arena Rajavacio",          "Voidscar Arena"                            },
  magisters_terrace = { "Bancal del Magister",      "Magisters' Terrace", "Magister's Terrace"  },
  maisara_caverns   = { "Cavernas de Maisara",      "Maisara Caverns"                           },
  murder_row        = { "El Frontal de la Muerte",  "Murder Row"                                },
  the_blinding_vale = { "El Valle Enceguecedor",    "The Blinding Vale"                         },
  den_of_nalorakk   = { "Guarida de Nalorakk",      "Den of Nalorakk"                           },
  nexus_point_xenas = { "Punto del Nexo Xenas",     "Nexus-Point Xenas", "Nexus Point Xenas"    },
  the_voidspire     = { "La Aguja del Vacio",       "The Voidspire"                             },
  the_dreamrift     = { "La Onirifalla",            "The Dreamrift"                             },
}

local MANUAL_BOSS_EJ_MATCHES = {
  windrunner_spire = {
    [2656] = { "kalis", "latch", "remache", "forgotenduo", "duoolvidado", "derelictduo" },
  },
}

local MANUAL_BOSS_ENCOUNTER_NAME_FALLBACKS = {
  windrunner_spire = {
    {
      bossAliases = { "kalis", "latch", "remache" },
      encounterAliases = { "forgotenduo", "duoolvidado", "derelictduo" },
    },
  },
}

-- ----------------------------------------------------------------
--  Utilidades
-- ----------------------------------------------------------------

local function NormalizeName(value)
  if value == nil then return nil end

  local ok, text = pcall(function()
    return tostring(value)
  end)
  if not ok or not text then
    return nil
  end

  local okNorm, normalized = pcall(function()
    local t = text:lower()
    t = t:gsub("\195\161", "a"):gsub("\195\169", "e"):gsub("\195\173", "i")
         :gsub("\195\179", "o"):gsub("\195\186", "u")
         :gsub("\195\188", "u"):gsub("\195\177", "n")
    t = t:gsub("[^%w]", "")
    return t
  end)

  if not okNorm or not normalized then
    return nil
  end

  return normalized
end

local function SafeText(value)
  if value == nil then
    return nil
  end

  local ok, text = pcall(function()
    return tostring(value)
  end)
  if not ok or not text then
    return nil
  end

  return text
end

local function GetNpcId(unitGuid)
  if not unitGuid then return nil end
  local parts = {}
  for p in string.gmatch(unitGuid, "[^-]+") do parts[#parts+1] = p end
  return #parts >= 6 and tonumber(parts[6]) or nil
end

local function AddIndexAlias(index, alias, instanceId)
  local n = NormalizeName(alias)
  if n and not index[n] then
    index[n] = instanceId
  end
end

local function AcquireBossPanelLine(frame, index)
  frame.lines = frame.lines or {}

  if frame.lines[index] then
    frame.lines[index]:Show()
    return frame.lines[index]
  end

  local line = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  line:SetJustifyH("LEFT")
  line:SetWidth(300)
  frame.lines[index] = line
  return line
end

function Tooltip:GetBossPanel()
  if self.bossPanel then
    return self.bossPanel
  end

  local frame = CreateFrame("Frame", "PuchiAssistsBossLootPanel", UIParent, "BackdropTemplate")
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0.04, 0.04, 0.09, 0.96)
  frame:SetBackdropBorderColor(0.75, 0.65, 0.25, 1)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetFrameLevel(10000)
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetSize(320, 120)
  frame:SetAlpha(1)
  frame:Hide()

  self.bossPanel = frame
  return frame
end

function Tooltip:HideBossPanel()
  if self.bossPanel then
    self.bossPanel:Hide()
  end
  self._lastBossPanelKey = nil
end

function Tooltip:ShowBossPanel(unitName, encounter)
  if not encounter then
    self:HideBossPanel()
    return
  end

  local key = tostring(unitName or "") .. ":" .. tostring(encounter.journalEncounterID or encounter.name or "")
  if self._lastBossPanelKey == key and self.bossPanel and self.bossPanel:IsShown() then
    return
  end

  self._lastBossPanelKey = key

  local frame = self:GetBossPanel()
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  local lineIndex = 1
  local prev = nil

  for _, line in ipairs(frame.lines or {}) do
    line:Hide()
    line:ClearAllPoints()
  end

  local title = AcquireBossPanelLine(frame, lineIndex)
  title:SetFont("Fonts\\ARIALN.TTF", 13, "")
  title:SetTextColor(0.4, 0.82, 1.0, 1)
  title:SetText(tostring(unitName or encounter.name or "Boss"))
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
  prev = title
  lineIndex = lineIndex + 1

  local subtitle = AcquireBossPanelLine(frame, lineIndex)
  subtitle:SetFont("Fonts\\ARIALN.TTF", 11, "")
  subtitle:SetTextColor(0.85, 0.85, 0.85, 1)
  subtitle:SetText(tostring(encounter.name or "Encounter"))
  subtitle:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -4)
  prev = subtitle
  lineIndex = lineIndex + 1

  if not encounter.loot or #encounter.loot == 0 then
    local empty = AcquireBossPanelLine(frame, lineIndex)
    empty:SetFont("Fonts\\ARIALN.TTF", 11, "")
    empty:SetTextColor(0.75, 0.75, 0.75, 1)
    empty:SetText("- Sin loot filtrado para tu clase/spec")
    empty:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -8)
    prev = empty
    lineIndex = lineIndex + 1
  else
    for _, item in ipairs(encounter.loot) do
      local line = AcquireBossPanelLine(frame, lineIndex)
      line:SetFont("Fonts\\ARIALN.TTF", 11, "")
      line:SetTextColor(1, 1, 1, 1)
      line:SetText(string.format("- %s (%s)", tostring(ns.BiSData:GetItemDisplayName(item)), tostring(item.slot or "N/D")))
      line:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -6)
      prev = line
      lineIndex = lineIndex + 1
    end
  end

  local height = 20
  for i = 1, lineIndex - 1 do
    local line = frame.lines[i]
    if line and line:IsShown() then
      height = height + line:GetStringHeight() + 6
    end
  end

  frame:SetHeight(math.max(90, height + 12))
  frame:Show()
end

function Tooltip:ShowBossPanelDiagnostic(titleText, lineTexts)
  local frame = self:GetBossPanel()
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  local lineIndex = 1
  local prev = nil

  for _, line in ipairs(frame.lines or {}) do
    line:Hide()
    line:ClearAllPoints()
  end

  local title = AcquireBossPanelLine(frame, lineIndex)
  title:SetFont("Fonts\\ARIALN.TTF", 13, "")
  title:SetTextColor(1.0, 0.82, 0.2, 1)
  title:SetText(tostring(titleText or "PuchiAssists Boss"))
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
  prev = title
  lineIndex = lineIndex + 1

  for _, text in ipairs(lineTexts or {}) do
    local line = AcquireBossPanelLine(frame, lineIndex)
    line:SetFont("Fonts\\ARIALN.TTF", 11, "")
    line:SetTextColor(0.85, 0.85, 0.85, 1)
    line:SetText(tostring(text))
    line:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -6)
    prev = line
    lineIndex = lineIndex + 1
  end

  local height = 20
  for i = 1, lineIndex - 1 do
    local line = frame.lines[i]
    if line and line:IsShown() then
      height = height + line:GetStringHeight() + 6
    end
  end

  frame:SetHeight(math.max(100, height + 12))
  frame:Show()
end

function Tooltip:ShowBossPanelTest()
  self:ShowBossPanelDiagnostic("PuchiAssists Boss Test", {
    "Si ves esto, el panel SI renderiza.",
    "El problema seria deteccion/matching.",
  })
end

-- ----------------------------------------------------------------
--  Indice nombre → instanceId  (se construye una vez)
-- ----------------------------------------------------------------

function Tooltip:BuildMapInstanceNameIndex()
  local index = {}

  -- Nombres del BiSData (ingles)
  for instanceId, data in pairs(ns.BiSData:GetInstances() or {}) do
    AddIndexAlias(index, data.name, instanceId)
    if data.uiMapID then
      local info = C_Map.GetMapInfo(data.uiMapID)
      if info and info.name then AddIndexAlias(index, info.name, instanceId) end
    end
    if data.displayMapID then
      local info = C_Map.GetMapInfo(data.displayMapID)
      if info and info.name then AddIndexAlias(index, info.name, instanceId) end
    end
  end

  -- Aliases manuales (español + variantes)
  for instanceId, aliases in pairs(MANUAL_POI_NAMES) do
    for _, alias in ipairs(aliases) do
      AddIndexAlias(index, alias, instanceId)
    end
  end

  self.mapInstanceNameIndex = index
end

function Tooltip:ResolveInstanceByMapPoiName(poiName)
  if not poiName or poiName == "" then return nil end

  if not self.mapInstanceNameIndex then
    self:BuildMapInstanceNameIndex()
  end

  return self.mapInstanceNameIndex[NormalizeName(poiName)]
end

function Tooltip:ResolveInstanceByMapPoiNameFuzzy(poiName)
  if not poiName or poiName == "" then
    return nil
  end

  local direct = self:ResolveInstanceByMapPoiName(poiName)
  if direct then
    return direct
  end

  local normalized = NormalizeName(poiName)
  if not normalized or normalized == "" then
    return nil
  end

  for alias, instanceId in pairs(self.mapInstanceNameIndex or {}) do
    if alias and (string.find(normalized, alias, 1, true) or string.find(alias, normalized, 1, true)) then
      return instanceId
    end
  end

  return nil
end

-- ----------------------------------------------------------------
--  Hover sobre remolino en mapa mundial
--  → abre ventana secundaria MapPoiTooltip con datos del EJ
-- ----------------------------------------------------------------

function Tooltip:HandleMapPoiTooltip(tooltip)
  if not self.enabled or not tooltip then return end
  if not WorldMapFrame or not WorldMapFrame:IsShown() then return end

  -- Solo POIs (sin unidad)
  local _, unit = tooltip:GetUnit()
  if unit then return end

  local poiName = nil
  local tooltipName = tooltip.GetName and tooltip:GetName() or nil
  if tooltipName then
    local titleFS = _G[tooltipName .. "TextLeft1"]
    poiName = titleFS and titleFS:GetText() or nil
  end

  if not poiName or poiName == "" then
    local regions = { tooltip:GetRegions() }
    for _, region in ipairs(regions) do
      if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.IsShown and region:IsShown() then
        local text = region:GetText()
        if text and text ~= "" then
          poiName = text
          break
        end
      end
    end
  end

  if ns.config and ns.config.debugTooltip then
    print("|cffff9900[PuchiAssists]|r POI tooltip: " .. tostring(poiName))
  end

  if not poiName or poiName == "" then return end

  local instanceId = self:ResolveInstanceByMapPoiName(poiName)

  if ns.config and ns.config.debugTooltip then
    print("|cffff9900[PuchiAssists]|r instanceId: " .. tostring(instanceId))
  end

  if not instanceId then return end

  -- Mostrar ventana secundaria (datos del Encounter Journal)
  if ns.MapPoiTooltip then
    ns.MapPoiTooltip:ShowForInstance(instanceId, tooltip)
  end
end

local function CollectVisibleFontStringTexts(frame, results, seen)
  if not frame or not frame.GetRegions then
    return
  end

  for _, region in ipairs({ frame:GetRegions() }) do
    if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.IsShown and region:IsShown() then
      local text = region:GetText()
      if text and text ~= "" and not seen[text] then
        seen[text] = true
        results[#results + 1] = text
      end
    end
  end

  if frame.GetChildren then
    for _, child in ipairs({ frame:GetChildren() }) do
      CollectVisibleFontStringTexts(child, results, seen)
    end
  end
end

function Tooltip:FindInstanceFromVisibleMapTexts()
  if not WorldMapFrame then
    return nil, nil
  end

  local texts = {}
  local seen = {}

  CollectVisibleFontStringTexts(WorldMapFrame, texts, seen)

  for _, text in ipairs(texts) do
    local instanceId = self:ResolveInstanceByMapPoiNameFuzzy(text)
    if instanceId then
      return instanceId, text
    end
  end

  return nil, nil
end

function Tooltip:HandleMapLabelText(text, anchor)
  if not self.enabled then
    return
  end

  if ns.config and ns.config.debugTooltip then
    print("|cffff9900[PuchiAssists]|r AreaLabel: " .. tostring(text))
  end

  if not text or text == "" then
    if ns.MapPoiTooltip then
      ns.MapPoiTooltip:Hide()
    end
    return
  end

  local instanceId = self:ResolveInstanceByMapPoiNameFuzzy(text)
  if instanceId and ns.MapPoiTooltip then
    self._lastHoverInstanceId = instanceId
    ns.MapPoiTooltip:ShowAttachedToMap(instanceId)
  elseif ns.MapPoiTooltip then
    self._lastHoverInstanceId = nil
    ns.MapPoiTooltip:Hide()
  end
end

local function GetTooltipTextLeft1(tooltipName)
  if not tooltipName or tooltipName == "" then
    return nil
  end

  local title = _G[tooltipName .. "TextLeft1"]
  if title and title.GetText then
    return title:GetText()
  end

  return nil
end

function Tooltip:StartMapPoiWatcher()
  if self._mapLabelTicker then
    return
  end

  self._mapLabelTicker = C_Timer.NewTicker(0.10, function()
    if not self.enabled then
      return
    end

    if not WorldMapFrame or not WorldMapFrame:IsShown() then
      if self._lastMapLabelText ~= nil then
        self._lastMapLabelText = nil
        if ns.MapPoiTooltip then
          ns.MapPoiTooltip:Hide()
        end
      end
      return
    end

    local bestText = nil
    local bestAnchor = nil

    if _G.WorldMapTooltip and _G.WorldMapTooltip.IsShown and _G.WorldMapTooltip:IsShown() then
      bestText = GetTooltipTextLeft1("WorldMapTooltip")
      bestAnchor = _G.WorldMapTooltip
    end

    if (not bestText or bestText == "") and _G.GameTooltip and _G.GameTooltip.IsShown and _G.GameTooltip:IsShown() then
      bestText = GetTooltipTextLeft1("GameTooltip")
      bestAnchor = _G.GameTooltip
    end

    local areaLabel = _G.WorldMapFrameAreaLabel
    if not areaLabel and WorldMapFrame.UIElementsFrame then
      areaLabel = WorldMapFrame.UIElementsFrame.AreaLabel
    end

    if (not bestText or bestText == "") and areaLabel and areaLabel.GetText then
      bestText = areaLabel:GetText()
      bestAnchor = areaLabel
    end

    local text = bestText
    if text ~= self._lastMapLabelText then
      self._lastMapLabelText = text
      self:HandleMapLabelText(text, bestAnchor or WorldMapFrame)
    elseif text and text ~= "" then
      local instanceId = self:ResolveInstanceByMapPoiNameFuzzy(text)
      if instanceId and instanceId ~= self._lastHoverInstanceId and ns.MapPoiTooltip then
        self._lastHoverInstanceId = instanceId
        ns.MapPoiTooltip:ShowAttachedToMap(instanceId)
      end
    else
      local instanceId, matchedText = self:FindInstanceFromVisibleMapTexts()
      if ns.config and ns.config.debugTooltip and matchedText then
        print("|cffff9900[PuchiAssists]|r VisibleMapText: " .. tostring(matchedText) .. " -> " .. tostring(instanceId))
      end

      if instanceId and ns.MapPoiTooltip then
        if instanceId ~= self._lastHoverInstanceId then
          self._lastHoverInstanceId = instanceId
          self._lastMapLabelText = matchedText
          ns.MapPoiTooltip:ShowAttachedToMap(instanceId)
        end
      elseif self._lastHoverInstanceId then
        self._lastHoverInstanceId = nil
        self._lastMapLabelText = nil
        if ns.MapPoiTooltip then
          ns.MapPoiTooltip:Hide()
        end
      end
    end
  end)
end

function Tooltip:HookTooltipFrame(tooltip)
  if not tooltip or self._hookedFrames[tooltip] then
    return
  end

  self._hookedFrames[tooltip] = true

  local function SafeHook(scriptName, handler)
    if tooltip.HasScript and not tooltip:HasScript(scriptName) then
      if ns.config and ns.config.debugTooltip then
        print("|cffff9900[PuchiAssists]|r Skip HookScript(" .. tostring(scriptName) .. ") en " .. tostring(tooltip.GetName and tooltip:GetName() or "tooltip"))
      end
      return
    end

    local ok, err = pcall(function()
      tooltip:HookScript(scriptName, handler)
    end)

    if not ok and ns.config and ns.config.debugTooltip then
      print("|cffff0000[PuchiAssists]|r HookScript fallo " .. tostring(scriptName) .. ": " .. tostring(err))
    end
  end

  SafeHook("OnTooltipSetUnit", function(t)
    self:HandleUnitTooltip(t)
  end)

  SafeHook("OnShow", function(t)
    self:HandleMapPoiTooltip(t)
  end)

  SafeHook("OnHide", function(t)
    t.__PuchiLastGuid = nil
    if ns.MapPoiTooltip then
      ns.MapPoiTooltip:Hide()
    end
  end)
end

function Tooltip:HookAllTooltipFrames()
  self:HookTooltipFrame(GameTooltip)

  if _G.WorldMapTooltip then
    self:HookTooltipFrame(_G.WorldMapTooltip)
  end

  if _G.WorldMapCompareTooltip1 then
    self:HookTooltipFrame(_G.WorldMapCompareTooltip1)
  end

  if _G.WorldMapCompareTooltip2 then
    self:HookTooltipFrame(_G.WorldMapCompareTooltip2)
  end

  self:StartMapPoiWatcher()
end

function Tooltip:OnWorldMapLoaded()
  self:HookAllTooltipFrames()
end

-- ----------------------------------------------------------------
--  Hover sobre boss dentro de instancia  (tooltip nativo)
-- ----------------------------------------------------------------

local function GetCurrentInstanceIdByMap(instanceMapID)
  if not instanceMapID or not ns.BiSData or not ns.BiSData.GetInstances then
    return nil
  end

  for instanceId, instanceData in pairs(ns.BiSData:GetInstances() or {}) do
    if tonumber(instanceData.uiMapID) == tonumber(instanceMapID) or tonumber(instanceData.displayMapID) == tonumber(instanceMapID) then
      return instanceId
    end
  end

  return nil
end

function Tooltip:GetCurrentInstanceContext()
  if not IsInInstance() then
    return nil
  end

  local instanceName, instanceType, _, _, _, _, _, instanceMapID = GetInstanceInfo()
  if not instanceName or instanceName == "" then
    return nil
  end

  local instanceId = nil
  if ns.BiSData and ns.BiSData.FindInstanceByName then
    instanceId = ns.BiSData:FindInstanceByName(instanceName)
  end

  if not instanceId then
    instanceId = self:ResolveInstanceByMapPoiNameFuzzy(instanceName)
  end

  if not instanceId then
    instanceId = GetCurrentInstanceIdByMap(instanceMapID)
  end

  if not instanceId then
    return nil
  end

  local isRaid = instanceType == "raid"
  local difficultyID = isRaid and 16 or 23
  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}

  return {
    instanceId = instanceId,
    instanceName = instanceName,
    isRaid = isRaid,
    difficultyID = difficultyID,
    classID = classData.classId or 0,
    specID = classData.specId or 0,
    classToken = classData.classToken,
    specName = classData.specName,
  }
end

function Tooltip:GetEJLootForContext(context)
  if not context or not ns.EJProvider or not ns.EJProvider.CollectLootForAddonEntry then
    return nil
  end

  self._unitLootCache = self._unitLootCache or {}
  local key = string.format("%s:%d:%d:%d", tostring(context.instanceId), tonumber(context.classID) or 0, tonumber(context.specID) or 0, tonumber(context.difficultyID) or 0)
  local cached = self._unitLootCache[key]
  if cached then
    return cached
  end

  local lootData = ns.EJProvider:CollectLootForAddonEntry(context.instanceId, {
    classID = context.classID,
    specID = context.specID,
    difficultyID = context.difficultyID,
    strictDifficulty = true,
  })

  if lootData then
    self._unitLootCache[key] = lootData
  end

  return lootData
end

function Tooltip:MatchEncounterByUnitName(lootData, unitName)
  unitName = SafeText(unitName)
  if not lootData or not unitName then
    return nil
  end

  local unitNorm = NormalizeName(unitName)
  if not unitNorm or unitNorm == "" then
    return nil
  end

  for _, encounter in ipairs(lootData.encounters or {}) do
    local encounterNorm = NormalizeName(encounter.name)
    if encounterNorm and (encounterNorm == unitNorm or string.find(encounterNorm, unitNorm, 1, true) or string.find(unitNorm, encounterNorm, 1, true)) then
      return encounter
    end
  end

  if EJ_GetCreatureInfo then
    for _, encounter in ipairs(lootData.encounters or {}) do
      for i = 1, 15 do
        local creatureName = EJ_GetCreatureInfo(i, encounter.journalEncounterID)
        if not creatureName then
          break
        end

        local creatureNorm = NormalizeName(creatureName)
        if creatureNorm and (creatureNorm == unitNorm or string.find(creatureNorm, unitNorm, 1, true) or string.find(unitNorm, creatureNorm, 1, true)) then
          return encounter
        end
      end
    end
  end

  return nil
end

function Tooltip:MatchEncounterByManualOverride(instanceId, lootData, unitName)
  unitName = SafeText(unitName)
  if not instanceId or not lootData or not unitName then
    return nil
  end

  local overrides = MANUAL_BOSS_EJ_MATCHES[instanceId]
  if not overrides then
    return nil
  end

  local unitNorm = NormalizeName(unitName)
  if not unitNorm or unitNorm == "" then
    return nil
  end

  local function BuildEncounterFromInstanceLoot(journalEncounterID)
    local items = {}
    for _, item in ipairs((lootData and lootData.instanceLoot) or {}) do
      if tonumber(item.encounterID) == tonumber(journalEncounterID) then
        items[#items + 1] = item
      end
    end

    if #items == 0 then
      return nil
    end

    local encounterName = "Encounter " .. tostring(journalEncounterID)
    for _, encounter in ipairs((lootData and lootData.encounters) or {}) do
      if tonumber(encounter.journalEncounterID) == tonumber(journalEncounterID) then
        encounterName = encounter.name or encounterName
        break
      end
    end

    return {
      name = encounterName,
      journalEncounterID = journalEncounterID,
      loot = items,
    }
  end

  for journalEncounterID, aliases in pairs(overrides) do
    for _, alias in ipairs(aliases) do
      local aliasNorm = NormalizeName(alias)
      if aliasNorm and (aliasNorm == unitNorm or string.find(aliasNorm, unitNorm, 1, true) or string.find(unitNorm, aliasNorm, 1, true)) then
        for _, encounter in ipairs(lootData.encounters or {}) do
          if tonumber(encounter.journalEncounterID) == tonumber(journalEncounterID) then
            return encounter
          end
        end

        local built = BuildEncounterFromInstanceLoot(journalEncounterID)
        if built then
          return built
        end
      end
    end
  end

  local nameFallbacks = MANUAL_BOSS_ENCOUNTER_NAME_FALLBACKS[instanceId]
  if nameFallbacks then
    for _, rule in ipairs(nameFallbacks) do
      local bossMatch = false
      for _, bossAlias in ipairs(rule.bossAliases or {}) do
        local aliasNorm = NormalizeName(bossAlias)
        if aliasNorm and (aliasNorm == unitNorm or string.find(aliasNorm, unitNorm, 1, true) or string.find(unitNorm, aliasNorm, 1, true)) then
          bossMatch = true
          break
        end
      end

      if bossMatch then
        for _, encounter in ipairs(lootData.encounters or {}) do
          local encounterNorm = NormalizeName(encounter.name)
          if encounterNorm then
            for _, encounterAlias in ipairs(rule.encounterAliases or {}) do
              local encounterAliasNorm = NormalizeName(encounterAlias)
              if encounterAliasNorm and (encounterNorm == encounterAliasNorm or string.find(encounterNorm, encounterAliasNorm, 1, true) or string.find(encounterAliasNorm, encounterNorm, 1, true)) then
                return encounter
              end
            end
          end
        end
      end
    end
  end

  return nil
end

function Tooltip:MatchEncounterByNpcId(lootData, npcId)
  npcId = tonumber(npcId)
  if not lootData or not npcId then
    return nil
  end

  if EJ_GetCreatureInfo then
    for _, encounter in ipairs((lootData and lootData.encounters) or {}) do
      for i = 1, 20 do
        local creatureName, _, creatureId = EJ_GetCreatureInfo(i, encounter.journalEncounterID)
        if not creatureName and not creatureId then
          break
        end

        if tonumber(creatureId) == npcId then
          return encounter
        end
      end
    end
  end

  return nil
end

function Tooltip:BuildLikelyEncounterFromLoot(instanceId, lootData, unitName)
  if not instanceId or not lootData then
    return nil
  end

  local safeUnitName = SafeText(unitName)
  local unitNorm = NormalizeName(safeUnitName)

  local desiredEncounterAlias = {}
  local hasRuleForBoss = false
  local nameFallbacks = MANUAL_BOSS_ENCOUNTER_NAME_FALLBACKS[instanceId]
  if nameFallbacks and unitNorm then
    for _, rule in ipairs(nameFallbacks) do
      for _, bossAlias in ipairs(rule.bossAliases or {}) do
        local bossAliasNorm = NormalizeName(bossAlias)
        if bossAliasNorm and (bossAliasNorm == unitNorm or string.find(bossAliasNorm, unitNorm, 1, true) or string.find(unitNorm, bossAliasNorm, 1, true)) then
          hasRuleForBoss = true
          for _, encounterAlias in ipairs(rule.encounterAliases or {}) do
            local encounterAliasNorm = NormalizeName(encounterAlias)
            if encounterAliasNorm then
              desiredEncounterAlias[encounterAliasNorm] = true
            end
          end
          break
        end
      end
    end
  end

  if nameFallbacks and unitNorm and not hasRuleForBoss then
    return nil
  end

  local lootByEncounterId = {}
  local countByEncounterId = {}
  for _, item in ipairs((lootData and lootData.instanceLoot) or {}) do
    local encounterId = tonumber(item and item.encounterID)
    if encounterId then
      lootByEncounterId[encounterId] = lootByEncounterId[encounterId] or {}
      table.insert(lootByEncounterId[encounterId], item)
      countByEncounterId[encounterId] = (countByEncounterId[encounterId] or 0) + 1
    end
  end

  local bestEncounter = nil
  local bestCount = -1

  for _, encounter in ipairs((lootData and lootData.encounters) or {}) do
    local encounterId = tonumber(encounter and encounter.journalEncounterID)
    if encounterId then
      local encounterCount = countByEncounterId[encounterId] or 0
      local encounterNorm = NormalizeName(encounter.name)

      if next(desiredEncounterAlias) and encounterNorm and desiredEncounterAlias[encounterNorm] and encounterCount > 0 then
        encounter.loot = lootByEncounterId[encounterId] or encounter.loot or {}
        return encounter
      end

      if encounterCount > bestCount then
        bestCount = encounterCount
        bestEncounter = encounter
      end
    end
  end

  if bestEncounter and bestCount > 0 then
    bestEncounter.loot = lootByEncounterId[tonumber(bestEncounter.journalEncounterID)] or bestEncounter.loot or {}
    return bestEncounter
  end

  local fallbackEncounterId = nil
  local fallbackCount = 0
  for encounterId, encounterCount in pairs(countByEncounterId) do
    if encounterCount > fallbackCount then
      fallbackCount = encounterCount
      fallbackEncounterId = encounterId
    end
  end

  if fallbackEncounterId and fallbackCount > 0 then
    return {
      name = "Encounter " .. tostring(fallbackEncounterId),
      journalEncounterID = fallbackEncounterId,
      loot = lootByEncounterId[fallbackEncounterId] or {},
    }
  end

  return nil
end

function Tooltip:AppendEncounterLootToTooltip(tooltip, unitName, unitGuid)
  unitName = SafeText(unitName)
  if not self.enabled or not tooltip or not unitName then
    return false
  end

  if unitGuid and tooltip.__PuchiLastGuid == unitGuid then
    return true
  end

  local context = self:GetCurrentInstanceContext()
  if not context then
    return false
  end

  local lootData = self:GetEJLootForContext(context)

  if ns.config and ns.config.debugTooltip then
    local instanceLootCount = lootData and lootData.instanceLoot and #lootData.instanceLoot or 0
    local encounterCount = lootData and lootData.encounters and #lootData.encounters or 0
    print("|cffff9900[PuchiAssists]|r LootData: instanceLoot=" .. tostring(instanceLootCount) .. " | encounters=" .. tostring(encounterCount) .. " | diff=" .. tostring(context.difficultyID))
  end

  local encounter = self:MatchEncounterByUnitName(lootData, unitName)
  if not encounter then
    encounter = self:MatchEncounterByManualOverride(context.instanceId, lootData, unitName)
  end

  if ns.config and ns.config.debugTooltip then
    print("|cffff9900[PuchiAssists]|r Unit tooltip: " .. tostring(unitName) .. " | instance=" .. tostring(context.instanceId) .. " | encounter=" .. tostring(encounter and encounter.name or "nil"))
  end

  if not encounter or not encounter.loot then
    return false
  end

  tooltip.__PuchiLastGuid = unitGuid or tooltip.__PuchiLastGuid
  tooltip:AddLine(" ")
  tooltip:AddLine("PuchiAssists EJ", 0.4, 0.8, 1)
  tooltip:AddLine(tostring(encounter.name or "Encounter"), 0.85, 0.85, 0.85)

  if #encounter.loot == 0 then
    tooltip:AddLine("- Sin loot filtrado para tu clase/spec", 0.75, 0.75, 0.75)
  else
    for _, item in ipairs(encounter.loot) do
      local name = ns.BiSData:GetItemDisplayName(item)
      tooltip:AddLine(string.format("- %s (%s)", name, item.slot or "N/D"), 1, 1, 1)
    end
  end

  tooltip:Show()
  return true
end

function Tooltip:FindEncounterForUnit(unitName)
  unitName = SafeText(unitName)
  if not unitName then
    return nil, nil
  end

  local context = self:GetCurrentInstanceContext()
  if not context then
    return nil, nil
  end

  local lootData = self:GetEJLootForContext(context)
  local encounter = self:MatchEncounterByUnitName(lootData, unitName)
  if not encounter then
    encounter = self:MatchEncounterByManualOverride(context.instanceId, lootData, unitName)
  end

  return encounter, context
end

function Tooltip:FindEncounterForUnitOrNpc(unitName, npcId)
  local safeUnitName = SafeText(unitName)

  local context = self:GetCurrentInstanceContext()
  if not context then
    return nil, nil
  end

  local lootData = self:GetEJLootForContext(context)
  local encounter = self:MatchEncounterByNpcId(lootData, npcId)

  if not encounter and safeUnitName then
    encounter = self:MatchEncounterByUnitName(lootData, safeUnitName)
    if not encounter then
      encounter = self:MatchEncounterByManualOverride(context.instanceId, lootData, safeUnitName)
    end
  end

  if not encounter then
    encounter = self:BuildLikelyEncounterFromLoot(context.instanceId, lootData, safeUnitName)
  end

  if ns.config and ns.config.debugTooltip and not encounter then
    local parts = {}
    for _, e in ipairs((lootData and lootData.encounters) or {}) do
      parts[#parts + 1] = tostring(e and e.name or "?") .. "(" .. tostring(e and e.journalEncounterID or "?") .. ")"
    end
    print("|cffff8800[PuchiAssists]|r Encounter list: " .. table.concat(parts, " | "))
  end

  return encounter, context
end

function Tooltip:StartBossPanelWatcher()
  if self._bossPanelTicker then
    return
  end

  self._bossPanelTicker = C_Timer.NewTicker(0.10, function()
    if not self.enabled then
      self:HideBossPanel()
      return
    end

    local unitToken = nil
    if UnitExists and UnitExists("target") then
      unitToken = "target"
    elseif UnitExists and UnitExists("mouseover") then
      unitToken = "mouseover"
    end

    if not unitToken then
      self:HideBossPanel()
      return
    end

    local unitName = SafeText(UnitName(unitToken))
    local unitGuid = UnitGUID and UnitGUID(unitToken) or nil
    local npcId = GetNpcId(unitGuid)

    if not unitName and not npcId then
      self:HideBossPanel()
      return
    end

    local encounter, context = self:FindEncounterForUnitOrNpc(unitName, npcId)
    if ns.config and ns.config.debugTooltip then
      print("|cffff9900[PuchiAssists]|r BossPanel watcher: " .. tostring(unitToken) .. " -> " .. tostring(unitName or ("npc:" .. tostring(npcId))) .. " | " .. tostring(encounter and encounter.name or "nil"))
    end

    if encounter then
      self:ShowBossPanel(unitName or ("NPC " .. tostring(npcId or "?")), encounter)
    else
      self:ShowBossPanelDiagnostic("PuchiAssists Boss", {
        "Unidad: " .. tostring(unitName or "nil"),
        "NPCID: " .. tostring(npcId or "nil"),
        "Trigger: " .. tostring(unitToken),
        "Instancia: " .. tostring(context and context.instanceId or "nil"),
        "Encounter: no encontrado",
        "Tip: selecciona el boss como target",
      })
    end
  end)
end

function Tooltip:InitBossEventWatcher()
  if self._bossEventFrame then
    return
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_TARGET_CHANGED")
  frame:SetScript("OnEvent", function()
    if not self.enabled then
      return
    end

    C_Timer.After(0, function()
      local unitName = UnitExists("target") and SafeText(UnitName("target")) or nil
      if ns.config and ns.config.debugTooltip then
        print("|cffff9900[PuchiAssists]|r PLAYER_TARGET_CHANGED: " .. tostring(unitName or "nil"))
      end
    end)
  end)

  self._bossEventFrame = frame
end

function Tooltip:TryHandleMouseoverTooltip(delay)
  C_Timer.After(delay or 0, function()
    if not self.enabled then
      return
    end

    if not UnitExists or not UnitExists("mouseover") then
      return
    end

    local unitName = SafeText(UnitName("mouseover"))
    local unitGuid = UnitGUID("mouseover")
    if not unitName then
      return
    end

    local tooltip = GameTooltip
    if not tooltip or (tooltip.IsShown and not tooltip:IsShown()) then
      return
    end

    self:AppendEncounterLootToTooltip(tooltip, unitName, unitGuid)
  end)
end

function Tooltip:InitUnitEventWatcher()
  if self._unitEventFrame then
    return
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
  frame:SetScript("OnEvent", function()
    if ns.config and ns.config.debugTooltip then
      local unitName = UnitExists("mouseover") and SafeText(UnitName("mouseover")) or "nil"
      print("|cffff9900[PuchiAssists]|r UPDATE_MOUSEOVER_UNIT: " .. tostring(unitName))
    end

    self:TryHandleMouseoverTooltip(0)
    self:TryHandleMouseoverTooltip(0.03)
    self:TryHandleMouseoverTooltip(0.10)
  end)

  self._unitEventFrame = frame
end

function Tooltip:HandleUnitTooltip(tooltip)
  if not self.enabled or not tooltip then return end

  local _, unit = tooltip:GetUnit()
  if not unit then return end

  local unitName = SafeText(UnitName(unit))
  local unitGuid = UnitGUID(unit)
  local npcId  = GetNpcId(unitGuid)

  if not unitName and not npcId then
    return
  end

  if unitName and self:AppendEncounterLootToTooltip(tooltip, unitName, unitGuid) then
    return
  end

  local context = self:GetCurrentInstanceContext()
  local instanceId = context and context.instanceId or nil
  if not instanceId then return end

  local bossId = ns.BiSData:FindBoss(instanceId, unitName or "", npcId)
  if not bossId then return end

  local classData = ns.ClassResolver and ns.ClassResolver:Get()
  if not classData or not classData.classToken then return end

  local items = ns.BiSData:GetItemsForBossByClass(instanceId, bossId, classData.classToken, classData.specName, classData.specId)

  tooltip:AddLine(" ")
  tooltip:AddLine("PuchiAssists BiS", 0.4, 0.8, 1)

  if not items or #items == 0 then
    tooltip:AddLine("- Sin BiS para " .. (classData.specName or classData.classToken or "tu clase"), 0.75, 0.75, 0.75)
  else
    for _, item in ipairs(items) do
      local name = ns.BiSData:GetItemDisplayName(item)
      tooltip:AddLine(string.format("- %s (%s)", name, item.slot or "N/D"), 1, 1, 1)
    end
  end

  tooltip:Show()
end

function Tooltip:HandleUnitTooltipData(tooltip, data)
  if not self.enabled or not tooltip or not data then
    return false
  end

  local unitName = SafeText(data.name)
  local unitGuid = SafeText(data.guid)
  local npcId = GetNpcId(unitGuid) or tonumber(data.id)

  if ns.config and ns.config.debugTooltip then
    print("|cffff9900[PuchiAssists]|r TooltipData(Unit): name=" .. tostring(unitName or "nil") .. " guid=" .. tostring(unitGuid or "nil") .. " npcId=" .. tostring(npcId or "nil"))
  end

  local appended = false
  if unitName then
    appended = self:AppendEncounterLootToTooltip(tooltip, unitName, unitGuid) or false
  end

  local encounter = nil
  local context = nil
  if npcId or unitName then
    encounter, context = self:FindEncounterForUnitOrNpc(unitName, npcId)
  end

  if encounter then
    self:ShowBossPanel(unitName or ("NPC " .. tostring(npcId or "?")), encounter)
  elseif context then
    self:ShowBossPanelDiagnostic("PuchiAssists Boss", {
      "Unidad: " .. tostring(unitName or "nil"),
      "NPCID: " .. tostring(npcId or "nil"),
      "Instancia: " .. tostring(context and context.instanceId or "nil"),
      "Encounter: no encontrado (fallback activo)",
    })
  end

  return appended or encounter ~= nil
end

-- ----------------------------------------------------------------
--  Init
-- ----------------------------------------------------------------

function Tooltip:Init()
  self.enabled = true

  self:HookAllTooltipFrames()
  self:InitUnitEventWatcher()
  self:InitBossEventWatcher()
  self:StartBossPanelWatcher()

  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
      if ns.config and ns.config.debugTooltip then
        print("|cffff9900[PuchiAssists]|r TooltipDataProcessor(Unit): " .. tostring(data and data.id or "nil"))
      end

      if not self:HandleUnitTooltipData(tooltip, data) then
        self:HandleUnitTooltip(tooltip)
      end
    end)
  end

  self:BuildMapInstanceNameIndex()

  if ns.config and ns.config.debugTooltip and ns.Print then
    ns.Print("Tooltip POI inicializado")
  end
end

function Tooltip:SetEnabled(enabled)
  self.enabled = not not enabled
  if not enabled and ns.MapPoiTooltip then
    ns.MapPoiTooltip:Hide()
  end
  if not enabled then
    self:HideBossPanel()
  end
end


