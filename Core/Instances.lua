local _, ns = ...

local Instances = {}
ns.Instances = Instances

local LOCALE = GetLocale and GetLocale() or "enUS"

local ENTRIES = {
  {
    id = "windrunner_spire",
    name = "Windrunner Spire",
    kind = "dungeon",
    journalInstanceID = 1299,
    difficultyID = 23,
    uiMapID = 2395,
    x = 0.35,
    y = 0.78,
    locale = { esES = "Aguja Brisaveloz", esMX = "Aguja Brisaveloz" },
  },
  {
    id = "voidscar_arena",
    name = "Voidscar Arena",
    kind = "dungeon",
    journalInstanceID = 1313,
    difficultyID = 23,
    uiMapID = 2444,
    x = 0.53,
    y = 0.33,
    locale = { esES = "Arena Rajavacio", esMX = "Arena Rajavacio" },
  },
  {
    id = "magisters_terrace",
    name = "Magisters' Terrace",
    kind = "dungeon",
    journalInstanceID = 1300,
    difficultyID = 23,
    uiMapID = 2424,
    x = 0.63,
    y = 0.15,
    locale = { esES = "Bancal del Magister", esMX = "Bancal del Magister" },
  },
  {
    id = "maisara_caverns",
    name = "Maisara Caverns",
    kind = "dungeon",
    journalInstanceID = 1315,
    difficultyID = 23,
    uiMapID = 2437,
    x = 0.43,
    y = 0.39,
    locale = { esES = "Cavernas de Maisara", esMX = "Cavernas de Maisara" },
  },
  {
    id = "murder_row",
    name = "Murder Row",
    kind = "dungeon",
    journalInstanceID = 1304,
    difficultyID = 23,
    uiMapID = 2393,
    x = 0.56,
    y = 0.60,
    locale = { esES = "El Frontal de la Muerte", esMX = "El Frontal de la Muerte" },
  },
  {
    id = "the_blinding_vale",
    name = "The Blinding Vale",
    kind = "dungeon",
    journalInstanceID = 1309,
    difficultyID = 23,
    uiMapID = 2413,
    x = 0.26,
    y = 0.77,
    locale = { esES = "El Valle Enceguecedor", esMX = "El Valle Enceguecedor" },
  },
  {
    id = "den_of_nalorakk",
    name = "Den of Nalorakk",
    kind = "dungeon",
    journalInstanceID = 1311,
    difficultyID = 23,
    uiMapID = 2437,
    x = 0.29,
    y = 0.83,
    locale = { esES = "Guarida de Nalorakk", esMX = "Guarida de Nalorakk" },
  },
  {
    id = "nexus_point_xenas",
    name = "Nexus-Point Xenas",
    kind = "dungeon",
    journalInstanceID = 1316,
    difficultyID = 23,
    uiMapID = 2405,
    x = 0.65,
    y = 0.61,
    locale = { esES = "Punto del Nexo Xenas", esMX = "Punto del Nexo Xenas" },
  },
  {
    id = "the_dreamrift",
    name = "The Dreamrift",
    kind = "raid",
    journalInstanceID = 1314,
    difficultyID = 16,
    uiMapID = 2413,
    x = 0.60,
    y = 0.62,
    locale = { esES = "La Onirifalla", esMX = "La Onirifalla" },
  },
  {
    id = "the_voidspire",
    name = "The Voidspire",
    kind = "raid",
    journalInstanceID = 1307,
    difficultyID = 16,
    uiMapID = 2405,
    x = 0.45,
    y = 0.64,
    locale = { esES = "La Aguja del Vacio", esMX = "La Aguja del Vacio" },
  },
}

local BY_ID = {}
for _, entry in ipairs(ENTRIES) do
  BY_ID[entry.id] = entry
end

function Instances:GetAll()
  return ENTRIES
end

function Instances:GetByID(entryId)
  return entryId and BY_ID[entryId] or nil
end

function Instances:GetLocalizedName(entryOrId)
  local entry = type(entryOrId) == "table" and entryOrId or self:GetByID(entryOrId)
  if not entry then
    return nil
  end

  local localized = entry.locale and entry.locale[LOCALE]
  if localized and localized ~= "" then
    return localized
  end

  return entry.name
end

function Instances:GetGrouped()
  local grouped = {
    dungeons = {},
    raids = {},
  }

  for _, entry in ipairs(ENTRIES) do
    if entry.kind == "raid" then
      grouped.raids[#grouped.raids + 1] = entry
    else
      grouped.dungeons[#grouped.dungeons + 1] = entry
    end
  end

  return grouped
end
