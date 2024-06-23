require "UnLua"
local table = require("table")
local G = require("G")

local OutlinerUtils = {}

function OutlinerUtils:LogInfo(...)
    G.log:info_obj(self, ...)
end

function OutlinerUtils:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function OutlinerUtils:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function OutlinerUtils:LogError(...)
    G.log:error_obj(self, ...)
end

function OutlinerUtils:SetOverlapActorOutline(Actor, bShow, StencilValue)
    -- 获取 Overlap 物件高亮
    if not Actor then
        return
    end
    local OverlappedActors = UE.TArray(UE.UObject)
    Actor:GetOverlappingActors(OverlappedActors)
    if Actor.RootSphere then
        local Radius = Actor.RootSphere.SphereRadius
        if Radius and Actor.RootSphere.SetSphereRadius then
            Actor.RootSphere:SetSphereRadius(Radius, true)
        end
    end
    
    for Index = 1, OverlappedActors:Length() do
        local OverActor = OverlappedActors:Get(Index)
        if OverActor and OverActor.StaticMeshComponent then
            local Name = OverActor.StaticMeshComponent:GetCollisionProfileName()
            if Name == "SmallObjectUnBreakable" then
                if bShow then
                    OverActor.StaticMeshComponent:SetRenderCustomDepth(true)
                    OverActor.StaticMeshComponent:SetCustomDepthStencilValue(StencilValue)
                else
                    OverActor.StaticMeshComponent:SetRenderCustomDepth(false)
                end
            end
        end
    end
end

function OutlinerUtils:SetActorOutline(bShow, Actor, StencilValue)
    if not Actor then
        return
    end

    if Actor.StaticMeshComponent then
        Actor.StaticMeshComponent:SetRenderCustomDepth(bShow)
        Actor.StaticMeshComponent:SetCustomDepthStencilValue(StencilValue)
    end

    if Actor.SkeletalMesh then
        Actor.SkeletalMesh:SetRenderCustomDepth(bShow)
        Actor.SkeletalMesh:SetCustomDepthStencilValue(StencilValue)
    end
end

function OutlinerUtils:GetOverlapSphereActor(Actor, Radius)
    if not Actor or not Radius then
        return
    end
    
    local ActorsToIgnore = UE.TArray(UE.AActor)
    local Targets = UE.TArray(UE.AActor)
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
    ObjectTypes:Add(UE.EObjectTypeQuery.ECC_WorldStatic)
    ObjectTypes:Add(UE.EObjectTypeQuery.ECC_WorldDynamic)
    ObjectTypes:Add(UE.EObjectTypeQuery.Destructible)

    UE.UHiCollisionLibrary.SphereOverlapActors(Actor, ObjectTypes, Actor:K2_GetActorLocation(),
            Radius, Radius, Radius, nil, ActorsToIgnore, Targets)
    
    return Targets
end

function OutlinerUtils:SetAreaAbilityOverlapSphereActorOutline(bShow,Actor,Radius,StencilValue,AreaAbility)
    self:LogInfo("ys","SetAreaAbilityOverlapSphereActorOutline : Actor = %s, Radius = %s, StencilValue = %s, AreaAbility = %s, bShow = %s", 
            Actor,Radius,StencilValue,Enum.E_AreaAbility.GetDisplayNameTextByValue(AreaAbility),bShow)

    if not bShow then
        --Clear outlined Actors
        if self.AreaAbilityUseOutlineActors then
            for k,v in pairs(self.AreaAbilityUseOutlineActors) do
                local CurActor = v
                if CurActor.SkeletalMesh then
                    CurActor.SkeletalMesh:SetRenderCustomDepth(false)
                end
                if CurActor.StaticMeshComponent then
                    CurActor.StaticMeshComponent:SetRenderCustomDepth(false)
                end
            end
        end

        return
    end

    --Check Parameters
    if not Actor or not Radius or not StencilValue or not AreaAbility then
        return
    end
    
    local Targets = self:GetOverlapSphereActor(Actor,Radius)
    
    local outlineTbl = {}
    for Ind = 1,Targets:Length() do
        local CurActor = Targets:Get(Ind)
        self:LogInfo("ys","Overlapping Actor Name = %s",G.GetDisplayName(CurActor))
        if CurActor.CheckResponseAreaAbilityType then
            if CurActor:CheckResponseAreaAbilityType(AreaAbility) then
                table.insert(outlineTbl,CurActor)
                if CurActor.SkeletalMesh then
                    CurActor.SkeletalMesh:SetRenderCustomDepth(true)
                    CurActor.SkeletalMesh:SetCustomDepthStencilValue(StencilValue)
                end
                if CurActor.StaticMeshComponent then
                    CurActor.StaticMeshComponent:SetRenderCustomDepth(true)
                    CurActor.StaticMeshComponent:SetCustomDepthStencilValue(StencilValue)
                end
            end
        end
    end
    self.AreaAbilityUseOutlineActors = outlineTbl
end

return OutlinerUtils
