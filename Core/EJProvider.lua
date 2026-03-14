local _, ns = ...

local EJProvider = {}
ns.EJProvider = EJProvider

local function NormalizeName(value)
  if not value or value == "" then
    return nil
  end

  return tostring(value):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local MIDNIGHT_SCAN_QUERIES = {
  "midnight",
  "windrunner",
  "murder",
  "magister",
  "maisara",
  "nalorakk",
  "voidspire",
  "dreamrift",
  "xenas",
  "blinding vale",
  "voidscar",
}

local MIDNIGHT_MAP_IDS = {
  [2393] = true,
  [2395] = true,
  [2405] = true,
  [2413] = true,
  [2424] = true,
  [2437] = true,
  [2444] = true,
  [2537] = true,
}

local MIDNIGHT_EJ_OVERRIDES = {
  windrunner_spire = { journalInstanceID = 1299, name = "Windrunner Spire", isRaid = false },
  voidscar_arena = { journalInstanceID = 1313, name = "Voidscar Arena", isRaid = false },
  magisters_terrace = { journalInstanceID = 1300, name = "Bancal del Magister", isRaid = false },
  maisara_caverns = { journalInstanceID = 1315, name = "Cavernas de Maisara", isRaid = false },
  murder_row = { journalInstanceID = 1304, name = "Murder Row", isRaid = false },
  the_blinding_vale = { journalInstanceID = 1309, name = "The Blinding Vale", isRaid = false },
  den_of_nalorakk = { journalInstanceID = 1311, name = "Guarida de Nalorakk", isRaid = false },
  nexus_point_xenas = { journalInstanceID = 1316, name = "Punto del Nexo Xenas", isRaid = false },
  the_dreamrift = { journalInstanceID = 1314, name = "The Dreamrift", isRaid = true },
  the_voidspire = { journalInstanceID = 1307, name = "The Voidspire", isRaid = true },
  midnight = { journalInstanceID = 1312, name = "Midnight", isRaid = true },
}

local function MakeSlug(value)
  local normalized = NormalizeName(value) or "unknown"
  normalized = normalized:gsub("[^%w]+", "_")
  normalized = normalized:gsub("_+", "_")
  normalized = normalized:gsub("^_", ""):gsub("_$", "")
  return normalized
end

local function SafeSetSlotFilter(slotFilter)
  if C_EncounterJournal and C_EncounterJournal.SetSlotFilter then
    C_EncounterJournal.SetSlotFilter(slotFilter or Enum.ItemSlotFilterType.NoFilter)
  end
end

local function GetDifficultyCandidates(isRaid, preferredDifficultyID)
  local preferred = tonumber(preferredDifficultyID)
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

  if isRaid then
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

local function GetStrictDifficultyCandidates(preferredDifficultyID)
  local preferred = tonumber(preferredDifficultyID)
  if preferred then
    return { preferred }
  end
  return {}
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

local function CollectInstanceLootForCurrentSelection()
  local loot = {}
  local seen = {}

  for lootIndex = 1, (EJ_GetNumLoot() or 0) do
    local info = C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex and C_EncounterJournal.GetLootInfoByIndex(lootIndex)
    if info and info.name and info.itemID then
      local key = tostring(info.itemID) .. ":" .. tostring(info.link or "")
      if not seen[key] then
        seen[key] = true
        loot[#loot + 1] = {
          itemId = info.itemID,
          itemID = info.itemID,
          encounterID = info.encounterID,
          name = info.name,
          slot = info.slot or "N/D",
          link = info.link,
          source = "Encounter Journal",
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

local function CollectEncountersForCurrentSelection(journalInstanceID, classID, specID)
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
          itemId = info.itemID,
          itemID = info.itemID,
          name = info.name,
          slot = info.slot or "N/D",
          link = info.link,
          source = "Encounter Journal",
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

function EJProvider:ResolveInstanceName(input)
  if not input or input == "" then
    return nil
  end

  local normalized = tostring(input):lower()
  if ns.BiSData and ns.BiSData.GetInstance then
    local instance = ns.BiSData:GetInstance(normalized)
    if instance and instance.name then
      return instance.name
    end
  end

  return tostring(input):gsub("_", " ")
end

function EJProvider:FindJournalInstanceByName(instanceName)
  local target = NormalizeName(instanceName)
  if not target then
    return nil
  end

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
        local journalInstanceID, name = EJ_GetInstanceByIndex(index, isRaid)
        if not journalInstanceID then
          break
        end

        if NormalizeName(name) == target then
          return {
            tier = tier,
            isRaid = isRaid,
            journalInstanceID = journalInstanceID,
            name = name,
          }
        end

        index = index + 1
      end
    end
  end

  return nil
end

function EJProvider:CollectLootForInstance(instanceName, options)
  options = options or {}

  local instance = self:FindJournalInstanceByName(instanceName)
  if not instance then
    return nil, "Instancia no encontrada en la Guia de aventura: " .. tostring(instanceName)
  end

  local difficultyID = tonumber(options.difficultyID) or 16
  local classID = tonumber(options.classID) or 0
  local specID = tonumber(options.specID) or 0

  if EJ_SelectTier then
    EJ_SelectTier(instance.tier)
  end

  EJ_SelectInstance(instance.journalInstanceID)
  EJ_SetDifficulty(difficultyID)
  SafeSetSlotFilter(options.slotFilter or Enum.ItemSlotFilterType.NoFilter)
  EJ_SetLootFilter(classID, specID)

  local encounters = {}
  local encounterIndex = 1

  while true do
    local encounterName, _, journalEncounterID = EJ_GetEncounterInfoByIndex(encounterIndex, instance.journalInstanceID)
    if not encounterName or not journalEncounterID then
      break
    end

    EJ_SelectEncounter(journalEncounterID)

    local loot = {}
    local seenByItemID = {}
    for lootIndex = 1, (EJ_GetNumLoot() or 0) do
      local info = C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex and C_EncounterJournal.GetLootInfoByIndex(lootIndex)
      if info and info.name and info.itemID and not seenByItemID[info.itemID] then
        seenByItemID[info.itemID] = true
        loot[#loot + 1] = {
          itemID = info.itemID,
          name = info.name,
          slot = info.slot or "N/D",
          link = info.link,
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

  return {
    instanceName = instance.name,
    difficultyID = difficultyID,
    classID = classID,
    specID = specID,
    tier = instance.tier,
    isRaid = instance.isRaid,
    encounters = encounters,
  }
end

function EJProvider:CollectLootForJournalInstance(journalInstanceID, options)
  options = options or {}

  if not journalInstanceID then
    return nil, "journalInstanceID invalido"
  end

  local preferredDifficultyID = tonumber(options.difficultyID) or 16
  local classID = tonumber(options.classID) or 0
  local specID = tonumber(options.specID) or 0
  local tier = tonumber(options.tier)

  if tier and EJ_SelectTier then
    EJ_SelectTier(tier)
  end

  local instanceName = options.instanceName
  if not instanceName and EJ_GetInstanceInfo then
    instanceName = EJ_GetInstanceInfo(journalInstanceID)
  end

  local selectedDifficultyID = preferredDifficultyID
  local encounters = {}
  local instanceLoot = {}
  local difficultyCandidates = options.strictDifficulty and GetStrictDifficultyCandidates(preferredDifficultyID) or GetDifficultyCandidates(options.isRaid, preferredDifficultyID)

  for _, difficultyID in ipairs(difficultyCandidates) do
    EJ_SelectInstance(journalInstanceID)
    EJ_SetDifficulty(difficultyID)
    SafeSetSlotFilter(options.slotFilter or Enum.ItemSlotFilterType.NoFilter)
    EJ_SetLootFilter(classID, specID)

    instanceLoot = CollectInstanceLootForCurrentSelection()
    encounters = CollectEncountersForCurrentSelection(journalInstanceID, classID, specID)
    selectedDifficultyID = difficultyID

    if #encounters > 0 or CountItems(instanceLoot) > 0 then
      if CountItems(instanceLoot) > 0 or CountTotalLoot(encounters) > 0 then
        break
      end

      EJ_SelectInstance(journalInstanceID)
      EJ_SetDifficulty(difficultyID)
      SafeSetSlotFilter(options.slotFilter or Enum.ItemSlotFilterType.NoFilter)
      EJ_SetLootFilter(0, 0)

      instanceLoot = CollectInstanceLootForCurrentSelection()
      local unfilteredEncounters = CollectEncountersForCurrentSelection(journalInstanceID, 0, 0)
      if CountItems(instanceLoot) > 0 or CountTotalLoot(unfilteredEncounters) > 0 then
        encounters = unfilteredEncounters
        selectedDifficultyID = difficultyID
        break
      end
    end
  end

  for _, item in ipairs(instanceLoot or {}) do
    item.difficulty = tostring(selectedDifficultyID)
  end

  for _, encounter in ipairs(encounters or {}) do
    for _, item in ipairs(encounter.loot or {}) do
      item.difficulty = tostring(selectedDifficultyID)
    end
  end

  return {
    instanceName = instanceName or tostring(journalInstanceID),
    difficultyID = selectedDifficultyID,
    classID = classID,
    specID = specID,
    tier = tier,
    isRaid = not not options.isRaid,
    instanceLoot = instanceLoot,
    encounters = encounters,
  }
end

function EJProvider:CollectLootForAddonEntry(entryId, options)
  options = options or {}

  local override = MIDNIGHT_EJ_OVERRIDES[entryId]
  if not override then
    return nil, "La instancia no existe en Encounter Journal para esta build: " .. tostring(entryId)
  end

  local scan = self:GetSavedScan()
  local tier = options.tier
  if scan then
    for _, entry in ipairs(scan) do
      if tonumber(entry.journalInstanceID) == tonumber(override.journalInstanceID) then
        tier = tier or entry.tier
        break
      end
    end
  end

  return self:CollectLootForJournalInstance(override.journalInstanceID, {
    difficultyID = options.difficultyID or (override.isRaid and 16 or 23),
    strictDifficulty = options.strictDifficulty,
    classID = options.classID,
    specID = options.specID,
    slotFilter = options.slotFilter,
    tier = tier,
    isRaid = override.isRaid,
    instanceName = override.name,
  })
end

function EJProvider:BuildMarkdown(lootData)
  if not lootData then
    return nil
  end

  local lines = {}
  lines[#lines + 1] = "# " .. tostring(lootData.instanceName)
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Fuente: Adventure Guide (Encounter Journal API)"
  lines[#lines + 1] = "Filtro aplicado: classID=" .. tostring(lootData.classID) .. ", specID=" .. tostring(lootData.specID) .. ", difficultyID=" .. tostring(lootData.difficultyID)
  lines[#lines + 1] = ""

  for _, encounter in ipairs(lootData.encounters or {}) do
    lines[#lines + 1] = "## " .. tostring(encounter.name)
    lines[#lines + 1] = ""

    if not encounter.loot or #encounter.loot == 0 then
      lines[#lines + 1] = "- Sin loot para este filtro."
      lines[#lines + 1] = ""
    else
      lines[#lines + 1] = "| Item | ItemID | Slot |"
      lines[#lines + 1] = "| --- | --- | --- |"
      for _, item in ipairs(encounter.loot) do
        lines[#lines + 1] = "| " .. tostring(item.name) .. " | " .. tostring(item.itemID) .. " | " .. tostring(item.slot) .. " |"
      end
      lines[#lines + 1] = ""
    end
  end

  return table.concat(lines, "\n")
end

function EJProvider:ExportMarkdownToSavedVariables(instanceName, options)
  local lootData, err = self:CollectLootForInstance(instanceName, options)
  if not lootData then
    return nil, err
  end

  local markdown = self:BuildMarkdown(lootData)
  if not markdown then
    return nil, "No se pudo construir markdown"
  end

  PuchiAssistsMidnightBiSDB = PuchiAssistsMidnightBiSDB or {}
  PuchiAssistsMidnightBiSDB.ejExports = PuchiAssistsMidnightBiSDB.ejExports or {}

  local specPart = options and options.specID and tostring(options.specID) or "0"
  local key = MakeSlug(instanceName) .. "_spec_" .. specPart

  PuchiAssistsMidnightBiSDB.ejExports[key] = {
    instanceName = lootData.instanceName,
    createdAt = date("%Y-%m-%d %H:%M:%S"),
    classID = lootData.classID,
    specID = lootData.specID,
    difficultyID = lootData.difficultyID,
    markdown = markdown,
  }

  return key, markdown
end

function EJProvider:ScanAllInstances()
  local results = {}

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
        local journalInstanceID, name = EJ_GetInstanceByIndex(index, isRaid)
        if not journalInstanceID then
          break
        end

        local ejName, description, bgImage, buttonImage1, loreImage, dungeonAreaMapID, link = EJ_GetInstanceInfo(journalInstanceID)
        results[#results + 1] = {
          tier = tier,
          isRaid = isRaid,
          index = index,
          journalInstanceID = journalInstanceID,
          name = ejName or name,
          dungeonAreaMapID = tonumber(dungeonAreaMapID),
          link = link,
        }

        index = index + 1
      end
    end
  end

  return results
end

function EJProvider:ExportScanToSavedVariables()
  local scan = self:ScanAllInstances()

  PuchiAssistsMidnightBiSDB = PuchiAssistsMidnightBiSDB or {}
  PuchiAssistsMidnightBiSDB.ejScan = {
    createdAt = date("%Y-%m-%d %H:%M:%S"),
    instances = scan,
  }

  return scan
end

function EJProvider:GetSavedScan()
  if PuchiAssistsMidnightBiSDB and PuchiAssistsMidnightBiSDB.ejScan and PuchiAssistsMidnightBiSDB.ejScan.instances then
    return PuchiAssistsMidnightBiSDB.ejScan.instances
  end

  return nil
end

function EJProvider:SearchSavedScan(query)
  local scan = self:GetSavedScan()
  if not scan then
    return nil, "No hay EJ scan guardado. Usa /puchi ejscan primero."
  end

  local normalized = NormalizeName(query)
  if not normalized or normalized == "" then
    return {}, nil
  end

  local matches = {}
  for _, entry in ipairs(scan) do
    local entryName = NormalizeName(entry.name)
    if entryName and string.find(entryName, normalized, 1, true) then
      matches[#matches + 1] = entry
    end
  end

  return matches, nil
end

function EJProvider:FindMidnightCandidatesInSavedScan()
  local scan = self:GetSavedScan()
  if not scan then
    return nil, "No hay EJ scan guardado. Usa /puchi ejscan primero."
  end

  local results = {}
  local seen = {}

  for _, entry in ipairs(scan) do
    if entry.dungeonAreaMapID and MIDNIGHT_MAP_IDS[tonumber(entry.dungeonAreaMapID)] then
      local key = tostring(entry.journalInstanceID)
      if not seen[key] then
        seen[key] = true
        results[#results + 1] = entry
      end
    else
      local entryName = NormalizeName(entry.name)
      if entryName then
        for _, query in ipairs(MIDNIGHT_SCAN_QUERIES) do
          local normalizedQuery = NormalizeName(query)
          if normalizedQuery and string.find(entryName, normalizedQuery, 1, true) then
            local key = tostring(entry.journalInstanceID)
            if not seen[key] then
              seen[key] = true
              results[#results + 1] = entry
            end
            break
          end
        end
      end
    end
  end

  table.sort(results, function(a, b)
    return tostring(a.name or "") < tostring(b.name or "")
  end)

  return results, nil
end
