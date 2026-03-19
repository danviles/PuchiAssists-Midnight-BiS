local _, ns = ...

ns.BossTooltip = ns.BossTooltip or {}

local BossTooltip = ns.BossTooltip

local encounterNameCache = nil

local function BuildEncounterCache()
  if encounterNameCache then
    return encounterNameCache
  end

  encounterNameCache = {}

  local entries = ns.Instances and ns.Instances:GetAll() or {}
  for _, entry in ipairs(entries) do
    if entry.journalInstanceID then
      local encounterIndex = 1
      while true do
        local encounterName, _, journalEncounterID = EJ_GetEncounterInfoByIndex(encounterIndex, entry.journalInstanceID)
        if not encounterName or not journalEncounterID then
          break
        end

        local nameLower = string.lower(encounterName)
        if not encounterNameCache[nameLower] then
          encounterNameCache[nameLower] = {}
        end
        encounterNameCache[nameLower][#encounterNameCache[nameLower] + 1] = {
          entry = entry,
          encounterName = encounterName,
          journalEncounterID = journalEncounterID,
        }

        encounterIndex = encounterIndex + 1
      end
    end
  end

  return encounterNameCache
end

local function InvalidateCache()
  encounterNameCache = nil
end

local function FindEncountersByName(name)
  if not name or name == "" then
    return nil
  end

  local cache = BuildEncounterCache()
  return cache[string.lower(name)]
end

local function GetLootForEncounter(entry, journalEncounterID)
  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  local classID = tonumber(classData.classId) or 0
  local specID = tonumber(classData.specId) or 0

  EJ_SelectInstance(entry.journalInstanceID)
  EJ_SetDifficulty(entry.difficultyID or 16)

  if C_EncounterJournal and C_EncounterJournal.SetSlotFilter then
    C_EncounterJournal.SetSlotFilter(Enum.ItemSlotFilterType.NoFilter)
  end

  EJ_SetLootFilter(classID, specID)
  EJ_SelectEncounter(journalEncounterID)

  local loot = {}
  local seen = {}
  for lootIndex = 1, (EJ_GetNumLoot() or 0) do
    local info = C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex and C_EncounterJournal.GetLootInfoByIndex(lootIndex)
    if info and info.name and info.itemID and not seen[info.itemID] then
      seen[info.itemID] = true
      loot[#loot + 1] = {
        itemID = info.itemID,
        name = info.name,
        slot = info.slot or "N/D",
        link = info.link,
      }
    end
  end

  return loot
end

local function AppendBiSToTooltip(tooltip, unitName)
  if not (ns.config and ns.config.showBossTooltip ~= false) then
    return
  end

  local matches = FindEncountersByName(unitName)
  if not matches or #matches == 0 then
    return
  end

  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  local classToken = classData.classToken or "N/D"
  local specName = classData.specName or "N/D"

  for _, match in ipairs(matches) do
    local loot = GetLootForEncounter(match.entry, match.journalEncounterID)
    if loot and #loot > 0 then
      local instanceName = ns.Instances and ns.Instances:GetLocalizedName(match.entry) or match.entry.name
      tooltip:AddLine(" ")
      tooltip:AddLine("|cff66ccffPuchiAssists BiS|r - " .. tostring(instanceName), 0.4, 0.8, 1)
      tooltip:AddLine(classToken .. " / " .. specName, 0.7, 0.7, 0.7)

      for _, item in ipairs(loot) do
        local displayName = item.name
        if item.link then
          displayName = item.link
        end
        tooltip:AddLine("  - " .. tostring(displayName) .. " [" .. tostring(item.slot) .. "]", 1, 1, 1)
      end
    end
  end
end

function BossTooltip:Init()
  if self.initialized then
    return
  end

  self.initialized = true

  GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
    local unit = select(2, tooltip:GetUnit())
    if not unit then
      return
    end

    if not UnitCreatureType(unit) then
      return
    end

    local unitName = UnitName(unit)
    if not unitName or unitName == "" then
      return
    end

    AppendBiSToTooltip(tooltip, unitName)
  end)
end

function BossTooltip:InvalidateCache()
  InvalidateCache()
end
