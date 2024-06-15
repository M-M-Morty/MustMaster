--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local Character = require("actors.common.Character")
local G = require("G")

---@type BPA_FakeAssistBase_C
local FakeAssistBase = Class(Character)

function FakeAssistBase:Initialize(Initializer)
    Super(FakeAssistBase).Initialize(self, Initializer)
    --self.MontageCallProxy = nil
end

-- function M:UserConstructionScript()
-- end

function FakeAssistBase:ReceiveBeginPlay()
    Super(FakeAssistBase).ReceiveBeginPlay(self)
    self:K2_SetActorTransform(self.BindTransform, false, nil, true)
    local Pos = self:K2_GetActorLocation()
    --G.log:info("yb", "[AssistSkill]spawn fake assist int pos(%s %s %s)， isClient %s", Pos.X, Pos.Y, Pos.Z, self:IsClient())
    -- 刚出生的时候应该绑定到相机上
    if self:IsClient() then
        local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
        if CameraManager then
            self:K2_AttachToActor(CameraManager, "None", UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
        end
        self.Mesh:SetRelativeScale3D(UE.FVector(0.01, 0.01, 0.01))
    end

    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, function () self:K2_DestroyActor() end}, self.LifeTime, false)
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return FakeAssistBase
