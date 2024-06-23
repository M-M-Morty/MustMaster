--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

---@type BP_DecalInteractiveComponent_C
local DecalInteractiveComp = Component(ComponentBase)
local decorator = DecalInteractiveComp.decorator

function DecalInteractiveComp:Start()
    Super(DecalInteractiveComp).Start(self)
    self.DecalActors:Clear()   
end

function DecalInteractiveComp:Stop()
    Super(DecalInteractiveComp).Stop(self)
    self.DecalActors:Clear()
end

decorator.message_receiver()
function DecalInteractiveComp:EnterDecal(DecalActor)    
    if DecalActor and DecalActor:IsValid() then       
        if self.DecalActors:Find(DecalActor) == 0 then            
            self.DecalActors:Add(DecalActor)
       end        
    end    
end

decorator.message_receiver()
function DecalInteractiveComp:LeaveDecal(DecalActor)    
    if DecalActor and DecalActor:IsValid() then
        if self.DecalActors:Find(DecalActor) ~= 0 then
            self.DecalActors:Remove(DecalActor)
        end
    end 
end


--DEBUG CODE
--decorator.message_receiver()
--function DecalInteractiveComp:OnReceiveTick(DeltaSeconds)
--    self:OnReceiveFootStep(true, self.actor:K2_GetActorLocation())
--end

decorator.message_receiver()
function DecalInteractiveComp:OnReceiveFootStep(isLeftFoot, ImpactPoint)    
    if self.DecalActors:Length() > 0 then        
        -- SET MPC Params
        local ParamName = "RipplePosition_RightFoot"
        if isLeftFoot then
            ParamName = "RipplePosition_LeftFoot"
        end        
        if self.MPC_Water and self.MPC_Water:IsValid() then        
            local ParamValue = UE.FLinearColor(ImpactPoint.X, ImpactPoint.Y, ImpactPoint.Z)
            UE.UKismetMaterialLibrary.SetVectorParameterValue(self.actor, self.MPC_Water, ParamName, ParamValue)
        end
    end
    --for Ind = 1, self.DecalActors:Length() do
    --    local DecalAvatar = self.DecalActors:Get(Ind)
    --    DecalAvatar:SendMessage("FootSteopInteractionEvent")        
    --end
end

return DecalInteractiveComp

