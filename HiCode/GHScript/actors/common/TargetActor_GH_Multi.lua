

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@type TargetActor_GH_Multi_C
local TargetActor_GH_Multi = Class()


function TargetActor_GH_Multi:UserConstructionScript()
    self.Overridden.UserConstructionScript(self)

    --数据相关，需要自己准备配置数据
    --self.Collision
    --self.REPEATE_COLLISION
    self.vOverlappedActors = UE.TMap(UE.AActor, 0)
    self.vCollideActors = UE.TArray(UE.AActor)
end
function TargetActor_GH_Multi:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    self.Collision.OnComponentBeginOverlap:Add(self, self.OnComponentBeginOverlap)
    self.Collision.OnComponentEndOverlap:Add(self, self.OnComponentEndOverlap)
end
function TargetActor_GH_Multi:ReceiveEndPlay(EndPlayReason)
    self.Overridden.ReceiveEndPlay(self, EndPlayReason)

    self.Collision.OnComponentBeginOverlap:Remove(self, self.OnComponentBeginOverlap)
    self.Collision.OnComponentEndOverlap:Remove(self, self.OnComponentEndOverlap)
end
function TargetActor_GH_Multi:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)

    --FunctionUtil:DrawShapeComponent(self.Collision)

    if self.OwningAbility and self.vCollideActors:Length() > 0 then
        self:ConfirmTargeting()
        self.vCollideActors:Clear()
    end
end


function TargetActor_GH_Multi:OnStartTargeting(Ability)
    self.Overridden.OnStartTargeting(self, Ability)

    local avatar = self.OwningAbility:GetAvatarActorFromActorInfo()
    self:K2_AttachToActor(avatar, '', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepRelative)
    self.bDestroyOnConfirmation = false
end
function TargetActor_GH_Multi:OnConfirmTargetingAndContinue()
    self:BroadcastTargetDataHandleWithActors(self.vCollideActors)
end

function TargetActor_GH_Multi:OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    --UnLua.LogWarn('TargetActor_GH_Multi:OnComponentBeginOverlap', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(OtherActor))

    if FunctionUtil:IsPlayer(OtherActor) then
        if self.REPEATE_COLLISION then
            self.vCollideActors:AddUnique(OtherActor)
        else
            local v = self.vOverlappedActors:Find(OtherActor)
            if not v then
                self.vCollideActors:AddUnique(OtherActor)
                self.vOverlappedActors:Add(OtherActor, true)
            end
        end
    end
end
function TargetActor_GH_Multi:OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    --UnLua.LogWarn('TargetActor_GH_Multi:OnComponentEndOverlap', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(OtherActor))
end


return TargetActor_GH_Multi

