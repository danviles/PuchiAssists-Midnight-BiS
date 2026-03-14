local _, ns = ...

-- ============================================================
--  MapPoiTooltip
--  Ventana secundaria junto al tooltip de remolino del mapa.
--  Lee los items directamente del Encounter Journal de Blizzard,
--  filtrados por clase, especializacion y dificultad mitica.
-- ============================================================

local MapPoiTooltip = {}
ns.MapPoiTooltip = MapPoiTooltip

-- Colores
local COLOR_HEADER    = { 0.4,  0.82, 1.0  }  -- Azul claro (titulo)
local COLOR_SUBTITLE  = { 0.75, 0.75, 0.75 }  -- Gris
local COLOR_BOSS      = { 1.0,  0.85, 0.3  }  -- Amarillo (jefe)
local COLOR_ITEM      = { 1.0,  1.0,  1.0  }  -- Blanco (item)
local COLOR_SLOT      = { 0.6,  0.6,  0.6  }  -- Gris oscuro (slot)
local COLOR_EMPTY     = { 0.55, 0.55, 0.55 }  -- Gris (sin datos)
local COLOR_SEARCHING = { 0.8,  0.8,  0.4  }  -- Amarillo tenue (buscando)

local FRAME_WIDTH   = 310
local LINE_PADDING  = 3    -- Espacio vertical entre lineas (px)
local FRAME_PAD_X   = 10   -- Padding horizontal interno
local FRAME_PAD_Y   = 10   -- Padding vertical interno
local FONT_TITLE    = 13
local FONT_BODY     = 11
local FONT_SMALL    = 10

-- Cache loot: clave = "instanceId:classID:specID:difficultyID"
local lootCache = {}

-- Sentinela para indicar que el EJ no encontro la instancia
local EJ_NOT_FOUND = "__NOT_FOUND__"

-- Frame principal (se crea una sola vez lazy)
local _frame = nil

-- ----------------------------------------------------------------
--  Creacion del frame
-- ----------------------------------------------------------------

local BACKDROP = {
  bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile     = true, tileSize = 16, edgeSize = 16,
  insets   = { left = 4, right = 4, top = 4, bottom = 4 },
}

local function BuildFrame()
  local frame = CreateFrame("Frame", "PuchiAssistsMapPoiTooltipFrame", UIParent, "BackdropTemplate")
  frame:SetBackdrop(BACKDROP)
  frame:SetBackdropColor(0.04, 0.04, 0.09, 0.97)
  frame:SetBackdropBorderColor(0.75, 0.65, 0.25, 1.0)
  frame:SetFrameStrata("TOOLTIP")
  frame:SetFrameLevel(210)
  frame:SetWidth(FRAME_WIDTH)
  frame:Hide()

  -- Pool de FontStrings reutilizables
  frame._pool = {}
  frame._poolCount = 0
  frame._usedCount = 0

  return frame
end

local function GetFrame()
  if not _frame then
    _frame = BuildFrame()
  end
  return _frame
end

-- ----------------------------------------------------------------
--  Pool de FontStrings
-- ----------------------------------------------------------------

local function AcquireLine(frame)
  frame._usedCount = (frame._usedCount or 0) + 1

  if frame._usedCount <= frame._poolCount then
    local line = frame._pool[frame._usedCount]
    line:Show()
    return line
  end

  -- Crear nueva FontString
  local line = frame:CreateFontString(nil, "OVERLAY")
  line:SetFont("Fonts\\ARIALN.TTF", FONT_BODY)
  line:SetJustifyH("LEFT")
  line:SetWidth(FRAME_WIDTH - FRAME_PAD_X * 2)
  line:SetWordWrap(true)

  frame._poolCount = frame._poolCount + 1
  frame._pool[frame._poolCount] = line
  return line
end

local function ReleaseAllLines(frame)
  for i = 1, (frame._poolCount or 0) do
    frame._pool[i]:Hide()
    frame._pool[i]:ClearAllPoints()
  end
  frame._usedCount = 0
end

-- ----------------------------------------------------------------
--  Construccion del contenido
-- ----------------------------------------------------------------

local function AddLine(frame, prevLine, text, r, g, b, fontSize, extraOffset)
  local line = AcquireLine(frame)
  line:SetFont("Fonts\\ARIALN.TTF", fontSize or FONT_BODY)
  line:SetTextColor(r, g, b, 1)
  line:SetText(text)

  local yOff = -(LINE_PADDING + (extraOffset or 0))
  if prevLine == nil then
    -- Primera linea
    line:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD_X, -FRAME_PAD_Y)
  else
    line:SetPoint("TOPLEFT", prevLine, "BOTTOMLEFT", 0, yOff)
  end

  return line
end

local function BuildContent(frame, lootData, instanceName)
  ReleaseAllLines(frame)
  frame:SetWidth(FRAME_WIDTH)

  local prev = nil

  -- === Titulo ===
  prev = AddLine(frame, nil,  instanceName, COLOR_HEADER[1], COLOR_HEADER[2], COLOR_HEADER[3], FONT_TITLE)

  -- Subtitulo clase/spec
  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  local sub = string.format(
    "BiS Mitica  |  %s - %s",
    classData.classDisplayName or "?",
    classData.specName or "?"
  )
  prev = AddLine(frame, prev, sub, COLOR_SUBTITLE[1], COLOR_SUBTITLE[2], COLOR_SUBTITLE[3], FONT_SMALL)

  -- Separador visual
  prev = AddLine(frame, prev, "--------------------------------------------", 0.35, 0.35, 0.35, FONT_SMALL, 2)

  -- === Contenido de loot ===
  if lootData == EJ_NOT_FOUND then
    prev = AddLine(frame, prev, "No encontrado en la Guia de Aventura.", COLOR_EMPTY[1], COLOR_EMPTY[2], COLOR_EMPTY[3], FONT_BODY, 2)
  elseif not lootData or not lootData.encounters then
    prev = AddLine(frame, prev, "Buscando en la Guia de Aventura...", COLOR_SEARCHING[1], COLOR_SEARCHING[2], COLOR_SEARCHING[3], FONT_BODY, 2)
  else
    local totalItems = 0
    for _, encounter in ipairs(lootData.encounters) do
      if encounter.loot and #encounter.loot > 0 then
        -- Nombre del jefe
        prev = AddLine(frame, prev, "> " .. encounter.name, COLOR_BOSS[1], COLOR_BOSS[2], COLOR_BOSS[3], FONT_BODY, 4)

        for _, item in ipairs(encounter.loot) do
          local itemText = "   " .. item.name
          local slotText = "   |cff888888[" .. (item.slot or "N/D") .. "]|r"

          prev = AddLine(frame, prev, itemText, COLOR_ITEM[1], COLOR_ITEM[2], COLOR_ITEM[3], FONT_BODY, 1)
          prev = AddLine(frame, prev, slotText, COLOR_SLOT[1], COLOR_SLOT[2], COLOR_SLOT[3], FONT_SMALL, 0)
          totalItems = totalItems + 1
        end
      end
    end

    if totalItems == 0 then
      prev = AddLine(frame, prev, "Sin items de nivel mitico para", COLOR_EMPTY[1], COLOR_EMPTY[2], COLOR_EMPTY[3], FONT_BODY, 2)
      prev = AddLine(frame, prev, "tu clase y especializacion.", COLOR_EMPTY[1], COLOR_EMPTY[2], COLOR_EMPTY[3], FONT_BODY, 1)
    end
  end

  -- Calcular altura total basada en las lineas usadas
  local totalHeight = FRAME_PAD_Y * 2
  for i = 1, frame._usedCount do
    local line = frame._pool[i]
    if line and line:IsShown() then
      totalHeight = totalHeight + line:GetStringHeight() + LINE_PADDING
    end
  end

  frame:SetHeight(math.max(totalHeight, 50))
end

-- ----------------------------------------------------------------
--  Posicionamiento
-- ----------------------------------------------------------------

local function PositionNextTo(frame, anchor)
  frame:ClearAllPoints()

  if not anchor or not anchor.GetRight or not anchor.GetTop then
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    return
  end

  local anchorRight  = anchor:GetRight()  or 0
  local anchorLeft   = anchor:GetLeft()   or 0
  local anchorTop    = anchor:GetTop()    or 0
  local anchorBottom = anchor:GetBottom() or 0
  local screenWidth  = GetScreenWidth()
  local screenHeight = GetScreenHeight()

  if anchorRight <= 0 or anchorTop <= 0 or anchorBottom >= screenHeight or anchorLeft >= screenWidth then
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    return
  end

  if anchor == UIParent then
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    return
  end

  if anchorRight + FRAME_WIDTH + 12 <= screenWidth then
    frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
  else
    frame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -8, 0)
  end
end

-- ----------------------------------------------------------------
--  API publica
-- ----------------------------------------------------------------

function MapPoiTooltip:ShowForInstance(instanceId, anchor)
  if not instanceId or not anchor then
    return
  end

  local classData = ns.ClassResolver and ns.ClassResolver:Get() or {}
  local classID  = classData.classId or 0
  local specID   = classData.specId  or 0

  local instData = ns.BiSData and ns.BiSData:GetInstance(instanceId)
  local isRaid   = instData and instData.type == "raid"
  local diffID   = isRaid and 16 or 23  -- 16=Mythic Raid / 23=Mythic party

  local englishName = (instData and instData.name) or instanceId:gsub("_", " ")

  local frame = GetFrame()
  PositionNextTo(frame, anchor)

  local cacheKey = string.format("%s:%d:%d:%d", instanceId, classID, specID, diffID)
  local cached   = lootCache[cacheKey]

  if cached then
    BuildContent(frame, cached, englishName)
    frame:Show()
    if ns.config and ns.config.debugTooltip then
      print("|cffff9900[PuchiAssists]|r MapPoiTooltip visible (cache): " .. tostring(englishName))
    end
    return
  end

  -- Mostrar inmediatamente "buscando" y luego poblar con datos reales
  BuildContent(frame, nil, englishName)
  frame:Show()
  if ns.config and ns.config.debugTooltip then
    print("|cffff9900[PuchiAssists]|r MapPoiTooltip visible (loading): " .. tostring(englishName))
  end

  if not ns.EJProvider then
    return
  end

  local lootData, err = ns.EJProvider:CollectLootForInstance(englishName, {
    classID     = classID,
    specID      = specID,
    difficultyID = diffID,
  })

  if lootData then
    lootCache[cacheKey] = lootData
  else
    lootCache[cacheKey] = EJ_NOT_FOUND
    if ns.config and ns.config.debugTooltip then
      print("|cffff9900[PuchiAssists]|r EJProvider error para " .. englishName .. ": " .. tostring(err))
    end
  end

  -- Redibujar con los datos reales (ya tenemos el resultado)
  BuildContent(frame, lootCache[cacheKey], englishName)
  frame:Show()
  if ns.config and ns.config.debugTooltip then
    print("|cffff9900[PuchiAssists]|r MapPoiTooltip visible (final): " .. tostring(englishName))
  end
end

function MapPoiTooltip:ShowCentered(instanceId)
  if not instanceId then
    return
  end

  local frame = GetFrame()
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)

  self:ShowForInstance(instanceId, frame)
end

function MapPoiTooltip:ShowAttachedToMap(instanceId)
  if not instanceId then
    return
  end

  local frame = GetFrame()
  frame:ClearAllPoints()

  if WorldMapFrame then
    frame:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 10, -30)
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
  end

  self:ShowForInstance(instanceId, frame)
end

function MapPoiTooltip:Hide()
  if _frame then
    _frame:Hide()
  end
end

function MapPoiTooltip:ClearCache()
  lootCache = {}
end

function MapPoiTooltip:Init()
  GetFrame()  -- pre-crea el frame al cargar
end

function MapPoiTooltip:IsReady()
  return _frame ~= nil
end

function MapPoiTooltip:DebugShowTest(instanceId)
  local testInstanceId = instanceId or "windrunner_spire"
  local anchor = _G.WorldMapFrameAreaLabel
  if not anchor and WorldMapFrame and WorldMapFrame.UIElementsFrame then
    anchor = WorldMapFrame.UIElementsFrame.AreaLabel
  end

  if not anchor and WorldMapFrame and WorldMapFrame:IsShown() then
    anchor = WorldMapFrame
  end

  if anchor then
    self:ShowForInstance(testInstanceId, anchor)
  else
    self:ShowCentered(testInstanceId)
  end
end
