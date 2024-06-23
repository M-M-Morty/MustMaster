require "UnLua"

local G = require("G")

Loader = {}
local HandleCounter = 0
local HandleToAction = {}
local ActionToHandle = {}
local HandleToCallback = {}

function GetHandle()
    HandleCounter = HandleCounter + 1
    return HandleCounter
end

function RecordHandleActionCallback(Handle, Action, Callback)
    ActionToHandle[Action] = Handle
    HandleToAction[Handle] = Action
    HandleToCallback[Handle] = Callback
end

function Loader:AsyncLoadActor(AssetPath, OnLoadComplete, FromActor)
    G.log:info("[lz]", "Async Load Actor [%s]", AssetPath)
    local InActor = G.GameInstance
    if FromActor ~= nil then
        InActor = FromActor
    end
    local ActorAsyncAction = UE.UAsyncAction_CreateActorAsync.CreateActorAsyncInLua(InActor:GetWorld(), AssetPath)
    local NewHandle = GetHandle()
    RecordHandleActionCallback(NewHandle, ActorAsyncAction, OnLoadComplete)
    ActorAsyncAction.OnComplete:Add(InActor, Loader:OnCompleted(NewHandle))
    ActorAsyncAction:Activate()
    return NewHandle
end

function Loader:AsyncLoadWidget(AssetPath, OnLoadComplete)
    G.log:info("[lz]", "Async Load UI Widget [%s]", AssetPath)
    local ActorAsyncAction = UE.UAsyncAction_CreateWidgetAsync.CreateWidgetAsyncInLua(G.GameInstance:GetWorld(), AssetPath)
    local NewHandle = GetHandle()
    RecordHandleActionCallback(NewHandle, ActorAsyncAction, OnLoadComplete)
    ActorAsyncAction.OnComplete:Add(G.GameInstance, Loader:OnCompleted(NewHandle))
    ActorAsyncAction:Activate()
    return NewHandle
end

function Loader:AsyncLoadAsset(AssetPath, OnLoadComplete)
    G.log:info("[lz]", "Async Load Actor [%s]", AssetPath)
    local AssetAsyncAction = UE.UAsyncAction_CreateAssetAsync.CreateAssetAsyncUsePath(G.GameInstance:GetWorld(), AssetPath)
    local NewHandle = GetHandle()
    RecordHandleActionCallback(NewHandle, AssetAsyncAction, OnLoadComplete)
    AssetAsyncAction.OnComplete:Add(G.GameInstance, Loader:OnCompleted(NewHandle))
    AssetAsyncAction:Activate()
    return NewHandle
end

function Loader:CancelAsyncLoadTask(Handle)
    local Action = HandleToAction[Handle]
    G.log:info("[lz]", "Cancel Loading Task [%s] [%s]", Handle, Action)
    if Action then
        Action:Cancel()
        ActionToHandle[Action] = nil
    end
    HandleToAction[Handle] = nil
    HandleToCallback[Handle] = nil
end

function Loader:OnCompleted(Handle)
    function _OnCompleted(ld, Object)
        local Callback = HandleToCallback[Handle]
        HandleToCallback[Handle] = nil

        local Action = HandleToAction[Handle]
        HandleToAction[Handle] = nil
        ActionToHandle[Action] = nil
        G.log:info('[lz]', 'Loading Task Complete [%s][%s]', Action, Callback)
        if Callback then
            Callback(Object)
        end
    end
    return _OnCompleted
end

------------------------------------------------------------------------------------
--unit test                                                                       --
------------------------------------------------------------------------------------

function Loader:TestLoaderAsyncLoadActor()
    function OnLoadCallback(Actor)
        G.log:info("[lz]", "on load actor callback in test %s", Actor)
        local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
        local Location = Player:K2_GetActorLocation() + UE.FVector(-300, 0, 0)
        Actor:K2_SetActorLocation(Location, false, nil, true)
    end
    local SkeletonActorPath = '/Game/Test/Characters/Test_Character/Boss/ParagonGrux/Characters/Heroes/Grux/Skins/Tier_2/Grux_Beetle_Molten/Meshes/GruxMolten.GruxMolten'
    Loader:AsyncLoadActor(SkeletonActorPath, OnLoadCallback)
end

function Loader:TestLoaderAsyncLoadWidget()
    function OnLoadCallback(Widget)
        G.log:info("[lz]", "on load widget callback in test %s", Widget)
    end

    local WidgetPath = '/Game/Test/TransportBetweenMapsDemo/Loading.Loading' --blueprint
    Loader:AsyncLoadWidget(WidgetPath, OnLoadCallback)
end

function Loader:TestLoaderChangeActorMaterial() 

    function OnLoadCallback(mtl)
        if mtl == nil then
            return
        end
        function OnActorLoad(Actor)
            if Actor == nil then
                return
            end
            local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
            local Location = Player:K2_GetActorLocation() + UE.FVector(-300, 0, 0)
            Actor:K2_SetActorLocation(Location, false, nil, true)
            local MaterialInstance = UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(0, mtl)
            local StaticMeshComponents = Actor:K2_GetComponentsByClass(UE.UStaticMeshComponent)
            for i = 1, StaticMeshComponents:Length() do
                StaticMeshComp = StaticMeshComponents:Get(i)
                StaticMeshComp:SetMaterial(0, MaterialInstance)
            end
        end 
        local MeshActorPath = '/Game/Test/SimpleMesh/CubeA.CubeA'
        Loader:AsyncLoadActor(MeshActorPath, OnActorLoad)
    end
    local MaterialPath = '/Game/Test/SimpleMesh/WorldGridMaterial.WorldGridMaterial'
    Loader:AsyncLoadAsset(MaterialPath, OnLoadCallback)
end

return Loader