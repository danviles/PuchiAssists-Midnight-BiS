local _, ns = ...

ns.BiSData = {
  instances = {},
}

local function NormalizeName(value)
  if not value or value == "" then
    return nil
  end

  return tostring(value):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

function ns.BiSData:SetInstances(instances)
  self.instances = instances or {}
end

function ns.BiSData:GetInstances()
  return self.instances
end

function ns.BiSData:GetInstance(instanceId)
  if not instanceId then
    return nil
  end

  return self.instances[instanceId]
end

function ns.BiSData:FindInstanceByName(instanceName)
  local normalizedName = NormalizeName(instanceName)
  if not normalizedName then
    return nil, nil
  end

  for instanceId, instanceData in pairs(self.instances) do
    if NormalizeName(instanceData.name) == normalizedName then
      return instanceId, instanceData
    end
  end

  return nil, nil
end

function ns.BiSData:FindBossByName(instanceId, bossName)
  local normalizedName = NormalizeName(bossName)
  if not normalizedName then
    return nil, nil
  end

  local instance = self.instances[instanceId]
  if not instance or not instance.bosses then
    return nil, nil
  end

  for bossId, bossData in pairs(instance.bosses) do
    if NormalizeName(bossData.name) == normalizedName then
      return bossId, bossData
    end
  end

  return nil, nil
end

function ns.BiSData:FindBossByNpcId(instanceId, npcId)
  if not npcId then
    return nil, nil
  end

  local instance = self.instances[instanceId]
  if not instance or not instance.bosses then
    return nil, nil
  end

  for bossId, bossData in pairs(instance.bosses) do
    if tonumber(bossData.npcId) == tonumber(npcId) then
      return bossId, bossData
    end
  end

  return nil, nil
end

function ns.BiSData:FindBoss(instanceId, bossName, npcId)
  local bossId, bossData = self:FindBossByNpcId(instanceId, npcId)
  if bossId then
    return bossId, bossData
  end

  return self:FindBossByName(instanceId, bossName)
end

function ns.BiSData:GetItemsForBossByClass(instanceId, bossId, classToken, specName)
  local instance = self.instances[instanceId]
  if not instance or not instance.bosses then
    return nil
  end

  local boss = instance.bosses[bossId]
  if not boss or not boss.loot then
    return nil
  end

  local classData = boss.loot[classToken]
  if not classData then
    return nil
  end

  if specName and classData[specName] then
    return classData[specName]
  end

  return classData.ALL
end

function ns.BiSData:GetItemDisplayName(item)
  if not item then
    return "N/D"
  end

  if item.name and item.name ~= "" then
    return item.name
  end

  if item.itemId then
    local itemName = C_Item.GetItemNameByID(item.itemId)
    if itemName then
      return itemName
    end

    return "item:" .. tostring(item.itemId)
  end

  return "N/D"
end
