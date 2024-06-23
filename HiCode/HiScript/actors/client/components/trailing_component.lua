require "UnLua"
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local TrailingComponent = Component(ComponentBase)
local decorator = TrailingComponent.decorator

--[[
Component for handle character trailing effect
]]

function TrailingComponent:Initialize(...)
    Super(TrailingComponent).Initialize(self, ...)
    self.TrailingClass = nil
    self.FadeoutTime = nil
    self.ShadowCount = nil
    self.StartDis = nil
end

decorator.message_receiver()
function TrailingComponent:SetTrailParameters(TrailingClass, FadeoutTime, ShadowCount, StartDis, MaterialInst)    
    self.TrailingClass = TrailingClass
    self.FadeoutTime = FadeoutTime
    self.ShadowCount = ShadowCount
    self.StartDis = StartDis
    self.MaterialInst = MaterialInst
end

decorator.message_receiver()
function TrailingComponent:OnReceiveTick(DeltaSeconds)    
    local DelayTime = self.FadeoutTime / self.ShadowCount    
    local UpdateTrailFunc = function()
        local Velocity = self.actor.CharacterMovement.Velocity:Size()
        if Velocity > self.StartDis then
            local World = self.actor:GetWorld()
            if not World then
                return
            end

            local SpawnParameters = UE.FActorSpawnParameters()
            local ExtraData = { SkeleMesh = self.actor.Mesh}            
            local TrailingActor = GameAPI.SpawnActor(self.actor:GetWorld(), self.TrailingClass, self.actor:GetTransform(), SpawnParameters, ExtraData)            
            TrailingActor:SetLifeSpan(self.FadeoutTime)
            if self.MaterialInst then
                TrailingActor.ShaddowMesh:SetMaterial(0, self.MaterialInst)
            end
        end
    end

    utils.DoDelay(self.actor, DelayTime, UpdateTrailFunc)
    
end


return TrailingComponent
