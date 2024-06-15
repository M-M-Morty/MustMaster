--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **`
--

---@type BPA_AssistBase_C
local Monster = require("actors.common.Monster")
local G = require("G")

local AssistBase = Class(Monster)

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

-- function M:ReceiveBeginPlay()
-- end

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

function AssistBase:ReceiveBeginPlay()
    Super(AssistBase).ReceiveBeginPlay(self)
    if self.bZeroGravity and self:HasCalcAuthority() then
        G.log:info("yb", "set zero gravity %s", self:IsClient())
        self.ZeroGravityComponent:EnterZeroGravity(-1, false, true)
    end
    -- self:K2_SetActorTransform(self.BindTransform, false, nil, true)
    -- local Pos = self:K2_GetActorLocation()
    -- G.log:info("yb", "spawn assist int pos(%s %s %s)， isClient %s", Pos.X, Pos.Y, Pos.Z, self:IsClient())
    -- -- 刚出生的时候应该绑定到相机上
    -- if self:IsClient() then
    --     local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    --     if self.SourceActor == Player then
    --         local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    --         if CameraManager then
    --             self:K2_AttachToActor(CameraManager, "None", UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
    --         end
    --     end
    -- end
end


function AssistBase:OnTransportToTarget()
    -- local TargetTransform = self.TargetTransform
    -- if TargetTransform then
    --     self:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
    --     self:K2_SetActorTransform(TargetTransform, false, nil, true)
    -- else 
    --     G.log:info("yb", "assist monster spawn point not find")
    -- end
end


return AssistBase
