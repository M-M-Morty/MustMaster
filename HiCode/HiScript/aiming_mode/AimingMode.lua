require "UnLua"
local G = require("G")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local EdUtils = require("common.utils.ed_utils")
local OutlinerUtils = require("common.utils.Outliner_utils")
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local DataTableUtils = require("common.utils.data_table_utils")
local ConstTextTable = require("common.data.const_text_data").data
local GameConstData = require("common.data.game_const_data").data

local AimingMode = UnLua.Class()

function AimingMode:LogInfo(...)
    G.log:info_obj(self, ...)
end

function AimingMode:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function AimingMode:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function AimingMode:LogError(...)
    G.log:error_obj(self, ...)
end

function AimingMode:ReceiveBeginPlay()
    self:StartAimingMode()
    self.AreaAbilityIDIgnore = {}
    self.AreaAbilityActorsIgnore = {}
end

function AimingMode:ReceiveEndPlay(Reason)
    self:StopAimingMode()
end

function AimingMode:StartAimingMode()
    local WorldContext = self:GetWorld()
    local Player = G.GetPlayerCharacter(WorldContext, 0)

    local Locomotion = Player.AppearanceComponent
    if Locomotion then
        Locomotion:Multicast_SetRotationMode(UE.EHiRotationMode.Aiming, true)
        Locomotion:SetAimingModeType(self.AimingModeType)
    end
end

function AimingMode:StopAimingMode()
    local WorldContext = self:GetWorld()
    local Player = G.GetPlayerCharacter(WorldContext, 0)

    if Player then
        local Locomotion = Player.AppearanceComponent
        if Locomotion then
            Locomotion:Multicast_SetRotationMode(UE.EHiRotationMode.VelocityDirection, true)
        end
    end
end

function AimingMode:Raycast(X, Y)
    local WorldContext = self:GetWorld()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(WorldContext, 0)
    
    local suc, WorldLocation, WorldDirection = PlayerController:DeprojectScreenPositionToWorld(X, Y)

    if suc then
        local Start = WorldLocation
        local End = Start + WorldDirection * 10000

        --local ActorsToIgnore = UE.TArray(UE.AActor)
        --local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
        --ActorsToIgnore:Add(Player)
        --local OutHit = UE.FHitResult()
        --local TraceChannel = UE.EObjectTypeQuery.Visibility
        --if self.AimingModeType == Enum.E_AimingModeType.AreaAbilityCopy then
        --    TraceChannel = UE.EObjectTypeQuery.Visibility
        --end
        --local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingle(WorldContext, Start, End,
        --                                                            TraceChannel, true, ActorsToIgnore, UE.EDrawDebugTrace.None, OutHit, true,
        --                                                            UE.FLinearColor(1, 0, 0, 1), UE.FLinearColor(0, 1, 0, 1), 20)

        local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
        if self.AimingModeType == Enum.E_AimingModeType.AreaAbilityUse then
            ObjectTypes:Add(UE.EObjectTypeQuery.WorldDynamic)
            ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
            ObjectTypes:Add(UE.EObjectTypeQuery.Destructible)
            ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
        elseif self.AimingModeType == Enum.E_AimingModeType.AreaAbilityCopy then
            ObjectTypes:Add(UE.EObjectTypeQuery.WorldDynamic)
            ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
            ObjectTypes:Add(UE.EObjectTypeQuery.Destructible)
            ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
        end
        local ActorsToIgnore = UE.TArray(UE.AActor)
        local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
        ActorsToIgnore:Add(Player)
        local tbAttachedActors = Player:GetAttachedActors()
        for Ind=1,tbAttachedActors:Length() do
            local AttachedActor = tbAttachedActors:Get(Ind)
            ActorsToIgnore:Add(AttachedActor)
        end
         if self.AreaAbilityIDIgnore then
             local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
             if Player and Player.EdRuntimeComponent then
                 for EditorId,_ in pairs(self.AreaAbilityIDIgnore) do
                     local Actor = Player.EdRuntimeComponent:GetEditorActor(EditorId)
                     if Actor then
                         ActorsToIgnore:Add(Actor)
                     end
                 end
             end
        end
        local AreaAbilityActorsIgnoreTmp = {}
        for Ind=1,#self.AreaAbilityActorsIgnore do
            local Actor = self.AreaAbilityActorsIgnore[Ind]
            if Actor and Actor:IsValid() then
                ActorsToIgnore:Add(Actor)
                table.insert(AreaAbilityActorsIgnoreTmp, Actor)
            end
        end
        self.AreaAbilityActorsIgnore = AreaAbilityActorsIgnoreTmp
        local HitResult = UE.FHitResult()
        local IsHit = UE.UKismetSystemLibrary.LineTraceSingleForObjects(WorldContext, Start, End, ObjectTypes, false, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
        if self.AimingModeType == Enum.E_AimingModeType.AreaAbilityUse then
            if IsHit then
                return HitResult
            end
        elseif self.AimingModeType == Enum.E_AimingModeType.AreaAbilityCopy then
            if IsHit then
                local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint,
                    Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName,
                    HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(HitResult)
                self.AreaAbilityData = DataTableUtils.GetAreaAbilityRow(HitActor)
                self:LogInfo("ys","get AreaAbilityData = %s, HitActor = %s",self.AreaAbilityData, G.GetDisplayName(HitActor))
                if self.AreaAbilityData and self.AreaAbilityData.Transforms then
                    local _, Cnt = EdUtils:CheckAreaAbilitChildActors(HitActor)
                    if Cnt ~= self.AreaAbilityData.Transforms:Length() then
                        -- tell server to spawn AreaAbility Actor
                        local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
                        if Player and Player.CAreaAbilityComponent then
                            local UEComps = HitActor:K2_GetComponentsByClass(UE.UActorComponent)
                            for Ind=1,UEComps:Length() do
                                local UEComp = UEComps:Get(Ind)
                                if UEComp then
                                    if UEComp.SetCollisionProfileName then -- In case have wrong collision
                                        UEComp:SetCollisionProfileName("SmallObjectUnBreakable", true)
                                    end
                                    if UEComp.SetGenerateOverlapEvents then
                                        UEComp:SetGenerateOverlapEvents(true)
                                    end
                                end
                            end
                            Player.CAreaAbilityComponent:Server_SpawnAreaAbilityTrigger(HitActor, self.AreaAbilityData)
                        end
                    end
                end
                if HitActor then
                    local UEComps = HitActor:K2_GetComponentsByClass(UE.UActorComponent)
                    local bIgnoreActor = true
                    for Ind=1,UEComps:Length() do
                        local UEComp = UEComps:Get(Ind)
                        if UEComp and UEComp.GetCollisionProfileName then
                            local Name = UEComp:GetCollisionProfileName()
                            if Name == "Interacted_AreaAbility" then -- In Case of In the Room or elevator
                                bIgnoreActor = false
                                break
                            end
                        end
                    end
                    if bIgnoreActor then
                        table.insert(self.AreaAbilityActorsIgnore, HitActor)
                    end
                end
                if HitActor and ((HitActor.bAreaAbilityCopyThrough and HitActor.GetEditorID) ) then
                    local EditorID = HitActor:GetEditorID()
                    self.AreaAbilityIDIgnore[EditorID] = true
                end
                --local ObjectType = HitComponent:GetCollisionObjectType()
                --if ObjectType == UE.EObjectTypeQuery.WorldStatic then
                --    if not HitComponent:IsA(UE.UStaticMeshComponent) then
                --        return HitResult
                --    end
                --else
                --    return HitResult
                --end
                --end
                return HitResult
            end
        end
    end
    return nil
end

function AimingMode:CrossRaycast()
    local WorldContext = self:GetWorld()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(WorldContext, 0)

    local X, Y = PlayerController:GetViewportSize()

    return self:Raycast(X * 0.5, Y * 0.5)
end

function AimingMode:ReceiveTick_AreaAbilityCopy(DeltaSeconds, OutHit)
    local Actor
    if OutHit then
        local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint,
                Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName,
                HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(OutHit)
        Actor = HitActor
    end
    if self.AimingModeType ~= Enum.E_AimingModeType.AreaAbilityCopy then
        return
    end
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
    local WorldContext = self:GetWorld()
    local Player = G.GetPlayerCharacter(WorldContext, 0)
    local BPConst = require("common.const.blueprint_const")
    if not Actor or not Actor.eAreaAbility or Actor.eAreaAbility == Enum.E_AreaAbility.None then
        --AreaAbilityVM:SetAimed(false)
        OutlinerUtils:SetOverlapActorOutline(self.OldActor, false)
        self.OldActor = nil
        AreaAbilityVM:EnterReplicatorNomalState()
        AreaAbilityVM:HideShineInfo()
        Player:SendMessage("DetectAreaAbility")
        return
    end
    
    OutlinerUtils:SetOverlapActorOutline(self.OldActor, false)
    self.OldActor = Actor
    OutlinerUtils:SetOverlapActorOutline(Actor, true, GameConstData.AreaAbilityScanStencil.IntValue)

    --AreaAbilityVM:SetAimed(true)
    AreaAbilityVM:EnterReplicatorAimState()

    if Actor.eAreaAbility then
        self:LogInfo("ys","Actor : %s, eAreaAbility = %s", G.GetDisplayName(Actor), Enum.E_AreaAbility.GetDisplayNameTextByValue(Actor.eAreaAbility))
        
        local Row = EdUtils:GetAreaAbilityDataTableRow(Actor.eAreaAbility)

        if Row.TypeTextKey then
            AreaAbilityVM:SetShineInfo(ConstTextTable[Row.TypeTextKey].Content, Row.TypeNameIcon)
        end

    end

    Player:SendMessage("DetectAreaAbility", Actor)
end

function AimingMode:ReceiveTick_AreaAbilityUse(DeltaSeconds, OutHit)
    if self.AimingModeType ~= Enum.E_AimingModeType.AreaAbilityUse then
        return
    end
    -- 使用区域能力-这里指的是对别的物体使用
    local WorldContext = self:GetWorld()
    local Player = G.GetPlayerCharacter(WorldContext, 0)
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
    
    local Actor
    if OutHit then
         local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint,
                Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName,
                HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(OutHit)
        AreaAbilityVM:EnterReplicatorAimState()
        Actor = HitActor
        local ResponsiveActor = OutlinerUtils:GetOverlapSphereActor(Player, GameConstData.AreaAbilityScanRadius.IntValue)
        for Ind = 1,ResponsiveActor:Length() do
            local CurActor = ResponsiveActor:Get(Ind)
            self:LogInfo("ys","Overlapping Actor Name = %s",G.GetDisplayName(CurActor))
        end
        self:LogInfo("ys","Hit Actor : %s, ResponsiveActor.Contain = %s, ResponsiveActor.size = %s", G.GetDisplayName(Actor), ResponsiveActor:Contains(Actor),
                ResponsiveActor:Length())
        --能够响应区域能力物件的描边
        if not Actor or not Actor.rAreaAbility or Actor.rAreaAbility:Length() == 0 or not ResponsiveActor:Contains(Actor) then
            OutlinerUtils:SetActorOutline(true, self.OldActor,GameConstData.AreaAbilityScanStencil.IntValue)
            self.OldActor = nil
            AreaAbilityVM:EnterReplicatorNomalState()
        else
            OutlinerUtils:SetActorOutline(true, self.OldActor,GameConstData.AreaAbilityScanStencil.IntValue)

            if Actor.CheckResponseAreaAbilityType then
                local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
                if Player and Player.CAreaAbilityComponent then
                    local eAreaAbility = Player.CAreaAbilityComponent:GetAreaAbilityType()
                    if Actor:CheckResponseAreaAbilityType(eAreaAbility) then
                        self.OldActor = Actor
                        OutlinerUtils:SetActorOutline(true, Actor, GameConstData.AreaAbilityHighlightStencil.IntValue)
                    end
                end
            end

        end
        
        Player:SendMessage("UseAreaAbility_Other", ImpactPoint)
    else
        AreaAbilityVM:EnterReplicatorNomalState()
        Player:SendMessage("UseAreaAbility_Other")
    end
end

function AimingMode:ReceiveTick(DeltaSeconds)
    if self.AimingModeType == Enum.E_AimingModeType.AreaAbilityCopy or self.AimingModeType == Enum.E_AimingModeType.AreaAbilityUse then
        local OutHit = self:CrossRaycast()
        self:ReceiveTick_AreaAbilityCopy(DeltaSeconds, OutHit)
        self:ReceiveTick_AreaAbilityUse(DeltaSeconds, OutHit)
    end
end

return AimingMode