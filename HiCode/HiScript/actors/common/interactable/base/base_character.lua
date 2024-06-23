--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/05/15
--

---@type

require "UnLua"
local G = require("G")
local Character = require("actors.common.Character")
local EdUtils = require("common.utils.ed_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")
local utils = require("common.utils")

local M = Class(Character)


function M:LogInfo(...)
    G.log:info_obj(self, ...)
end

function M:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function M:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function M:LogError(...)
    G.log:error_obj(self, ...)
end

function M:Initialize(...)
    Super(M).Initialize(self, ...)
    self.JsonObject = nil
    self.ActorIdList = {}
    self.CompIdList = {}
    self.MainActor = nil
    self.NPCMoveViaPointComponent = nil
end


function M:IsReady()
    -- 定义在 BP_BaseItem 中;  会在 Server 和 Client 同步
    -- 如果存在关联的 Actor, 所有关联的 Actor Spawn 出来才是设置成 true;
    return self.bReady
end

function M:MergeToActorIdList(IdList, CompName)
    for _,EdiorId in ipairs(IdList) do
        local ActorId = self:GetActorIdBase(EdiorId)
        if CompName~="" then -- Is ActorComponent
            if not self.CompIdList[CompName] then
                self.CompIdList[CompName] = {}
            end
            self.CompIdList[CompName][ActorId] = false
        end
        if not self.ActorIdList[ActorId] then
            self:LogInfo("zsf", "[base_character] MergeToActorIdList %s %s %s", ActorId, self:GetEditorID(), G.GetDisplayName(self))
            self.ActorIdList[ActorId] = false
        end
    end
end

function M:GetJsonObject()
    return self.JsonObject
end

function M:GetEditorDataComp()
    local HiEditorDataCompClass = UE.UClass.Load(BPConst.HiEditorDataComp)
    local HiEditorDataComp = self:GetComponentByClass(HiEditorDataCompClass)
    return HiEditorDataComp
end

function M:GetEditorID()
    local HiEditorDataComp = self:GetEditorDataComp()
    if HiEditorDataComp then
        return HiEditorDataComp.EditorId
    end
end

function M:GetMutableActorComponent()
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableComponent = self:GetComponentByClass(MutableActorComponentClass)
    return MutableComponent
end

function M:IsClientReady()
    local MutableComponent = self:GetMutableActorComponent()
    if MutableComponent then
        return MutableComponent:IsClientReady()
    end
    return false
end

function M:CheckChildReady()
    if self.bReady then
        return
    end
    local isReady, cnt = true, 0
    local CompReadyList = {}
    for ActorId,bIsReady in pairs(self.ActorIdList) do
        ActorId = tostring(ActorId)
        if not bIsReady then
            cnt = cnt + 1
            local EditorActor = self:GetEditorActor(ActorId)
            if not EditorActor then
                isReady = false
            else
                self.ActorIdList[ActorId] = true
                self:ChildReadyNotify(ActorId)
                -- deal with actorcompont of this actor
                local Comps = self:K2_GetComponentsByClass(UE.UActorComponent)
                for Ind = 1, Comps:Length() do
                    local Comp = Comps[Ind]
                    local CompName = G.GetObjectName(Comp)
                    if self.CompIdList[CompName] then
                        if self.CompIdList[CompName][ActorId] ~= nil then
                            self.CompIdList[CompName][ActorId] = true
                            local isCompReady = true
                            for _,bIsReady2 in pairs(self.CompIdList[CompName]) do
                                if not bIsReady2 then
                                    isCompReady = false
                                    break
                                end
                            end
                            if isCompReady then
                                table.insert(CompReadyList, Comp)
                            end
                        end
                    end
                end
            end
        end
    end
    -- notify actor components
    for _,Comp in ipairs(CompReadyList) do
        local CompName = G.GetObjectName(Comp)
        local ActorIdList = {}
        for ActorId2,_ in pairs(self.CompIdList[CompName]) do
            table.insert(ActorIdList, ActorId2)
        end
        if self:IsServer() then
            if Comp.AllChildReadyServer then
                Comp:AllChildReadyServer(ActorIdList)
            end
        else
            if Comp.AllChildReadyClient then
                Comp:AllChildReadyClient(ActorIdList)
            end
        end
    end

    if cnt <= 0 or isReady then
        if cnt > 0 then
            local HiEditorDataComp = self:GetEditorDataComp()
            if HiEditorDataComp then
                HiEditorDataComp:SetInit(false)
                HiEditorDataComp:SetUE5Property()
            end
        end
        self.bReady = true
        if self:IsServer() then
            self:AllChildReadyServer()
        else
            self:AllChildReadyClient()
        end
    end
end


function M:MissionPlayAnimSequence(AnimPath, bLoop)
    self:Multicast_MissionPlayAnimSequenceNotify(AnimPath, bLoop)
end

function M:Multicast_MissionPlayAnimSequenceNotify_RPC(AnimPath, bLoop)
    local AnimSeq = LoadObject(AnimPath)
    self.Mesh:SetAnimationMode(Enum.EAnimationMode.AnimationSingleNode)
    self.Mesh:PlayAnimation(AnimSeq, bLoop)
end

-- server
function M:OnClientActorReady()
   self:CheckPlayMissionMontage()
end

-- client & server
function M:CheckPlayMissionMontage()
    if self.PlayingMontagePath == "" or self.PlayingMontagePath == nil then
        self:DoMissionStopMontage()
    else
        self:DoMissionPlayMontage()
    end
end

-- server
function M:MissionStopMontage()
    self.PlayingMontagePath = ""
    if self:IsClientReady() then
        self:DoMissionStopMontage()
    end
    -- self:Multicast_MissionStopMontageNotify()
end

-- client & server
-- function M:Multicast_MissionStopMontageNotify_RPC()
function M:DoMissionStopMontage()
    if self.PlayingMontage then
        if self.Mesh then
            local AnimInstance = self.Mesh:GetAnimInstance()
            if AnimInstance then
                AnimInstance:Montage_Stop(0.0, self.PlayingMontage)
            end
        end
        self.PlayingMontage = nil
    end
end

-- server
function M:MissionPlayMontage(AnimPath, bLoop)
    self.PlayingMontagePath = AnimPath
    if self:IsClientReady() then
        self:DoMissionPlayMontage()
    end
end

-- client
function M:OnRep_PlayingMontagePath()
    if not self.bHasBegunPlay then
        return
    end
    self:CheckPlayMissionMontage()
end

-- client & server
function M:DoMissionPlayMontage()
    self.PlayingMontage = LoadObject(self.PlayingMontagePath)
    if self.Mesh then
        --self.Mesh:SetAnimationMode(Enum.EAnimationMode.AnimationSingleNode)
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.Mesh, self.PlayingMontage, 1.0)
        self.bComplete = false
        local InterruptedFunc = function(name) -- 这里 StopMontage 会被打断后调这个回调
            if self.bComplete then
                return
            end
            self.bComplete = true
            self:CallEvent_MontageInterruptOrComplete(Enum.E_MontageCompleteType.Interrupt)
        end
        local CompletedFunc = function(name)
            if self.bComplete then
                return
            end
            self.bComplete = true
            self:CallEvent_MontageInterruptOrComplete(Enum.E_MontageCompleteType.Complete)
        end
        local OnMontageBlendOut = function(name)
            --self:CallEvent_MontageInterruptOrComplete(Enum.E_MontageCompleteType.BlendOut)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self, InterruptedFunc)
        PlayMontageCallbackProxy.OnCompleted:Add(self, CompletedFunc)
        PlayMontageCallbackProxy.OnBlendOut:Add(self, OnMontageBlendOut)

        local World = self:GetWorld()
        local AnimInstance = self.Mesh:GetAnimInstance()
        if AnimInstance then
            local CurrentActiveMontage = AnimInstance:GetCurrentActiveMontage()
            if CurrentActiveMontage then
                local MontageLength = CurrentActiveMontage:GetPlayLength()
                utils.DoDelay(World, MontageLength,
                        function()
                            if not self.bComplete then
                                self.bComplete = true
                                self:CallEvent_MontageInterruptOrComplete(Enum.E_MontageCompleteType.Complete)
                            end
                        end)
            end
        end
    end
end

function M:SetWayPointActor(WayPointActor)
    self.WayPoint = UE.FSoftObjectPtr(WayPointActor)
    --self[self.WayPointKey] = WayPointActor
end

function M:TriggerAtWayPointIndexByMission(WayPointID, index)
    self:TriggerAtWayPointIndex(index, WayPointID, true)
end

---@param index 移动到路点的 index 位置
---@param InWayPointID 移动到路点的 ID, BP_WayPoint实例通过 GetEditorID() 方法获取
---@param trigger_by_mission 是否通过任务触发
function M:TriggerAtWayPointIndex(index, InWayPointID, trigger_by_mission)
end

function M:ReachIndex(index, OtherActor, bLast)
    if OtherActor == self then
        --self:LogInfo("zsf", "[base_character_lua] ReachIndex %s", index)
        self:CallEvent_ReachWayPointIndex(index)
    end
    self.Overridden.ReachIndex(self, index, OtherActor, bLast)
end

function M:StartMove()
    self.Overridden.StartMove(self)
end

function M:StopMove(bLast)
    self.Overridden.StopMove(self, bLast)
end

function M:ChildReadyNotify(ActorId)
end

function M:AllChildReadyServer()

end

function M:AllChildReadyClient()
end

function M:ChildTriggerMainActor(ChildActor)
    -- MainActor 可以通过 SoftReference 来关联 ChildActor
    -- ChildActor 完成一些逻辑，比如: 开宝箱
    -- 通知 MainActor 当前完成 ChildActor 的操作
end

function M:GetMainActor()
    return self.MainActor
end

function M:MakeMainActor(MainActor)
    self.MainActor = MainActor
end

function M:ListenActorSpawnOrDestroy(ActorID, Listener, bSpawnOrDestroy)
    ActorID = tostring(ActorID)
    local ChildActor = self:GetMutableActorSubSystem():GetActor(ActorID)
    if ChildActor then
        self:CheckChildReady()
    end

    self:LogInfo("zsf", "ListenActorSpawnOrDestroy %s %s %s %s", Listener, ActorID, bSpawnOrDestroy, ChildActor)
end

function M:GetMutableActorSubSystem()
    return SubsystemUtils.GetMutableActorSubSystem(self)
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
end

function M:GetEditorActor(EditorID)
    if self:IsServer() then
        return self:GetMutableActorSubSystem():GetActor(EditorID)
    else
        -- set other GameMode by WorldSettings
        local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
        if Player and Player.EdRuntimeComponent then
            return Player.EdRuntimeComponent:GetEditorActor(EditorID)
        else -- In Case not EdRuntimeComponent
            local EdActor = EdUtils.mapEdActors[EditorID]
            if EdActor and not UE.UKismetSystemLibrary.IsValid(EdActor) then -- released object
                EdUtils.mapEdActors[EditorID] = nil
                EdActor = nil
            end
            return EdActor
        end
    end
end

function M:AddEditorActor(EditorActor)
    if self:IsServer() then
        return
    end
    -- set other GameMode by WorldSettings
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    if Player and Player.EdRuntimeComponent then
        Player.EdRuntimeComponent:AddEditorActor(EditorActor)
    else -- In Case not EdRuntimeComponent
        local EditorID = EditorActor:GetEditorID()
        if EdUtils.mapEdActors then
            EdUtils.mapEdActors[EditorID] = EditorActor
            for EdID,Actor in pairs(EdUtils.mapEdActors) do
                if Actor and UE.UKismetSystemLibrary.IsValid(Actor) then
                    if Actor.CheckChildReady then
                        Actor:CheckChildReady()
                    end
                else -- released object
                    EdUtils.mapEdActors[EdID] = nil
                end
            end
        end
    end
end

function M:RemoveEditorActor(Actor)
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    if Player and Player.EdRuntimeComponent then
        Player.EdRuntimeComponent:RemoveEditorActor(Actor)
    end
end

function M:ReceiveBeginPlay()
    EdUtils:ReceiveBeginPlay(self)
    self:AddEditorActor(self)
    Super(M).ReceiveBeginPlay(self)
    if self:IsClient() then
        self:SendMessage("NotifyServerClientActorReady")
        self:CheckPlayMissionMontage()
    end
end

function M:ReceiveEndPlay(Reson)
    EdUtils:ReceiveEndPlay(self, Reson)
    Super(M).ReceiveEndPlay(self)
end

function M:MissionComplete(eMiniGame, sData)
    local json = require("thirdparty.json")
    local Param = {
        eMiniGame=eMiniGame,
        sData=sData
    }
    local Data=json.encode(Param)
    self:CallEvent_MissionComplete(Data)
end

function M:ReceiveDestroyed()
    self:RemoveEditorActor(self)
    self.Overridden.ReceiveDestroyed(self)
end

function M:GetActorContainerPropertyName(PropertyName)
    return PropertyName.."@Container"
end

function M:GetActorIdBase(ActorId)
    if ActorId then
        local Data = EdUtils:SplitPath(ActorId, "@")
        if #Data > 1 then
            ActorId = Data[2]
        end
    end
    return ActorId
end

function M:GetActorIdSingle(PropertyName)
    local Name = self:GetActorContainerPropertyName(PropertyName)
    local Con = self[Name]
    if Con then
        return self:GetActorIdBase(Con[1])
    end
end

function M:GetActorIds(PropertyName)
    local Name = self:GetActorContainerPropertyName(PropertyName)
    local IDs = {}
    if self[Name] then
        for ind=1,#self[Name] do
            local ActorId = self[Name][ind]
            table.insert(IDs, self:GetActorIdBase(ActorId))
        end
    end
    return IDs
end

return M