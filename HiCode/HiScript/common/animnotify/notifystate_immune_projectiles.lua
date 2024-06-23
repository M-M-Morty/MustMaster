--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type ANS_ImmuneProjectile_C
local NotifyState_Immune_Projectiles = Class()

-- function M:Received_NotifyBegin(MeshComp, Animation, TotalDuration)
-- end

-- function M:Received_NotifyTick(MeshComp, Animation, FrameDeltaTime)
-- end

-- function M:Received_NotifyEnd(MeshComp, Animation)
-- end

function NotifyState_Immune_Projectiles:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    --self.ImmuneHandler = Owner:SendMessage("AddImmuneProjectiles", self.ImmuneProjectileInfo)
    if Owner.BP_ImmuneProjectileComponent then
        self.ImmuneHandler = Owner.BP_ImmuneProjectileComponent:AddImmuneProjectiles(self.ImmuneProjectileInfo)
    end
    return true
end

function NotifyState_Immune_Projectiles:Received_NotifyEnd(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    Owner:SendMessage("RemoveImmuneProjectiles", self.ImmuneHandler)
    return true
end

return NotifyState_Immune_Projectiles
