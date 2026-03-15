local _, ns = ...

ns.UI = ns.UI or {}

local InstanceWindow = {}
ns.UI.InstanceWindow = InstanceWindow

local FALLBACK_ICON = 134400

local function GetDifficultyLabel(difficultyID)
  local labels = {
    [23] = "Mitica",
    [16] = "Mitica",
    [15] = "Heroica",
    [14] = "Normal",
    [8] = "Desafio",
    [2] = "Heroica",
    [1] = "Normal",
  }

  return labels[tonumber(difficultyID)] or tostring(difficultyID or "N/D")
end

local function ShowItemTooltip(row)
  if not row or not row.itemData then
    return
  end

  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  if row.itemLink then
    GameTooltip:SetHyperlink(row.itemLink)
  elseif row.itemData.itemID then
    GameTooltip:SetItemByID(row.itemData.itemID)
  else
    GameTooltip:SetText(tostring(row.itemData.name or "Item"), 1, 1, 1)
  end

  GameTooltip:AddLine("Slot: " .. tostring(row.itemData.slot or "N/D"), 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Dificultad: " .. tostring(row.itemData.difficulty or "N/D"), 0.8, 0.8, 0.8)
  if row.itemData.source then
    GameTooltip:AddLine("Fuente: " .. tostring(row.itemData.source), 0.7, 0.7, 0.7)
  end
  GameTooltip:Show()
end

local function ResolveItemVisual(item)
  if not item then
    return nil, FALLBACK_ICON, "Item"
  end

  if item.link then
    local _, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(item.link)
    return itemLink or item.link, icon or FALLBACK_ICON, tostring(item.name or item.link)
  end

  if item.itemID then
    local _, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(item.itemID)
    if itemLink then
      return itemLink, icon or FALLBACK_ICON, tostring(item.name or itemLink)
    end

    local iconById = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item.itemID)
    return nil, iconById or FALLBACK_ICON, tostring(item.name or ("Item " .. tostring(item.itemID)))
  end

  return nil, FALLBACK_ICON, tostring(item.name or "Item")
end

local function BuildGroups(lootData)
  local groups = {}
  local byEncounterID = {}

  for _, encounter in ipairs((lootData and lootData.encounters) or {}) do
    local group = {
      name = encounter.name or "Encounter",
      journalEncounterID = encounter.journalEncounterID,
      items = {},
    }
    groups[#groups + 1] = group
    if encounter.journalEncounterID then
      byEncounterID[tonumber(encounter.journalEncounterID)] = group
    end
  end

  local extras = {
    name = "Extras de la instancia",
    items = {},
  }

  for _, item in ipairs((lootData and lootData.instanceLoot) or {}) do
    local group = byEncounterID[tonumber(item.encounterID)]
    if group then
      group.items[#group.items + 1] = item
    else
      extras.items[#extras.items + 1] = item
    end
  end

  if #extras.items > 0 then
    groups[#groups + 1] = extras
  end

  return groups
end

local function AcquireRow(frame)
  frame.rows = frame.rows or {}
  frame.nextRowIndex = (frame.nextRowIndex or 0) + 1

  local row = frame.rows[frame.nextRowIndex]
  if row then
    row:Show()
    return row
  end

  row = CreateFrame("Button", nil, frame.content)
  row:SetSize(520, 18)
  row:EnableMouse(true)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(16, 16)
  row.icon:SetPoint("LEFT", 0, 0)
  row.icon:SetTexture(FALLBACK_ICON)

  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
  row.text:SetJustifyH("LEFT")
  row.text:SetWidth(480)

  row:SetScript("OnEnter", function(self)
    ShowItemTooltip(self)
  end)

  row:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  frame.rows[frame.nextRowIndex] = row
  return row
end

local function CreateWindow()
  if InstanceWindow.frame then
    return InstanceWindow.frame
  end

  local frame = CreateFrame("Frame", "PuchiAssistsWindow", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(580, 460)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 8, 0)
  frame.title:SetText("PuchiAssists")

  frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -36)
  frame.subtitle:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
  frame.subtitle:SetJustifyH("LEFT")

  frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -56)
  frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 14)

  frame.content = CreateFrame("Frame", nil, frame.scroll)
  frame.content:SetSize(520, 1)
  frame.scroll:SetScrollChild(frame.content)

  frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  frame:SetScript("OnEvent", function()
    if InstanceWindow.currentLootData and frame:IsShown() then
      InstanceWindow:OpenEncounterJournal(InstanceWindow.currentLootData, InstanceWindow.currentDisplayName)
    end
  end)

  InstanceWindow.frame = frame
  return frame
end

function InstanceWindow:OpenEncounterJournal(lootData, displayName)
  if not lootData then
    return
  end

  self.currentLootData = lootData
  self.currentDisplayName = displayName

  local frame = CreateWindow()
  frame:Show()

  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  frame.title:SetText("PuchiAssists - " .. tostring(displayName or lootData.instanceName or "Instancia"))
  frame.subtitle:SetText(string.format(
    "Clase: %s | Spec: %s | Dificultad: %s",
    tostring(classData.classToken or "N/D"),
    tostring(classData.specName or "N/D"),
    tostring(GetDifficultyLabel(lootData.difficultyID))
  ))

  frame.nextRowIndex = 0
  for _, row in ipairs(frame.rows or {}) do
    row:Hide()
    row.itemData = nil
    row.itemLink = nil
  end

  local y = -2
  local hasRows = false

  for _, group in ipairs(BuildGroups(lootData)) do
    if group.items and #group.items > 0 then
      local header = AcquireRow(frame)
      header:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, y)
      header:SetPoint("RIGHT", frame.content, "RIGHT", 0, 0)
      header.icon:Hide()
      header.text:ClearAllPoints()
      header.text:SetPoint("LEFT", header, "LEFT", 0, 0)
      header.text:SetText("|cff66ccff" .. tostring(group.name or "Encounter") .. "|r")
      header.itemData = nil
      header.itemLink = nil
      y = y - 20
      hasRows = true

      for _, item in ipairs(group.items) do
        local row = AcquireRow(frame)
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 16, y)
        row:SetPoint("RIGHT", frame.content, "RIGHT", -12, 0)

        local itemLink, itemIcon, itemName = ResolveItemVisual(item)
        local suffix = ""
        if item.displayAsExtremelyRare then
          suffix = " {Extremely Rare}"
        elseif item.displayAsVeryRare then
          suffix = " {Very Rare}"
        end

        row.icon:Show()
        row.icon:SetTexture(itemIcon or FALLBACK_ICON)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetText(string.format("- %s [%s]%s", tostring(itemName), tostring(item.slot or "N/D"), suffix))
        row.itemData = item
        row.itemLink = itemLink or item.link
        y = y - 18
      end

      y = y - 8
    end
  end

  if not hasRows then
    local empty = AcquireRow(frame)
    empty:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, y)
    empty:SetPoint("RIGHT", frame.content, "RIGHT", 0, 0)
    empty.icon:Hide()
    empty.text:ClearAllPoints()
    empty.text:SetPoint("LEFT", empty, "LEFT", 0, 0)
    empty.text:SetText("|cffff6666No se encontro loot en Encounter Journal para esta instancia y dificultad.|r")
    empty.itemData = nil
    empty.itemLink = nil
    y = y - 18
  end

  frame.content:SetHeight(math.max(20, -y + 20))
end
