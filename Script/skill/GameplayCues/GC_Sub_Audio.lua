--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local G = require("G")
local BPConst = require("common.const.blueprint_const")
---@type GC_Sub_Audio_C
local GC_Sub_Audio = UnLua.Class()

function GC_Sub_Audio:OnExecute(Target, Parameters, Context)    
    --self.Overridden.OnExecute(self, Target, Parameters, Context)
    if self.AkAudioEvent and self.AkAudioEvent:IsValid() then
        if Target and Target:IsValid() then
            local ActorComponent = self:GetActorComponent(Target)
            if ActorComponent and ActorComponent:IsValid() then 
                local Location = ActorComponent:K2_GetComponentLocation()
                local BlockingHit = false
                UE.UAbilitySystemBlueprintLibrary.GetImpactPointFromParameters(Parameters, BlockingHit, Location)                
                if UE.UAkGameplayStatics.IsValidAkLocation(Location) then                    
                    --G.log:debug("GC_Sub_Audio", "OnExecute %s %s %s", tostring(BlockingHit), tostring(Location), tostring(Context))                       
                    local PostEventAtLocationAsyncNode =  UE.UPostEventAtLocationAsync.PostEventAtLocationAsync(ActorComponent, self.AkAudioEvent, Location, UE.FRotator(0, 0, 0))
                    PostEventAtLocationAsyncNode:Activate()
                end
            end
        end
    end
end

function GC_Sub_Audio:GetActorComponent(Other)
    local BPACharacterBaseClass = BPConst.GetBPACharacterBaseClass()
    local Character = Other:Cast(BPACharacterBaseClass)
    if Character ~= nil then -- if is BPACharacterBase
        return Character.Mesh
    else
        local Component = Character:GetComponentByClass(UE.UGeometryCollectionComponent)
        if Component and Component:IsValid() then
            return Component
        else
            return nil
        end
    end
end

return GC_Sub_Audio