local _, ns = ...

ns.Events = ns.Events or {}

function ns.Events:Register(frame, event)
  if frame and event then
    frame:RegisterEvent(event)
  end
end
