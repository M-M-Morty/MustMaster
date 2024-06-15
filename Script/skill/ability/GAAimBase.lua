-- 瞄准型技能

local G = require("G")

local GAPlayerBase = require("skill.ability.GAPlayerBase")
local GAAimBase = Class(GAPlayerBase)


function GAAimBase:HandleActivateAbility()
    Super(GAAimBase).HandleActivateAbility(self)

    if self:IsServer() then
        local TargetActor = GameAPI.SpawnActor(self.OwnerActor:GetWorld(), self.TargetActorClass, self.OwnerActor:GetTransform(), UE.FActorSpawnParameters(), {})

        local WaitTargetDataTask = UE.UAbilityTask_WaitTargetData.WaitTargetDataUsingActor(self, "", UE.EGameplayTargetingConfirmation.CustomMulti, TargetActor)
        WaitTargetDataTask:ReadyForActivation()
        self:AddTaskRefer(WaitTargetDataTask)
    end

    if self:IsClient() then
        self.OwnerActor.AppearanceComponent:AimAction(true)
    end
end

function GAAimBase:Tick(DeltaSeconds)
    Super(GAAimBase).Tick(self, DeltaSeconds)
    if self.bEnd then
        return
    end

    if self:IsServer() then
        local CameraRotation = self.OwnerActor:GetCameraRotation()

        -- TODO 临时测试玩家跟随镜头转向.
        CameraRotation.Pitch = 0
        CameraRotation.Roll = 0
        self.OwnerActor.AppearanceComponent:Server_SmoothActorRotation(CameraRotation, 200, 0, DeltaSeconds)
    end
end

function GAAimBase:HandleEndAbility(bWasCancelled)
    Super(GAAimBase).HandleEndAbility(self, bWasCancelled)

    if self:IsClient() then
        self.OwnerActor.AppearanceComponent:AimAction(false)
    end
end

return GAAimBase
