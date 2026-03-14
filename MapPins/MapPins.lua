local _, ns = ...

local MapPins = {}
ns.MapPins = MapPins

local activeNodes = {}
local DEFAULT_PIN_ICON = {
  icon = 134400,
}
local DEFAULT_RAID_PIN_ICON = {
  icon = 134400,
  r = 1,
  g = 0.82,
  b = 0.2,
  a = 1,
}
local DEFAULT_DUNGEON_PIN_ICON = {
  icon = 134400,
  r = 0.35,
  g = 0.8,
  b = 1,
  a = 1,
}

local function PackCoord(x, y)
  local xCoord = math.floor(x * 10000 + 0.5)
  local yCoord = math.floor(y * 10000 + 0.5)
  return xCoord * 10000 + yCoord
end

local function NormalizeCoord(value)
  if not value then
    return nil
  end

  local numberValue = tonumber(value)
  if not numberValue then
    return nil
  end

  if numberValue > 1 then
    numberValue = numberValue / 100
  end

  if numberValue < 0 then
    return 0
  end

  if numberValue > 1 then
    return 1
  end

  return numberValue
end

local function IterNodes(t, prev)
  local coord, node = next(t, prev)
  if not coord then
    return nil
  end

  return coord, nil, node.icon, node.scale, node.alpha
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

local pluginHandler = {}

function pluginHandler:GetNodes2(uiMapID)
  if not ns.MapPins or not ns.MapPins.enabled then
    return IterNodes, {}, nil
  end

  local nodes = activeNodes[uiMapID]
  if not nodes then
    return IterNodes, {}, nil
  end

  return IterNodes, nodes, nil
end

function pluginHandler:OnEnter(uiMapID, coord)
  local mapNodes = activeNodes[uiMapID]
  if not mapNodes then
    return
  end

  local node = mapNodes[coord]
  if not node or not node.instance then
    return
  end

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(node.instance.name or "Instancia", 1, 0.82, 0)
  GameTooltip:AddLine((node.instance.type == "raid" and "Raid" or "Dungeon"), 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Haz click izquierdo para ver BiS.", 0.4, 0.8, 1)

  GameTooltip:Show()
end

function pluginHandler:OnLeave()
  GameTooltip:Hide()
end

function pluginHandler:OnClick(button, down, uiMapID, coord)
  if down or button ~= "LeftButton" then
    return
  end

  local mapNodes = activeNodes[uiMapID]
  if not mapNodes then
    return
  end

  local node = mapNodes[coord]
  if not node or not node.instance then
    return
  end

  if ns.UI and ns.UI.InstanceWindow and ns.UI.InstanceWindow.Open then
    ns.UI.InstanceWindow:Open(node.instance)
  end
end

function pluginHandler:OnRelease()
end

local defaults = {
  icon_scale = 1.5,
  icon_alpha = 1.0,
}
local PLUGIN_NAME = "PuchiAssists_MidnightBiS"

local function GetInstanceIcon(instance)
  if instance and instance.type == "raid" then
    return DEFAULT_RAID_PIN_ICON
  end

  return DEFAULT_DUNGEON_PIN_ICON
end

function MapPins:AddDebugCurrentMapNode()
  if not ns.config or not ns.config.debugCurrentMapPin then
    return
  end

  local mapID = C_Map.GetBestMapForUnit("player")
  if not mapID then
    return
  end

  local x = 0.5
  local y = 0.5
  local playerPos = C_Map.GetPlayerMapPosition(mapID, "player")
  if playerPos then
    x = playerPos.x or x
    y = playerPos.y or y
  end

  activeNodes[mapID] = activeNodes[mapID] or {}
  local coord = PackCoord(x, y)

  activeNodes[mapID][coord] = {
    instanceId = "debug_current_map",
    instance = {
      id = "debug_current_map",
      name = "PuchiAssists Debug Pin",
      type = "dungeon",
      bosses = {},
    },
    icon = DEFAULT_PIN_ICON,
    scale = 1.4,
    alpha = defaults.icon_alpha,
  }
end

function MapPins:EnsureHandyNotesPluginEnabled()
  if not HandyNotes or not HandyNotes.db or not HandyNotes.db.profile then
    return false
  end

  local profile = HandyNotes.db.profile
  profile.enabledPlugins = profile.enabledPlugins or {}

  if profile.enabledPlugins[PLUGIN_NAME] then
    return false
  end

  profile.enabledPlugins[PLUGIN_NAME] = true
  return true
end

function MapPins:BuildNodes()
  activeNodes = {}

  for instanceId, instance in pairs(ns.BiSData:GetInstances() or {}) do
    local mapID = instance.displayMapID or instance.uiMapID
    local normalizedX = NormalizeCoord(instance.x)
    local normalizedY = NormalizeCoord(instance.y)

    if mapID and normalizedX and normalizedY then
      activeNodes[mapID] = activeNodes[mapID] or {}
      local coord = PackCoord(normalizedX, normalizedY)

      activeNodes[mapID][coord] = {
        instanceId = instanceId,
        instance = instance,
        icon = GetInstanceIcon(instance),
        scale = 1.4,
        alpha = defaults.icon_alpha,
      }
    end
  end

  self:AddDebugCurrentMapNode()
end

function MapPins:Init()
  self.initialized = true
  self.enabled = true

  if not HandyNotes then
    return
  end

  self:BuildNodes()
  HandyNotes:RegisterPluginDB(PLUGIN_NAME, pluginHandler, defaults)
  self:EnsureHandyNotesPluginEnabled()
  HandyNotes:SendMessage("HandyNotes_NotifyUpdate", PLUGIN_NAME)
end

function MapPins:SetEnabled(enabled)
  self.enabled = not not enabled
  self:Refresh()
end

function MapPins:SetDebugCurrentMapPin(enabled)
  if not ns.config then
    return
  end

  ns.config.debugCurrentMapPin = not not enabled
  self:Refresh()
end

function MapPins:GetStatsForMap(uiMapID)
  local stats = {
    enabled = self.enabled,
    hasHandyNotes = not not HandyNotes,
    mapID = uiMapID,
    totalMaps = 0,
    nodesOnMap = 0,
  }

  for _, nodes in pairs(activeNodes) do
    stats.totalMaps = stats.totalMaps + 1
  end

  if uiMapID and activeNodes[uiMapID] then
    for _ in pairs(activeNodes[uiMapID]) do
      stats.nodesOnMap = stats.nodesOnMap + 1
    end
  end

  return stats
end

function MapPins:Refresh()
  if not HandyNotes then
    return
  end

  self:EnsureHandyNotesPluginEnabled()

  if self.enabled then
    self:BuildNodes()
  else
    activeNodes = {}
  end

  HandyNotes:SendMessage("HandyNotes_NotifyUpdate", PLUGIN_NAME)
end
