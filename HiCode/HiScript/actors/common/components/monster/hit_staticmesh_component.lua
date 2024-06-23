require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local HitStaticMeshComponent = Component(ComponentBase)

local decorator = HitStaticMeshComponent.decorator


decorator.message_receiver()
function HitStaticMeshComponent:BeginRecordWhenHitStatic()
    -- G.log:debug("yj", "HitStaticMeshComponent:BeginRecordWhenHitStatic %s", self.actor:GetDisplayName())
    self.bBeginRecord = true
end

decorator.message_receiver()
function HitStaticMeshComponent:EndRecordWhenHitStatic()
    -- G.log:debug("yj", "HitStaticMeshComponent:EndRecordWhenHitStatic %s", self.actor:GetDisplayName())
    self.bBeginRecord = false
    self.HitTransforms:Clear()
end

decorator.message_receiver()
function HitStaticMeshComponent:HandleHitStaticMesh(HitResult, HitTransform)
    -- G.log:debug("yj", "HitStaticMeshComponent:HandleHitStaticMesh %s", self.actor:GetDisplayName())
    if not self.bBeginRecord then
        return
    end

    local HitComp = HitResult.Component
    if not HitComp then
        return
    end

    local HitActor = HitComp:GetOwner()
    -- G.log:debug("yj", "HitStaticMeshComponent:HandleHitStaticMesh Name.%s HasTag.%s", G.GetDisplayName(HitActor), HitActor:ActorHasTag("BrokenGroundPlaceHolder"))
    if not HitActor:ActorHasTag("BrokenGroundPlaceHolder") then
        return
    end

    -- G.log:debug("yj", "HitStaticMeshComponent:HandleHitStaticMesh HitTransform.%s Name.%s", HitTransform, G.GetDisplayName(HitActor))
    HitActor:K2_DestroyActor()
    self.HitTransforms:Add(HitTransform)
end

return HitStaticMeshComponent
