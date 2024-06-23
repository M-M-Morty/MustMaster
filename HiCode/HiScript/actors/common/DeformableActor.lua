--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")

local Actor = require("common.actor")

---@type BP_DeformableActor_C
local DeformableActor = Class(Actor)

--function DeformableActor:ReceiveBeginPlay()    
--    Super(DeformableActor).ReceiveBeginPlay(self)
--    if self:GetComponentByClass(UE.USkeletalMeshComponent) then        
--        local Mesh = self:GetComponentByClass(UE.USkeletalMeshComponent)
--        Mesh.OnComponentHit:Add(self, self.OnHit)
--    end        
--end
--
--function DeformableActor:ReceiveEndPlay()
--    Super(DeformableActor).ReceiveEndPlay(self)
--    if self:GetComponentByClass(UE.USkeletalMeshComponent) then
--        local Mesh = self:GetComponentByClass(UE.USkeletalMeshComponent)
--        Mesh.OnComponentHit:Remove(self, self.OnHit)
--    end
--end
--
--function DeformableActor:OnHit(HitComponent, OtherActor, OtherComp, NormalImpulse, HitResult)    
--    G.log:debug("DeformableActor", "OnComponentHit %s ", G.GetDisplayName(OtherActor))   
--    self.InstaDeform:OnHitByLine(HitResult) 
--end

return RegisterActor(DeformableActor)