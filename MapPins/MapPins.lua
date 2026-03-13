local _, ns = ...

local MapPins = {}
ns.MapPins = MapPins

local activeNodes = {}

local function PackCoord(x, y)
  local xCoord = math.floor(x * 10000 + 0.5)
  local yCoord = math.floor(y * 10000 + 0.5)
  return xCoord * 10000 + yCoord
end

local function IterNodes(t, prev)
  local coord, node = next(t, prev)
  if not coord then
    return nil
  end

  return coord, nil, node.icon, node.scale, node.alpha
end

local pluginHandler = {}

function pluginHandler:GetNodes2(uiMapID)
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

  local classInfo = ns.ClassResolver and ns.ClassResolver:Get() or {}
  local classToken = classInfo.classToken
  local specName = classInfo.specName

  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(node.instance.name or "Instancia", 1, 0.82, 0)
  GameTooltip:AddLine((node.instance.type == "raid" and "Raid" or "Dungeon") .. " | Clase: " .. (classToken or "N/D"), 0.8, 0.8, 0.8)

  local hasAnyBiS = false
  for bossId, bossData in pairs(node.instance.bosses or {}) do
    local items = ns.BiSData:GetItemsForBossByClass(node.instance.id, bossId, classToken, specName)
    if items and #items > 0 then
      hasAnyBiS = true
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(bossData.name or bossId, 0.4, 0.8, 1)

      for _, item in ipairs(items) do
        local itemName = ns.BiSData:GetItemDisplayName(item)
        local slot = item.slot or "N/D"
        local difficulty = item.difficulty or "N/D"
        GameTooltip:AddLine("- " .. itemName .. " [" .. slot .. "] {" .. difficulty .. "}", 1, 1, 1)
      end
    end
  end

  if not hasAnyBiS then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Sin BiS registrado para tu clase/spec.", 0.7, 0.7, 0.7)
  end

  GameTooltip:Show()
end

function pluginHandler:OnLeave()
  GameTooltip:Hide()
end

function pluginHandler:OnClick()
end

function pluginHandler:OnRelease()
end

local defaults = {
  icon_scale = 1.0,
  icon_alpha = 1.0,
}

function MapPins:BuildNodes()
  activeNodes = {}

  for instanceId, instance in pairs(ns.BiSData:GetInstances() or {}) do
    if instance.uiMapID and instance.x and instance.y then
      activeNodes[instance.uiMapID] = activeNodes[instance.uiMapID] or {}
      local coord = PackCoord(instance.x, instance.y)

      activeNodes[instance.uiMapID][coord] = {
        instanceId = instanceId,
        instance = instance,
        icon = instance.icon or "Interface\\MINIMAP\\TRACKING\\Dungeon",
        scale = defaults.icon_scale,
        alpha = defaults.icon_alpha,
      }
    end
  end
end

function MapPins:Init()
  self.enabled = true

  if not HandyNotes then
    if ns.Print then
      ns.Print("HandyNotes no esta cargado. Los pines de mapa no se mostraran.")
    end
    return
  end

  self:BuildNodes()
  HandyNotes:RegisterPluginDB("PuchiAssists_MidnightBiS", pluginHandler, defaults)
end

function MapPins:Refresh()
  if not self.enabled then
    return
  end

  if not HandyNotes then
    return
  end

  self:BuildNodes()
  HandyNotes:SendMessage("HandyNotes_NotifyUpdate", "PuchiAssists_MidnightBiS")
end
