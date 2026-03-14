local _, ns = ...

ns.UI = ns.UI or {}

local InstanceWindow = {}
ns.UI.InstanceWindow = InstanceWindow

local FALLBACK_ICON = 134400

local function ShowItemTooltip(row)
  if not row or not row.itemData then
    return
  end

  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  if row.itemLink then
    GameTooltip:SetHyperlink(row.itemLink)
  elseif row.itemData.itemId then
    GameTooltip:SetItemByID(row.itemData.itemId)
  else
    GameTooltip:SetText(row.itemData.name or "Item", 1, 1, 1)
  end

  GameTooltip:AddLine("Slot: " .. tostring(row.itemData.slot or "N/D"), 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Dificultad: " .. tostring(row.itemData.difficulty or "N/D"), 0.8, 0.8, 0.8)
  if row.itemData.source then
    GameTooltip:AddLine("Fuente: " .. tostring(row.itemData.source), 0.7, 0.7, 0.7)
  end

  if row.itemLink and IsShiftKeyDown() then
    GameTooltip_ShowCompareItem(GameTooltip)
    row.compareShown = true
  else
    GameTooltip_HideShoppingTooltips(GameTooltip)
    row.compareShown = false
  end

  GameTooltip:Show()
end

local function GetOrderedBossList(instance)
  local ordered = {}
  for bossId, bossData in pairs((instance and instance.bosses) or {}) do
    ordered[#ordered + 1] = {
      bossId = bossId,
      bossData = bossData,
      order = bossData.bossesOrder or 999,
    }
  end

  table.sort(ordered, function(a, b)
    if a.order == b.order then
      return tostring(a.bossData.name or a.bossId) < tostring(b.bossData.name or b.bossId)
    end

    return a.order < b.order
  end)

  return ordered
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
  row:SetSize(500, 18)
  row:EnableMouse(true)
  row:SetMouseMotionEnabled(true)
  row:SetHitRectInsets(-4, -4, -2, -2)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(16, 16)
  row.icon:SetPoint("LEFT", 0, 0)
  row.icon:SetTexture(FALLBACK_ICON)

  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
  row.text:SetJustifyH("LEFT")

  row:SetScript("OnEnter", function(self)
    ShowItemTooltip(self)
  end)

  row:SetScript("OnLeave", function()
    GameTooltip_HideShoppingTooltips(GameTooltip)
    GameTooltip:Hide()
  end)

  row:SetScript("OnUpdate", function(self)
    if not self.itemData then
      return
    end

    if not GameTooltip:IsOwned(self) and MouseIsOver(self) then
      ShowItemTooltip(self)
      return
    end

    if not self.itemLink or not GameTooltip:IsOwned(self) then
      return
    end

    local shouldShowCompare = IsShiftKeyDown()
    if shouldShowCompare and not self.compareShown then
      GameTooltip_ShowCompareItem(GameTooltip)
      self.compareShown = true
    elseif not shouldShowCompare and self.compareShown then
      GameTooltip_HideShoppingTooltips(GameTooltip)
      self.compareShown = false
    end
  end)

  frame.rows[frame.nextRowIndex] = row
  return row
end

local function ResolveItemVisual(item)
  if not item then
    return nil, FALLBACK_ICON, "N/D"
  end

  if item.link and item.link ~= "" then
    local _, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(item.link)
    return item.link, icon or FALLBACK_ICON, item.name or ns.BiSData:GetItemDisplayName(item)
  end

  if item.itemId then
    local _, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(item.itemId)
    if itemLink then
      return itemLink, icon or FALLBACK_ICON, ns.BiSData:GetItemDisplayName(item)
    end

    local iconById = C_Item.GetItemIconByID(item.itemId)
    return nil, iconById or FALLBACK_ICON, ns.BiSData:GetItemDisplayName(item)
  end

  if item.name and item.name ~= "" then
    local _, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(item.name)
    return itemLink, icon or FALLBACK_ICON, item.name
  end

  return nil, FALLBACK_ICON, ns.BiSData:GetItemDisplayName(item)
end

local function BuildEncounterLootGroups(lootData)
  local groups = {}
  local extras = {
    name = "Extras de la instancia",
    items = {},
  }

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

  for _, item in ipairs((lootData and lootData.instanceLoot) or {}) do
    local encounterID = tonumber(item.encounterID)
    local group = encounterID and byEncounterID[encounterID] or nil
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

local function CreateWindow()
  if InstanceWindow.frame then
    return InstanceWindow.frame
  end

  local frame = CreateFrame("Frame", "PuchiAssistsBiSWindow", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(560, 440)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 8, 0)
  frame.title:SetText("PuchiAssists BiS")

  frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -34)
  frame.subtitle:SetText("")

  frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -54)
  frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 12)

  frame.content = CreateFrame("Frame", nil, frame.scroll)
  frame.content:SetSize(500, 1)
  frame.scroll:SetScrollChild(frame.content)

  frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  frame:SetScript("OnEvent", function(_, event)
    if event == "GET_ITEM_INFO_RECEIVED" and InstanceWindow.currentInstance and frame:IsShown() then
      InstanceWindow:Open(InstanceWindow.currentInstance)
    end
  end)

  InstanceWindow.frame = frame
  return frame
end

function InstanceWindow:Open(instance)
  if not instance then
    return
  end

  self.currentInstance = instance

  local frame = CreateWindow()
  frame:Show()

  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  local classToken = classData.classToken
  local specName = classData.specName
  local specId = classData.specId

  frame.title:SetText("PuchiAssists BiS - " .. tostring(instance.name or "Instancia"))
  frame.subtitle:SetText("Clase: " .. tostring(classToken or "N/D") .. " | Spec: " .. tostring(specName or "N/D"))

  frame.nextRowIndex = 0
  local contentWidth = math.max(420, frame.scroll:GetWidth() - 26)
  frame.content:SetWidth(contentWidth)

  for _, row in ipairs(frame.rows or {}) do
    row:Hide()
    row.itemData = nil
  end

  local y = -2

  for _, bossEntry in ipairs(GetOrderedBossList(instance)) do
    local bossId = bossEntry.bossId
    local bossData = bossEntry.bossData

    local header = AcquireRow(frame)
    header:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, y)
    header:SetPoint("RIGHT", frame.content, "RIGHT", 0, 0)
    header.icon:Hide()
    header.text:ClearAllPoints()
    header.text:SetPoint("LEFT", header, "LEFT", 0, 0)
    header.text:SetText("|cff66ccff" .. tostring(bossData.name or bossId) .. "|r")
    header.itemData = nil
    header.itemLink = nil
    header.compareShown = false
    y = y - 20

    local items = ns.BiSData:GetItemsForBossByClass(instance.id, bossId, classToken, specName, specId)
    if items and #items > 0 then
      for _, item in ipairs(items) do
        local row = AcquireRow(frame)
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 12, y)
        row:SetPoint("RIGHT", frame.content, "RIGHT", -12, 0)

        local itemLink, itemIcon, itemName = ResolveItemVisual(item)
        local slot = tostring(item.slot or "N/D")
        local difficulty = tostring(item.difficulty or "N/D")
        row.icon:Show()
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetText("- " .. itemName .. " [" .. slot .. "] {" .. difficulty .. "}")
        row.icon:SetTexture(itemIcon or FALLBACK_ICON)
        row.itemData = item
        row.itemLink = itemLink
        row.compareShown = false

        y = y - 18
      end
    else
      local row = AcquireRow(frame)
      row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 12, y)
      row:SetPoint("RIGHT", frame.content, "RIGHT", -12, 0)
      row.icon:Hide()
      row.text:ClearAllPoints()
      row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
      row.text:SetText("|cffbfbfbf- BiS pendiente para tu clase/spec|r")
      row.itemData = nil
      row.itemLink = nil
      row.compareShown = false
      y = y - 18
    end

    y = y - 8
  end

  frame.content:SetHeight(math.max(20, -y + 20))
end

function InstanceWindow:OpenEncounterJournal(lootData, displayName)
  if not lootData then
    return
  end

  local frame = CreateWindow()
  frame:Show()

  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  frame.title:SetText("PuchiAssists EJ - " .. tostring(displayName or lootData.instanceName or "Instancia"))
  frame.subtitle:SetText("Clase: " .. tostring(classData.classToken or "N/D") .. " | Spec: " .. tostring(classData.specName or "N/D") .. " | Fuente: Encounter Journal")

  frame.nextRowIndex = 0
  local contentWidth = math.max(420, frame.scroll:GetWidth() - 26)
  frame.content:SetWidth(contentWidth)

  for _, row in ipairs(frame.rows or {}) do
    row:Hide()
    row.itemData = nil
  end

  local y = -2

  if lootData.instanceLoot and #lootData.instanceLoot > 0 then
    local header = AcquireRow(frame)
    header:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, y)
    header:SetPoint("RIGHT", frame.content, "RIGHT", 0, 0)
    header.icon:Hide()
    header.text:ClearAllPoints()
    header.text:SetPoint("LEFT", header, "LEFT", 0, 0)
    header.text:SetText("|cff66ccffLoot filtrado de la instancia|r")
    header.itemData = nil
    header.itemLink = nil
    header.compareShown = false
    y = y - 20

    for _, group in ipairs(BuildEncounterLootGroups(lootData)) do
      if group.items and #group.items > 0 then
        local groupHeader = AcquireRow(frame)
        groupHeader:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 12, y)
        groupHeader:SetPoint("RIGHT", frame.content, "RIGHT", -12, 0)
        groupHeader.icon:Hide()
        groupHeader.text:ClearAllPoints()
        groupHeader.text:SetPoint("LEFT", groupHeader, "LEFT", 0, 0)
        groupHeader.text:SetText("|cff66ccff" .. tostring(group.name or "Encounter") .. "|r")
        groupHeader.itemData = nil
        groupHeader.itemLink = nil
        groupHeader.compareShown = false
        y = y - 18

        for _, item in ipairs(group.items) do
          local row = AcquireRow(frame)
          row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 24, y)
          row:SetPoint("RIGHT", frame.content, "RIGHT", -12, 0)

          local itemLink, itemIcon, itemName = ResolveItemVisual(item)
          local slot = tostring(item.slot or "N/D")
          local suffix = ""
          if item.displayAsExtremelyRare then
            suffix = " {Extremely Rare}"
          elseif item.displayAsVeryRare then
            suffix = " {Very Rare}"
          end

          row.icon:Show()
          row.text:ClearAllPoints()
          row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
          row.text:SetText("- " .. itemName .. " [" .. slot .. "]" .. suffix)
          row.icon:SetTexture(itemIcon or FALLBACK_ICON)
          row.itemData = item
          row.itemLink = itemLink or item.link
          row.compareShown = false

          y = y - 18
        end

        y = y - 6
      end
    end

    y = y - 10
  end

  if (not lootData.instanceLoot or #lootData.instanceLoot == 0) and (not lootData.encounters or #lootData.encounters == 0) then
    local row = AcquireRow(frame)
    row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, y)
    row:SetPoint("RIGHT", frame.content, "RIGHT", 0, 0)
    row.icon:Hide()
    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.text:SetText("|cffff6666- Encounter Journal sin encounters para esta instancia/dificultad en esta build|r")
    row.itemData = nil
    row.itemLink = nil
    row.compareShown = false
    y = y - 18
  end

  frame.content:SetHeight(math.max(20, -y + 20))
end
