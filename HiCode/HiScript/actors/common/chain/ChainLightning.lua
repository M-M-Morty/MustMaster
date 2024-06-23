--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local ChainBase = require("actors.common.chain.ChainBase")
local SkillUtils = require("common.skill_utils")
local HiCollisionLibrary = require("common.HiCollisionLibrary")

---@type BP_ChainLightning_C
local ChainLightning = Class(ChainBase)

function ChainLightning:ReceiveBeginPlay()
    Super(ChainLightning).ReceiveBeginPlay(self)
    G.log:info(self.__TAG__, "ChainLightning:ReceiveBeginPlay: %s", G.GetObjectName(self))

    self:SendMessage("RegisterUnHitCallback", self.UnHitCallback, self)
    self.HitActors:Clear()
    self.CurHop = 0
    self.PreLocation = nil
    self.CurHitActor = self.SourceActor
    self.HitCntMap = {}

    self.LastKnockInfoInst = SkillUtils.KnockInfoStructToObject(self.LastKnockInfo)

    if self:IsServer() then
        local EndLocation = self:SelectNextHopLocation()
        --第一条跳哪怕没有目标也要飞出去
        if EndLocation == nil and self.CurHop == 0 then
            local MoveDirection = self.SourceActor:GetActorForwardVector()
            MoveDirection = MoveDirection * self.MaxChooseRadius; 
            EndLocation =  self.SourceActor:K2_GetActorLocation() + MoveDirection;
        end
        self:Multicast_CastChainEffect(EndLocation)
    end
end






function ChainLightning:SelectNextHopLocation()
    local ActorsToIgnore = UE.TArray(UE.AActor)
    local CurDistance = self.MaxChooseRadius * self.MaxHop
    ActorsToIgnore:AddUnique(self.CurHitActor)
    ActorsToIgnore:AddUnique(self.SourceActor)
    self.CurHitActor = nil
    local Hits = UE.TArray(UE.FHitResult)
    UE.UKismetSystemLibrary.SphereTraceMultiForObjects(self:GetWorld(), self:K2_GetActorLocation(), self:K2_GetActorLocation(), self.MaxChooseRadius, self.Spec.HitTypes, false, ActorsToIgnore, self.DebugType, Hits, true)
    if Hits:Length() > 0 then
        --G.log:info(self.__TAG__, "ChainLightning:SelectNextHopLocation: hits num %s", Hits:Length())
        local HitPoint = nil
        for idx = 1, Hits:Length() do
            local CurActor = Hits:Get(idx).Component:GetOwner()
            if SkillUtils.IsEnemy(CurActor, self.SourceActor) then
                local KeyName = G.GetObjectName(CurActor)
                local Cnt = self.HitCntMap[KeyName]
                if Cnt == nil then
                    Cnt = 0
                end
                --G.log:info(self.__TAG__, "ChainLightning:SelectNextHopLocation: cur monster name %s hit count %s", KeyName, Cnt)
                local Distance = (self:K2_GetActorLocation() - Hits:Get(idx).Component:K2_GetComponentLocation()):Size() + Cnt * self.MaxChooseRadius
                if CurDistance > Distance then
                    CurDistance = Distance
                    HitPoint = CurActor:K2_GetActorLocation()
                    --HitPoint =  Hits:Get(idx).Component:K2_GetComponentLocation()
                    --HitPoint =  Hits:Get(idx).ImpactPoint
                    self.CurHitActor = CurActor
                end        
            end
        end
        if self.CurHitActor then
            local KeyName = G.GetObjectName(self.CurHitActor)
            local Cnt = self.HitCntMap[KeyName]
            --G.log:info(self.__TAG__, "ChainLightning:SelectNextHopLocation: target name %s, target count %s", KeyName, Cnt)
            if Cnt == nil then
                Cnt = 0
            end
            self.HitCntMap[KeyName] = Cnt + 1
            G.log:info(self.__TAG__, "ChainLightning:SelectNextHopLocation: %s (%f %f %f) %d %f ", G.GetObjectName(self.CurHitActor), HitPoint.X, HitPoint.Y, HitPoint.Z, self.CurHop, CurDistance)
        end

        return HitPoint
    end
    G.log:info(self.__TAG__, "ChainLightning:SelectNextHopLocation: not find target: %s %d %d", G.GetObjectName(self), Hits:Length(), self.CurHop)
    return nil
end


function ChainLightning:OnChainEnd()
    self.CurHop = self.CurHop + 1
    if self:IsServer() then
        local HitFlag = self:PerformOverlap(self:K2_GetActorLocation(), self:K2_GetActorLocation() - self.PreLocation)
        if self.CurHop < self.MaxHop and HitFlag then
            local NextHopLocation = self:SelectNextHopLocation()
            if NextHopLocation then
                self:Multicast_CastChainEffect(NextHopLocation)
            else
                self.ChainTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.LastEffect}, self.LastKnockDelay, false) 
            end
        else
            self.ChainTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.LastEffect}, self.LastKnockDelay, false) 
        end
    end
    if self.CurHop == self.MaxHop and self.HitActors:Num() == 0 then
        self:DestroySelf()
    end
end

function ChainLightning:OnPlayHopEffect()
    UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self, self.HopHitNS, self:K2_GetActorLocation(), self:K2_GetActorRotation())
    self:GetWorld():SpawnActor(self.HopHitEffect, self:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self)
end

function ChainLightning:OnCastChainEffect(EndPos)
    Super(ChainLightning).OnCastChainEffect(self, EndPos)
    self.PreLocation = self:K2_GetActorLocation()
    self:K2_SetActorLocation(EndPos, false, UE.FHitResult(), true)
    --  G.log:info(self.__TAG__, "ChainLightning:OnChainEnd 1 %s", tostring(EndPos))
    if self:IsClient() then
        UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnPlayHopEffect}, self.ChainDuration * 0.5, false)
    end
end

function ChainLightning:PerformOverlap(OriginLocation, ForwardVector)
    if self.SourceActor and self.SourceActor.TimeDilationComponent and self.SourceActor.TimeDilationComponent.bWitchTime then
        return false
    end

    -- A small sweep step in forward direction, instead of overlap(without hit points).
    local Hits = UE.TArray(UE.FHitResult)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:AddUnique(self.SourceActor)
    if self.SourceActor:IsPlayerComp() then
        HiCollisionLibrary.PerformSweep(self, self.Spec, OriginLocation, UE.FRotator(), 10, ForwardVector, self.Spec.HitTypes, ActorsToIgnore, Hits, self.DebugType)
    else
        HiCollisionLibrary.PerformOverlapComponents(self, self.Spec, OriginLocation, ForwardVector, self.Spec.HitTypes, ActorsToIgnore, Hits, self.bDebug)
    end

    local TargetHits = UE.TArray(UE.FHitResult)
    for _, Hit in pairs(Hits:ToTable()) do
        local CurActor = Hit.Component:GetOwner()
        if CurActor == self.CurHitActor then
            TargetHits:AddUnique(Hit)
            break
        end
    end

    G.log:info(self.__TAG__, "ChainLightning:PerformOverlap: %d", Hits:Length())

    if Hits:Length() > 0 then
        self.HitActors:Add(TargetHits:Get(1).Component:GetOwner())
        self:SendMessage("ExecCalcForHits", TargetHits, nil, true, false)
        return true
    end
    return false
end


function ChainLightning:HitCallback(ChannelType, Hit)
    if self.HitCallbackFunc then
        self.HitCallbackFunc(self.HitCallbackOwner, ChannelType, Hit, self.ApplicationTag, false)
    end
end

function ChainLightning:LastEffect()
    -- G.log:info(self.__TAG__, "ChainLightning:LastEffect actors: %s", self.HitActors:Num())
    local ValidActors = UE.TArray(UE.AActor)
    for _, Actor in pairs(self.HitActors:ToTable()) do
        if Actor and Actor:IsValid() then
            -- G.log:info(self.__TAG__, "ChainLightning:LastEffect actor name: %s", G.GetObjectName(Actor))
            ValidActors:AddUnique(Actor)
        end
    end
    -- G.log:info(self.__TAG__, "ChainLightning:LastEffect valid actors %s", ValidActors:Num())
    local HitResult = SkillUtils.MakeHitResultsFromActors(ValidActors, self.SourceActor:K2_GetActorLocation())
    local GASpec = self.StartLocation.SourceAbility
    if not GASpec then
        G.log:error(self.__TAG__, "LastEffect failed: GASpec is nil")
        self:DestroySelf()
        return
    end
    local bFounded, EffectContainer, Specs = GASpec:MakeSpecsByTag(self.LastCalcEventTag, GASpec:GetAbilityLevel())
    local bFoundedOfSelf, _, SelfSpecs = GASpec:MakeSelfSpecsByTag(self.LastCalcEventTag, GASpec:GetAbilityLevel())
    if not bFounded and not bFoundedOfSelf then
        G.log:warn(self.__TAG__, "GASkillBase OnCalcEvent not found EffectContainer for tag: %s", GetTagName(EventTag))
        self:DestroySelf()
        return
    end
    if not UE.UKismetSystemLibrary.IsValidClass(EffectContainer.TargetType) then
        G.log:error(self.__TAG__, "GASkillBase OnCalcEvent TargetActor type is invalid for tag: %s", GetTagName(EventTag))
        self:DestroySelf()
        return
    end
    
    -- G.log:info(self.__TAG__, "show LastEffect %s %s", Specs:Num(), SelfSpecs:Num())
    --最后大击退的knockInfo
    self:SendMessage("InitCalcForHits", self.SourceActor, self, self.Spec, self.LastKnockInfoInst, Specs, self.HitSceneTargetConfig, nil, SelfSpecs)
    self:SendMessage("ExecCalcForHits", HitResult, nil, true, true)
    self:DestroySelf()
end
return ChainLightning
