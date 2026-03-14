local _, ns = ...

ns.CursorMapTooltip = ns.CursorMapTooltip or {}

local function CreateFrames(self)
  if self.frame and self.tooltip then
    return
  end

  local frame = CreateFrame("Frame")
  local tooltip = CreateFrame("GameTooltip", "PuchiAssistsCursorMapTooltip", UIParent, "GameTooltipTemplate")

  frame:Hide()

  frame:SetScript("OnUpdate", function(_, elapsed)
    self.elapsed = (self.elapsed or 0) + (elapsed or 0)
    if self.elapsed < 0.08 then
      return
    end
    self.elapsed = 0

    if not self.enabled then
      tooltip:Hide()
      return
    end

    local mapID = nil
    local x = nil
    local y = nil

    if WorldMapFrame and WorldMapFrame:IsShown() and WorldMapFrame.GetMapID then
      mapID = WorldMapFrame:GetMapID()

      local canvas = WorldMapFrame.GetCanvasContainer and WorldMapFrame:GetCanvasContainer()
      if canvas and canvas:IsShown() and canvas.GetWidth and canvas.GetHeight then
        local canvasWidth = canvas:GetWidth()
        local canvasHeight = canvas:GetHeight()

        if canvasWidth and canvasWidth > 0 and canvasHeight and canvasHeight > 0 then
          local cursorX, cursorY = GetCursorPosition()
          local scale = canvas:GetEffectiveScale() or 1

          cursorX = cursorX / scale
          cursorY = cursorY / scale

          local left = canvas:GetLeft() or 0
          local bottom = canvas:GetBottom() or 0

          local normalizedX = (cursorX - left) / canvasWidth
          local normalizedY = 1 - ((cursorY - bottom) / canvasHeight)

          if normalizedX >= 0 and normalizedX <= 1 and normalizedY >= 0 and normalizedY <= 1 then
            x = normalizedX
            y = normalizedY
          end
        end
      end
    end

    if not mapID then
      mapID = C_Map.GetBestMapForUnit("player")
    end

    if (not x or not y) and mapID then
      local pos = C_Map.GetPlayerMapPosition(mapID, "player")
      if pos then
        x = pos.x
        y = pos.y
      end
    end

    tooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
    tooltip:ClearLines()
    tooltip:AddLine("PuchiAssists Debug", 0.4, 0.8, 1)
    tooltip:AddLine("MapID: " .. tostring(mapID or "N/D"), 1, 1, 1)
    tooltip:AddLine(string.format("X: %.4f  Y: %.4f", tonumber(x) or 0, tonumber(y) or 0), 0.9, 0.9, 0.9)
    tooltip:Show()
  end)

  self.frame = frame
  self.tooltip = tooltip
end

function ns.CursorMapTooltip:Init()
  CreateFrames(self)
end

function ns.CursorMapTooltip:SetEnabled(enabled)
  CreateFrames(self)

  self.enabled = not not enabled

  if self.enabled then
    self.frame:Show()
  else
    self.frame:Hide()
    if self.tooltip then
      self.tooltip:Hide()
    end
  end
end

function ns.CursorMapTooltip:IsEnabled()
  return not not self.enabled
end
