

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@type TargetActor_GH_Instant_C
local TargetActor_GH_Instant_C = Class()


function TargetActor_GH_Instant_C:UserConstructionScript()
    self.Overridden.UserConstructionScript(self)

    --数据相关，需要自己准备配置数据
    self.vCollideActors = UE.TArray(UE.AActor)
    --self.USE_PROJECTILE_LOCATION = false
end
function TargetActor_GH_Instant_C:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    self.Collision.OnComponentBeginOverlap:Add(self, self.OnComponentBeginOverlap)
end
function TargetActor_GH_Instant_C:ReceiveEndPlay(EndPlayReason)
    self.Overridden.ReceiveEndPlay(self, EndPlayReason)

    self.Collision.OnComponentBeginOverlap:Remove(self, self.OnComponentBeginOverlap)
end
function TargetActor_GH_Instant_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)
end


function TargetActor_GH_Instant_C:OnStartTargeting(Ability)
    self.Overridden.OnStartTargeting(self, Ability)

    if self.USE_PROJECTILE_LOCATION and Ability.projectile_bomb_location then
        self:K2_SetActorLocation(Ability.projectile_bomb_location, false, nil, true)
    end

    --FunctionUtil:DrawShapeComponent(self.Collision)
end
function TargetActor_GH_Instant_C:OnConfirmTargetingAndContinue()
    self:BroadcastTargetDataHandleWithActors(self.vCollideActors)
end

function TargetActor_GH_Instant_C:OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    --UnLua.LogWarn('TargetActor_GH_Instant_C:OnComponentBeginOverlap', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(OtherActor))

    if FunctionUtil:IsPlayer(OtherActor) then
        self.vCollideActors:AddUnique(OtherActor)
    end
end


return TargetActor_GH_Instant_C

