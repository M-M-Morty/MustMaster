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
local Actor = require("common.actor")
local EdUtils = require("common.utils.ed_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")
local utils = require("common.utils")

local M = Class(Actor)

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

function M:GetPlayerActor(OtherActor)
    if OtherActor.EdRuntimeComponent then
        return OtherActor
    end
end

function M:Initialize(...)
    Super(M).Initialize(self, ...)
    self.JsonObject = nil
    self.ActorIdList = {}
    self.CompIdList = {}
    self.CompFuncNames = {
        {"IsVisible", "SetVisibility"},
        {"GetCollisionEnabled", "SetCollisionEnabled"},
        --{"GetGameplayVisibility", "SetGameplayVisibility"}
    }
    self.CompFuncPropertys = {}
    self.MainActor = nil
    self.StatusFlow_RemoveTimer = nil
end

function M:UserConstructionScript()
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
            self:LogInfo("zsf", "[base_item] MergeToActorIdList %s %s %s", ActorId, self:GetEditorID(), G.GetDisplayName(self))
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

function M:GetActorID()
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableActorComponent = self:GetComponentByClass(MutableActorComponentClass)
    return MutableActorComponent:GetActorID()
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

function M:ChildReadyNotify(ActorId)

end

function M:AllChildReadyServer()
    if self.Overridden.AllChildReadyServer then
        self.Overridden.AllChildReadyServer(self)
    end
end

function M:AllChildReadyClient()
    if self.Overridden.AllChildReadyClient then
        self.Overridden.AllChildReadyClient(self)
    end
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

    self:LogInfo("zsf", "ListenActorSpawnOrDestroy %s %s %s %s %s", self:GetEditorID(), Listener, ActorID, bSpawnOrDestroy, ChildActor)
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
        if EditorID ~= nil then
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
    if self.AreaAbilityTrigger == nil then
        self.AreaAbilityTrigger = self.Sphere
    end
    if self.AreaAbilityTrigger then
        self.AreaAbilityTrigger.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_AreaAbilityTrigger)
        self.AreaAbilityTrigger.OnComponentEndOverlap:Add(self, self.OnEndOverlap_AreaAbilityTrigger)
    end

    if not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.Sapwn2Appear) or
            not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.Appear) then -- deal with old behavior
        if not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.Sapwn2Appear) then
            self:StatusFlow_Appear(false)
            --@param bServer
            --@param EnumKey
            --@param Value S_StatusFlowEffect
            self:Call_StatusFlow_Func(Enum.E_StatusFlow.Sapwn2Appear, function(bServer, EnumKey, Value)
                self:Multicast_CallStatusFlow(EnumKey)
            end)
        else
            self:StatusFlow_Appear2SealedOrInActive()
        end
    else
        self:StatusFlow_Appear2SealedOrInActive()
    end

    Super(M).ReceiveBeginPlay(self)
end

function M:ReceiveEndPlay(Reson)
    EdUtils:ReceiveEndPlay(self, Reson)
    if self.AreaAbilityTrigger then
        self.AreaAbilityTrigger.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_AreaAbilityTrigger)
        self.AreaAbilityTrigger.OnComponentEndOverlap:Remove(self, self.OnEndOverlap_AreaAbilityTrigger)
    end
    Super(M).ReceiveEndPlay(self)
end

function M:MissionComplete(sData)
   self:CallEvent_MissionComplete(sData)
end

function M:ReceiveDestroyed()
    self:StatusFlow_ClearEffect()
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

-- suppport for VisibilityManagementComponent
function M:IsGameplayVisible()
    return self.VisibilityManagementComponent.bVisibilityInGameplay
end

function M:SetCollisionEnabled(NewType)
    utils.SetActorCollisionEnabled(self, NewType)
end

function M:OnClientUpdateGameplayVisibility()
end

---- Area Ability Begin -----------
---@param InvokerActor AActor
function M:DoClientAreaAbilityCopyAction(InvokerActor)
     local playerActor = self:GetPlayerActor(InvokerActor)
    if playerActor then
        playerActor.CAreaAbilityComponent:Server_AreaAbilityCopy(self)
    end
end

function M:Multicast_Fly2Other_RPC(EndLocation)
    local function DoFly2Other(EndLocation)
        self.NS_AreaLightFire_Keep:SetVisibility(true)
        self.NS_AreaLightFire_Keep:SetActive(true, true)
        self.NS_absorb:SetActive(false, false)
        self.NS_absorb:SetVisibility(false)

        local GravityScale = 5.0
        local overrideGravityZ = -980 * GravityScale
        local OutVelocity = UE.FVector()
        UE.UGameplayStatics.SuggestProjectileVelocity_CustomArc(self, OutVelocity, self:K2_GetActorLocation(), EndLocation, overrideGravityZ, 0.5)

        self.RootSphere:SetSphereRadius(1.0, false)
        --self.RootSphere:SetCollisionProfileName('InteractedDropItem', true)
        self.RootSphere:SetCollisionProfileName('GhostPawn', true)
        self.RootSphere:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        self.RootSphere:SetMobility(UE.EComponentMobility.Movable)
        self.ProjectileMovement:SetActive(true)
        self.ProjectileMovement:SetUpdatedComponent(self.RootSphere)
        self.ProjectileMovement:SetComponentTickEnabled(true)
        --self.ProjectileMovement.ProjectileGravityScale = GravityScale
        self.ProjectileMovement.ProjectileGravityScale = 0.0
        local ItemLocation = self:K2_GetActorLocation()
        local Velocity = EndLocation - ItemLocation
        Velocity:Normalize()
        -- 这个速度可以调整
        self.ProjectileMovement.Velocity = Velocity * 1000
        --self.ProjectileMovement.Velocity = OutVelocity
        self.ProjectileMovement.OnProjectileStop:Remove(self, self.AreaAbility_Fly2Player_ProjectileMoveStop_Other)
        self.ProjectileMovement.OnProjectileStop:Add(self, self.AreaAbility_Fly2Player_ProjectileMoveStop_Other)

        self.RootSphere.OnComponentHit:Remove(self, self.AreaAbility_Fly2Player_OnComponentHit_Other)
        self.RootSphere.OnComponentHit:Add(self, self.AreaAbility_Fly2Player_OnComponentHit_Other)
    end
    DoFly2Other(EndLocation)
end

function M:AreaAbility_Fly2Player_OnComponentHit_Other(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
     if self.ProjectileMovement then
         if self.DoAreaAbility_Fly2Player_OnComponentHit_Other then
             self:DoAreaAbility_Fly2Player_OnComponentHit_Other(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
         end
    end
end

function M:AreaAbility_Fly2Player_ProjectileMoveStop_Other(ImpactResult)
    if self.ProjectileMovement then
        self.ProjectileMovement:SetComponentTickEnabled(false)
        self.ProjectileMovement.ProjectileGravityScale = 0.0
        self.ProjectileMovement.Velocity = UE.FVector(0,0,0)
    end
end

function M:AreaAbility_Fly2Other(EndLocation)
    self:Multicast_Fly2Other(EndLocation)
end

---@param PlayerAtor AActor
function M:AreaAbility_Fly2Player(PlayerAtor)
    if self.ProjectileMovement then
        self.bFly2Player = true
        self.vFly2PlayerStart = self:K2_GetActorLocation()
        local function DoFly2Play(EndLocation, factor)
            self.RootSphere:SetMobility(UE.EComponentMobility.Movable)
            --self.RootSphere:SetSphereRadius(0.0, false)
            --self.RootSphere:SetCollisionProfileName('Interacted_AreaAbility', true)
            self.ProjectileMovement:SetActive(true)
            self.ProjectileMovement:SetUpdatedComponent(self.RootSphere)
            self.ProjectileMovement:SetComponentTickEnabled(true)
            self.ProjectileMovement.ProjectileGravityScale = 0.0
            -- 这个获取指定的某点
            local ItemLocation = self:K2_GetActorLocation()
            local Velocity = EndLocation - ItemLocation
            Velocity:Normalize()
            -- 这个速度可以调整
            self.ProjectileMovement.Velocity = Velocity * self.fAbsorbVelocity*factor
            self.ProjectileMovement.OnProjectileStop:Remove(self, self.AreaAbility_Fly2Player_ProjectileMoveStop)
            self.ProjectileMovement.OnProjectileStop:Add(self, self.AreaAbility_Fly2Player_ProjectileMoveStop)

            self.RootSphere.OnComponentHit:Remove(self, self.AreaAbility_Fly2Player_OnComponentHit)
            self.RootSphere.OnComponentHit:Add(self, self.AreaAbility_Fly2Player_OnComponentHit)
            self.RootSphere.OnComponentBeginOverlap:Remove(self, self.AreaAbility_Fly2Player_OnBeginOverlap)
            self.RootSphere.OnComponentBeginOverlap:Add(self, self.AreaAbility_Fly2Player_OnBeginOverlap)
        end

        if not self:HasAuthority() then
            HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Get", self)
        end
        -- 往 up 的方向先移动一段距离
        local ItemLocation = self:K2_GetActorLocation()
        local UpLocation = ItemLocation + self.RootSphere:GetUpVector()*10
        DoFly2Play(UpLocation, 300)
        utils.DoDelay(self:GetWorld(), self.fAbsorbUpTime, function()
            -- 这里获取下挂点的位置
            local PlayerLocation = PlayerAtor:K2_GetActorLocation()
            if PlayerAtor.GetSocketLocation then
                PlayerLocation = PlayerAtor:GetSocketLocation(PlayerAtor.CAreaAbilityComponent.AreaAbilityFlyAttachName)
            end
            DoFly2Play(PlayerLocation, 5000)
        end)
    end
    self.Overridden.AreaAbility_Fly2Player(self, PlayerAtor)
end

function M:AreaAbility_Fly2Player_OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    self:AreaAbility_Fly2Player_OnComponentHit(nil, OtherActor, nil, nil, nil)
end

function M:AreaAbility_Fly2Player_OnComponentHit(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
    if not self:HasAuthority() then
        return
    end
    --TODO(dougzhang): 这里先判断数量只能获得一个
    if self.ProjectileMovement then
        local ServerPlayerActor = self:GetPlayerActor(OtherActor)
        if ServerPlayerActor then
            local AbilityType = ServerPlayerActor.CAreaAbilityComponent:GetAreaAbilityType()
            if AbilityType and AbilityType ~= Enum.E_AreaAbility.None then
                return
            end

            self:LogInfo("ys", "base_item : self.cAreaAbility = %s", Enum.E_AreaAbility.GetDisplayNameTextByValue(self.cAreaAbility))
            -- 该角色的相应能力++
            ServerPlayerActor.CAreaAbilityComponent:SetAreaAbilityType(self.cAreaAbility)

            self.bFly2Player = false
            self:Multicast_ReceiveAreaAbility(ServerPlayerActor, self.cAreaAbility)
        end
    end
end

function M:AreaAbility_Fly2Player_ProjectileMoveStop(ImpactResult)
    if self.ProjectileMovement then
        self.ProjectileMovement:SetComponentTickEnabled(false)
        self.ProjectileMovement.ProjectileGravityScale = 0.0
        self.ProjectileMovement.Velocity = UE.FVector(0,0,0)
    end
end

---@param InvokerActor AActor
function M:Multicast_AreaAbilityCopy_RPC(InvokerActor)
    local ServerPlayerActor = self:GetPlayerActor(InvokerActor)
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    local PlayerActor = G.GetPlayerCharacter(self:GetWorld(), 0)
    if ServerPlayerActor == PlayerActor then
        --PlayerActor:SendMessage("ReceiveAreaAbility", self)
        local ActorLocation = self:K2_GetActorLocation()
        local PlayerLocation = ServerPlayerActor:K2_GetActorLocation()
        local ForwardV = ActorLocation - PlayerLocation
        local Rotator = UE.UKismetMathLibrary.MakeRotationFromAxes(ForwardV,UE.FVector(0.0,0.0,0.0), UE.FVector(0.0,0.0,0.0))
        local CustomSmoothContext = UE.FCustomSmoothContext()
        ServerPlayerActor:GetLocomotionComponent():SetCharacterRotation(Rotator, false, CustomSmoothContext)

        -- 做场景里边的表现; 当前光效需要飞到 ServerPlayerActor 的位置
        self:AreaAbility_Fly2Player(ServerPlayerActor)

        local Montage = ServerPlayerActor.CAreaAbilityComponent.AreaAbilityCopyAnim
        --local Montage = LoadObject('/Game/Character/Player/Shared_Man/Animation/Locomotion/HappyMove/Man_P_SkateBoard_SpecialIdle_Montage.Man_P_SkateBoard_SpecialIdle_Montage')
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(ServerPlayerActor.Mesh, Montage, 1.0)
        ServerPlayerActor:SendMessage("EnableAreaAbility", false)
        local callback = function(name)
        end
        PlayMontageCallbackProxy.OnBlendOut:Add(self, callback)
        PlayMontageCallbackProxy.OnInterrupted:Add(self, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self, callback)
        local AnimInstance = ServerPlayerActor.Mesh:GetAnimInstance()
        if AnimInstance then
            local CurrentActiveMontage = AnimInstance:GetCurrentActiveMontage()
            if CurrentActiveMontage then
                local MontageLength = CurrentActiveMontage:GetPlayLength()
                utils.DoDelay(self:GetWorld(), MontageLength, function()
                    ServerPlayerActor:SendMessage("EnableAreaAbility", true)
                    ServerPlayerActor:SendMessage("CloseCopyerPanel", false)
                end)
            end
        end
    end
end

---@param InvokerActor AActor
function M:Multicast_ReceiveAreaAbility_RPC(InvokerActor, cAreaAbility)
    local ServerPlayerActor = self:GetPlayerActor(InvokerActor)
    --Sync Server and Client Property
    self.cAreaAbility = cAreaAbility
    
    if ServerPlayerActor then
        ServerPlayerActor:SendMessage("ReceiveAreaAbility", self)
    end
end

---@param InvokerActor AActor
function M:DoServerAreaAbilityCopyAction(InvokerActor)
    if self:HasAuthority() then
        local PlayerActor = self:GetPlayerActor(InvokerActor)
        if PlayerActor then
            if self.cAreaAbility then
                -- 服务端获取物品; 被copy了能力
                -- 当前物件的能力没有了
                -- 当前是否只是获取一次的区域能力
                --self.eAreaAbility = Enum.E_AreaAbility.None
                self:Multicast_AreaAbilityCopy(InvokerActor)
            end
        end
    end
end

--Check if Self(base_item) is responsive to AreaAbilityType
function M:CheckResponseAreaAbilityType(AreaAbilityType)
    if AreaAbilityType and self.rAreaAbility then
        for Ind=1,self.rAreaAbility:Length() do
            local AreaAbility = self.rAreaAbility:Get(Ind)
            if AreaAbility and AreaAbility == AreaAbilityType then
                return true
            end
        end
    end
    return false
end

--Process if Self(base_item) is responsive to AreaAbilityType
function M:ProcessResponseAreaAbilityType(AreaAbilityType, bUsing)
    if AreaAbilityType and self.rAreaAbility then
        --For Each responsive area ability, check if a responsive function is set
        for Ind=1,self.rAreaAbility:Length() do
            local AreaAbility = self.rAreaAbility:Get(Ind)
            if AreaAbility then
                local ProcessFunctionName = "ResponseAreaAbility_"..Enum.E_AreaAbility.GetDisplayNameTextByValue(AreaAbility)
                self:LogInfo("ys","OnBeginOverlap_AreaAbilityTrigger: i = %d FunctionName = %s, iAreaAbility = %s, self.ProcessFunctionName = %s",
                        Ind,ProcessFunctionName,Enum.E_AreaAbility.GetDisplayNameTextByValue(AreaAbilityType),self[ProcessFunctionName])
                if AreaAbilityType == AreaAbility and self[ProcessFunctionName] then
                    self[ProcessFunctionName](self,bUsing)
                end
            end
        end
    end
end

-- 检测下是否还有被其他特定种类的区域能力持续影响
function M:CheckEffectLasting(AreaAbilityType)
    local OverlappedActors = UE.TArray(UE.AActor)
    local bEffectLasting = false
    if self.AreaAbilityTrigger then
        self.AreaAbilityTrigger:GetOverlappingActors(OverlappedActors)
        for Index = 1, OverlappedActors:Length() do
            local Actor = OverlappedActors:Get(Index)
            if Actor.iAreaAbility and Actor.iAreaAbility == AreaAbilityType then
                bEffectLasting = true
                break
            end
        end
    end
    return bEffectLasting
end

--Delegant functions
--Triggered when otherActor has iAreaAbility
function M:OnBeginOverlap_AreaAbilityTrigger(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    self:LogInfo("ys","BaseItem : OnBeginOverlap_AreaAbilityTrigger %s",G.GetDisplayName(self))
    self.Event_AreaAbilityReceive:Broadcast(OtherActor.iAreaAbility)
    self:ProcessResponseAreaAbilityType(OtherActor.iAreaAbility, true)
end

function M:OnEndOverlap_AreaAbilityTrigger(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
end
---- Area Ability End -----------

---- Status Flow Begin ------------------
local StatusFlowEffectFuncMaps = {
    PlayEffect=function(self, EnumKey, Value)
        if Value == nil then
            return
        end
        local Effect, EffectTransform = Value.Effect, Value.EffectTransform
        local bOk = Value and Effect
        if bOk then
            local EffectObj = UE.UObject.Load(tostring(Effect))
            if EffectObj then
                if EffectObj:IsA(UE.UNiagaraSystem) then
                    if self:IsClient() then --- Niagara Effect Only Show at Client
                        local NiagaraObj = UE.UNiagaraFunctionLibrary.SpawnSystemAttached(EffectObj, self.RootSphere, nil,
                                EffectTransform.Translation, UE.FRotator(0, 0, 0), UE.EAttachLocation.KeepRelativeOffset,
                                true, true)
                        return {NiagaraObj}
                    end
                elseif EffectObj:IsA(UE.ULevelSequence) then --fixme(dougzhang): Play Sequence, Server&Client; In Case Of Modify Of Transform
                    local LevelSequencerPlayer, OutActors = UE.ULevelSequencePlayer.CreateLevelSequencePlayer(self:GetWorld(), EffectObj, UE.FMovieSceneSequencePlaybackSettings())
                    if LevelSequencerPlayer then
                        LevelSequencerPlayer:Play()
                    end
                    local Actors = {LevelSequencerPlayer, OutActors}
                    return Actors
                end
            end
        end
    end,
    ReplaceMaterial=function(self, ValidComps, MaterialIns, DelayTime, Callback)
        local ValidCompCnt = #ValidComps
        for _,ValidComp in ipairs(ValidComps) do
            local MI
            if self:IsClient() then
                MI = UE.UPrimitiveComponent.CreateDynamicMaterialInstance(ValidComp, 0, MaterialIns, "None")    --从0开始
            end
            local DelayRun
            DelayRun = function(args)
                local Val, MI = args[1], args[2]
                if Val >= 1.0 then
                    ValidCompCnt = ValidCompCnt - 1
                    if ValidCompCnt <= 0 then
                        if Callback then
                            Callback()
                        end
                    end
                    return
                end
                if MI ~= nil then
                    UE.UMaterialInstanceDynamic.SetScalarParameterValue(MI,"Dissolve",Val)
                end
                Val = Val + 0.01
                utils.DoDelay(self:GetWorld(), DelayTime, DelayRun, {Val, MI})
            end
            DelayRun({0.0, MI})
        end
    end,
}
function M:StatusFlow_Appear_StoreProperty()
    local Comps = self:K2_GetComponentsByClass(UE.UActorComponent)
    for Ind = 1, Comps:Length() do
        local Comp = Comps[Ind]
        local CompName = G.GetObjectName(Comp)
        if self.CompFuncPropertys[CompName] == nil then
            self.CompFuncPropertys[CompName] = {}
        end
        for _,FuncNameData in ipairs(self.CompFuncNames) do
            local FuncName, FuncNameInv = FuncNameData[1], FuncNameData[2]
            if Comp[FuncName] then
                local Val = Comp[FuncName](Comp)
                self.CompFuncPropertys[CompName][FuncNameInv] = Val
            end
        end
    end
end

function M:GetCompFuncProperty(CompName, FuncNameInv, bAppear)
    local ret = nil
    if bAppear then
        if self.CompFuncPropertys[CompName]~=nil and self.CompFuncPropertys[CompName][FuncNameInv]~=nil then
            ret = self.CompFuncPropertys[CompName][FuncNameInv]
        end
    end
    if ret == nil then
        return
    end
    if FuncNameInv == "SetVisibility" then
        return {ret, false}
    elseif FuncNameInv == "SetCollisionEnabled" then
        if bAppear then
            if type(ret) == "number" then -- Not Dynamic Added, Exp: SphereComponent_0
                return {ret}
            end
        else
            return {UE.ECollisionEnabled.NoCollision}
        end
    end
end

function M:StatusFlow_Appear(bAppear)
    if not bAppear then
        self:StatusFlow_Appear_StoreProperty()
    end
    local Comps = self:K2_GetComponentsByClass(UE.UActorComponent)
    for Ind = 1, Comps:Length() do
        local Comp = Comps[Ind]
        local CompName = G.GetObjectName(Comp)
        for _,FuncNameData in ipairs(self.CompFuncNames) do
            local FuncName, FuncNameInv = FuncNameData[1], FuncNameData[2]
            if Comp[FuncNameInv] then
                local Val = self:GetCompFuncProperty(CompName, FuncNameInv, bAppear)
                --local isOk = false
                --local OkNames = {"RootSphere", "TrackTargetAnchor", "Sphere",
                --                 "Box", "BillboardComponent", "SkeletalMesh","FakeEffect",
                --                 "Cube_DropItem","Niagara_Spawn","Niagara_Open","LockEffect","UnlockEffect",
                --                "Niagara_Open_Di","Arrow","Spline","MeshCollision","NS_Strongboxgoldenlight01", "Niagara","NS_PSB_huo","NS_PSB_MeiHuo","Player_Detector","SphereComponent_0"}
                --for _,OkName in ipairs(OkNames) do
                --    if CompName == OkName then
                --        isOk = true
                --        break
                --    end
                --end
                if Val ~= nil then
                    Comp[FuncNameInv](Comp, unpack(Val))
                end
            end
        end
    end
end

function M:StatusFlow_CleanTimer()
    if self.StatusFlow_RemoveTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.StatusFlow_RemoveTimer)
        self.StatusFlow_RemoveTimer = nil
    end
end

function M:StatusFlow_CallNext(Value, Callback)
    local Duration = 1.0
    if Value.DelayTime > 0.0 then
        Duration = Value.DelayTime
    end
    local function cb()
        if Callback then
            Callback()
        end
    end
    self:StatusFlow_CleanTimer()
    self.StatusFlow_RemoveTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, cb}, Duration, false)
end

--[[Merge Status]]--
function M:Call_StatusFlow_ChainEffect(EnumKey, Value, PreStatus, CurStatus)
    local KeyName = Enum.E_StatusFlow.GetDisplayNameTextByValue(EnumKey)
    if self:Check_StatusFlow_Func_NIL(EnumKey) then
        return
    end
    self:StatusFlow_ClearEffect(EnumKey, Value)
    local Effects = StatusFlowEffectFuncMaps.PlayEffect(self, EnumKey, Value) ---- 0 Appear2InActive or Active2InActive, and other status
    self:AddStatusFlowEffect(Effects)

    if EnumKey == Enum.E_StatusFlow.Sapwn2Appear then --- 1. Sapwn2Appear
        self:StatusFlow_Appear(true)
        self:StatusFlow_CallNext(Value, function()
            self:StatusFlow_Appear2SealedOrInActive()
        end)
    elseif EnumKey == Enum.E_StatusFlow.Sealed2InActive or EnumKey == Enum.E_StatusFlow.Appear2Sealed then
        self.bStatusFlowSealed = not self.bStatusFlowSealed --- If this actor is sealed, will be unsealed by outter
    --elseif EnumKey == Enum.E_StatusFlow.Appear2InActive then
    --    self:StatusFlow_CallNext(Value, function()
    --         self:Call_StatusFlow_Func(Enum.E_StatusFlow.InActive2Active)
    --    end)
    elseif EnumKey == Enum.E_StatusFlow.InActive2Active or EnumKey == Enum.E_StatusFlow.Active2Active then --- 2. InActive2Active
        if self.bStatusFlowSealed then -- If Pre Status is Sealed?
            return
        end
        -- Check If Active2Active, generate a loop; Else When EndOverlap will Trigger Active2InActive
        if not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.Active2Active) then
            self:StatusFlow_CallNext(Value, function()
                 self:Call_StatusFlow_Func(Enum.E_StatusFlow.Active2Active)
            end)
        end
    elseif EnumKey == Enum.E_StatusFlow.Active2Complete or Enum.E_StatusFlow.InActive2Complete then --- 4 . Active2Complete 5. InActive2Complete
        -- If Complete2Destroy is true, destroy this actor
        if not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.Complete2Destroy) then
            self:StatusFlow_CallNext(Value, function()
                self:Call_StatusFlow_Func(Enum.E_StatusFlow.Complete2Destroy)
            end)
        end
    elseif EnumKey == Enum.E_StatusFlow.Complete2Destroy then -- 9. Complete2Destroy
        local Comps = self:K2_GetComponentsByClass(UE.UActorComponent)
        local ValidComps = {}
        for Ind = 1, Comps:Length() do
            local Comp = Comps[Ind]
            if Comp:IsA(UE.USkeletalMeshComponent) or Comp:IsA(UE.UStaticMeshComponent) then
                table.insert(ValidComps, Comp)
            end
        end
        local MaterialIns = UE.UObject.Load(tostring(self.StatusFLowDestroyMaterial))
        StatusFlowEffectFuncMaps.ReplaceMaterial(self, ValidComps, MaterialIns, 0.01, function()
            if self:IsServer() then
                self:K2_DestroyActor()
            end
        end)
    end
end

function M:StatusFlow_Appear2SealedOrInActive()
    -- Current Choose One of Appear2Sealed or Appear2InActive
    if not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.Appear2Sealed) then -- uninteractable
        self:Call_StatusFlow_Func(Enum.E_StatusFlow.Appear2Sealed)
    elseif not self:Check_StatusFlow_Func_NIL(Enum.E_StatusFlow.Appear2InActive) then -- interactable
        self:Call_StatusFlow_Func(Enum.E_StatusFlow.Appear2InActive)
    end
end
--[[Merge Status]]--

function M:OnRep_bStatusFlowSealed()
    if not self.bStatusFlowSealed then -- true to false, unsealed
        self:Call_StatusFlow_Func(Enum.E_StatusFlow.Sealed2InActive)
    end
    if self.SetInteractable then
        if self.bStatusFlowSealed then
            self:SetInteractable(Enum.E_InteractedItemStatus.UnInteractable)
        else
            self:SetInteractable(Enum.E_InteractedItemStatus.Interactable)
        end
    end
end

function M:AddStatusFlowEffect(Effects)
    if self.tStatusFlowEffect == nil then
        self.tStatusFlowEffect = {}
    end
    if Effects ~= nil then
        for _,Effect in ipairs(Effects) do
            table.insert(self.tStatusFlowEffect, Effect)
        end
    end
end

function M:ClearStatusFlowEffect()
    self.tStatusFlowEffect = {}
end

function M:StatusFlow_ClearEffect(EnumKey, Value)
    --- delete Old sealed Niagara Effect
    if self.tStatusFlowEffect ~= nil then
        for Ind=1,#self.tStatusFlowEffect do
            local OldEffect = self.tStatusFlowEffect[Ind]
            if UE.UKismetSystemLibrary.IsValid(OldEffect) then
                -- fixme(dougzhang): delete sequence & SequenceActors; and spawnable actors
                if OldEffect:IsA(UE.ULevelSequencePlayer) then
                    OldEffect:Stop()
                end
                if OldEffect.K2_DestroyActor then
                    --local ChildActors = UE.TArray(UE.AActor)
                    --OldEffect:GetAllChildActors(ChildActors)
                    --local AttachActors = UE.TArray(UE.AActor)
                    --OldEffect:GetAttachedActors(AttachActors)
                    OldEffect:K2_DestroyActor()
                end
                if OldEffect.K2_DestroyComponent then
                    OldEffect:K2_DestroyComponent()
                end
            end
        end
    end
    self:ClearStatusFlowEffect()
end

function M:Check_StatusFlow_Func_NIL(EnumKey)
    local HiEditorDataComp = self:GetEditorDataComp()
    if not HiEditorDataComp then
        return true
    end
    return HiEditorDataComp:Check_StatusFlow_Func_NIL(EnumKey)
end

--@param: EnumKeyRaw -> Mission Set Target Status
function M:Mission_Call_StatusFlow_Func(EnumKey, EnumKeyRaw)
    local StartName = Enum.E_StatusFlowRaw.GetDisplayNameTextByValue(self.eStatusFlowRaw)
    local EndName = Enum.E_StatusFlowRaw.GetDisplayNameTextByValue(EnumKeyRaw)
    local Name = string.format("%s2%s", StartName, EndName)
    local MaxValue = Enum.E_StatusFlow.GetMaxValue()

    self:Multicast_Mission_CallStatusFlow(EnumKeyRaw)

    for Ind=0,MaxValue do
        local EName = Enum.E_StatusFlow.GetDisplayNameTextByValue(Ind)
        if EName == Name then
            self:Call_StatusFlow_Func(Ind)
            return
        end
    end
end

function M:Multicast_Mission_CallStatusFlow_RPC(EnumKeyRaw)
    self.Overridden.BP_Mission_CallStatusFlow(self, EnumKeyRaw)
end

--@param EnumKey Enum from E_StatusFlow
function M:Call_StatusFlow_Func(EnumKey, Callback)
    local HiEditorDataComp = self:GetEditorDataComp()
    if not HiEditorDataComp then
        return
    end
    HiEditorDataComp:Call_StatusFlow_Func(EnumKey, Callback)
end

function M:GetStatusFlowRawIndex(Name)
    local MaxValue = Enum.E_StatusFlowRaw.GetMaxValue()
    for Ind=0,MaxValue do
        local EName = Enum.E_StatusFlowRaw.GetDisplayNameTextByValue(Ind)
        if EName == Name then
            return Ind
        end
    end
end

function M:SetStatusFlowRaw(EnumKey)
    local KeyName = Enum.E_StatusFlow.GetDisplayNameTextByValue(EnumKey)
    local KeyNameData = EdUtils:SplitPath(KeyName, "2")
    local StatusName = KeyName
    if #KeyNameData == 2 then
        StatusName = KeyNameData[2]
    end
    local PreStatusFlowRaw = self.eStatusFlowRaw
    self.eStatusFlowRaw = self:GetStatusFlowRawIndex(StatusName)
    return PreStatusFlowRaw, self.eStatusFlowRaw
end

function M:Multicast_CallStatusFlow_RPC(EnumKey)
    --- After Actor Spawned, then will call this RPC to set status
    local StatusFlowEffect = self.StatusFlowEffect
    local Value = StatusFlowEffect:Find(EnumKey)
    local PreSta, CurSta = self:SetStatusFlowRaw(EnumKey)
    self:Call_StatusFlow_ChainEffect(EnumKey, Value, PreSta, CurSta)

    if self.BP_CallStatusFlow then -- For BP Callback
        self:BP_CallStatusFlow(PreSta, CurSta)
    end
end
---- Status Flow End ------------------

function M:IsDead()
    return false
end

function M:GetAbilitySystemComponent()
    return self.HiAbilitySystemComponent
end

return M
