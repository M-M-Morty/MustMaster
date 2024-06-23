require "UnLua"
local G = require("G")

local TriggerEvent = require("actors.common.volumes.TriggerEvent")

local TriggerVolumeEventManager = Class()

local TriggerEventStack = {}


function TriggerVolumeEventManager:PlayerBeginOverlap(TriggerVolume, Player)
    local TopEvent = TriggerEventStack[#TriggerEventStack]
    if TopEvent then
        TopEvent:ActorEndOverlapEvent()
    end
    local Event = TriggerEvent.new(TriggerVolume, Player)
    Event:ActorBeginOverlapEvent()
    table.insert(TriggerEventStack, Event)          
    G.log:info("[hycoldrain]", "TriggerVolumeEventManager:PlayerBeginOverlap--check stack begin- [%s] [%s]  [%s]", tostring(#TriggerEventStack),  G.GetDisplayName(TriggerVolume), G.GetDisplayName(Player))      
   
end

function TriggerVolumeEventManager:PlayerEndOverlap(TriggerVolume, Player)        
    G.log:info("[hycoldrain]", "TriggerVolumeEventManager:PlayerEndOverlap--check stack begin- [%s]", tostring(#TriggerEventStack))       
    TriggerVolume:SendMessage("OnPlayerLeaveTrigger", Player) 
    if #TriggerEventStack > 0 then
        G.log:info("[hycoldrain]", "check volume event stack info --[%s]  [%s]  [%s]", tostring(TriggerEventStack[#TriggerEventStack]),   tostring(TriggerEventStack[#TriggerEventStack].TriggerVolume), tostring(TriggerEventStack[#TriggerEventStack].OverlapedActor))
        local TriggerEvent = table.remove(TriggerEventStack, #TriggerEventStack)
        G.log:info("[hycoldrain]", "check vollume event in top of stack [%s] [%s]", G.GetDisplayName(TriggerVolume), G.GetDisplayName(TriggerEvent.TriggerVolume))
        if TriggerVolume == TriggerEvent.TriggerVolume then
            TriggerEvent = TriggerEventStack[#TriggerEventStack]
            if TriggerEvent then -- if Trigger Event is nil , out of the last volume
                TriggerEvent:ActorBeginOverlapEvent()
            end
        else
            for ind = 1, #TriggerEventStack do
                local TempEvent = table.remove(TriggerEventStack, #TriggerEventStack)
                if TriggerVolume == TempEvent.TriggerVolume then                    
                    table.insert(TriggerEventStack, TriggerEvent)      
                    break
                end
            end
        end        
    end    
end

function TriggerVolumeEventManager:LeaveWorld()
    TriggerEventStack = {}
end


--function TriggerVolumeEventManager:PlayerEndOverlap(TriggerVolume, Player)    
--    if #TriggerEventStack > 0 then
--        local Event = TriggerEventStack[1]
--        Event:ActorEndOverlapEvent()
--        table.remove(TriggerEventStack, 1)       
--        if #TriggerEventStack > 0 then
--            Event = TriggerEventStack[1]
--            Event:ActorBeginOverlapEvent()
--        end
--    end    
--end


--function TriggerVolumeEventManager:IsVolumeAInsideB(InVolumeA, InVolumeB)
--    local OverlapTriggerVolumes = UE.TArray(UE.AHiTriggerVolume)
--    InVolumeB:GetOverlappingActors(OverlapTriggerVolumes, UE.AHiTriggerVolume)
--    if OverlapTriggerVolumes:Find(InVolumeA) then
--        return true
--    else
--        return false
--    end
--end
--
---------debug code
--function TriggerVolumeEventManager:DebugPrintVolumes(inVolumes)
--    G.log:info("[hycoldrain]", "TriggerVolumeEventManager:PlayerBeginOverlap--- [%s] [%s]", tostring(inVolumes:Length()), tostring(inVolumes))
--    local Count = inVolumes:Length()
--    for ind = 1, Count do
--        local Volume = inVolumes:Get(ind)        
--        if Volume then
--            G.log:info("[hycoldrain]", "TriggerVolumeEventManager:PlayerBeginOverlap--- [%s]", G.GetDisplayName(Volume))
--        end
--    end
--end


return TriggerVolumeEventManager