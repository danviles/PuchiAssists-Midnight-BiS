local _, ns = ...

local Tooltip = {}
ns.Tooltip = Tooltip

local function GetCurrentInstanceData()
  local inInstance = IsInInstance()
  if not inInstance then
    return nil, nil
  end

  local instanceName = GetInstanceInfo()
  if not instanceName or instanceName == "" then
    return nil, nil
  end

  return ns.BiSData:FindInstanceByName(instanceName)
end

local function GetTooltipUnitName(tooltip)
  local _, unit = tooltip:GetUnit()
  if not unit then
    return nil, nil
  end

  local name = UnitName(unit)
  if not name or name == "" then
    return nil, nil
  end

  return unit, name
end

local function GetNpcIdFromUnitGuid(unitGuid)
  if not unitGuid or unitGuid == "" then
    return nil
  end

  local segments = {}
  for part in string.gmatch(unitGuid, "[^-]+") do
    segments[#segments + 1] = part
  end

  if #segments < 6 then
    return nil
  end

  return tonumber(segments[6])
end

function Tooltip:Init()
  self.enabled = true

  GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
    self:HandleUnitTooltip(tooltip)
  end)
end

function Tooltip:AppendBossBiS(tooltip, bossId, instanceId)
  if not self.enabled or not tooltip then
    return
  end

  local classData = ns.ClassResolver and ns.ClassResolver:Get()
  if not classData or not classData.classToken then
    return
  end

  local items = ns.BiSData:GetItemsForBossByClass(instanceId, bossId, classData.classToken, classData.specName)
  if not items or #items == 0 then
    return
  end

  tooltip:AddLine(" ")
  tooltip:AddLine("PuchiAssists BiS", 0.4, 0.8, 1)

  for _, item in ipairs(items) do
    local itemName = ns.BiSData:GetItemDisplayName(item)
    local line = string.format("- %s (%s)", itemName, item.slot or "N/D")
    tooltip:AddLine(line, 1, 1, 1)
  end

  tooltip:Show()
end

function Tooltip:HandleUnitTooltip(tooltip)
  if not self.enabled or not tooltip then
    return
  end

  local unit, unitName = GetTooltipUnitName(tooltip)
  if not unit or not unitName then
    return
  end

  local unitGuid = UnitGUID(unit)
  if tooltip.__PuchiAssistsLastGuid and tooltip.__PuchiAssistsLastGuid == unitGuid then
    return
  end

  local instanceId = GetCurrentInstanceData()
  if not instanceId then
    return
  end

  local npcId = GetNpcIdFromUnitGuid(unitGuid)
  local bossId = ns.BiSData:FindBoss(instanceId, unitName, npcId)
  if not bossId then
    return
  end

  tooltip.__PuchiAssistsLastGuid = unitGuid
  self:AppendBossBiS(tooltip, bossId, instanceId)
end
