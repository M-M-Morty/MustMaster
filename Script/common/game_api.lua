local G = require("G")

local GameAPI = {}

GameAPI.SpawnActor = function(World, Class, Tranform, SpawnParameters, ExtraData, ExtraSpawnOp)
    assert(Class ~= nil, "GameAPI.SpawnActor Class is nil")
    local bDeferConstruction = SpawnParameters.bDeferConstruction
    if ExtraData then
        SpawnParameters.bDeferConstruction = true
    end
    local actor
    local bStaticMesh = Class:IsA(UE.UStaticMesh)
    if bStaticMesh then
        actor = World:SpawnStaticMeshActor(Class, Tranform, SpawnParameters)
    else
        actor = World:SpawnActorEx(Class, Tranform, nil, nil, SpawnParameters)
    end
    if ExtraData then
        for k, v in pairs(ExtraData) do
            actor[k] = v
        end
    end
    if ExtraSpawnOp then
        ExtraSpawnOp(actor)
    end
    if not bStaticMesh then
        if SpawnParameters.bDeferConstruction and not bDeferConstruction then
            UE.UGameplayStatics.FinishSpawningActor(actor, Tranform)
        end
    end

    return actor

end

GameAPI.IsPlayer = function(actor)
    local LocalRole = actor:GetLocalRole() == UE.ENetRole.ROLE_AutonomousProxy
    local StandAlone = UE.UKismetSystemLibrary.IsStandalone(actor)
    return LocalRole or StandAlone
end

local __server_actor_list__ = {}

local __client_actor_list__ = {}

local __server_actor_tag_list__ = {}

local __client_actor_tag_list__ = {}

GameAPI.__AddActor__ = function(actor)
    if actor:IsServer() then
        table.insert(__server_actor_list__, actor)
    else
        table.insert(__client_actor_list__, actor)
    end

    local tag_list = nil
    if actor:IsServer() then
        tag_list = __server_actor_tag_list__
    else
        tag_list = __client_actor_tag_list__
    end

    for Ind = 1, actor.Tags:Length() do
        local Tag = actor.Tags:Get(Ind)
        if tag_list[Tag] == nil then
            tag_list[Tag] = {}
        end
        table.insert(tag_list[Tag], actor)
    end
end

GameAPI.__RemoveActor__ = function(actor)
    local __actor_list__ = __client_actor_list__
    if actor:IsServer() then
        __actor_list__ = __server_actor_list__
    end

    for index, v in ipairs(__actor_list__) do
        if actor == v then
            table.remove(__actor_list__, index)
        end
    end

    local tag_list = nil
    if actor:IsServer() then
        tag_list = __server_actor_tag_list__
    else
        tag_list = __client_actor_tag_list__
    end

    for Ind = 1, actor.Tags:Length() do
        local Tag = actor.Tags:Get(Ind)
        if tag_list[Tag] == nil then
            tag_list[Tag] = {}
        end
        for index, v in ipairs(tag_list[Tag]) do
            if actor == v then
                table.remove(tag_list[Tag], index)
                break
            end
        end
    end
end

GameAPI.GetActors = function(WorldContext)
    assert(WorldContext)
    local server = UE.UKismetSystemLibrary.IsDedicatedServer(WorldContext)
    if server then
        return __server_actor_list__
    else
        return __client_actor_list__
    end
end

GameAPI.GetActorsWithTag = function(WorldContext, Tag)
    assert(WorldContext)
    local server = UE.UKismetSystemLibrary.IsDedicatedServer(WorldContext)
    if server then
        return __server_actor_tag_list__[Tag] or {}
    else
        return __client_actor_tag_list__[Tag] or {}
    end
end

GameAPI.GetActorsWithTags = function(WorldContext, Tags)
    local ret = {}
    for i = 1, Tags:Length() do
        local Tag = Tags:Get(i)
        local Actors = GameAPI.GetActorsWithTag(WorldContext, Tag)
        if Actors then
            utils.merge_array(ret, Actors)
        end
    end

    return ret
end

GameAPI.AimingMode_Raycast = function(X, Y, TraceChannel)
    local WorldContext = G.GameInstance:GetWorld()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(WorldContext, 0)
    
    local WorldLocation, WorldDirection = PlayerController:DeprojectScreenPositionToWorld(X, Y)

    local Start = WorldLocation
    local End = Start + WorldDirection * 100000

    local ActorsToIgnore = UE.TArray(UE.AActor)
    local OutHit = UE.FHitResult()
    local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingle(WorldContext, Start, End, 
                                                                TraceChannel, true, ActorsToIgnore, UE.EDrawDebugTrace.None, OutHit, true,
                                                                UE.FLinearColor(1, 0, 0, 1), UE.FLinearColor(0, 1, 0, 1), 20)

    if ReturnValue then
        return OutHit.HitObjectHandle.Actor
    else
        return nil
    end
end

GameAPI.AimingMode_CrossRaycast = function()
    local WorldContext = G.GameInstance:GetWorld()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(WorldContext, 0)

    local X, Y = PlayerController:GetViewportSize()

    return GameAPI.AimingMode_Raycast(X * 0.5, Y * 0.5, UE.ETraceTypeQuery.FluidTrace)
end

_G.GameAPI = GameAPI

return GameAPI