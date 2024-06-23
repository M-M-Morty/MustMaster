--
-- @COMPANY
-- @AUTHOR
--

local G = require('G')

local FunctionUtil = {}
local UIUtils = require("common.utils.ui_utils")
function FunctionUtil:FindAbilitySpecFromHandle(ASC, SpecHandle)
    if (not ASC) or (not SpecHandle) then
        return
    end
    local arySpec = ASC.ActivatableAbilities.Items
    local length = arySpec:Length()
    if length > 0 then
        for i = 1, length do
            local spec = arySpec:Get(i)
            if UE.UAbilitySystemBlueprintLibrary.EqualEqual_GameplayAbilitySpecHandle(SpecHandle, spec.Handle) then
                return spec
            end
        end
    end
end
function FunctionUtil:TryActiveGA(srcActor, GACls)
    if (not srcActor) or (not GACls) then
        return
    end
    local ASC = srcActor:GetHiAbilitySystemComponent()
    if not ASC then
        return
    end
    local SpecHandle = ASC:FindAbilitySpecHandleFromClass(GACls)
    if SpecHandle.Handle == -1 then --havent give
        ASC:K2_GiveAbility(GACls)
        SpecHandle = ASC:FindAbilitySpecHandleFromClass(GACls)
    end
    ASC:BP_TryActivateAbilityByHandle(SpecHandle, true)
end
function FunctionUtil:CancelGA(srcActor, GACls)
    if (not srcActor) or (not GACls) then
        return
    end
    local ASC = srcActor:GetHiAbilitySystemComponent()
    if not ASC then
        return
    end
    local SpecHandle = ASC:FindAbilitySpecHandleFromClass(GACls)
    ASC:BP_CancelAbilityHandle(SpecHandle)
end
function FunctionUtil:IsGAInActive(srcActor, GACls)
    if (not srcActor) or (not GACls) then
        return false
    end
    local ASC = srcActor:GetHiAbilitySystemComponent()
    if not ASC then
        return false
    end
    local SpecHandle = ASC:FindAbilitySpecHandleFromClass(GACls)
    local Spec = self:FindAbilitySpecFromHandle(ASC, SpecHandle)
    return UE.UHiGASLibrary.IsAbilityActive(Spec)
end

function FunctionUtil:FindNearestPlayer(srcActor, radius)
    local tbObjectTypes = { UE.EObjectTypeQuery.Pawn }
    local PlayerClass = self:IndexRes('BPA_AvatarBase_C')
    local overlapActors = UE.TArray(UE.AActor)
    UE.UKismetSystemLibrary.SphereOverlapActors(srcActor, srcActor:K2_GetActorLocation(), radius, tbObjectTypes, PlayerClass, {}, overlapActors)
    local length = overlapActors:Length()
    local nearestActor
    if length > 0 then
        local dist
        for i = 1, length do
            local actor = overlapActors:Get(i)
            local d = srcActor:GetDistanceTo(actor)
            if (not dist) or dist > d then
                nearestActor = actor
                dist = d
            end
        end
    end
    return nearestActor
end

function FunctionUtil:GetPosRelativePoint(point, rot, length)
    local vec = UE.FVector(length, 0, 0)
    local newLocal = UE.UKismetMathLibrary.GreaterGreater_VectorRotator(vec, rot)
    return point + newLocal
end

function FunctionUtil:PrintScreen(text, color, duration)
    color = color or UE.FLinearColor(1, 1, 1, 1)
    duration = duration or 100
    UE.UKismetSystemLibrary.PrintString(nil, text, true, false, color, duration)
end
function FunctionUtil:DrawShapeComponent(shapeComp, duration)
    if not shapeComp then
        return
    end
    local ownerActor = shapeComp:GetOwner()
    if not ownerActor then
        return
    end

    local DRAW_DURATION = duration or 0
    local DRAW_THICKNESS = 0
    local DRAW_COLOR = UE.FLinearColor(1, 0, 0)

    local Worldlocation = shapeComp:K2_GetComponentLocation()
    local WorldRotation = shapeComp:K2_GetComponentRotation()
    if shapeComp:IsA(UE.USphereComponent) then
        local radius = shapeComp:GetScaledSphereRadius()
        UE.UKismetSystemLibrary.DrawDebugSphere(ownerActor, Worldlocation, radius, 12, DRAW_COLOR, DRAW_DURATION, DRAW_THICKNESS)
    elseif shapeComp:IsA(UE.UBoxComponent) then
        local extent = shapeComp:GetScaledBoxExtent()
        UE.UKismetSystemLibrary.DrawDebugBox(ownerActor, Worldlocation, extent, DRAW_COLOR, WorldRotation, DRAW_DURATION, DRAW_THICKNESS)
    elseif shapeComp:IsA(UE.UCapsuleComponent) then
        local radius = shapeComp:GetScaledCapsuleRadius()
        local halfHeight = shapeComp:GetScaledCapsuleHalfHeight()
        UE.UKismetSystemLibrary.DrawDebugCapsule(ownerActor, Worldlocation, halfHeight, radius, WorldRotation, DRAW_COLOR, DRAW_DURATION, DRAW_THICKNESS)
    end
end

function FunctionUtil:GetBlueprintObjectClassPath(ubpObj)
    local objRef = UE.UKismetSystemLibrary.Conv_ObjectToSoftObjectReference(ubpObj)
    local str = UE.UKismetSystemLibrary.Conv_SoftObjectReferenceToString(objRef)
    return string.format('%s_C', str)
end

function FunctionUtil:AddGameplayTag(Actor, strTag)
    local ASC = Actor and Actor:GetAbilitySystemComponent()
    if not ASC then
        return
    end

    local t = {}
    if type(strTag) == 'table' then
        t = strTag
    else
        t = {strTag}
    end
    local TagContainer = UE.FGameplayTagContainer()
    for i, v in ipairs(t) do
        local tag = UE.UHiGASLibrary.RequestGameplayTag(v)
        if not ASC:HasGameplayTag(tag) then
            TagContainer.GameplayTags:Add(tag)
        end
    end
    UE.UAbilitySystemBlueprintLibrary.AddLooseGameplayTags(Actor, TagContainer, true)
end
function FunctionUtil:RemoveGameplayTag(Actor, strTag)
    local ASC = Actor and Actor:GetAbilitySystemComponent()
    if not ASC then
        return
    end

    local t = {}
    if type(strTag) == 'table' then
        t = strTag
    else
        t = {strTag}
    end
    local TagContainer = UE.FGameplayTagContainer()
    for i, v in ipairs(t) do
        local tag = UE.UHiGASLibrary.RequestGameplayTag(v)
        if ASC:HasGameplayTag(tag) then
            TagContainer.GameplayTags:Add(tag)
        end
    end
    UE.UAbilitySystemBlueprintLibrary.RemoveLooseGameplayTags(Actor, TagContainer, true)
end
function FunctionUtil:HasGameplayTag(Actor, Tag)
    local ASC = Actor and Actor:GetAbilitySystemComponent()
    if not ASC then
        return false
    end

    if Tag and type(Tag) == 'string' then
        Tag = UE.UHiGASLibrary.RequestGameplayTag(Tag)
    end
    return ASC:HasGameplayTag(Tag)
end

function FunctionUtil:GetCachedGlobalResourcesObject()
    G.log:info("ghgame", "GetCachedGlobalResourcesObject")
    local CachedObject = UIUtils.GetUIGlobalObject()
    if not CachedObject then
        local GlobalResourceObject = '/Game/CP0032305_GH/Blueprints/Common/GlobalResources.GlobalResources_C'
        CachedObject = UE.UObject.Load(GlobalResourceObject):GetDefaultObject()
        if CachedObject then
            UIUtils.CacheUIGlobalObject(CachedObject)
        end
        G.log:debug("ghgame", "Resource Cached Object reload")
    end
    if CachedObject then
        return CachedObject
    end
end
function FunctionUtil:IndexRes(key)
    local cls = self:GlobalUClass(key)
    if cls then
        return cls
    end
    return self:GlobalUObject(key)
end
function FunctionUtil:GlobalUClass(key)
    local CachedObject = self:GetCachedGlobalResourcesObject()
    if not CachedObject then
        G.log:warn("ghgame", "Resource Cached Object is nil")
        return
    end
    ---@type TMap
    local ClassMap = CachedObject.ClassResources
    local classObj = ClassMap:Find(key)
    if not classObj then
        G.log:warn("ghgame", "FunctionUtil:GlobalUClass %s not found", key)
    end
    return classObj
end
function FunctionUtil:GlobalUObject(key)
    local CachedObject = self:GetCachedGlobalResourcesObject()
    if not CachedObject or not CachedObject.ObjectResources then
        G.log:warn("ghgame", "Resource Cached Object is nil")
        return
    end
    ---@type TMap
    local LoadedObjMap = CachedObject.ObjectResources
    local LoadedObject = LoadedObjMap:Find(key)
    if LoadedObject and LoadedObject:IsValid() then
        return LoadedObject
    end
end
function FunctionUtil:GlobalEnum(key)
    local CachedObject = self:GetCachedGlobalResourcesObject()
    if not CachedObject or not CachedObject.EnumResourcePaths then
        G.log:warn("ghgame", "Resource Cached Object is nil")
        return
    end

    ---@type TMap
    local PathMap = CachedObject.EnumResourcePaths
    local FoundedPath = PathMap:Find(key)
    if FoundedPath then
        local objPath = UE.UKismetSystemLibrary.BreakSoftObjectPath(FoundedPath)
        local LoadedObj = UE.UObject.Load(objPath)
        if LoadedObj then
            return LoadedObj
        else
            G.log:warn("ghgame", "FunctionUtil:GlobalEnum %s load fail", key)
        end
    else
        G.log:warn("ghgame", "FunctionUtil:GlobalEnum %s not found", key)
    end
end

function FunctionUtil:FloatEqual(fSrcVal, fTarVal, fTolerance)
    fTolerance = fTolerance or 0.001
    return UE.UKismetMathLibrary.NearlyEqual_FloatFloat(fSrcVal, fTarVal, fTolerance)
end
function FunctionUtil:FloatZero(fSrcVal, fTolerance)
    return self:FloatEqual(fSrcVal, 0, fTolerance)
end
function FunctionUtil:FloatNotZero(fSrcVal, fTolerance)
    return not self:FloatZero(fSrcVal, fTolerance)
end
function FunctionUtil:FloatLittle(fSrcVal, fTarVal, fTolerance)
    fTolerance = fTolerance or 0.001
    return (fTarVal - fSrcVal) > fTolerance
end
function FunctionUtil:FloatGreat(fSrcVal, fTarVal, fTolerance)
    fTolerance = fTolerance or 0.001
    return (fSrcVal - fTarVal) > fTolerance
end

-- 定义以下适配接口
function FunctionUtil:IsHiCharacter(actor)
    return actor:IsA(UE.AHiCharacter)
end
function FunctionUtil:IsPlayer(actor)
    local cls = self:IndexRes('BPA_AvatarBase_C')
    return cls and actor:IsA(cls)
end
function FunctionUtil:IsMonster(actor)
    return self:IsHiCharacter(actor) and (not self:IsPlayer(actor))
end
function FunctionUtil:GetActorDesc(actor)
    return string.format('ACTOR:%s, IsHiCharacter:%s, IsPlayer:%s, IsMonster:%s',
    UE.UKismetSystemLibrary.GetDisplayName(actor),
    tostring(self:IsHiCharacter(actor)), tostring(self:IsPlayer(actor)), tostring(self:IsMonster(actor)))
end
function FunctionUtil:IsGHCharacter(actor)
    local cls = self:IndexRes('BPA_GH_MonsterBase_C')
    return cls and actor:IsA(cls)
end


function FunctionUtil:CheckActionRaw(Pawn, tarActor, action, tbFilter, tbTrace)
    if not Pawn or not action then
        return false, 'param error'
    end

    local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
    tbFilter = tbFilter or {'Weight', 'Dist', 'Z', 'Yaw', 'CD', 'Tag', 'ExTag', 'Recast', 'Trace'}
    tbTrace = tbTrace or {}

    local SrcLocation = Pawn:K2_GetActorLocation()
    local TarLocation = tarActor and tarActor:K2_GetActorLocation()
    local extend = Pawn:GetBlackBoardExtend()
    local checkResult = true
    local strText = ''

    local existWeight = TableUtil:Contains(tbFilter, 'Weight') 
    if checkResult and existWeight then
        checkResult = FunctionUtil:FloatNotZero(action.Weight)
        strText = strText .. string.format('%s: Weight-%s ', action.ActionKey, checkResult)
    end

    local existDist = TableUtil:Contains(tbFilter, 'Dist') and (FunctionUtil:FloatNotZero(action.DistMin) or FunctionUtil:FloatNotZero(action.DistMax))
    if checkResult and existDist then
        local dist = Pawn:GetDistanceTo(tarActor)
        checkResult = action.DistMin < dist and dist < action.DistMax
        strText = strText .. string.format('Dist(%.2f)-%s ', dist, checkResult)
        --G.log:debug("duzy", "FunctionUtil:CheckActionRaw existDist:%s", tostring(checkResult))
    end

    local existZ =  TableUtil:Contains(tbFilter, 'Z') and (FunctionUtil:FloatNotZero(action.ZMin) or FunctionUtil:FloatNotZero(action.ZMax))
    if checkResult and existZ then
        local z = TarLocation.Z - SrcLocation.Z
        checkResult = action.ZMin < z and z < action.ZMax
        strText = strText .. string.format('Z(%.2f)-%s ', z, checkResult)
        --G.log:debug("duzy", "FunctionUtil:CheckActionRaw existZ:%s", tostring(checkResult))
    end

    local existYaw =  TableUtil:Contains(tbFilter, 'Yaw') and FunctionUtil:FloatNotZero(action.DeltaYaw)
    if checkResult and existYaw then
        local lootAtRot = UE.UKismetMathLibrary.FindLookAtRotation(SrcLocation, TarLocation)
        local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(Pawn:K2_GetActorRotation(), lootAtRot)
        checkResult = action.DeltaYaw * -1 < deltaRot.Yaw and deltaRot.Yaw < action.DeltaYaw
        strText = strText .. string.format('Yaw(%.2f)-%s ', deltaRot.Yaw, checkResult)
        --G.log:debug("duzy", "FunctionUtil:CheckActionRaw existYaw:%s", tostring(checkResult))
    end

    local existCD =  TableUtil:Contains(tbFilter, 'CD') and FunctionUtil:FloatNotZero(action.CoolDown)
    if checkResult and existCD then
        local lastCast = 0
        if extend then
            lastCast = extend:GetSkillCastTime(action.ActionKey) or 0
        end
        local current = UE.UGameplayStatics.GetTimeSeconds(Pawn)
        checkResult = FunctionUtil:FloatZero(lastCast) or (current - lastCast) > action.CoolDown
        strText = strText .. string.format('CoolDown(%.2f)-%s ', current - lastCast, checkResult)
        --G.log:debug("duzy", "FunctionUtil:CheckActionRaw existCD:%s", tostring(checkResult))
    end

    local vTags = Pawn.ChararacteStateManager and Pawn.ChararacteStateManager.vTags
    local existTags =  TableUtil:Contains(tbFilter, 'Tag') and (UE.UBlueprintGameplayTagLibrary.GetNumGameplayTagsInContainer(action.tag) > 0)
    if checkResult and existTags then
        if action.matchType == UE.EGameplayContainerMatchType.Any then
            checkResult = UE.UBlueprintGameplayTagLibrary.HasAnyTags(vTags, action.tag, true)
        else
            checkResult = UE.UBlueprintGameplayTagLibrary.HasAllTags(vTags, action.tag, true)
        end
        strText = strText .. string.format('Tag-%s ', checkResult)
        --G.log:debug("duzy", "FunctionUtil:CheckActionRaw existCD:%s", tostring(existTags))
    end

    local existExcludeTags =  TableUtil:Contains(tbFilter, 'ExTag') and (UE.UBlueprintGameplayTagLibrary.GetNumGameplayTagsInContainer(action.excludeTag) > 0)
    if checkResult and existExcludeTags then
        local excludeMatch = false
        if action.excludeTagMatch == UE.EGameplayContainerMatchType.Any then
            excludeMatch = UE.UBlueprintGameplayTagLibrary.HasAnyTags(vTags, action.excludeTag, true)
        else
            excludeMatch = UE.UBlueprintGameplayTagLibrary.HasAllTags(vTags, action.excludeTag, true)
        end
        checkResult = not excludeMatch
        strText = strText .. string.format('ExcludeTag-%s ', checkResult)
    end

    local existRecast =  TableUtil:Contains(tbFilter, 'Recast') and action.RecastCheck
    if checkResult and existRecast then
        local HitLocation = UE.FVector()
        local bReturn = UE.UNavigationSystemV1.NavigationRaycast(Pawn, SrcLocation, TarLocation, HitLocation, UE.UNavigationQueryFilter)
        checkResult = (not bReturn) or math.abs(HitLocation.Z - SrcLocation.Z) < 40
        strText = strText .. string.format('Recast-%s ', checkResult)
    end

    local existLineTrace = TableUtil:Contains(tbFilter, 'Trace') and action.TraceHeight:Length() > 0 and tarActor
    if checkResult and existLineTrace then
        for i, offset in pairs(action.TraceHeight) do
            if tbTrace[offset] == nil then
                local lookat = UE.UKismetMathLibrary.FindLookAtRotation(SrcLocation, TarLocation)
                local forward = UE.UKismetMathLibrary.GetForwardVector(lookat)
                local ActorsToIgnore = {}
	            local HitResult = UE.FHitResult()
                local traceStart = UE.FVector(SrcLocation.X, SrcLocation.Y, SrcLocation.Z + offset)
                tbTrace[offset] = UE.UKismetSystemLibrary.LineTraceSingle(Pawn:GetWorld(), traceStart, traceStart + forward * 400, UE.ETraceTypeQuery.WorldStatic, false, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
            end
            checkResult = checkResult and (not tbTrace[offset])
        end
        strText = strText .. string.format('Trace-%s ', checkResult)
    end

    return checkResult, strText
end
function FunctionUtil:SelectActionRaw(Pawn, tarActor, queryState)
    if not tarActor then
        --G.log:debug("duzy", "FunctionUtil:SelectActionRaw tarActor ERROR")
        return false
    end

    local extend = Pawn:GetBlackBoardExtend()
    local actions = extend.actions
    if not actions then
        --G.log:debug("duzy", "FunctionUtil:SelectActionRaw actions ERROR")
        return false
    end

    local tbRand = {}
    local bEmpty = true
    local length = actions:Length()
    if length < 1 then
        --G.log:debug("duzy", "FunctionUtil:SelectActionRaw actions:Length() ERROR")
        return false
    end

    local strResult = ''
    local tbTrace = {}
    for i = 1, length do
        local action = actions:Get(i)
        local checkResult, strText = self:CheckActionRaw(Pawn, tarActor, action, nil, tbTrace)
        strResult = strResult .. strText
        if checkResult then
            tbRand[action.ActionKey] = action
            --G.log:debug("duzy", "FunctionUtil:SelectActionRaw ACTION:%s", action.ActionKey)
            bEmpty = false
            if queryState then
                break
            end
        end
    end

    --G.log:debug("duzy", "FunctionUtil:SelectActionRaw RESULT:%s", strResult)
    local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
    if queryState then
        return (not bEmpty)
    else
        local tSelect = TableUtil:WeightRandom(tbRand, function(k, v) return v.Weight end, 1)
        if #tSelect > 0 then
            local action = tSelect[1][2]
            return action
        end
    end
end

function FunctionUtil:MakeUDKnockInfo(WorldContext, FKnock)
    local UDObject = UE.NewObject(FunctionUtil:IndexRes('UD_KnockInfo_C'), WorldContext)
    if FKnock then
        UDObject.KnockDisScale = FKnock.KnockDisScale
        UDObject.KnockImpulse = FKnock.KnockImpulse
        UDObject.KnockDir = FKnock.KnockDir
        UDObject.EnableZeroGravity = FKnock.EnableZeroGravity
        UDObject.ZeroGravityTime = FKnock.ZeroGravityTime
        UDObject.TimeDilation = FKnock.TimeDilation
        UDObject.HitTags = FKnock.HitTags
        UDObject.bUseInstigatorDir = FKnock.bUseInstigatorDir
        UDObject.InstigatorAngleOffset = FKnock.InstigatorAngleOffset
    end
    return UDObject
end

return FunctionUtil
