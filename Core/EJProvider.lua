local _, ns = ...

local EJProvider = {}
ns.EJProvider = EJProvider

local function SafeSetSlotFilter(slotFilter)
  if C_EncounterJournal and C_EncounterJournal.SetSlotFilter then
    C_EncounterJournal.SetSlotFilter(slotFilter or Enum.ItemSlotFilterType.NoFilter)
  end
end

local function GetDifficultyCandidates(entry, preferredDifficultyID, strictDifficulty)
  local preferred = tonumber(preferredDifficultyID)
  if strictDifficulty and preferred then
    return { preferred }
  end

  local list = {}
  local seen = {}

  local function add(id)
    id = tonumber(id)
    if id and not seen[id] then
      seen[id] = true
      list[#list + 1] = id
    end
  end

  add(preferred)

  if entry and entry.kind == "raid" then
    add(16)
    add(15)
    add(14)
    add(17)
  else
    add(23)
    add(8)
    add(2)
    add(1)
  end

  return list
end

local function CountTotalLoot(encounters)
  local total = 0
  for _, encounter in ipairs(encounters or {}) do
    total = total + #(encounter.loot or {})
  end
  return total
end

local function CountItems(items)
  return #(items or {})
end

local function CollectInstanceLootForCurrentSelection(selectedDifficultyID)
  local loot = {}
  local seen = {}

  for lootIndex = 1, (EJ_GetNumLoot() or 0) do
    local info = C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex and C_EncounterJournal.GetLootInfoByIndex(lootIndex)
    if info and info.name and info.itemID then
      local key = tostring(info.itemID) .. ":" .. tostring(info.link or "")
      if not seen[key] then
        seen[key] = true
        loot[#loot + 1] = {
          itemID = info.itemID,
          encounterID = info.encounterID,
          name = info.name,
          slot = info.slot or "N/D",
          link = info.link,
          source = "Encounter Journal",
          difficulty = tostring(selectedDifficultyID or "N/D"),
          displayAsVeryRare = info.displayAsVeryRare,
          displayAsExtremelyRare = info.displayAsExtremelyRare,
        }
      end
    end
  end

  table.sort(loot, function(a, b)
    if tostring(a.slot) == tostring(b.slot) then
      return tostring(a.name) < tostring(b.name)
    end
    return tostring(a.slot) < tostring(b.slot)
  end)

  return loot
end

local function CollectEncountersForCurrentSelection(journalInstanceID, selectedDifficultyID)
  local encounters = {}
  local encounterIndex = 1

  while true do
    local encounterName, _, journalEncounterID = EJ_GetEncounterInfoByIndex(encounterIndex, journalInstanceID)
    if not encounterName or not journalEncounterID then
      encounterName, _, journalEncounterID = EJ_GetEncounterInfoByIndex(encounterIndex)
    end

    if not encounterName or not journalEncounterID then
      break
    end

    EJ_SelectEncounter(journalEncounterID)

    local loot = {}
    local seenByItemID = {}
    for lootIndex = 1, (EJ_GetNumLoot() or 0) do
      local info = C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex and C_EncounterJournal.GetLootInfoByIndex(lootIndex, encounterIndex)
      if info and info.name and info.itemID and not seenByItemID[info.itemID] then
        seenByItemID[info.itemID] = true
        loot[#loot + 1] = {
          itemID = info.itemID,
          encounterID = journalEncounterID,
          name = info.name,
          slot = info.slot or "N/D",
          link = info.link,
          source = "Encounter Journal",
          difficulty = tostring(selectedDifficultyID or "N/D"),
        }
      end
    end

    table.sort(loot, function(a, b)
      if tostring(a.slot) == tostring(b.slot) then
        return tostring(a.name) < tostring(b.name)
      end
      return tostring(a.slot) < tostring(b.slot)
    end)

    encounters[#encounters + 1] = {
      name = encounterName,
      journalEncounterID = journalEncounterID,
      loot = loot,
    }

    encounterIndex = encounterIndex + 1
  end

  return encounters
end

function EJProvider:CollectLootForEntry(entryOrId, options)
  options = options or {}

  local entry = type(entryOrId) == "table" and entryOrId or (ns.Instances and ns.Instances:GetByID(entryOrId))
  if not entry or not entry.journalInstanceID then
    return nil, "Instancia no disponible en Encounter Journal"
  end

  local preferredDifficultyID = tonumber(options.difficultyID) or tonumber(entry.difficultyID) or 16
  local classID = tonumber(options.classID) or 0
  local specID = tonumber(options.specID) or 0

  local selectedDifficultyID = preferredDifficultyID
  local encounters = {}
  local instanceLoot = {}
  local difficultyCandidates = GetDifficultyCandidates(entry, preferredDifficultyID, options.strictDifficulty ~= false)

  for _, difficultyID in ipairs(difficultyCandidates) do
    EJ_SelectInstance(entry.journalInstanceID)
    EJ_SetDifficulty(difficultyID)
    SafeSetSlotFilter(options.slotFilter or Enum.ItemSlotFilterType.NoFilter)
    EJ_SetLootFilter(classID, specID)

    instanceLoot = CollectInstanceLootForCurrentSelection(difficultyID)
    encounters = CollectEncountersForCurrentSelection(entry.journalInstanceID, difficultyID)
    selectedDifficultyID = difficultyID

    if #encounters > 0 or CountItems(instanceLoot) > 0 then
      if CountItems(instanceLoot) > 0 or CountTotalLoot(encounters) > 0 then
        break
      end

      EJ_SelectInstance(entry.journalInstanceID)
      EJ_SetDifficulty(difficultyID)
      SafeSetSlotFilter(options.slotFilter or Enum.ItemSlotFilterType.NoFilter)
      EJ_SetLootFilter(0, 0)

      instanceLoot = CollectInstanceLootForCurrentSelection(difficultyID)
      local unfilteredEncounters = CollectEncountersForCurrentSelection(entry.journalInstanceID, difficultyID)
      if CountItems(instanceLoot) > 0 or CountTotalLoot(unfilteredEncounters) > 0 then
        encounters = unfilteredEncounters
        selectedDifficultyID = difficultyID
        break
      end
    end
  end

  return {
    instanceId = entry.id,
    instanceName = (ns.Instances and ns.Instances:GetLocalizedName(entry)) or entry.name,
    difficultyID = selectedDifficultyID,
    classID = classID,
    specID = specID,
    isRaid = entry.kind == "raid",
    instanceLoot = instanceLoot,
    encounters = encounters,
  }
end

function EJProvider:CollectLootForAddonEntry(entryId, options)
  return self:CollectLootForEntry(entryId, options)
end
