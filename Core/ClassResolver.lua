local _, ns = ...

local ClassResolver = {}
ns.ClassResolver = ClassResolver

local cache = {
  classToken = nil,
  classDisplayName = nil,
  classFileName = nil,
  specId = nil,
  specName = nil,
}

function ClassResolver:Refresh()
  local classDisplayName, classFileName, classId = UnitClass("player")
  cache.classDisplayName = classDisplayName
  cache.classFileName = classFileName
  cache.classToken = classFileName
  cache.classId = classId

  local specIndex = GetSpecialization()
  if specIndex then
    local specId, specName = GetSpecializationInfo(specIndex)
    cache.specId = specId
    cache.specName = specName
  else
    cache.specId = nil
    cache.specName = nil
  end
end

function ClassResolver:Init()
  self:Refresh()
end

function ClassResolver:Get()
  return cache
end
