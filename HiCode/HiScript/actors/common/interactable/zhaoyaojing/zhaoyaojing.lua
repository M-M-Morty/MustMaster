--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/03/23
--

---@type BP_GXMirror2_C
local G = require("G")
local os = require("os")
local table = require("table")

require "UnLua"
local ActorBase = require("actors.common.interactable.base.interacted_item")

local M = Class(ActorBase)

function M:CanActive(OtherActor)
    if not self:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return false
    end
    local Owner = OtherActor:GetOwner()
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    --G.log:debug("zsf", "CanActive %s %s %s %s %s %s", self:IsClient(), self:IsServer(), Owner:GetDisplayName(), Owner, PlayerControl, Owner==PlayerControl)
    return Owner == PlayerControl
end

function M:ResetAlTreasure()
    --[[
        退出触发范围之后，把所有宝箱设置为初始状态
    ]]--
    if self.ChestActorIds then
        for ind = 1, #self.ChestActorIds do
            local EditorID = self.ChestActorIds[ind]
            local Actor = self:GetEditorActor(EditorID)
            if Actor then
                if Actor.bFake then
                    self:ShowTreasureEffect(Actor, false)
                end
            end
        end
    end
end

function M:Initialize(...)
    Super(M).Initialize(self, ...)
    self.time_duration = 0.0
    self.direrctionVs = {
        UE.FVector(1.0, 1.0, 1.0),
        UE.FVector(1.0, 1.0, -1.0),
        UE.FVector(1.0, -1.0, 1.0),
        UE.FVector(1.0, -1.0, -1.0),
        UE.FVector(-1.0, 1.0, 1.0),
        UE.FVector(-1.0, 1.0, -1.0),
        UE.FVector(-1.0, -1.0, 1.0),
        UE.FVector(-1.0, -1.0, -1.0),
    }
    self.OldMirrorRotator = nil
    self.ActorId2Effect = {}
    self.WayPointKey = "WayPoint"
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self.SK_Prop_ButterflyMirror_02:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    self.Sphere1.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_Target)
    self.Sphere1.OnComponentEndOverlap:Add(self, self.OnEndOverlap_Target)
end

function M:OnBeginOverlap_Target(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if self.NPCMoveViaPoint and self.NPCMoveViaPoint.bGotoTarget and OtherActor == self then
        self:LogInfo('zsf', '[zhaoyaojing] OnBeginOverlap_Sphere %s', G.GetDisplayName(OtherActor))
        self.SK_Prop_ButterflyMirror_02:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        self:PlayButterflyChangeAnim()
        self.Butterfly:SetHiddenInGame(true)
    end
end

function M:OnEndOverlap_Target(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)

end

function M:IsZhaoYaoJing()
    return true
end

function M:Multicast_Event_PlayChangeAnim_RPC()
    if self.bFinishChangeAnim then
        return
    end
    self.bFinishChangeAnim = true
    if self:IsClient() then
        local ChildActor = self.ChaosCacheManager.ChildActor
        self:LogInfo("zsf", "[zhaoyaojing] Event_PlayChangeAnim_RPC %s %s %s", ChildActor, ChildActor.ActorSequence, self.bActive)
        self.ActorSequence.SequencePlayer:Play()
        ChildActor.ActorSequence.SequencePlayer:Play()
        utils.DoDelay(self:GetWorld(), 2.5,
function()
                self.ActorSequence.SequencePlayer:StopAtCurrentTime()
                ChildActor.ActorSequence.SequencePlayer:StopAtCurrentTime()
                self:PlayChangeEffect()
                ChildActor.JingMian_GeometryCollection:SetHiddenInGame(false)
                self.Butterfly:SetVisibility(false, true)
                self.Sphere:SetSphereRadius(1000, true)
                self.bActive = true
                self:LogicComplete2(tostring(Enum.E_MirrorStatus.Triggered))
           end)
    end
end

function M:PlayButterflyChangeAnim()
    self.Sphere:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    self:Multicast_Event_PlayChangeAnim()
end

function M:PlayChangeEffect()
    --local Children = UE.TArray(UE.USceneComponent)
    --self.NS:GetChildrenComponents(true, Children)
    --for ind=1,Children:Length() do
    --    local Child = Children:Get(ind)
    --    self:LogInfo("zsf", "[zhaoyaojing] PlayChangeEffect %s", Child)
    --    Child:SetActive(true, true)
    --end
end

function M:ChildReadyNotify(ActorId)
    self:LogInfo("zsf", "[zhaoyaojing] ChildReadyNotify %s", ActorId)
    if self.NPCMoveViaPoint then
        self.NPCMoveViaPoint:ChildReadyNotify(ActorId)
    end
end

function M:UpdateOwnerLocationAndRotation(Location, Rotator)
    --self:LogInfo("zsf", "[zhaoyaojing] UpdateOwnerLocationAndRotation %s %s", Location, Rotator)
    self.Sphere:K2_SetWorldLocationAndRotation(Location, Rotator, false, nil, false)
    --local HitResult = UE.FHitResult()
    --local TrailingLocation = self:GetTrainlingLocation()
    --self.Trailing:K2_SetWorldLocation(TrailingLocation, false, HitResult, false)
end

function M:AllChildReadyServer()
    local IDs = self:GetActorIds("RelatedActors")
    self:LogInfo("zsf", "[zhaoyaojing] AllChildReadyServer %s %s", IDs, #IDs)
    self.RealChestActors = {}
    for ind=1,#IDs do
        local EditorID = IDs[ind]
        local Actor = self:GetEditorActor(EditorID)
        if Actor then
            if Actor.MakeMainActor then
                Actor:MakeMainActor(self)
                self:LogInfo("zsf", "[zhaoyaojing] AllChildReadyServer %s %s %s", EditorID, G.GetDisplayName(Actor), not Actor.bFake)
            end
            if not Actor.bFake then
                table.insert(self.RealChestActors, EditorID)
            end
        end
    end
    Super(M).AllChildReadyServer(self)
end

function M:AllChildReadyClient()
    local IDs = self:GetActorIds("RelatedActors")
    self:LogInfo("zsf", "[zhaoyaojing] AllChildReadyClient %s %s", IDs, #IDs)
    self.ChestActorIds = IDs
    for ind=1,#IDs do
        local EditorID = IDs[ind]
        local Actor = self:GetEditorActor(EditorID)
        --if Actor and Actor.bFake then
        --    Actor:SetActorHiddenInGame(true)
        --end
    end
    Super(M).AllChildReadyClient(self)
end

function M:ChildTriggerMainActor(ChildActor)
    local EditorID = ChildActor:GetEditorID()
    if self.RealChestActors then
        for i,eId in ipairs(self.RealChestActors) do
            if eId == EditorID then
                table.remove(self.RealChestActors, i)
            end
        end
    end
    self:LogInfo("zsf", "[zhaoyaojing] ChildTriggerMainActor %s %s %s", EditorID, G.GetDisplayName(ChildActor), #self.RealChestActors)
    if #self.RealChestActors == 0 then
        utils.DoDelay(self:GetWorld(), 2.5,
                function()
            self:Multicast_OpenAllRealChest()
        end)
    end
end

function M:Multicast_OpenAllRealChest_RPC()
    self:LogInfo("zsf", "[zhaoyaojing] Multicast_OpenAllRealChest_RPC")
    self.bActive = false
    if self:IsClient() then
        local ChildActor = self.ChaosCacheManager.ChildActor
        --ChildActor.ActorSequence.SequencePlayer:PlayReverse()
    else
        self:LogicComplete2(tostring(Enum.E_MirrorStatus.Completed))
    end
end

function M:Multicast_ReceiveDamage_RPC(PlayerActor, InteractLocation, bAttack)
    self:LogInfo("zsf", "[zhaoyaojing] Multicast_ReceiveDamage_RPC")
    self:Client_RemoveInitationScreenUI()
    if self.NPCMoveViaPoint then
        self:SetInteractable(Enum.E_InteractedItemStatus.UnInteractable)
        local StartLocation = self.NPCMoveViaPoint.startLocation
        self.NPCMoveViaPoint:SetGotToTarget(StartLocation)
    end
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
    self.Sphere1.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_Target)
    self.Sphere1.OnComponentEndOverlap:Remove(self, self.OnEndOverlap_Target)
end

function M:GetPlayerLocation()
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    return Player:K2_GetActorLocation()
end

function M:GetPlayerBounds()
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    local Origin, BoxExtent = Player:GetActorBounds()
    return Origin, BoxExtent
end

function M:GetPlayerCamera()
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    local Camera = PlayerControl.PlayerCameraManager
    return Camera
end

function M:GetYPitch()
   --[[ 获取在Y轴的倾斜计算 ]]--
    local PlayerLocation = self:GetPlayerLocation()
    local Origin, BoxExtent = self:GetPlayerBounds()
    local PlayerFootLocation = PlayerLocation - BoxExtent
    local ActorLocation = self:K2_GetActorLocation()
    local TowardsFootV = PlayerFootLocation - ActorLocation
    TowardsFootV = UE.UKismetMathLibrary.Normal(TowardsFootV)
    local HorV = self.RootSphere:GetForwardVector()
    HorV = UE.UKismetMathLibrary.Normal(HorV)
    local ZOffset = ActorLocation.z - PlayerLocation.z
    local ZOffsetAbs = UE.UKismetMathLibrary.Abs(ZOffset)
    local isHor = UE.UALSMathLibrary.AngleInRange(ZOffsetAbs, 0, 100.0, 0.0, false)
    if isHor then
        return 0.0
    else
        local Factor = (ZOffset > 0.0) and -1.0 or 1.0
        local Angle2Player = UE.UKismetMathLibrary.DegAcos(UE.UKismetMathLibrary.Dot_VectorVector(TowardsFootV, HorV)) * Factor
        local Val = UE.UKismetMathLibrary.FClamp(Angle2Player, -15.0, 15.0)
        return Val
    end
end

function M:GetXRollAndZYaw()
    local PlayerLocation = self:GetPlayerLocation()
    local ActorLocation = self:K2_GetActorLocation()
    local ForwardV = PlayerLocation - ActorLocation
    local Rotator = UE.UKismetMathLibrary.MakeRotationFromAxes(ForwardV,UE.FVector(0.0,0.0,0.0), UE.FVector(0.0,0.0,0.0))
    return Rotator
end

function M:GetTreasureAllPoints(TreasureActor)
    --[[获取宝箱 Bouding 所有8个点+中心点的坐标用于测试可见性]]--
    local Points = {}
    local TreasureActorLoction = TreasureActor:K2_GetActorLocation()
    table.insert(Points, TreasureActorLoction)
    local Origin, BoxExtent, SphereRadius = UE.UKismetSystemLibrary.GetComponentBounds(TreasureActor.SkeletalMesh)
    --self:LogInfo("zsf", "[zhaoyaojing] GetTreasureAllPoints %s %s %s", TreasureActor, BoxExtent, Origin)
    for ind=1,#self.direrctionVs do
        local dir = self.direrctionVs[ind]
        table.insert(Points, Origin + UE.UKismetMathLibrary.Multiply_VectorVector(dir, BoxExtent))
    end
    return Points
end

function M:GetMirrorComponent()
    local ChildActor = self.ChaosCacheManager.ChildActor
    return ChildActor.JingMian_GeometryCollection
end

function M:IsInReflection(TreasureActor, Point)
    --[[
        根据平凡反射数学公式计算当前点是否在镜面中显示
        使用射线可以测试使用有阻挡关系
    ]]--
    local PlaneLocation = self:GetMirrorComponent():K2_GetComponentLocation()
    local PlaneUpV = self:GetMirrorComponent():GetForwardVector()
    PlaneUpV = UE.UKismetMathLibrary.Normal(PlaneUpV)
    local FPlane = UE.UKismetMathLibrary.MakePlaneFromPointAndNormal(PlaneLocation, PlaneUpV)
    local Camera = self:GetPlayerCamera()
    local CameraLocation = Camera:GetCameraLocation()
    local MirrorToPlane = UE.UKismetMathLibrary.Vector_MirrorByPlane(Point, FPlane)

    local World = self:GetWorld()
    local Start = CameraLocation
    local End = MirrorToPlane
    local ActorsToIgnore = UE.TArray(UE.AActor)
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    ActorsToIgnore:Add(Player)
    ActorsToIgnore:Add(TreasureActor)
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    ActorsToIgnore:Add(PlayerControl)
    local OutHit = UE.FHitResult()
    local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingle(World, Start, End,
            UE.ETraceTypeQuery.Visibility, false, ActorsToIgnore, UE.EDrawDebugTrace.None, OutHit, true,
            UE.FLinearColor(1, 0, 0, 1), UE.FLinearColor(0, 1, 0, 1), 5.0)
    if not ReturnValue then
        return false
    end
    local HitActor = OutHit.HitObjectHandle.Actor
    --G.log:debug("zsf", "IsInReflection111 %s", HitActor)
    local Name = G.GetObjectName(HitActor)
    --G.log:debug("zsf", "IsInReflection222 %s %s", HitActor, Name)
    if not UE.UKismetStringLibrary.StartsWith(Name, "BP_GXMirror") then
        return false
    end
    local ImpactPoint = OutHit.ImpactPoint
    local ImpactNormal = OutHit.ImpactNormal
    local V = UE.UKismetMathLibrary.Subtract_VectorVector(CameraLocation, ImpactPoint)
    --G.log:debug("zsf", "IsInReflection111 %s %s %s %s", Name, CameraLocation, ImpactPoint, V)
    local VToPlane = UE.UKismetMathLibrary.ProjectVectorOnToPlane(V, ImpactNormal)
    local A = VToPlane * 2.0 - V
    A = UE.UKismetMathLibrary.Normal(A)
    local V2 = MirrorToPlane - CameraLocation
    V2 = UE.UKismetMathLibrary.Normal(V2)
    local degree = UE.UKismetMathLibrary.RadiansToDegrees(UE.UKismetMathLibrary.Dot_VectorVector(A, V2))
    --self:LogInfo("zsf", "[zhaoyaojing] IsInReflection %s %s", Name, degree)
    return degree < 90.0
end

function M:IsCameraAnti()
    --[[相机朝向是否和镜面相同，相同则是背对]]--
    local PlaneUpV = self:GetMirrorComponent():GetUpVector()
    PlaneUpV = UE.UKismetMathLibrary.Normal(PlaneUpV)
    local Camera = self:GetPlayerCamera()
    local CameraTransform = Camera.TransformComponent
    local CameraForwardV = CameraTransform:GetForwardVector()
    CameraForwardV = UE.UKismetMathLibrary.Normal(CameraForwardV)
    local degree = UE.UKismetMathLibrary.RadiansToDegrees(UE.UKismetMathLibrary.Dot_VectorVector(PlaneUpV, CameraForwardV))
    --G.log:debug("zsf", "IsCameraAnti %s", degree)
    return degree < 0.0
end

function M:ShowTreasureEffect(TreasureActor, isIn)
    --TreasureActor:SetActorHiddenInGame(not isIn)
    if not TreasureActor.FakeEffect then
        return
    end
    if isIn and not TreasureActor.bFakeTriggered then
        TreasureActor.FakeEffect:SetVisibility(true)
        TreasureActor.FakeEffect:SetActive(true)
    else
        TreasureActor.FakeEffect:SetVisibility(false)
    end
end

function M:SetTreasureStatus(TreasureActor)
    --[[设置宝箱状态]]--
    local isIn = false
    local Points = self:GetTreasureAllPoints(TreasureActor)
    for ind=1,#Points do
        local Point = Points[ind]
        local isReflection = self:IsInReflection(TreasureActor, Point)
        if isReflection then
            isIn = true
            break
        end
    end
    --[[ 根据当前相机朝向设置可见性 ]]--
    isIn = isIn and self:IsCameraAnti()
    self:ShowTreasureEffect(TreasureActor, isIn)
    --self:LogInfo("zsf", "[zhaoyaojing] ShowTreasureEffect %s %s", TreasureActor:GetDisplayName(), isIn)
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
    if not self:IsReady() then
        return
    end
    if not self.bActive then
        return
    end
    if not self:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return
    end

    local Rotator = self:GetXRollAndZYaw()
    local Pitch = self:GetYPitch()
    local NewRotator = UE.UKismetMathLibrary.MakeRotator(Rotator.Roll, Pitch, Rotator.Yaw)
    local SelfRotator = self.RootSphere:K2_GetComponentRotation()
    local LerpRotator = UE.UKismetMathLibrary.RLerp(SelfRotator, NewRotator, 0.2, true)
    --TODO: 这个把镜子旋转起来之后会很耗性能，晚点看看怎么优化下; 反射的东西越多越卡顿
    if not UE.UKismetMathLibrary.EqualEqual_RotatorRotator(self.OldMirrorRotator, LerpRotator, 0.1) then
        --G.log:debug("zsf", "ReceiveTick 111")
        self.RootSphere:K2_SetWorldRotation(LerpRotator, false, UE.FHitResult(), false)
        self.OldMirrorRotator = LerpRotator
        --self.RootSphere:K2_SetWorldRotation(UE.UKismetMathLibrary.MakeRotator(Rotator.Roll, 0.0, Rotator.Yaw), false, UE.FHitResult(), false)
    end
    if self.ChestActorIds then
        for ind = 1, #self.ChestActorIds do
            local EditorID = self.ChestActorIds[ind]
            local Actor = self:GetEditorActor(EditorID)
            if Actor then
                if Actor.bFake then
                    self:SetTreasureStatus(Actor)
                end
            end
        end
    end
end

function M:SetWayPointActor(WayPointActor)
    self[self.WayPointKey] = UE.FSoftObjectPtr(WayPointActor)
    --self[self.WayPointKey] = WayPointActor
end

return M
