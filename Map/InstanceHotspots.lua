local _, ns = ...

local InstanceHotspots = {}
ns.InstanceHotspots = InstanceHotspots

local ACTIVE_MAPS = {
  [2393] = true,
  [2395] = true,
  [2405] = true,
  [2413] = true,
  [2424] = true,
  [2437] = true,
  [2444] = true,
  [2537] = true,
}

local HOTSPOTS = {
  { id = "murder_row",        name = "El Frontal de la Muerte",  mapID = 2393, x = 0.56, y = 0.60, kind = "dungeon" },
  { id = "windrunner_spire",  name = "Aguja Brisaveloz",         mapID = 2395, x = 0.35, y = 0.78, kind = "dungeon" },
  { id = "maisara_caverns",   name = "Cavernas de Maisara",      mapID = 2437, x = 0.43, y = 0.39, kind = "dungeon" },
  { id = "den_of_nalorakk",   name = "Guarida de Nalorakk",      mapID = 2437, x = 0.29, y = 0.83, kind = "dungeon" },
  { id = "voidscar_arena",    name = "Arena Rajavacio",          mapID = 2444, x = 0.53, y = 0.33, kind = "dungeon" },
  { id = "nexus_point_xenas", name = "Punto del Nexo Xenas",     mapID = 2405, x = 0.65, y = 0.61, kind = "dungeon" },
  { id = "the_voidspire",     name = "La Aguja del Vacio",       mapID = 2405, x = 0.45, y = 0.64, kind = "raid" },
  { id = "the_dreamrift",     name = "La Onirifalla",            mapID = 2413, x = 0.60, y = 0.62, kind = "raid" },
  { id = "the_blinding_vale", name = "El Valle Enceguecedor",    mapID = 2413, x = 0.26, y = 0.77, kind = "dungeon" },
  { id = "magisters_terrace", name = "Bancal del Magister",      mapID = 2424, x = 0.63, y = 0.15, kind = "dungeon" },
}

local function GetCanvas()
  if not WorldMapFrame then
    return nil
  end

  if WorldMapFrame.GetCanvasContainer then
    return WorldMapFrame:GetCanvasContainer()
  end

  return WorldMapFrame.ScrollContainer or WorldMapFrame
end

local function GetCurrentMapID()
  if WorldMapFrame and WorldMapFrame.GetMapID then
    return WorldMapFrame:GetMapID()
  end
  return nil
end

local function CreateButton(parent, entry)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(34, 34)
  button.entry = entry
  button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp")
  button:SetFrameStrata("TOOLTIP")
  button:SetFrameLevel(5000)
  button:SetClampedToScreen(true)

  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(1, 0, 0, 0.20)
  button.bg = bg

  local tex = button:CreateTexture(nil, "OVERLAY")
  tex:SetAllPoints()
  tex:SetTexture("Interface\\Minimap\\POIIcons")
  tex:SetTexCoord(0.0, 0.125, 0.0, 0.125)
  tex:SetAlpha(1.0)
  button.texture = tex

  local hl = button:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  hl:SetBlendMode("ADD")

  button:SetScript("OnEnter", function(self)
    if ns.MapPoiTooltip and ns.MapPoiTooltip.ShowCentered then
      ns.MapPoiTooltip:ShowCentered(self.entry.id)
    end
  end)

  button:SetScript("OnLeave", function()
    if ns.MapPoiTooltip then
      ns.MapPoiTooltip:Hide()
    end
  end)

  button:SetScript("OnClick", function(self)
    if ns.MapHubMenu and ns.MapHubMenu.NavigateToEntry then
      ns.MapHubMenu:NavigateToEntry(self.entry, self.entry.name)
    end
  end)

  return button
end

function InstanceHotspots:Refresh()
  if not self.initialized or not self.canvas then
    return
  end

  local mapID = GetCurrentMapID()
  local shouldShow = WorldMapFrame and WorldMapFrame:IsShown() and ACTIVE_MAPS[mapID]

  for _, button in ipairs(self.buttons) do
    local entry = button.entry
    if shouldShow and entry.mapID == mapID then
      button:ClearAllPoints()
      button:SetPoint("CENTER", self.canvas, "TOPLEFT", entry.x * self.canvas:GetWidth(), -entry.y * self.canvas:GetHeight())
      button:Show()
    else
      button:Hide()
    end
  end
end

function InstanceHotspots:Init()
  if self.initialized and self.canvas then
    return
  end

  self.canvas = GetCanvas()

  if not self.canvas then
    return
  end

  self.initialized = true

  if self.buttons then
    self:Refresh()
    return
  end

  self.buttons = {}

  for _, entry in ipairs(HOTSPOTS) do
    self.buttons[#self.buttons + 1] = CreateButton(self.canvas, entry)
  end

  self.canvas:HookScript("OnSizeChanged", function()
    self:Refresh()
  end)

  if WorldMapFrame then
    WorldMapFrame:HookScript("OnShow", function()
      self:Refresh()
    end)
    WorldMapFrame:HookScript("OnHide", function()
      if ns.MapPoiTooltip then
        ns.MapPoiTooltip:Hide()
      end
    end)
  end

  self.ticker = C_Timer.NewTicker(0.20, function()
    self:Refresh()
  end)

  self:Refresh()
end

function InstanceHotspots:OnWorldMapLoaded()
  self.initialized = false
  self.canvas = nil
  self:Init()
  self:Refresh()
end
