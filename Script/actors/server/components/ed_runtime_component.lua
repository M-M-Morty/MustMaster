local string = require("string")
local EdUtils = require("common.utils.ed_utils")
local table = require("table")
local G = require("G")
local GameAPI = require("common.game_api")
-- local UIManager = require('ui.ui_manager')
local utils = require("common.utils")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local NpcInteractItemModule = require("mission.npc_interact_item")
local ConstTextTable = require("common.data.const_text_data").data

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
     if not self:HasAuthority() then
         local PlayerActor = G.GetPlayerCharacter(self:GetWorld(), 0)
         if PlayerActor.PlayerState then
             local ItemManager = PlayerActor.PlayerState:GetPlayerController().ItemManager
             if ItemManager then
                 ItemManager:RegAddItemCallBack(self, self.OnItemAdd)
                 ItemManager:RegRemoveItemCallBack(self, self.OnItemRemove)
                 ItemManager:RegUpdateItemCallBack(self, self.OnItemUpdate)
             end
         end
     end
 end

function M:ReceiveEndPlay()
    if not self:HasAuthority() then
        local PlayerActor = G.GetPlayerCharacter(self:GetWorld(), 0)
        if PlayerActor then
            if PlayerActor.PlayerState then
                local ItemManager = PlayerActor.PlayerState:GetPlayerController().ItemManager
                if ItemManager then
                    ItemManager:UnRegAddItemCallBack(self, self.OnItemAdd)
                    ItemManager:UnRegRemoveItemCallBack(self, self.OnItemRemove)
                    ItemManager:UnRegUpdateItemCallBack(self, self.OnItemUpdate)
                end
            end
        end
    end
    --if self.AreaAbilityCollisionComp then
    --    self.AreaAbilityCollisionComp.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_AreaAbilityCollisionComp)
    --    self.AreaAbilityCollisionComp.OnComponentEndOverlap:Remove(self, self.OnEndOverlap_AreaAbilityCollisionComp)
    --end
    Super(M).ReceiveEndPlay(self)
end

-- function M:ReceiveTick(DeltaSeconds)
-- end

function M:HasAuthority()
    local owner = self:GetOwner()
    return owner and owner:HasAuthority() or false
end

function M:GetOwnerActorLabel()
    local owner = self:GetOwner()
    return owner and G.GetDisplayName(owner) or 'Unknow OwnerActor'
end

function M:GetOwnerController()
    local owner = self:GetOwner()   ---@type APawn
    if owner and owner.GetController then
        return owner:GetController()
    end
end

function M:IsOwnerControllerLocalPlayer()
    local controller = self:GetOwnerController()
    return controller and controller:IsLocalPlayerController() or false
end

function M:AddEditorActor(EditorActor)
    if self:IsOwnerControllerLocalPlayer() then
        local Owner = self:GetOwner()   ---@type APawn
        if Owner and Owner:IsClient() then
            local EditorID = EditorActor:GetEditorID()
            if EditorID then
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
end

function M:RemoveEditorActor(EditorActor)
    if self:IsOwnerControllerLocalPlayer() then
        local EditorID = EditorActor:GetEditorID()
        if EditorID then
            EdUtils.mapEdActors[EditorID] = nil
        end
    end
end

function M:GetEditorActor(EditorID)
    if self:IsOwnerControllerLocalPlayer() then
        if EditorID then
            local EdActor = EdUtils.mapEdActors[EditorID]
            if EdActor and not UE.UKismetSystemLibrary.IsValid(EdActor) then -- released object
                EdUtils.mapEdActors[EditorID] = nil
                EdActor = nil
            end
            return EdActor
        end
    end
end

function M:RemoveAllInteractedUI()
    self.arrClientNearbyActors:Clear()
    self:UpdateInteractItems(self.arrClientNearbyActors)
end

---@param nearbyActor AActor
function M:AddNearbyActor(nearbyActor)
    if self:IsOwnerControllerLocalPlayer() then
        self.arrClientNearbyActors:AddUnique(nearbyActor)
        self:UpdateInteractItems(self.arrClientNearbyActors)
        -- UIManager:UpdateInteractiveUI(self.arrClientNearbyActors, self)
    end
    self:LogInfo('zsf', 'player %s enter %s pick radius (%s)', self:GetOwnerActorLabel(), G.GetDisplayName(nearbyActor), self.arrClientNearbyActors:Length())
end

---@param nearbyActor AActor
function M:RemoveNearbyActor(nearbyActor)
    if not self.arrClientNearbyActors:Contains(nearbyActor) then
        -- 不在arrClientNearbyActors里的直接返回，避免触发后续UpdateInteractItems
        return
    end
    if self:IsOwnerControllerLocalPlayer() then
        self.arrClientNearbyActors:RemoveItem(nearbyActor)
        self:UpdateInteractItems(self.arrClientNearbyActors)
        -- UIManager:UpdateInteractiveUI(self.arrClientNearbyActors, self)
    end
    self:LogInfo('zsf', 'player %s leave %s pick radius (%s)', self:GetOwnerActorLabel(), G.GetDisplayName(nearbyActor), self.arrClientNearbyActors:Length())
end

function M:UpdateInteractItems(nearbyActors)
    local tbItem = {}
    local cnt = 1
    local bNotSort
    local ForceIndex
    for i = 1, nearbyActors:Num() do
        ---@type AActor
        local actorInstance = nearbyActors:Get(i)
        if actorInstance and actorInstance.GetUIShowActors then
            local Actors = actorInstance:GetUIShowActors()
            for _,Actor in ipairs(Actors) do
                if ForceIndex == nil then
                    ForceIndex = Actor.ForceIndex
                end
                if bNotSort == nil then
                    bNotSort = Actor.bNotSort
                end
                local splite_str, sUI = ". ", tostring(Actor.sUIPick)
                local index = sUI:find(splite_str)
                if index and index > 0 then
                    sUI = sUI:sub(index+2)
                end
                --Actor.sUIPick = tostring(cnt)..splite_str..sUI
                cnt = cnt + 1
                local function ItemSelectecCallback()
                    local localPlayerActor = self.actor
                    if localPlayerActor then
                        Actor:DoClientInteractAction(localPlayerActor)
                    end
                end
                local ShowUIPick = Actor.sUIPick
                if ConstTextTable[ShowUIPick] ~= nil then
                    ShowUIPick = ConstTextTable[ShowUIPick].Content
                end
                local Item = NpcInteractItemModule.DefaultInteractEntranceItem.new(Actor, ShowUIPick, ItemSelectecCallback, self:GetActorInteractType(Actor))
                if Actor.sUIIcon then
                    local Path = UE.UKismetSystemLibrary.GetPathName(Actor.sUIIcon)
                    Item:SetDisplayIconPath(Path)
                end
                if Actor.bUseable ~= nil then
                    Item:SetUsable(Actor.bUseable)
                end
                table.insert(tbItem, Item)
            end
        end
    end
    if self.actor.PlayerUIInteractComponent ~= nil then
        self.actor.PlayerUIInteractComponent:UpdateInteractItems(tbItem, bNotSort, ForceIndex)
    end
end

function M:hasClientNearbyActor()
    return self.arrClientNearbyActors:Num() > 0
end

function M:GetActorInteractType(actor)
    if actor.eInteractType == nil then
        return Enum.Enum_InteractType.Normal
    end
    return actor.eInteractType
end

---@param InvokerActor AActor
---@param InteractLocation Vector
function M:ProcessServerInteract(InvokerActor, Damage, InteractLocation)
    if self:HasAuthority() then
        if InvokerActor and InvokerActor.DoServerInteractAction then
            InvokerActor:DoServerInteractAction(self:GetOwner(), Damage, InteractLocation)
        end
    end
end

---@param InvokerActor AActor
function M:ProcessServerAreaAbilityCopy(AreaAbilityItemID, Location, eAreaAbility)
    if self:HasAuthority() then
        local ActorTransform = UE.FTransform()
        ActorTransform.Translation = Location
        local AreaAbilityActorUseOther = self:AreaAbilityUseEffectOther(ActorTransform, eAreaAbility)
        if AreaAbilityActorUseOther and AreaAbilityActorUseOther.DoServerAreaAbilityCopyAction then
            AreaAbilityActorUseOther.AreaAbilityItemID = AreaAbilityItemID
            AreaAbilityActorUseOther:DoServerAreaAbilityCopyAction(self:GetOwner())
        end
    end
end

function M:OnBeginOverlap_AreaAbilityCollisionComp(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if OtherActor.UseAreaAbility then
        -- 开始生效
        self:LogInfo("zsf", "OnBeginOverlap_AreaAbilityCollisionComp %s %s", G.GetDisplayName(OtherActor), self.eAreaAbility)
        OtherActor:UseAreaAbility(self.eAreaAbility, true)
    end
end

function M:OnEndOverlap_AreaAbilityCollisionComp(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if OtherActor.UseAreaAbility then
        -- 开始失效
        self:LogInfo("zsf", "OnEndOverlap_AreaAbilityCollisionComp %s %s", G.GetDisplayName(OtherActor), self.eAreaAbility)
        OtherActor:UseAreaAbility(self.eAreaAbility, false)
    end
end

function M:AreaAbilityUseEffectOther(ActorTransform, AreaAbilityType, OwnerActor)
    local AreaAbilityType = AreaAbilityType or Enum.E_AreaAbility.Lighting
    local WorldContext = self.actor:GetWorld()
    if not OwnerActor then
        OwnerActor = WorldContext
    end
    local Actor = WorldContext:SpawnActor(self.AreaAbilityLightClass, ActorTransform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, OwnerActor)
    Actor.eAreaAbilityMain = AreaAbilityType
    Actor.eAreaAbility = AreaAbilityType
    return Actor
end

function M:AreaAbilityUseEffect(eAreaAbility, InvokerActor, AreaAbilityItemID, StartLocation, Location)

    if not self:HasAuthority() then
        return
    end
    local Mesh = self.actor.Mesh
    if not Mesh then
        return
    end
    if eAreaAbility == Enum.E_AreaAbility.None then
        for Ind=1,self.PSList:Length() do
            local Actor = self.PSList:Get(Ind)
            --if Actor:GetParentComponent() == Mesh then
            --    Actor:K2_DetachFromComponent(UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
            --end
            if Actor then
                Actor:K2_DestroyActor()
            end
        end
        self.PSList:Clear()
    elseif eAreaAbility == Enum.E_AreaAbility.Lighting or true then -- todo(dougzhang): other AreaAbility
       for Ind=1,self.PSList:Length() do
            local Actor = self.PSList:Get(Ind)
           if Actor then
               Actor:K2_DestroyActor()
           end
        end
        self.PSList:Clear()
        local WorldContext = self.actor:GetWorld()
         local ActorTransform = UE.FTransform.Identity
        local Actor = WorldContext:SpawnActor(self.AreaAbilitySelfActorClass, ActorTransform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, WorldContext)
        -- set AreaAbilityType
        Actor.eAreaAbilityMain = self.eDefaultAreaAbility
        Actor.eAreaAbility = self.eDefaultAreaAbility
        local worldLocation = self.actor:K2_GetActorLocation()
        Actor:K2_SetActorLocation(UE.FVector(StartLocation.X, StartLocation.Y, StartLocation.Z), false, UE.FHitResult(), true)
        Actor:K2_AttachToComponent(Mesh, '', UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld)
        local function AreaAbilityUseEnd(args)
            local InvokerActor, AreaAbilityItemID, StartLocation, Location = args[1], args[2], args[3], args[4]
            local CanDestroy = true
            if CanDestroy then
                self:Multicast_AreaAbilityUse(self.actor, InvokerActor, AreaAbilityItemID, Enum.E_AreaAbility.None, StartLocation, Location)
            end
        end
        utils.DoDelay(self.actor, Actor.RemainTime, AreaAbilityUseEnd, {InvokerActor, AreaAbilityItemID, StartLocation, Location})
        --local worldLocation = self.actor:K2_GetActorLocation()
        --local ActorTransform = UE.FTransform(UE.FRotator(0, 0, 0):ToQuat(), UE.FVector(worldLocation.X, worldLocation.Y, worldLocation.Z), UE.FVector(1, 1, 1))
        --local Actor = WorldContext:SpawnActor(self.AreaAbilitySelfActorClass, ActorTransform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, WorldContext)
        ------Actor:K2_AttachToComponent(Mesh, self.AreaAbilityUseAttachName, UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
        --Actor:K2_AttachToActor(self:GetOwner(), '', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepRelative)
        --if Actor.RotatingMovement then
        --    Actor.RotatingMovement.PivotTranslation = worldLocation
        --end
        --Actor:K2_SetActorLocation(worldLocation, false, UE.FHitResult(), true)
        --Actor:K2_SetActorRelativeLocation(, false, nil, true)
        self.PSList:Add(Actor)
    end
end

---@param PlayerActor AActor
---@param InvokerActor AActor 这个可能是自己；或者是其他 NPC
---@param AreaAbilityItemID Int
function M:Multicast_AreaAbilityUse_RPC(ServerPlayerActor, InvokerActor, AreaAbilityItemID, eAreaAbility, StartLocation, Location)
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    if ServerPlayerActor == InvokerActor then -- (对自己使用）
        if eAreaAbility ~= Enum.E_AreaAbility.None then
            --if not self.AreaAbilityCollisionComp then
            --    self.AreaAbilityCollisionComp = self.actor:AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity, false)
            --    --self.AreaAbilityCollisionComp:SetCollisionObjectType(UE.ECollisionChannel.ECC_Pawn)
            --    self.AreaAbilityCollisionComp.ComponentTags = {"AreaAbilityCollisionComp"}
            --    self.AreaAbilityCollisionComp:SetCollisionProfileName('Interacted_ItemTrigger', true)
            --    self.AreaAbilityCollisionComp.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_AreaAbilityCollisionComp)
            --    self.AreaAbilityCollisionComp.OnComponentEndOverlap:Add(self, self.OnEndOverlap_AreaAbilityCollisionComp)
            --end
            --self.AreaAbilityCollisionComp:SetSphereRadius(self.AreaAbilitySelfUseRadius, true)
            --self.AreaAbilityCollisionComp:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
            self.bInUseAreaAbility = true
            if not self:HasAuthority() then
                HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Loop", self.actor)
                if ServerPlayerActor and ServerPlayerActor.Mesh then
                    ServerPlayerActor.Mesh:SetOverlayMaterial(self.AreaAbilitySelfMI)
                end
            end
        else
            self.bInUseAreaAbility = false
            --if self.AreaAbilityCollisionComp then
            --    self.AreaAbilityCollisionComp:SetSphereRadius(0.0, false)
            --    self.AreaAbilityCollisionComp:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
            --end
        end
        self:LogInfo("zsf", "Multicast_AreaAbilityUse_RPC %s %s %s %s", AreaAbilityItemID, eAreaAbility, Enum.E_AreaAbility.None, self.AreaAbilityCollisionComp)

        -- 区域能力变化需要检测当前的生效状态
        --if self.AreaAbilityCollisionComp then
        --    local OverlappedActors = UE.TArray(UE.AActor)
        --    self.AreaAbilityCollisionComp:GetOverlappingActors(OverlappedActors)
        --    for Index = 1, OverlappedActors:Length() do
        --        local OtherActor = OverlappedActors:Get(Index)
        --        if OtherActor.UseAreaAbility then
        --            self:LogInfo("zsf", "UseAreaAbility %s %s", G.GetDisplayName(OtherActor), self.eAreaAbility)
        --            if eAreaAbility==Enum.E_AreaAbility.None then
        --                OtherActor:UseAreaAbility(self.eAreaAbility, false)
        --            else
        --                OtherActor:UseAreaAbility(eAreaAbility, true)
        --            end
        --        end
        --    end
        --end

        -- 标识当前使用何种的区域能力
        self.eAreaAbility = eAreaAbility
    else
        if self.actor == ServerPlayerActor then
            --PlayerActor:SendMessage("ReceiveAreaAbility", self)
            local ActorLocation = Location
            self.AreaAbilityUseLocation = Location
            local PlayerLocation = ServerPlayerActor:K2_GetActorLocation()
            local ForwardV = ActorLocation - PlayerLocation
            local Rotator = UE.UKismetMathLibrary.MakeRotationFromAxes(ForwardV,UE.FVector(0.0,0.0,0.0), UE.FVector(0.0,0.0,0.0))
            local CustomSmoothContext = UE.FCustomSmoothContext()
            ServerPlayerActor:GetLocomotionComponent():SetCharacterRotation(Rotator, false, CustomSmoothContext)

             local Montage = self.AreaAbilityCopyAnim
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
                                local AreaAbilityActorUseOther = self:AreaAbilityUseEffectOther(ActorTransform, eAreaAbility)
                                if AreaAbilityActorUseOther then
                                    AreaAbilityActorUseOther:AreaAbility_Fly2Other(self.AreaAbilityUseLocation)
                                    if AreaAbilityActorUseOther.Multicast_UseOtherDelay then
                                        AreaAbilityActorUseOther:Multicast_UseOtherDelay(self.AreaAbilityUseDuration)
                                    end
                                end
                            else
                                --if self.AreaAbilityActorUseOther then
                                --    self.AreaAbilityActorUseOther:K2_DestroyActor()
                                --    self.AreaAbilityActorUseOther = nil
                                --end
                            end
                        else
                            HiAudioFunctionLibrary.PlayAKAudio("Scn_Skills_Light_Cast", self.actor)
                        end
                    end)
                end
            end
        end
    end

    if ServerPlayerActor == InvokerActor then -- (对自己使用）
        self:AreaAbilityUseEffect(self.eAreaAbility, InvokerActor, AreaAbilityItemID, StartLocation, Location)
    end

    if self:HasAuthority() then
        return
    else
        local ItemCnt = self:AddAreaAbilityItem(AreaAbilityItemID, 0)
        self:LogInfo("zsf", "[UI] UseAreaAbility %s %s", AreaAbilityItemID, ItemCnt)
        if AreaAbilityVM.SetAreaAbilityUsing then
            AreaAbilityVM:SetHasAreaAbility(ItemCnt>0)
            AreaAbilityVM:SetAreaAbilityUsing(ItemCnt <= 0)
            AreaAbilityVM:SetAreaCopyerUsable(ItemCnt <= 0)
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
        else
        end
        if ServerPlayerActor == InvokerActor then -- (对自己使用）
            self:AreaAbilityUseEffect(self.eAreaAbility, InvokerActor, AreaAbilityItemID, StartLocation, Location)
        else
        end
        return
    end
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
                local BPConst = require("common.const.blueprint_const")
                local ItemCnt = self:AddAreaAbilityItem(AreaAbilityItemID, 0)
                AreaAbilityVM:SetHasAreaAbility(ItemCnt>0)
                AreaAbilityVM:SetAreaAbilityUsing(ItemCnt <= 0)
                AreaAbilityVM:SetAreaCopyerUsable(ItemCnt <= 0)
            end)
        end
    end
end

---@param InvokerActor AActor 这个可能是自己；或者是其他 NPC
---@param AreaAbilityItemID Int
---@param eAreaAbility Enum
function M:ProcessServerAreaAbilityUse(InvokerActor, AreaAbilityItemID, eAreaAbility, StartLocation, Location)
    if not self:HasAuthority() then
        return
    end
    -- 这里区分是对自己还是对其他物体使用; 自己的能力还在使用中，不能使用
    if self:GetOwner() == InvokerActor then
        if self.eAreaAbility ~= Enum.E_AreaAbility.None then
            return
        end
    end

    -- 使用了该能力；ItemCnt--
    -- 这里遍历能力多了需要优化下 --
    local ItemCnt = self:AddAreaAbilityItem(AreaAbilityItemID, -1)
    self:Multicast_AreaAbilityUse(self.actor, InvokerActor, AreaAbilityItemID, eAreaAbility, StartLocation, Location)
    -- 这里区域能力有个持续时间; 持续时间过后则结束当前效果
    --local function AreaAbilityUseEnd(args)
    --    local InvokerActor, AreaAbilityItemID, Location = args[1], args[2], args[3]
    --    --self.eAreaAbility = Enum.E_AreaAbility.None
    --    local CanDestroy = true
    --    if CanDestroy then
    --        self:Multicast_AreaAbilityUse(self.actor, InvokerActor, AreaAbilityItemID, Enum.E_AreaAbility.None, Location)
    --    end
    --end
    if self:GetOwner() == InvokerActor then
        local Duration = self.AreaAbilityUseDuration
        --utils.DoDelay(self.actor, Duration, AreaAbilityUseEnd, {InvokerActor, AreaAbilityItemID, Location})
    end

    self.Overridden.ProcessServerAreaAbilityUse(self, InvokerActor, AreaAbilityItemID, eAreaAbility, StartLocation, Location)
end

---@param InvokerActor AActor 获取区域能力client检测到的Actor; server 根据 Actor 合数据在对应位置 Attach AreaAbility Trigger
---@param AreaAbilityData (S_AreaAbility) 对应的 DT_AreaAbility 中的一行
function M:Server_SpawnAreaAbilityTrigger_RPC(InvokerActor, AreaAbilityData)
    -- add trigger via AreaAbilityData.Transforms
    if not AreaAbilityData then
        return
    end
    local CreatedMap,_ = EdUtils:CheckAreaAbilitChildActors(InvokerActor)
    local Transforms = AreaAbilityData.Transforms
    for Ind=1, Transforms:Length() do
        local AreaAbilityTag = EdUtils.AreaAbilityPrefix..tostring(Ind)
        if not CreatedMap[AreaAbilityTag] then
            --todo: change AreaAbility Type, Lighting, Dark and so on
            local ActorTransform = Transforms[Ind]
            local InvokerActorLocation = InvokerActor:K2_GetActorLocation()
            ActorTransform.Translation = UE.UKismetMathLibrary.Add_VectorVector(ActorTransform.Translation, InvokerActorLocation)
            local AreaAbilityActor = self:AreaAbilityUseEffectOther(ActorTransform, AreaAbilityData.Ability)
            AreaAbilityActor.AreaAbilityTag = AreaAbilityTag
            --AreaAbilityActor:K2_AttachToActor(InvokerActor, '', UE.EAttachmentRule.KeepWorld,
            --        UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld)
            --AreaAbilityActor:K2_SetWorldTransform(ActorTransform, false, nil, false)
        end
    end
end

---@param EditorIds Array
function M:ProcessLoadMutableActorAction(EditorIds)
    local MutableActorOperations = require("actor_management.mutable_actor_operations")
    for ind=1,EditorIds:Length() do
        local EditorID = EditorIds:Get(ind)
        MutableActorOperations.LoadMutableActor(tostring(EditorID))
    end
end

function M:Server_ItemsAdd_RPC(ItemsInfo)
    local ItemManager = self.actor.PlayerState:GetPlayerController().ItemManager
    for Ind=1,ItemsInfo:Length() do
        local Node = ItemsInfo[Ind]
        local ItemId = Node.ItemID
        local ItemNum = Node.ItemNum
        ItemManager:AddItemByExcelID(ItemId, ItemNum)
    end
end

function M:Client_ItemOpenDetails_RPC(ItemDetailsOpenType, ItemsInfo, StrParams)
    if self:HasAuthority() then
        return
    end
    local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    local ItemDef = require("CP0032305_GH.Script.item.ItemDef")

    local tItemsInfo = {}
    local ItemId
    for Ind=1,ItemsInfo:Length() do
        local Node = ItemsInfo[Ind]
        if ItemId == nil then
            ItemId = Node.ItemID
        end
        table.insert(tItemsInfo, {ItemID=Node.ItemID,ItemNum=Node.ItemNum})
    end
    if ItemDetailsOpenType == Enum.E_ItemDetailsOpenType.OpenDetailsAndItemsAddWhenClose then
        if ItemId then
            local ItemConfig = ItemUtil.GetItemConfigByExcelID(ItemId)
            if ItemConfig and ItemConfig.category_ID == ItemDef.CATEGORY.TASK_ITEM and ItemConfig.task_item_display_type == ItemDef.TASK_ITEM_DISPLAY_TYPE.PICTURE then
                ---@type WBP_Knapsack_ViewImg
                local WBPImg = UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_ViewImg)
                WBPImg:SetImages(ItemConfig.task_item_details)
                local function CloseCallback()
                    local tItemsInfoNew = {}
                    for _,ItemNode in ipairs(tItemsInfo) do
                        local ItemDetails = self.ItemDetails:Copy()
                        ItemDetails.ItemID = ItemNode.ItemID
                        ItemDetails.ItemNum = ItemNode.ItemNum
                        table.insert(tItemsInfoNew, ItemDetails)
                    end
                    self:Server_ItemsAdd(tItemsInfoNew)
                    WBPImg:SetCloseCallBack(nil)
                end
                WBPImg:SetCloseCallBack(CloseCallback)
            end
        end
    elseif ItemDetailsOpenType == Enum.E_ItemDetailsOpenType.OpenInteractionEmitterAndItemsAddWhenClose then
        local ConstTextTable = require("common.data.const_text_data").data
        local PicText = require("CP0032305_GH.Script.common.pic_const")
        local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
        local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        local ObjectInfo = ""
        local ConstTextConfig = ConstTextTable[StrParams[1]]
        if ConstTextConfig then
            ObjectInfo = ConstTextConfig.Content
        end
        local InText = ""
        ConstTextConfig = ConstTextTable[StrParams[2]]
        if ConstTextConfig then
            InText = ConstTextConfig.Content
        end
        local Texture2D = PicText.GetPicResource(StrParams[3])
        local ImagePath = UE.UKismetSystemLibrary.GetPathName(Texture2D)
        local bShowTopTip =  StrParams[4]=="true"
        local CallBack=function()
            local tItemsInfoNew = {}
            for _,ItemNode in ipairs(tItemsInfo) do
                local ItemDetails = self.ItemDetails:Copy()
                ItemDetails.ItemID = ItemNode.ItemID
                ItemDetails.ItemNum = ItemNode.ItemNum
                table.insert(tItemsInfoNew, ItemDetails)
            end
            self:Server_ItemsAdd(tItemsInfoNew)
        end
        HudMessageCenterVM:ShowInteractionEmitter(ObjectInfo,InText,ImagePath,CallBack,bShowTopTip)
    end
end

function M:AreaAbilityCopyEffect(eAreaAbility)
    local NiagaraPath = self.mapAreaAbilityCopyEffect:Find(eAreaAbility)
    if NiagaraPath  then
        local EffectObj = UE.UObject.Load(tostring(NiagaraPath))
        if self.actor and self.actor.Mesh then
            local NiagaraObj = UE.UNiagaraFunctionLibrary.SpawnSystemAttached(EffectObj, self.actor.Mesh, self.AreaAbilityUseAttachName)
        end
    end
end

function M:UpdateAreaAbilityItems(ItemInfo)
    local BPConst = require("common.const.blueprint_const")
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    if AreaAbilityVM.SetAreaAbilityUsing then
        local PlayerActor = G.GetPlayerCharacter(self:GetWorld(), 0)
        local ItemCnt = self:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
        AreaAbilityVM:SetHasAreaAbility(ItemCnt>0)
        AreaAbilityVM:SetAreaAbilityUsing(ItemCnt <= 0)
        AreaAbilityVM:SetAreaCopyerUsable(ItemCnt <= 0)
    end
end

function M:Client_AreaAbilityItems_RPC(arrAreaAbilityItems)
    local BPConst = require("common.const.blueprint_const")
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    self.arrAreaAbilityItems = arrAreaAbilityItems

    local ItemCnt = self:AddAreaAbilityItem(BPConst.AreaAbilityItemLightID, 0)
    AreaAbilityVM:SetHasAreaAbility(ItemCnt>0)
    AreaAbilityVM:SetAreaAbilityUsing(ItemCnt <= 0)
    AreaAbilityVM:SetAreaCopyerUsable(ItemCnt <= 0)
end

function M:AddAreaAbilityItem(AreaAbilityItemID, AreaAbilityItemNum)
    self.arrAreaAbilityItems=self.arrAreaAbilityItems+AreaAbilityItemNum
    if self.arrAreaAbilityItems < 0 then
        self.arrAreaAbilityItems = 0
    end
    if self:HasAuthority() then
        if AreaAbilityItemNum ~= 0 then
            self:Client_AreaAbilityItems(self.arrAreaAbilityItems)
        end
    end
    return self.arrAreaAbilityItems
end

function M:OnItemAdd(Item)
    self:LogInfo("zsf", "OnItemAdd %s %s", Item.ExcelID, Item.StackCount)
    self:UpdateAreaAbilityItems({ItemID=Item.ExcelID, ItemNum=Item.StackCount})
end

function M:OnItemRemove(_, ExcelID, _)
    self:LogInfo("zsf", "OnItemRemove %s", ExcelID)
    self:UpdateAreaAbilityItems({ItemID=ExcelID, ItemNum=0})
end

function M:OnItemUpdate(Item)
    self:LogInfo("zsf", "OnItemUpdate %s", Item)
    self:UpdateAreaAbilityItems({ItemID=Item.ExcelID, ItemNum=Item.StackCount})
end

function M:MissionComplete(eMiniGame, sData)
    local json = require("thirdparty.json")
    local Param = {
        eMiniGame=eMiniGame,
        sData=sData
    }
    local Data=json.encode(Param)
    self.Event_MissionComplete:Broadcast(Data)
end

return M
