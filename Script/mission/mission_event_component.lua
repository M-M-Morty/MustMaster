--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")

---@type BP_MissionEventComponent_C
local MissionEventComponent = UnLua.Class()

function MissionEventComponent:Initialize(Initializer)
    self.Events = {}
    self.ListeningEventKeys = {}
    self.GeneratedEventID = 0
end

-- function M:ReceiveBeginPlay()
-- end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

function MissionEventComponent:RegisterEvent(Event)
    if (Event:GetEventID() ~= 0) then
        G.log:error("xaelpeng", "MissionEventComponent:RegisterEvent %s Has Set EventID", Event:GetName())
        return
    end
    local EventID = self:GenerateEventID()
    Event:SetEventID(EventID)
    if self.Events[EventID] ~= nil then
        G.log:error("xaelpeng", "MissionEventComponent:RegisterEvent %s Has Already registered", Event:GetName())
        return
    end
    G.log:debug("xaelpeng", "MissionEventComponent:RegisterEvent %d %s", EventID, Event:GetName())
    self.Events[EventID] = Event
end

function MissionEventComponent:UnregisterEvent(Event)
    local EventID = Event:GetEventID()
    if (EventID == 0) then
        G.log:error("xaelpeng", "MissionEventComponent:UnregisterEvent %s EventID Not Set", Event:GetName())
        return
    end
    if (self.Events[EventID] == nil) then
        G.log:error("xaelpeng", "MissionEventComponent:UnregisterEvent %s Has Not registered", Event:GetName())
        return
    end
    G.log:debug("xaelpeng", "MissionEventComponent:UnregisterEvent %d %s", EventID, Event:GetName())
    self.Events[EventID] = nil
    Event:ResetEventID()
end

function MissionEventComponent:GenerateEventID()
    self.GeneratedEventID = self.GeneratedEventID + 1
    return self.GeneratedEventID
end

function MissionEventComponent:OnEvent(EventID, EventParamStr)
    G.log:debug("xaelpeng", "MissionEventComponent:OnEvent %s", EventID)
    if self.Events[EventID] == nil then
        G.log:error("xaelpeng", "MissionEventComponent:OnEvent %s Has Not registered", EventID)
        return
    end
    local Event = self.Events[EventID]
    Event:OnEvent(EventParamStr)
end

return MissionEventComponent
