require "UnLua"
---Destructible base actor and implement BPI_Destructible interface.
---Child class can overwrite this to show different break behavior.

local table = require("table")
local G = require("G")
local BPConst = require ("common.const.blueprint_const")
local utils = require("common.utils")
local MutableActorOperations = require("actor_management.mutable_actor_operations")

local ActorBase = require("actors.common.interactable.base.interacted_item")
--local Actor = require("common.actor")

local Destructible = Class(ActorBase)

function Destructible:LogInfo(...)
    G.log:info_obj(self, ...)
end

function Destructible:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function Destructible:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function Destructible:LogError(...)
    G.log:error_obj(self, ...)
end

function Destructible:Initialize(...)
    Super(Destructible).Initialize(self, ...)

    self.bBreak = false
    self.bBreakStarted = false
    self.SMTransform = nil
    self.SMTransform_old = nil
end

function Destructible:GetEditorDataComp()
    local HiEditorDataCompClass = UE.UClass.Load(BPConst.HiEditorDataComp)
    local HiEditorDataComp = self:GetComponentByClass(HiEditorDataCompClass)
    return HiEditorDataComp
end

function Destructible:GetEditorID()
    local HiEditorDataComp = self:GetEditorDataComp()
    if HiEditorDataComp then
        return HiEditorDataComp.EditorId
    end
end

function Destructible:ReceiveDamageOnMulticast(PlayerActor, Damage, InteractLocation)
    self.InteractLocation = InteractLocation
    --if self:HasAuthority() then
    --    return
    --end
    if false then
        --if not self.bDestroying then
        --    self.bDestroying = true
        --    self.GeometryCollectionComponent:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        --    if self.Multicast_RemoveOnBreak then
        --        self:Multicast_RemoveOnBreak()
        --    end
        --end
    else
        local SpawnTransform = UE.UKismetMathLibrary.MakeTransform(InteractLocation, UE.FRotator(0, 0, 0), UE.FVector(1, 1, 1))
        if self.bRegisterAllComponents then
            UE.UHiBlueprintFunctionLibrary.RegisterAllComponents(self.FSActor)
            self.bRegisterAllComponents = false
        end
        if self.FSActor then
            self.FSActor:K2_SetActorTransform(SpawnTransform, false, nil, true)
            self.FSActor.UseDirectionalVector = false
            self.FSActor.UseRadialVector = true
            self.FSActor.RadialMagnitude = 750
            self.FSActor:CE_Trigger()
        end
    end
end

function Destructible:Server_ReceiveDamage(PlayerActor, Damage, InteractLocation)
    self.Overridden.Server_ReceiveDamage(self, PlayerActor, Damage, InteractLocation)
    local EditorId = self:GetEditorID()
    if not EditorId then -- 不是编辑器 Actor 还是按原来流程处理
        return
    end
    if self.HP then
        self.HP = self.HP-Damage
        if self.HP <= 0 then
            local EditorId = self:GetEditorID()
            if EditorId and not self.bBreakStarted then
                self.bBreakStarted = true
                local function cb()
                    MutableActorOperations.UnloadMutableActor(EditorId)
                end
                UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, cb}, 5.0, false)
            end
        end
    end
end

function Destructible:ReceiveBeginPlay()
    Super(Destructible).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("Destructible(%s, server: %s)", G.GetObjectName(self), self:IsServer())

    --self.Sphere.OnComponentBeginOverlap:Add(self, self.OnSphereBeginOverlap)
    --self.Sphere.OnComponentEndOverlap:Add(self, self.OnSphereEndOverlap)
    self.StaticMesh.OnComponentHit:Add(self, self.OnComponentHitSM)
    self.StaticMesh.OnComponentBeginOverlap:Add(self, self.OnComponentBeginOverlapSM)
    self.GeometryCollectionComponent.OnComponentHit:Add(self, self.OnComponentHitGC)
    self.GeometryCollectionComponent.OnComponentBeginOverlap:Add(self, self.OnComponentBeginOverlapGC)
    if self.GCField and self.GCField.ChildActor then
        self.GCField.ChildActor.BoxVolumeCol.OnComponentHit:Add(self, self.OnComponentHitGCField)
        self.GCField.ChildActor.BoxVolumeCol.OnComponentBeginOverlap:Add(self, self.OnComponentBeginOverlapGCField)
    end
    -- 兼容原来没有配置的
    if not self.StaticMesh.StaticMesh then
        self:SetGCActive(true, false)
    else
        self:SetGCActive(false, false)
    end
    self.SMTransform = self.StaticMesh:K2_GetComponentToWorld()
    self.SMTransform_old = self.SMTransform
    local Origin, BoxExtent, SphereRadius = UE.UKismetSystemLibrary.GetComponentBounds(self.GeometryCollectionComponent)
    self.GC_BoxExtent = BoxExtent

    local SpawnTransform = self.GeometryCollectionComponent:K2_GetComponentToWorld()

    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn

    local SpawnTransform = UE.FTransform(self:K2_GetActorRotation():ToQuat(), self:K2_GetActorLocation())
    --self.FSActor = GameAPI.SpawnActor(self:GetWorld(), self.HitFSPath, SpawnTransform, SpawnParameters)
    self.FSActor = self.FSActorComp.ChildActor
    if self.FSActor then
        UE.UHiBlueprintFunctionLibrary.UnregisterAllComponents(self.FSActor)
        self.bRegisterAllComponents = true
    end

    --local FSMaterBreakAllPath = UE.UKismetSystemLibrary.BreakSoftClassPath(self.FSMaterBreakAll)
end

function Destructible:OnSphereBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
end

function Destructible:OnSphereEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
end

function Destructible:OnComponentHitSM(HitComponent, OtherActor, OtherComp, NormalImpulse, HitResult)
end

function Destructible:OnComponentHitGC(HitComponent, OtherActor, OtherComp, NormalImpulse, HitResult)
    if not self:HasAuthority() then
        return
    end
    local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint,
        Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName,
        HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(HitResult)
    local Impulse = UE.UKismetMathLibrary.Multiply_VectorFloat(ImpactNormal, 100)
    -- Add offset to make torque and cause rotation.
    self.GeometryCollectionComponent:AddImpulseAtLocation(Impulse, ImpactPoint)
end

function Destructible:OnComponentBeginOverlapSM(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    --self:SetGCActive(true)
    --self:OnBreak(nil, nil, nil, nil)
end

function Destructible:OnComponentHitGCField(HitComponent, OtherActor, OtherComp, NormalImpulse, HitResult)
    --self.GeometryCollectionComponent.ObjectType = UE.EObjectStateTypeEnum.Chaos_Object_Dynamic
    --self.GeometryCollectionComponent:SetSimulatePhysics(true)
    --self:OnBreak(nil, nil, HitResult, nil)
    --if not self.StaticMesh.StaticMesh then
    --    if self.GCField and self.GCField.ChildActor then
    --        self.GCField.ChildActor:K2_DestroyActor()
    --    end
    --end
    --self:SetGCActive(true, true)
end

function Destructible:OnComponentBeginOverlapGCField(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
end

function Destructible:OnComponentBeginOverlapGC(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    --local SpawnTransform = self.GeometryCollectionComponent:K2_GetComponentToWorld()
    --self.FSActor:K2_SetActorTransform(SpawnTransform, false, nil, true)
    --self.FSActor.UseDirectionalVector = false
    --self.FSActor.UseRadialVector = true
    --self.FSActor.RadialMagnitude = 750
    --self.FSActor:CE_Trigger()
end


function Destructible:ReceiveEndPlay()
    Super(Destructible).ReceiveEndPlay(self)
    --self.Sphere.OnComponentBeginOverlap:Remove(self, self.OnSphereBeginOverlap)
    --self.Sphere.OnComponentEndOverlap:Remove(self, self.OnSphereEndOverlap)
    self.StaticMesh.OnComponentHit:Remove(self, self.OnComponentHitSM)
    self.StaticMesh.OnComponentBeginOverlap:Remove(self, self.OnComponentBeginOverlapSM)
    self.GeometryCollectionComponent.OnComponentHit:Remove(self, self.OnComponentHitGC)
    self.GeometryCollectionComponent.OnComponentBeginOverlap:Remove(self, self.OnComponentBeginOverlapGC)
    if self.GCField and self.GCField.ChildActor then
        self.GCField.ChildActor.BoxVolumeCol.OnComponentHit:Remove(self, self.OnComponentHitGCField)
        self.GCField.ChildActor.BoxVolumeCol.OnComponentBeginOverlap:Remove(self, self.OnComponentBeginOverlapGCField)
    end

    if self.FSActor then
        self.FSActor:K2_DestroyActor()
    end
end
--[[
    Implement BPI_Destructible interface.
]]
function Destructible:OnHit(Instigator, Causer, Hit, Durability, RemainDurability)
    G.log:debug(self.__TAG__, "OnHit instigator: %s, Causer: %s, Durability: %f, Remain: %f", G.GetObjectName(Instigator), G.GetObjectName(Causer), Durability, RemainDurability)
end

function Destructible:OnChaosBreak_SkillBehavior()
    if self.bBreakAll then -- BP_SC_Prop_street_02 这种显示的是一个铁链，实际上就是个StaticMesh做了整体的碰撞，不是精细物理模拟，破碎就要整个都破碎才能表现的比较正常
        -- 这里可以设置 Decay 衰减的表现；目前不需要
        local SpawnTransform = self.GeometryCollectionComponent:K2_GetComponentToWorld()
        if self.bRegisterAllComponents then
            UE.UHiBlueprintFunctionLibrary.RegisterAllComponents(self.FSActor)
            self.bRegisterAllComponents = false
        end
        self.FSActor:K2_SetActorTransform(SpawnTransform, false, nil, true)
        local FSBoxExtent = self.FSActor.BoxVolumeCol:GetScaledBoxExtent()
        local Scale = UE.UKismetMathLibrary.Divide_VectorVector(self.GC_BoxExtent, FSBoxExtent)
        Scale.Z = Scale.Z * 2.0
        self.FSActor:SetActorScale3D(Scale)
        self.FSActor:K2_SetActorRotation(UE.FRotator(0, 0, 0), false)
        self.FSActor:CE_Trigger()
    end
end

function Destructible:OnChaosBreak()
    self.Overridden.OnChaosBreak(self)

    self:OnChaosBreak_SkillBehavior()
    self.bChaosBreak = true
    if not self:HasAuthority() then
        --HiAudioFunctionLibrary.PlayAKAudio("Play_Scn_Itm_WoodBox_Normal_Impact", self)
        if self.NS_Break and self.InteractLocation then
            local HitResult = UE.FHitResult()
            self.NS_Break:K2_SetWorldLocation(self.InteractLocation, false, HitResult, false)
            self.NS_Break:SetActive(true, true)
        end
    end
    local isDelayDelete = true
    if self:GetEditorID() then
        if not self:HasAuthority() then
            local localPlayerActor = G.GetPlayerCharacter(self, 0)
            local InteractLocation = self.InteractLocation and self.InteractLocation or UE.FVector(0, 0, 0)
            isDelayDelete = false
            self:DoClientInteractActionWithLocation(localPlayerActor, 1, InteractLocation)
        end
    end
    if isDelayDelete then
        if self.bBreakStarted then
            return
        end

        self.bBreakStarted = true
        UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.K2_DestroyActor}, self.DestroyDelayTime, false)
        if self:IsServer() then
            self.GeometryCollectionComponent:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        end
    end
end

function Destructible:SetGCActive(bOn, bGCPhysic)
    --self.StaticMesh:SetSimulatePhysics(not bOn)
    self.StaticMesh:SetVisibility(not bOn)
    self.StaticMesh:SetHiddenInGame(bOn)
    if bOn then
        self.StaticMesh:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    else
        self.StaticMesh:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
    end


    self.GeometryCollectionComponent:SetActive(bOn)
    if bGCPhysic then
        self.GeometryCollectionComponent:SetSimulatePhysics(bGCPhysic)
        --self.GeometryCollectionComponent:SetSimulatePhysics(true)
    end
    self.GeometryCollectionComponent:SetVisibility(bOn)
    self.GeometryCollectionComponent:SetHiddenInGame(not bOn)
    self.GeometryCollectionComponent.EnableClustering = not bOn
    if self.StaticMesh.StaticMesh then
        local SMTransform = self.StaticMesh:K2_GetComponentToWorld()
        self.GeometryCollectionComponent:K2_SetWorldTransform(SMTransform, false, nil, false)
        --self.GeometryCollectionComponent:K2_AttachToComponent(self.StaticMesh, "", UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld)
    end
end

function Destructible:OnBreak(Instigator, Causer, Hit, Durability)
    if not (self.GeometryCollectionComponent and self.GeometryCollectionComponent.RestCollection) then -- Invalid RestCollection
        return
    end
    --if self.bNoBreak then -- ImplicitObjectUnion
    --    return
    --end

    local HitFS = self.DestructComponent.HitFS

    if HitFS then
        self:SetGCActive(true, true)

        local function do_break()
            self.bBreak = true
            if self.InteractionComponent then
                self.InteractionComponent:SetInteractable(false)
            end

            local World = self:GetWorld()
            local SpawnTransform = self:GetTransform()
            if Hit then
                local HitPoint = UE.FVector(Hit.ImpactPoint.X, Hit.ImpactPoint.Y, Hit.ImpactPoint.Z)
                local HitNormal = UE.UKismetMathLibrary.NegateVector(Hit.ImpactNormal)
                --G.log:debug(self.__TAG__, "OnBreak instigator: %s, Causer: %s, Durability: %f, HitFS: %s, Hit: %s, HitPoint = (%s, %s, %s)", G.GetObjectName(Instigator),
                -- G.GetObjectName(Causer), Durability, HitFS, Hit, HitPoint.X, HitPoint.Y, HitPoint.Z)

                local Center, Extent = self:GetActorBounds()
                if Causer and UE.UKismetMathLibrary.VSize(UE.UKismetMathLibrary.Subtract_VectorVector(HitPoint, Center)) > UE.UKismetMathLibrary.VSize(Extent) then
                    G.log:debug(self.__TAG__, "OnBreak instigator: %s, Causer: %s, Durability: %f, HitFS: %s", G.GetObjectName(Instigator), G.GetObjectName(Causer), Durability, HitFS)
                    HitPoint = Center--UE.FVector(Hit.Location.X, Hit.Location.Y, Hit.Location.Z)
                    HitNormal = UE.UKismetMathLibrary.GetDirectionUnitVector(Causer:K2_GetActorLocation(), Center)
                end
                SpawnTransform = UE.UKismetMathLibrary.MakeTransform(HitPoint, UE.UKismetMathLibrary.Conv_VectorToRotator(HitNormal), UE.FVector(1, 1, 1))
            end
            if self.bRegisterAllComponents then
                UE.UHiBlueprintFunctionLibrary.RegisterAllComponents(self.FSActor)
                self.bRegisterAllComponents = false
            end
            if self.FSActor then
                self.FSActor:K2_SetActorTransform(SpawnTransform, false, nil, true)
                self.FSActor.UseDirectionalVector = false
                self.FSActor.UseRadialVector = true
                self.FSActor.RadialMagnitude = 750
                self.FSActor:CE_Trigger()
            end

            utils.DoDelay(self:GetWorld(), 0.1, function() -- MissionNode Actor HitEvent, must do delay
                if self.GCField and self.GCField.ChildActor then
                    self.GCField.ChildActor:K2_DestroyActor()
                end
            end)

            if self.DoChaosBreakFunc then
               self:DoChaosBreakFunc()
            end
        end
        --UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, do_break}, 0.01, false)
        if self.bAttackBreak ~= true then
            return
        end
        do_break()
        self:OnChaosBreak()
    end
end

--[[
    Handle capture and throw behavior.
]]
function Destructible:OnCapture(Instigator)
    G.log:debug(self.__TAG__, "OnCapture by %s", G.GetObjectName(Instigator))

    if self.GeometryCollectionComponent then
        --self.GeometryCollectionComponent:SetSimulatePhysics(false)
        --self.GeometryCollectionComponent:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    end
end

function Destructible:OnAbsorbCancel()
    G.log:debug(self.__TAG__, "OnAbsorbCancel")
    if self.GeometryCollectionComponent then
        --self.GeometryCollectionComponent:SetSimulatePhysics(true)
        --self.GeometryCollectionComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
    end
end

function Destructible:OnThrow(Instigator)
    G.log:debug(self.__TAG__, "OnThrow by %s", G.GetObjectName(Instigator))
    --if self.GeometryCollectionComponent then
    --    self.GeometryCollectionComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
    --end
end

function Destructible:OnDestroy()
    G.log:debug(self.__TAG__, "OnDestroy")
    --self.GeometryCollectionComponent:SetSimulatePhysics(true)
    --Hit.ImpactPoint = self:K2_GetActorLocation()
    self:OnBreak(nil, nil, nil, 0)
    if self.GCField and self.GCField.ChildActor then
        self.GCField.ChildActor:K2_DestroyActor()
    end
end

return RegisterActor(Destructible)
