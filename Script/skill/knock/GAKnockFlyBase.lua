local G = require("G")

local GAKnockBase = require("skill.knock.GAKnockBase")
local InKnockTypes = require("common.event_const").InKnockTypes
local GAKnockFly = Class(GAKnockBase)

function GAKnockFly:ActivateAbilityFromEvent()
    Super(GAKnockFly).ActivateAbilityFromEvent(self)

    self:BeginKnockFly(self.KnockParams)
end

function GAKnockFly:BeginKnockFly(KnockParams)
    self:FaceToInstigator(KnockParams)

    self.OwnerActor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(KnockParams.Instigator, true)
    if KnockParams.Instigator.CharacterMovement then
        KnockParams.Instigator.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(self.OwnerActor, true)
    end

    self.OwnerActor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.Custom, true)

    self:BeginKnockFlyStageFlying()

    self.OwnerActor:SendMessage("BeginHitFly")
    self.Component.HitData.KnockLoopType = Enum.EKnockLoopType.Normal
    self.InKnockHandle = self.OwnerActor.BuffComponent:AddInKnockHitFlyBuff()

    self.is_knock_fly = true
end

function GAKnockFly:EndKnockFly()
    if self.is_knock_fly then
        self.OwnerActor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(self.KnockParams.Instigator, false)
        if self.KnockParams.Instigator.CharacterMovement then
            self.KnockParams.Instigator.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(self.OwnerActor, false)
        end

        self.KnockParams = nil

        self:EndKnockFlyState()
        self.OwnerActor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.None, true)

        self.is_knock_fly = false

        -- 空中会把CharacterMovement切成Flying可能有两个阶段，第一阶段是真正飞行的阶段fly，第二阶段是一个调整姿态的stop阶段，两个状态结束就切成Falling或Walking
        self.is_knock_fly_stage_fly = false
        self.is_knock_fly_stage_stop = false
        self.is_knock_fly_stage_land = false

        if not self.bEnd then
            self:K2_EndAbility()
        end
    end
end

function GAKnockFly:EndKnockFlyState()
    self.OwnerActor.BuffComponent:RemoveInKnockHitFlyBuff(self.InKnockHandle)
    self.OwnerActor:SendMessage("EndHitFly")
    self.OwnerActor.CharacterStateManager:SetHitState(false)
end

function GAKnockFly:BeginKnockFlySubStageFly()
    self.is_knock_fly_stage_fly = true
    self:PlayKnockFlyMontage()
end

function GAKnockFly:EndKnockFlySubStageFly()
    self.is_knock_fly_stage_fly = false
end

function GAKnockFly:BeginKnockFlySubStageStop()
    self.is_knock_fly_stage_stop = true
    self:PlayKnockFlyStopMontage()
    self.Component.HitData.KnockLoopType = Enum.EKnockLoopType.KnockFlyBlockedByWall
end

function GAKnockFly:EndKnockFlySubStageStop()
    self.is_knock_fly_stage_stop = false
end

function GAKnockFly:BeginKnockFlyStageFlying()
    self.OwnerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Flying)
    self:BeginKnockFlySubStageFly()
end

-- flying和stop都结束以后调用
function GAKnockFly:EndKnockFlyStageFlying()
    if self.OwnerActor and self.OwnerActor.ZeroGravityComponent and self.OwnerActor.ZeroGravityComponent:IsInZeroGravity() then
        return
    else
        if self.OwnerActor then
            if self.OwnerActor:IsOnFloor() then
                self.OwnerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
            else
                self.OwnerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
            end            
        end
    end
end

function GAKnockFly:PlayKnockFlyMontage()
    if not self.OwnerActor then
        return
    end
    
    local KnockInfo = self.KnockParams.KnockInfo

    G.log:debug(self.__TAG__, "Play knock fly start montage: %s, dis scale: %s", G.GetObjectName(self.HitFlyAnim), KnockInfo.KnockDisScale)
    self.OwnerActor.MotionWarping:AddOrUpdateWarpTargetFromTransform("HitTarget", UE.FTransform(UE.FRotator(0, 0, 0):ToQuat(), UE.FVector(0, 0, 0), KnockInfo.KnockDisScale))

    self:PlayMontageWithCallback(self.OwnerActor.Mesh, self.HitFlyAnim, 1.0, self.OnKnockFlyMontageInterrupted, self.OnKnockFlyMontageCompleted, self.OnKnockFlyMontageBlendOut)
end

--被打断的话说明撞墙了，播放stop，然后变成下落状态
function GAKnockFly:OnKnockFlyMontageInterrupted(name)
    G.log:debug(self.__TAG__, "OnKnockFlyMontageInterrupted")
    self:OnKnockFlyStartProcessEnded()
end

--完整播放完的话，结束空中飞行状态，直接等AnimBP放起身动画动画
function GAKnockFly:OnKnockFlyMontageCompleted(name)
    G.log:debug(self.__TAG__, "OnKnockFlyMontageCompleted")
    self:OnKnockFlyStartProcessEnded()
end

function GAKnockFly:OnKnockFlyMontageBlendOut(name)
    G.log:debug(self.__TAG__, "OnKnockFlyMontageBlendOut")
    self:OnKnockFlyStartProcessEnded()
end

function GAKnockFly:OnKnockFlyStartProcessEnded()
    if not self.is_knock_fly_stage_fly then
        return
    end

    self:EndKnockFlySubStageFly()
    self:EndKnockFlyStageFlying()
end

function GAKnockFly:PlayKnockFlyStopMontage()
    G.log:debug(self.__TAG__, "Play knock fly stop montage: %s", G.GetObjectName(self.HitFlyStopAnim))
    local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.OwnerActor.Mesh, self.HitFlyStopAnim, 1.0)
    local callback = function(name)
                        self.OnKnockFlyStopMontageEnd(self, name)
                    end
    PlayMontageCallbackProxy.OnInterrupted:Add(self.OwnerActor, callback)
    PlayMontageCallbackProxy.OnCompleted:Add(self.OwnerActor, callback)

end

function GAKnockFly:OnKnockFlyStopMontageEnd(name)
   self:EndKnockFlySubStageStop()
   self:EndKnockFlyStageFlying()
end

function GAKnockFly:KnockFlyBlockedByWall()
    self.OwnerActor.CharacterMovement.Velocity = UE.FVector(0, 0, 0)
    self:BeginKnockFlySubStageStop()
end

function GAKnockFly:ReceiveMoveBlockedBy(HitResult)
    if not self.is_knock_fly_stage_fly then
        return
    end

    if self.HitFlyStopAnim and HitResult.bBlockingHit and HitResult.ImpactNormal:Dot(-self.OwnerActor.CharacterMovement.Velocity) > math.cos(math.rad(self.HitFlySlideAngle)) then
        self:KnockFlyBlockedByWall()
    end
end

function GAKnockFly:OnHitFlyLand()
    if self.is_knock_fly and not self.is_knock_fly_stage_land then
        self.is_knock_fly_stage_land = true
        self:PlayKnockFlyLandMontage()
    end
end

function GAKnockFly:PlayKnockFlyLandMontage()
    if self.HitFlyLandAnim then
        G.log:debug(self.__TAG__, "Play knock fly land montage: %s", G.GetObjectName(self.HitFlyLandAnim))
        self:PlayMontageWithCallback(self.OwnerActor.Mesh, self.HitFlyLandAnim, 1.0, self.OnKnockFlyLandMontageInterrupted, self.OnKnockFlyLandMontageCompleted, self.OnKnockFlyLandMontageBlendOut)
    else
        self:EndKnockFly()
    end
end

function GAKnockFly:OnKnockFlyLandMontageInterrupted(name)
    if self.bEnd then
        return
    end

    self:EndKnockFly()
end

function GAKnockFly:OnKnockFlyLandMontageCompleted(name)
    if self.bEnd then
        return
    end

    self:EndKnockFly()
end

function GAKnockFly:OnKnockFlyLandMontageBlendOut(name)
    if self.bEnd then
        return
    end

    self:EndKnockFly()
end

function GAKnockFly:K2_OnEndAbility(bWasCancelled)
    Super(GAKnockFly).K2_OnEndAbility(self, bWasCancelled)

    if bWasCancelled then
        if self.is_knock_fly_stage_fly then
            self.OwnerActor:StopAnimMontage(self.HitFlyAnim)
            self.is_knock_fly_stage_fly = false
        end

        if self.is_knock_fly_stage_stop then
            self.OwnerActor:StopAnimMontage(self.HitFlyStopAnim)
            self.is_knock_fly_stage_stop = false
        end

        if self.is_knock_fly_stage_land then
            self.OwnerActor:StopAnimMontage(self.HitFlyLandAnim)
            self.is_knock_fly_stage_land = false
        end
    end

    self:EndKnockFly()
end

return GAKnockFly
