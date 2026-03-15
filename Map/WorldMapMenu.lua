local _, ns = ...

ns.MapHubMenu = ns.MapHubMenu or {}

local WORLD_MAP_BUTTON_ICON = [[Interface\Icons\INV_Misc_TreasureChest03]]

local function GetCanvasParent()
  if not WorldMapFrame then
    return nil
  end

  if WorldMapFrame.GetCanvasContainer then
    return WorldMapFrame:GetCanvasContainer()
  end

  return WorldMapFrame
end

local function BuildMenu()
  local grouped = ns.Instances and ns.Instances:GetGrouped() or { dungeons = {}, raids = {} }
  local menu = {
    { text = "PuchiAssists", isTitle = true, notCheckable = true },
    { text = DUNGEONS or "Mazmorras", isTitle = true, notCheckable = true },
  }

  local function addEntry(entry)
    local displayName = ns.Instances:GetLocalizedName(entry)
    menu[#menu + 1] = {
      text = displayName,
      notCheckable = true,
      func = function()
        ns.MapHubMenu:OpenEntry(entry)
      end,
    }
  end

  for _, entry in ipairs(grouped.dungeons) do
    addEntry(entry)
  end

  menu[#menu + 1] = { text = " ", disabled = true, notCheckable = true }
  menu[#menu + 1] = { text = RAIDS or "Bandas", isTitle = true, notCheckable = true }

  for _, entry in ipairs(grouped.raids) do
    addEntry(entry)
  end

  return menu
end

function ns.MapHubMenu:OpenEntry(entry)
  if not entry then
    return
  end

  if WorldMapFrame and WorldMapFrame.SetMapID and entry.uiMapID then
    WorldMapFrame:SetMapID(entry.uiMapID)
  end

  if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint and entry.uiMapID and entry.x and entry.y then
    local waypoint = UiMapPoint.CreateFromCoordinates(entry.uiMapID, entry.x, entry.y)
    if waypoint then
      C_Map.SetUserWaypoint(waypoint)
      if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
      end
    end
  end

  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  local lootData = ns.EJProvider and ns.EJProvider:CollectLootForAddonEntry(entry.id, {
    classID = classData.classId or 0,
    specID = classData.specId or 0,
    difficultyID = entry.difficultyID,
    strictDifficulty = true,
  })

  if lootData and ns.UI and ns.UI.InstanceWindow and ns.UI.InstanceWindow.OpenEncounterJournal then
    ns.UI.InstanceWindow:OpenEncounterJournal(lootData, ns.Instances:GetLocalizedName(entry))
  elseif ns.Print then
    ns.Print("No se pudo cargar loot para " .. tostring(ns.Instances:GetLocalizedName(entry) or entry.id))
  end
end

local function UpdateButtonAnchor(button)
  local parent = GetCanvasParent()
  if not button or not parent then
    return
  end

  button:ClearAllPoints()
  button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -68, -2)
end

local function CreateMapButton()
  if ns.MapHubMenu.button or not WorldMapFrame then
    return
  end

  local parent = GetCanvasParent() or WorldMapFrame
  local button = CreateFrame("Button", "PuchiAssistsMapButton", parent)
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

  local dropDown = CreateFrame("Frame", "PuchiAssistsMapDropDown", UIParent, "UIDropDownMenuTemplate")
  UIDropDownMenu_Initialize(dropDown, function(_, level)
    if level ~= 1 then
      return
    end

    for _, item in ipairs(BuildMenu()) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = item.text
      info.isTitle = item.isTitle
      info.disabled = item.disabled
      info.notCheckable = true
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
    GameTooltip:SetText("PuchiAssists", 1, 1, 1)
    GameTooltip:AddLine("Lista de mazmorras y bandas de Midnight", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  ns.MapHubMenu.button = button
  ns.MapHubMenu.dropDown = dropDown
end

function ns.MapHubMenu:GetDebugStatus()
  return {
    worldMapShown = WorldMapFrame and WorldMapFrame:IsShown() or false,
    worldMapMapID = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() or nil,
    buttonExists = self.button ~= nil,
    buttonShown = self.button and self.button:IsShown() or false,
  }
end

function ns.MapHubMenu:RefreshVisibility()
  if not self.button and WorldMapFrame then
    CreateMapButton()
  end

  if not self.button then
    return
  end

  UpdateButtonAnchor(self.button)

  if WorldMapFrame and WorldMapFrame:IsShown() then
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
    WorldMapFrame:HookScript("OnShow", function()
      ns.MapHubMenu:RefreshVisibility()
    end)
    WorldMapFrame:HookScript("OnHide", function()
      ns.MapHubMenu:RefreshVisibility()
    end)
  end
end
