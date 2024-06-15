require "UnLua"
local G = require("G")

local CameraAreaTrigger = Class()

function CameraAreaTrigger:OnEnter(actor)
    --G.log:error("devin", "CameraAreaTrigger:OnEnter")

    if self.AreaTriggerType ~= Enum.Enum_CameraAreaTriggerType.Boss then
        return
    end

    if actor.IsPlayer and actor:IsPlayer() then
        local BossArray = UE.TArray(UE.AActor)
        UE.UGameplayStatics.GetAllActorsWithTag(self:GetWorld(), "Boss", BossArray)   
        if (BossArray:Length() and BossArray[1] ~= nil) then
            actor.CharacterStateManager:SetBossBattleState(true, BossArray[1])     
        end
    end
end

function CameraAreaTrigger:OnLeave(actor)
    --G.log:error("devin", "CameraAreaTrigger:OnLeave")

    if self.AreaTriggerType ~= Enum.Enum_CameraAreaTriggerType.Boss then
        return
    end

    if actor ~= nil and actor.IsPlayer and actor:IsPlayer() then
        actor.CharacterStateManager:SetBossBattleState(false, nil)
    end
end


-- Move To Character
-- function PlayerState:UserConstructionScript()
--     --G.log:info("hycoldrain", "PlayerState:UserConstructionScript")

--     for Ind = 1, self.AttributeSetClasses:Length() do
--         local CurAttributeSet = NewObject(self.AttributeSetClasses:Get(Ind), self)
--         self:AddAttributeSet(CurAttributeSet)
--     end
-- end

return CameraAreaTrigger