--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/04/19
--

---@type BP_SightPillarLogic_C
local os = require("os")
local table = require("table")
local math = require("math")

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.base.base_item")
local Loader = require("actors.client.AsyncLoaderManager")
local EdUtils = require("common.utils.ed_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
    self.sightpillarsActors = nil
    self.isActive = false
    self.now_round = 0
    self.isplaying = false
    self.is_finished = false
    self.now_playing_actor_index = {}
    self.ok_timecost = 0.0
end

function M:IsPlayer(OtherActor)
    local Owner = OtherActor:GetOwner()
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    return Owner == PlayerControl
end

function M:CanActive(OtherActor)
    if not self:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return false
    end
    return self:IsPlayer(OtherActor)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self.Box.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_Sphere)
    self.Box.OnComponentEndOverlap:Add(self, self.OnEndOverlap_Sphere)
end

function M:GetRoundNum()
    return #self.relist
end

function M:RandomTwo()
    -- 随机两个点，和上次的不一样
    if self.sightpillarsActors == nil then
        return 0, 0
    end
    local tab = {}
    for ind = 1, #self.sightpillarsActors do
       table.insert(tab, ind)
    end

    local index1, index2
    while true
    do
        math.randomseed(os.time())
        local random_ind1 = math.random(#tab)
        index1 = tab[random_ind1]
        table.remove(tab, index1)
        local random_ind2 = math.random(#tab)
        index2 = tab[random_ind2]
        --G.log:debug("zsf", "RandomTow %s %s", index1, index2)
        if not (self.now_playing_actor_index and #self.now_playing_actor_index == 2 and self.now_playing_actor_index[1] == index1 and self.now_playing_actor_index[2] == index2) then
            break
        end
    end
    return index1, index2
end

function M:AllChildReadyClient()
    self:LogInfo("zsf", "[sightpillarlogic] AllChildReadyClient")
    self:InitSightPillarsActors()
    Super(M).AllChildReadyClient(self)
end

function M:InitSightPillarsActors()
    if not self:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return
    end

    local ActorIDs = self:GetActorIds("RefreshList")
    self.relist = {}
    for ind=1,#ActorIDs,2 do
        k,v = ActorIDs[ind], ActorIDs[ind+1]
        --self:LogInfo("zsf", "[sightpillarlogic_lua] %s %s", k, v)
        table.insert(self.relist, {k, v})
    end

    self.sightpillarsActors = {}
    local cnt = 0
    for ind=1,#ActorIDs,1 do
        local EditorID = ActorIDs[ind]
        table.insert(self.sightpillarsActors, EditorID)
        cnt = cnt + 1
    end

    self:GotoNextRound()
end

function M:OnBeginOverlap_Sphere(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self:CanActive(OtherActor) then
        return
    end
    self.isActive = true
end

function M:OnEndOverlap_Sphere(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:CanActive(OtherActor) then
        return
    end
    --G.log:debug("zsf", "OnEndOverlap_Sphere")
    self.isActive = false
    --self.isplaying = false
    --self.now_round = 0
    --self.sightpillarsActors = nil
end

function M:ReceiveEndPlay()
    self.Box.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_Sphere)
    self.Box.OnComponentEndOverlap:Remove(self, self.OnEndOverlap_Sphere)
    self.now_round = 0
    self.is_finished = false
    self.sightpillarsActors = nil
    Super(M).ReceiveEndPlay(self)
end


function M:CheckFinish()
    --G.log:debug("zsf", "CheckFinish %s %s", self.now_round, self:GetRoundNum())
    return self.now_round > 1 and self.now_round > self:GetRoundNum()
end

function M:SetFinished()
    for ind = 1, #self.sightpillarsActors do
        local EditorId = self.sightpillarsActors[ind]
    end
    self:LogicComplete()
end

function M:MissionComplete(eMiniGame, sData)
   self:CallEvent_MissionComplete(sData)
end

function M:GetNextTwoPillarIndex()
    if self.now_round <= #self.relist then
        local data = self.relist[self.now_round]
        return tonumber(data[1]), tonumber(data[2])
    end
    return nil, nil
end

function M:GotoNextRound()
    self.isplaying = false
    self.now_round = self.now_round + 1
    self:LogInfo("zsf", "GotoNextRound %s %s", self.now_round, self:CheckFinish())
    if self:CheckFinish()then
        self.isplaying = false
        self:SetFinished()
        return
    end
    local ind1, ind2 = self:GetNextTwoPillarIndex()
    if ind1 == nil or ind2 == nil then
        return
    end
    self.now_playing_actor_index = {}
    table.insert(self.now_playing_actor_index, ind1)
    table.insert(self.now_playing_actor_index, ind2)
    for ind = 1, #self.sightpillarsActors do
        local index = self.sightpillarsActors[ind]
        local Actor = self:GetEditorActor(index)
        if tostring(index) == tostring(ind1) or
            tostring(index) == tostring(ind2) then
            Actor:SetAppear()
        end
    end
    self.isplaying = true
end

function M:GetPlayerCamera()
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    local Camera = PlayerControl.PlayerCameraManager
    --G.log:debug("zsf", "GetPlayerCamera %s", Camera)
    return Camera
end

function M:ValueInRange(Val)
    return Val > 0 and Val < 10
end

function M:DrawDebug(ActorFront, ActorBack)
    local Camera = self:GetPlayerCamera()
    local CameraLocation = Camera:GetCameraLocation()
    local BillboardFront = ActorFront.Billboard
    local FrontLocaiton = BillboardFront:K2_GetComponentLocation()
    local BillboardBack = ActorBack.Billboard
    local BackLocaiton = BillboardBack:K2_GetComponentLocation()

    local World = self:GetWorld()
    local Start = FrontLocaiton
    local End = BackLocaiton
    local ActorsToIgnore = UE.TArray(UE.AActor)
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    ActorsToIgnore:Add(Player)
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    ActorsToIgnore:Add(PlayerControl)
    local OutHit = UE.FHitResult()
    local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingle(World, Start, End,
            UE.ETraceTypeQuery.Visibility, false, ActorsToIgnore, UE.EDrawDebugTrace.ForDuration, OutHit, true,
            UE.FLinearColor(1, 0, 0, 1), UE.FLinearColor(0, 1, 0, 1), 5.0)

    local CameraTransform = Camera.TransformComponent
    local CameraForwardV = CameraTransform:GetForwardVector()
    local Start = CameraLocation
    local End = CameraLocation + CameraForwardV * 100.0
    local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingle(World, Start, End,
            UE.ETraceTypeQuery.Visibility, false, ActorsToIgnore, UE.EDrawDebugTrace.ForDuration, OutHit, true,
            UE.FLinearColor(1, 0, 0, 1), UE.FLinearColor(0, 1, 0, 1), 5.0)

    local ActorDir = FrontLocaiton - BackLocaiton
    local Dis = UE.UKismetMathLibrary.GetPointDistanceToLine(CameraLocation, BackLocaiton, ActorDir)
    CameraForwardV = UE.UKismetMathLibrary.Normal(CameraForwardV)
    ActorDir = UE.UKismetMathLibrary.Normal(ActorDir)
    local Degree = UE.UKismetMathLibrary.DegACos(UE.UKismetMathLibrary.Dot_VectorVector(CameraForwardV, ActorDir))

    G.log:debug("zsf", "DrawDebug 111 %s %s %s %s", Dis, Degree, G.GetObjectName(ActorFront), G.GetObjectName(ActorBack))
end

function M:CheckOK(ActorFront, ActorBack)
    --self:DrawDebug(ActorFront, ActorBack)
    local Camera = self:GetPlayerCamera()
    local CameraLocation = Camera:GetCameraLocation()
    local BillboardFront = ActorFront.Billboard
    local FrontLocaiton = BillboardFront:K2_GetComponentLocation()
    FrontLocaiton.z = FrontLocaiton.z + ActorFront:GetHeight()
    local BillboardBack = ActorBack.Billboard
    local BackLocaiton = BillboardBack:K2_GetComponentLocation()
    BackLocaiton.z = BackLocaiton.z + ActorBack:GetHeight()

    local World = self:GetWorld()
    local Start = CameraLocation
    local End = BackLocaiton
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(ActorFront)
    ActorsToIgnore:Add(ActorBack)
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    ActorsToIgnore:Add(Player)
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    ActorsToIgnore:Add(PlayerControl)
    local OutHit = UE.FHitResult()
    local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingle(World, Start, End,
            UE.ETraceTypeQuery.WorldStatic, false, ActorsToIgnore, UE.EDrawDebugTrace.None, OutHit, true,
            UE.FLinearColor(1, 0, 0, 1), UE.FLinearColor(0, 1, 0, 1), 5.0)
    if ReturnValue then -- 中间有阻挡不行, 这个射线检测和摄像机的朝向无关
        local HitActor = OutHit.HitObjectHandle.Actor
        local Name = G.GetObjectName(HitActor)
        --self:LogInfo("zsf", "CheckOK 111 %s %s %s", Name, G.GetObjectName(ActorFront), G.GetObjectName(ActorBack))
        self.ok_timecost = 0.0
        return false
    end

    local ActorDir = FrontLocaiton - BackLocaiton
    local Dis = UE.UKismetMathLibrary.GetPointDistanceToLine(CameraLocation, BackLocaiton, ActorDir)
    if Dis > 10.0 then -- 摄像机位置到两个物体连线的直线的距离在一定范围内才能看到, 这个20可以改成可配置
        --self:LogInfo("zsf", "CheckOK 333 %s %s %s", Dis, G.GetObjectName(ActorFront), G.GetObjectName(ActorBack))
        self.ok_timecost = 0.0
        return false
    end

    local CameraTransform = Camera.TransformComponent
    local CameraForwardV = CameraTransform:GetForwardVector()
    CameraForwardV = UE.UKismetMathLibrary.Normal(CameraForwardV)
    ActorDir = UE.UKismetMathLibrary.Normal(ActorDir)
    local Degree = UE.UKismetMathLibrary.DegACos(UE.UKismetMathLibrary.Dot_VectorVector(CameraForwardV, ActorDir))
    if Degree < 150 then -- 摄像机朝向要大致在一个方向上能认为是对上的，需要支持配置
        --self:LogInfo("zsf", "CheckOK 222 %s %s %s", Name, G.GetObjectName(ActorFront), G.GetObjectName(ActorBack))
        self.ok_timecost = 0.0
        return false
    end

    self:LogInfo("zsf", "CheckOK %s %s %s %s %s", self.now_round, self:GetRoundNum(), ActorFront:GetDisplayName(), ActorBack:GetDisplayName(), self.ok_timecost)

    self.ok_timecost = self.ok_timecost + 0.2
    -- 里对其了需要维持 1~2s 才能通过当前
    local bComplete = self.ok_timecost > 2.0
    return true, bComplete
end

function M:FindActor(index_)
    for ind = 1, #self.sightpillarsActors do
        local index = self.sightpillarsActors[ind]
        if tostring(index) == tostring(index_) then
            return self:GetEditorActor(index)
        end
    end
end

function M:GetFrontAndBackActor()
    -- 根据缩放确定前后, 近大远小，所以前小远大； 因为是等比缩放可以直接根据 Length 判断
    local Actor1 = self:FindActor(self.now_playing_actor_index[1])
    local Actor2 = self:FindActor(self.now_playing_actor_index[2])
    if not Actor1 or not Actor2 then
        return nil, nil
    end
    local Billboard1 = Actor1.Billboard
    local Scale1 = Billboard1:K2_GetComponentScale()
    local Billboard2 = Actor2.Billboard
    local Scale2 = Billboard2:K2_GetComponentScale()
    if Actor2.bFront then
        return Actor2, Actor1
    else
        return Actor1, Actor2
    end
end

function M:SetOK(ActorFront, ActorBack, bOk, bComplete)
    ActorFront:SetOK(bOk, bComplete)
    ActorBack:SetOK(bOk, bComplete)
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
    if not self:IsReady() then
        return
    end
    if not self:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self) and not self.isActive then
        return
    end
    --self:LogInfo("zsf", "[sightpillarlogic] ReceiveTick %s %s %s %s %s", #self.sightpillarsActors, self.is_finished, self:CheckFinish(), self.now_round, #self.now_playing_actor_index)
    if self.sightpillarsActors == nil or self.is_finished then
        return
    end
    if self:CheckFinish() then
        return
    end
    if self.now_round ~= 0 then
        if #self.sightpillarsActors >= 2 and #self.now_playing_actor_index == 2 then
            local ActorFront, ActorBack = self:GetFrontAndBackActor()
            if ActorFront and ActorBack then
                local bOk, bComplete = self:CheckOK(ActorFront, ActorBack)
                self:SetOK(ActorFront, ActorBack, bOk, bComplete)
                if self.isplaying and bComplete then
                    self.ok_timecost = 0.0
                    self:GotoNextRound()
                end
            end
        end
    end
end

return M