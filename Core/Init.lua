local addonName, ns = ...

ns.name = addonName
ns.version = "0.1.0"

local addon = CreateFrame("Frame")
ns.addon = addon

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPuchiAssists|r: " .. tostring(msg))
end

ns.Print = Print

addon:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local loadedAddonName = ...
    if loadedAddonName ~= addonName then
      return
    end

    PuchiAssistsMidnightBiSDB = PuchiAssistsMidnightBiSDB or {}

    if ns.ClassResolver and ns.ClassResolver.Init then
      ns.ClassResolver:Init()
    end

    if ns.MapPins and ns.MapPins.Init then
      ns.MapPins:Init()
    end

    if ns.Tooltip and ns.Tooltip.Init then
      ns.Tooltip:Init()
    end
  elseif event == "PLAYER_LOGIN" then
    if ns.ClassResolver and ns.ClassResolver.Refresh then
      ns.ClassResolver:Refresh()
    end

    if ns.MapPins and ns.MapPins.Refresh then
      ns.MapPins:Refresh()
    end
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    local unit = ...
    if unit == "player" and ns.ClassResolver and ns.ClassResolver.Refresh then
      ns.ClassResolver:Refresh()
    end
  end
end)

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

SLASH_PUCHIASSIST1 = "/puchi"
SlashCmdList.PUCHIASSIST = function()
  if not ns.ClassResolver then
    Print("ClassResolver no disponible.")
    return
  end

  local classData = ns.ClassResolver:Get()
  local className = classData.classDisplayName or "N/D"
  local classToken = classData.classToken or "N/D"
  local specName = classData.specName or "Sin especializacion"

  Print("Clase: " .. className .. " (" .. classToken .. ")")
  Print("Spec: " .. specName)
end
