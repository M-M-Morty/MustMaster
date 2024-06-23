local string = require("string")
local EdUtils = require("common.utils.ed_utils")
local OutlinerUtils = require("common.utils.Outliner_utils")
local table = require("table")
local G = require("G")
local GameAPI = require("common.game_api")
local utils = require("common.utils")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local ConstTextTable = require("common.data.const_text_data").data
local GameConstData = require("common.data.game_const_data").data

local M = Component(ComponentBase)

local decorator = M.decorator

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

 function M:Initialize(Initializer)
    Super(M).Initialize(self, Initializer)
 end

 function M:ReceiveBeginPlay()
     Super(M).ReceiveBeginPlay(self)
 end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end

function M:HasAuthority()
    local owner = self:GetOwner()
    return owner and owner:HasAuthority() or false
end

function M:AreaAbilityInUse()
    if self.inAreaAbility == Enum.E_AreaAbility.None then
        return false
    else
        return true
    end
end

function M:AreaAbilityUseEffectOther(ActorTransform, AreaAbilityType, OwnerActor)
    local WorldContext = self.actor:GetWorld()
    if not OwnerActor then
        OwnerActor = WorldContext
    end
    local Actor = WorldContext:SpawnActor(self.AreaAbilityActorClass:Find(AreaAbilityType), ActorTransform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, WorldContext)
    return Actor
end

function M:ClearSpawnedActor()
    for Ind=1,self.PSList:Length() do
        local Actor = self.PSList:Get(Ind)
        if Actor then
            Actor:K2_DestroyActor()
        end
    end
    self.PSList:Clear()
end

function M:AreaAbilityUseEffect(eAreaAbility, InvokerActor, StartLocation, Location)
    if not self:HasAuthority() then
        return
    end
    local Mesh = self.actor.Mesh
    if not Mesh then
        return
    end

    -- Clear AreaAbility Actor Spawned before
    self:ClearSpawnedActor()
    
    if eAreaAbility == Enum.E_AreaAbility.None then
        return
    else
        -- Spawn New Actor
        local WorldContext = self.actor:GetWorld()
        local ActorTransform = UE.FTransform.Identity
        if self.AreaAbilitySelfActorClass then
            local SpawnClass = self.AreaAbilitySelfActorClass:Find(eAreaAbility)
            if SpawnClass then
                local Actor = WorldContext:SpawnActor(SpawnClass, ActorTransform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, WorldContext)
                
                -- 修正Actor中特效的偏移
                local RelativePosition = UE.FVector(2.0 * Actor.EffectRadius,0,0)
                
                -- Todo : 获得actor肩上挂接点的位置, SpawnPosition
                local SpawnPosition = UE.FVector(0,0,200) + RelativePosition
                
                -- Set Actor Property
                Actor.iAreaAbility = eAreaAbility
                local worldLocation = self.actor:K2_GetActorLocation()
                Actor:K2_SetActorLocation(UE.FVector(StartLocation.X, StartLocation.Y, StartLocation.Z) + SpawnPosition, false, UE.FHitResult(), true)
                Actor:K2_AttachToComponent(Mesh, '', UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld)
                
                --Todo : 飞到ActorTransform原始位置
                local RotationStartPosition = UE.FVector(StartLocation.X, StartLocation.Y, StartLocation.Z)
                Actor:Multicast_Fly2Pos(RotationStartPosition)

                local function AreaAbilityUseEnd(args)
                    self:LogInfo("ys","AreaAbilityUseEnd")
                    local InvokerActor, StartLocation, Location = args[1], args[2], args[3]
                    self:Multicast_AreaAbilityUse(self.actor, InvokerActor, Enum.E_AreaAbility.None, StartLocation, Location)
                end
                utils.DoDelay(self.actor, Actor.RemainTime, AreaAbilityUseEnd, {InvokerActor, StartLocation, Location})

                self.PSList:Add(Actor)
            else
                self:LogWarn("ys","AreaAbilitySelfActorClass Cannot find %s",Enum.E_AreaAbility.GetDisplayNameTextByValue(eAreaAbility))
            end
        else
            self:LogWarn("ys","Cannot Find AreaAbilitySelfActorClass")
        end

    end
end

---@param PlayerActor AActor
---@param InvokerActor AActor 这个可能是自己；或者是其他 NPC
function M:Multicast_AreaAbilityUse_RPC(ServerPlayerActor, InvokerActor, eAreaAbility, StartLocation, Location)
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    if ServerPlayerActor == InvokerActor then -- (对自己使用）
        if not self:AreaAbilityInUse() then
            if not self:HasAuthority() then
                HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Loop", self.actor)
                if ServerPlayerActor.Mesh then
                    ServerPlayerActor.Mesh:SetOverlayMaterial(self.AreaAbilitySelfMI)
                end
            end
        end
        self:LogInfo("zsf", "Multicast_AreaAbilityUse_RPC %s %s %s", eAreaAbility, Enum.E_AreaAbility.None, self.AreaAbilityCollisionComp)

        -- 标识当前在使用中的区域能力类型
        self.inAreaAbility = eAreaAbility
        
        self:AreaAbilityUseEffect(self.inAreaAbility, InvokerActor, StartLocation, Location)
    else
        if self.actor == ServerPlayerActor then
            local ActorLocation = Location
            self.AreaAbilityUseLocation = Location
            local PlayerLocation = ServerPlayerActor:K2_GetActorLocation()
            local ForwardV = ActorLocation - PlayerLocation
            local Rotator = UE.UKismetMathLibrary.MakeRotationFromAxes(ForwardV,UE.FVector(0.0,0.0,0.0), UE.FVector(0.0,0.0,0.0))
            local CustomSmoothContext = UE.FCustomSmoothContext()
            ServerPlayerActor:GetLocomotionComponent():SetCharacterRotation(Rotator, false, CustomSmoothContext)

            local Montage = self.AreaAbilityCopyAnim
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
                    utils.DoDelay(self.actor, MontageLength, function()
                        ServerPlayerActor:SendMessage("EnableAreaAbility", true)
                    end)
                    utils.DoDelay(self.actor, 0.5, function()
                        if self:HasAuthority() then
                            if eAreaAbility ~= Enum.E_AreaAbility.None then
                                local ActorTransform = ServerPlayerActor:GetTransform()
                                local PlayerLocation = ServerPlayerActor:GetSocketLocation(self.AreaAbilityFlyAttachName)
                                --PlayerLocation.X = PlayerLocation.X + 100
                                ActorTransform.Translation = PlayerLocation
                                --Todo : 获得actor肩上挂接点的位置
                                local AreaAbilityActorUseOther = self:AreaAbilityUseEffectOther(ActorTransform, eAreaAbility)
                                if AreaAbilityActorUseOther then
                                    AreaAbilityActorUseOther.iAreaAbility = eAreaAbility
                                    AreaAbilityActorUseOther:AreaAbility_Fly2Other(self.AreaAbilityUseLocation)
                                    if AreaAbilityActorUseOther.Multicast_UseOtherDelay then
                                        AreaAbilityActorUseOther:Multicast_UseOtherDelay(self.AreaAbilityUseDuration)
                                    end
                                end
                            end
                        else
                            HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Cast", self.actor)
                        end
                    end)
                end
            end
        end
    end

    if eAreaAbility == Enum.E_AreaAbility.None then
        -- 当前使用的区域能力已经失效了
        if self.actor == ServerPlayerActor then -- 处理自己
            if not self:HasAuthority() then
                if ServerPlayerActor and ServerPlayerActor.Mesh then
                    ServerPlayerActor.Mesh:SetOverlayMaterial(nil)
                end
                HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Loop_Stop", self.actor)
            end
        end
    end
    
    -- Process UI Panel Close
    if self.actor == ServerPlayerActor then
        if ServerPlayerActor == InvokerActor then -- (对自己使用）
            ServerPlayerActor:SendMessage("CloseAreaAbilityPanel", false)
        else
            utils.DoDelay(self.actor, 3.0, function()
                local PlayerActor = self.actor
                if ServerPlayerActor == InvokerActor then -- (对自己使用）
                    -- 使用的 player 退出使用模式
                    ServerPlayerActor:SendMessage("CloseAreaAbilityPanel", false)
                else
                    -- 使用的 player 退出使用模式
                    ServerPlayerActor:SendMessage("CloseAreaAbilityPanel", false)
                end
                
                --Update VM
                local AbilityType = self:GetAreaAbilityType()
                AreaAbilityVM:SetAreaAbilityType(AbilityType)
            end)
        end
    end
end

---@param InvokerActor AActor
function M:Server_AreaAbilityCopy_RPC(Location, eAreaAbility)
    if self:HasAuthority() then
        local ActorTransform = UE.FTransform()
        ActorTransform.Translation = Location
        local AreaAbilityActorUseOther = self:AreaAbilityUseEffectOther(ActorTransform, eAreaAbility)
        if AreaAbilityActorUseOther and AreaAbilityActorUseOther.DoServerAreaAbilityCopyAction then
            AreaAbilityActorUseOther.cAreaAbility = eAreaAbility
            G.log:warn("ys", " AreaAbilityActorUseOther.cAreaAbility = %s", Enum.E_AreaAbility.GetDisplayNameTextByValue(AreaAbilityActorUseOther.cAreaAbility))
            AreaAbilityActorUseOther:DoServerAreaAbilityCopyAction(self:GetOwner())
        end
    end
end

---@param InvokerActor AActor 这个可能是自己；或者是其他 NPC
---@param eAreaAbility Enum
function M:Server_AreaAbilityUse_RPC(InvokerActor, eAreaAbility, StartLocation, Location)
    --Only Execute on server
    if not self:HasAuthority() then
        return
    end
    
    -- 这里区分是对自己还是对其他物体使用; 自己的能力还在使用中，不能使用
    if self:GetOwner() == InvokerActor then
        if self:AreaAbilityInUse() then
            return
        end
    end

    -- 使用了该能力,不能重复使用
    self:SetAreaAbilityType(Enum.E_AreaAbility.None)
    self:Multicast_AreaAbilityUse(self.actor, InvokerActor, eAreaAbility, StartLocation, Location)

    --self.Overridden.ProcessServerAreaAbilityUse(self, InvokerActor, eAreaAbility, StartLocation, Location)
end

---@param InvokerActor AActor 获取区域能力client检测到的Actor; server 根据 Actor 合数据在对应位置 Attach AreaAbility Trigger
---@param AreaAbilityData (S_AreaAbility) 对应的 DT_AreaAbility 中的一行
function M:Server_SpawnAreaAbilityTrigger_RPC(InvokerActor, AreaAbilityData)
    -- add trigger via AreaAbilityData.Transforms
    if not AreaAbilityData then
        return
    end
    
    self:LogInfo("ys","Server_SpawnAreaAbilityTrigger_RPC, AreaAbilityData.AreaAbility = %s, invokeActor = %s",
            Enum.E_AreaAbility.GetDisplayNameTextByValue(AreaAbilityData.Ability),G.GetDisplayName(InvokerActor))

    local CreatedMap,_ = EdUtils:CheckAreaAbilitChildActors(InvokerActor)
    local Transforms = AreaAbilityData.Transforms
    for Ind=1, Transforms:Length() do
        local AreaAbilityTag = EdUtils.AreaAbilityPrefix..tostring(Ind)
        self:LogWarn("ys","CreatedMap.Size = %d, AreaAbilityTag = %s",
                #CreatedMap,AreaAbilityTag)
        if not CreatedMap[AreaAbilityTag] then
            --todo: change AreaAbility Type, Lighting, Dark and so on
            local ActorTransform = Transforms[Ind]
            local InvokerActorLocation = InvokerActor:K2_GetActorLocation()
            ActorTransform.Translation = UE.UKismetMathLibrary.Add_VectorVector(ActorTransform.Translation, InvokerActorLocation)
            local AreaAbilityActor = self:AreaAbilityUseEffectOther(ActorTransform, AreaAbilityData.Ability, InvokerActor)
            AreaAbilityActor.eAreaAbility = AreaAbilityData.Ability
            AreaAbilityActor.AreaAbilityTag = AreaAbilityTag
            
            --attach到关卡编辑器刷出来的bp会触发奇怪的bug，导致相对坐标变成attachedActor的世界坐标，回头研究一下
            AreaAbilityActor:K2_AttachToActor(InvokerActor, 'None', UE.EAttachmentRule.KeepWorld,
                    UE.EAttachmentRule.KeepWorld,UE.EAttachmentRule.KeepWorld)
            --手动添加微小偏移即可解决该bug
            AreaAbilityActor:K2_SetActorRelativeLocation(UE.FVector(0.1,0,0),false,nil,false)
        end
    end
end

function M:AreaAbilityCopyEffect(eAreaAbility)
    local NiagaraPath = self.mapAreaAbilityCopyEffect:Find(eAreaAbility)
    if NiagaraPath  then
        local EffectObj = UE.UObject.Load(tostring(NiagaraPath))
        self:LogWarn("ys","AreaAbilityCopyEffect: EffectObj = %s, NiagaraPath = %s",EffectObj,NiagaraPath)
        if self.actor and self.actor.Mesh then
            local NiagaraObj = UE.UNiagaraFunctionLibrary.SpawnSystemAttached(EffectObj, self.actor.Mesh, self.AreaAbilityUseAttachName)
        end
    end
end

function M:AreaAbilityScanEffect(eAreaAbility)
    local NiagaraPath = self.AreaAbilityScan
    if NiagaraPath then
        local EffectObj = UE.UObject.Load(tostring(NiagaraPath))
        if self.actor then
            local rootComp = self.actor:K2_GetRootComponent()
            if not self.ScanNiagaraObj then
                self:LogInfo("ys","Spawn ScanNiagaraObj: EffectObj = %s, NiagaraPath = %s",EffectObj,NiagaraPath)
                self.ScanNiagaraObj = UE.UNiagaraFunctionLibrary.SpawnSystemAttached(EffectObj, rootComp, self.AreaAbilityScanAttachName)
            else
                self.ScanNiagaraObj:Activate()
            end
        end
    end
    OutlinerUtils:SetAreaAbilityOverlapSphereActorOutline(true, self.actor,
            GameConstData.AreaAbilityScanRadius.IntValue,GameConstData.AreaAbilityScanStencil.IntValue,eAreaAbility)
end

function M:AreaAbilityScanEffectEnd()
    if self.ScanNiagaraObj then
        self:LogWarn("ys","AreaAbilityScanEffectEnd: self.ScanNiagaraObj = %s",self.ScanNiagaraObj)
        self.ScanNiagaraObj:Deactivate()
    end
    OutlinerUtils:SetAreaAbilityOverlapSphereActorOutline(false)
end

function M:Client_AreaAbility_RPC(AreaAbilityType)
    local BPConst = require("common.const.blueprint_const")
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
    
    self.sAreaAbility = AreaAbilityType
    self:LogWarn("ys","self.sAreaAbility = %d",self.sAreaAbility)
    
    if AreaAbilityVM.SetAreaAbilityUsing then
        AreaAbilityVM:SetAreaAbilityType(AreaAbilityType)
    end
end

function M:SetAreaAbilityType(AreaAbilityType)
    if self:HasAuthority() then
        --Set on Server
        self.sAreaAbility = AreaAbilityType
        
        --Store data on playstate
        self:StoreAreaAbilityData()
        
        --Sync to Client
        self:Client_AreaAbility(AreaAbilityType)
    end
end

function M:GetAreaAbilityType()
    return self.sAreaAbility
end

function M:Server_LoadAreaAbilityData_RPC()
    if self:HasAuthority() then
        --Load data from playstate
        local PlayerState = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0)
        local DataComponent = PlayerState.PlayerAreaAbilitySaveDataComponent
        self.sAreaAbility = DataComponent.sAreaAbility

        --Sync to Client
        self:Client_AreaAbility(self.sAreaAbility)

        self:LogInfo("ys","LoadAreaAbilityData Success, self.sAreaAbility = %s",Enum.E_AreaAbility.GetDisplayNameTextByValue(self.sAreaAbility))
    end
end

function M:StoreAreaAbilityData()
    if self:HasAuthority() then
        --Store data on playstate
        local PlayerState = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0)
        local DataComponent = PlayerState.PlayerAreaAbilitySaveDataComponent
        DataComponent.sAreaAbility = self.sAreaAbility

        self:LogInfo("ys","StoreAreaAbilityData Success")
    end
end

return M
