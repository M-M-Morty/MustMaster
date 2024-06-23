

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')


---@type TargetActor_GH_Projectile_C
local TargetActor_GH_Projectile_C = Class()


function TargetActor_GH_Projectile_C:UserConstructionScript()
    self.Overridden.UserConstructionScript(self)

    --数据相关，需要自己准备配置数据
    self.vCollideActors = UE.TArray(UE.AActor)
    --self.COLLISION_DELAY_TIME = 0
    --self.FLY_OBJ_CLASS = ''
end
function TargetActor_GH_Projectile_C:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)
end
function TargetActor_GH_Projectile_C:ReceiveEndPlay(EndPlayReason)
    self.Overridden.ReceiveEndPlay(self, EndPlayReason)
end
function TargetActor_GH_Projectile_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)
end


function TargetActor_GH_Projectile_C:OnStartTargeting(Ability)
    self.Overridden.OnStartTargeting(self, Ability)

    self.target_start_time = UE.UGameplayStatics.GetTimeSeconds(self)
    if self.FLY_OBJ_CLASS then
        self.flyObjectInst = self:GetWorld():SpawnActor(self.FLY_OBJ_CLASS, self:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self)
        self:K2_AttachToActor(self.flyObjectInst, '', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepRelative)
    end
end
function TargetActor_GH_Projectile_C:OnConfirmTargetingAndContinue()
    self:BroadcastTargetDataHandleWithActors(self.vCollideActors)
end

function TargetActor_GH_Projectile_C:OnCollideActor(tarActor, hitResult)
    --UnLua.LogWarn('TargetActor_GH_Projectile_C:OnCollideActor', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(tarActor))

    local current = UE.UGameplayStatics.GetTimeSeconds(self)
    if (not self.target_start_time) or (current - self.target_start_time < (self.COLLISION_DELAY_TIME or 0)) then
        return
    end

    self.vCollideActors:AddUnique(tarActor)
    return true
end


return TargetActor_GH_Projectile_C

