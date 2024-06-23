require "UnLua"

local G = require("G")
local WeaponData = require("common.data.weapon_data").data
local HeroData = require("common.data.hero_initial_data").data
local camp_relation_data = require("common.data.camp_relation_data")
local SkillInputTypes = require("common.event_const").SkillInputTypes

SkillUtils = {}

local AttrNames = {}
-- 韧性
AttrNames.Tenacity = "Tenacity"
AttrNames.MaxTenacity = "MaxTenacity"

-- 血量
AttrNames.Health = "Health"
AttrNames.MaxHealth = "MaxHealth"

-- 伤害
AttrNames.Damage = "Damage"

-- 耐力
AttrNames.Stamina = "Stamina"
AttrNames.MaxStamina = "MaxStamina"

-- 能量值
AttrNames.Power = "Power"
AttrNames.MaxPower = "MaxPower"

-- 超级登场技能能量值
AttrNames.SuperPower = "SuperPower"
AttrNames.MaxSuperPower = "MaxSuperPower"

-- 子弹能量属性(西雅)
AttrNames.Bullet = "Bullet"
AttrNames.MaxBullet = "MaxBullet"

SkillUtils.AttrNames = AttrNames

function SkillUtils.GetAttribute(ASC, Name)
    local Attr = ASC:FindAttributeByName(Name)
    if not Attr.AttributeOwner then
        return nil
    end

    local AttributeSet = ASC:GetAttributeSet(Attr.AttributeOwner)
    if not AttributeSet then
        return nil
    end

    return AttributeSet[Name]
end

--- Set attribute base value by name.
function SkillUtils.SetAttributeBaseValue(ASC, Name, BaseValue)
    local Attr = ASC:FindAttributeByName(Name)
    -- bug, not work! 有时间再查，调用会报错。
    --if not UE.UAbilitySystemBlueprintLibrary.IsValid(Attr) then
    if Attr.AttributeName == "" then
        return
    end

    ASC:SetAttributeBaseValue(Attr, BaseValue)
end

function SkillUtils.IsNormalSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.Normal
end

function SkillUtils.IsInAirNormalSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.InAirNormal
end

function SkillUtils.IsRushSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.Rush
end

function SkillUtils.IsFallAttackSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.FallAttack
end

function SkillUtils.IsChargeSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.Charge
end

function SkillUtils.IsInAirChargeSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.InAirCharge
end

function SkillUtils.IsKickSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.Kick
end

function SkillUtils.IsBlockSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.Block
end

function SkillUtils.IsStrikeBackSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.StrikeBack
end

function SkillUtils.IsSuperSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.Super
end

function SkillUtils.IsSecondarySkill(SkillType)
    return SkillType == Enum.Enum_SkillType.SecondarySkill
end

-- Use different type of SkillManager.
function SkillUtils.IsComboManagerSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.Normal or SkillType ==
               Enum.Enum_SkillType.InAirNormal
end


function SkillUtils.IsAssistManagerSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.AssistSkill
end

function SkillUtils.IsChargeManagerSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.Charge or SkillType ==
               Enum.Enum_SkillType.InAirCharge or SkillType ==
               Enum.Enum_SkillType.ClimbForwardCharge or SkillType ==
               Enum.Enum_SkillType.ClimbLeftCharge or SkillType ==
               Enum.Enum_SkillType.ClimbRightCharge or SkillType ==
               Enum.Enum_SkillType.ClimbBackCharge
end

function SkillUtils.IsDefaultTypeSkill(SkillType)
    return SkillType == Enum.Enum_SkillType.Default
end

function SkillUtils.IsCommonNormal(SkillType)
    return SkillType == Enum.Enum_SkillType.Normal or SkillType ==
               Enum.Enum_SkillType.InAirNormal
end

-- Convert KnockInfo UObject to UStruct, As UObject as RPC Parameters can not replicated.
function SkillUtils.KnockInfoObjectToStruct(KnockInfo)
    local KInfo = Struct.UD_FKnockInfo()
    KInfo.KnockDisScale = KnockInfo.KnockDisScale
    KInfo.KnockImpulse = KnockInfo.KnockImpulse
    KInfo.KnockDir = KnockInfo.KnockDir
    KInfo.EnableZeroGravity = KnockInfo.EnableZeroGravity
    KInfo.ZeroGravityTime = KnockInfo.ZeroGravityTime
    KInfo.TimeDilation = KnockInfo.TimeDilation
    KInfo.bUseInstigatorDir = KnockInfo.bUseInstigatorDir
    KInfo.InstigatorAngleOffset = KnockInfo.InstigatorAngleOffset
    return KInfo
end

function SkillUtils.KnockInfoObjectToReplicatedStruct(KnockInfo)
    local KInfo = Struct.UD_FKnockInfoReplicated()
    KInfo.KnockDisScale = KnockInfo.KnockDisScale
    KInfo.KnockImpulse = KnockInfo.KnockImpulse
    KInfo.KnockDir = KnockInfo.KnockDir
    KInfo.EnableZeroGravity = KnockInfo.EnableZeroGravity
    KInfo.ZeroGravityTime = KnockInfo.ZeroGravityTime
    KInfo.TimeDilation = KnockInfo.TimeDilation
    KInfo.bUseInstigatorDir = KnockInfo.bUseInstigatorDir
    KInfo.InstigatorAngleOffset = KnockInfo.InstigatorAngleOffset
    KInfo.KnockZAxisAngle = KnockInfo.KnockZAxisAngle
    KInfo.Hit = KnockInfo.Hit
    return KInfo
end

-- Convert KnockInfo struct to object, pass into FGameplayEventData
function SkillUtils.KnockInfoStructToObject(KnockInfo)
    local KInfoClass = UE.UObject.Load(
                           "/Game/Blueprints/Common/UserData/UD_KnockInfo.UD_KnockInfo_C")
    local KInfo = NewObject(KInfoClass)
    KInfo.KnockDisScale = KnockInfo.KnockDisScale
    KInfo.KnockImpulse = KnockInfo.KnockImpulse
    KInfo.KnockDir = KnockInfo.KnockDir
    KInfo.EnableZeroGravity = KnockInfo.EnableZeroGravity
    KInfo.ZeroGravityTime = KnockInfo.ZeroGravityTime
    KInfo.TimeDilation = KnockInfo.TimeDilation
    KInfo.HitTags = KnockInfo.HitTags
    KInfo.bUseInstigatorDir = KnockInfo.bUseInstigatorDir
    KInfo.InstigatorAngleOffset = KnockInfo.InstigatorAngleOffset

    return KInfo
end

function SkillUtils.KnockInfoReplicatedToNormal(KnockInfo)
    local KInfo = Struct.UD_FKnockInfo()
    KInfo.KnockDisScale = KnockInfo.KnockDisScale
    KInfo.KnockImpulse = KnockInfo.KnockImpulse
    KInfo.KnockDir = KnockInfo.KnockDir
    KInfo.EnableZeroGravity = KnockInfo.EnableZeroGravity
    KInfo.ZeroGravityTime = KnockInfo.ZeroGravityTime
    KInfo.TimeDilation = KnockInfo.TimeDilation
    KInfo.bUseInstigatorDir = KnockInfo.bUseInstigatorDir
    KInfo.InstigatorAngleOffset = KnockInfo.InstigatorAngleOffset
    KInfo.KnockZAxisAngle = KnockInfo.KnockZAxisAngle
    KInfo.Hit = KnockInfo.Hit
    return KInfo
end

function SkillUtils.NewKnockInfoObject()
    local KInfoClass = UE.UObject.Load(
            "/Game/Blueprints/Common/UserData/UD_KnockInfo.UD_KnockInfo_C")
    local KInfo = NewObject(KInfoClass)

    return KInfo
end

-- Check whether object implement BPI_Interactable
function SkillUtils.IsInteractable(Actor)
    return Actor.InteractionComponent and
               Actor.InteractionComponent:IsInteractable()
end

-- Check whether specified object type can damageable by skill.
function SkillUtils.IsObjectTypeDamageable(ObjectType)
    return ObjectType == UE.ECollisionChannel.ECC_Pawn or
            ObjectType == UE.ECollisionChannel.MountActor or
            ObjectType == UE.ECollisionChannel.ECC_PhysicsBody
end

-- Make non-complete HitResults from HitComponents.
function SkillUtils.MakeHitResultsFromComponents(HitComponents, Origin)
    local HitResults = UE.TArray(UE.FHitResult)
    for Ind = 1, HitComponents:Length() do
        local CurComp = HitComponents:Get(Ind)
        local CurActor = CurComp:GetOwner()
        local Dist, TargetLocation = UE.UHiUtilsFunctionLibrary.GetNearestDistanceToComponent(Origin, CurComp)
        if Dist < 0 then
            TargetLocation = CurComp:K2_GetComponentLocation()
        end
        local Normal = UE.UKismetMathLibrary.Normal(Origin - TargetLocation)
        local PhysicsMaterial = nil
        -- local PhysicsMaterials = UE.TArray(UE.UPhysicalMaterial)
        -- UE.HiCollisionLibrary.GetComponentPhysicsMaterial(CurComp, true, PhysicsMaterials)                
        -- if PhysicsMaterials:Length() > 0 then
        --    PhysicsMaterial = PhysicsMaterials[1]
        -- end

        HitResults:AddUnique(UE.UGameplayStatics.MakeHitResult(false, true, 0,
                                                               0,
                                                               TargetLocation,
                                                               TargetLocation,
                                                               Normal, Normal,
                                                               PhysicsMaterial,
                                                               CurActor,
                                                               CurComp, "", "",
                                                               0, 0, 0,
                                                               UE.FVector(),
                                                               UE.FVector()))
    end
    return HitResults
end

-- Make non-complete HitResults from HitActors.
function SkillUtils.MakeHitResultsFromActors(HitActors, Origin)
    local HitResults = UE.TArray(UE.FHitResult)
    for Ind = 1, HitActors:Length() do
        local CurActor = HitActors:Get(Ind)
        local TargetLocation = CurActor:K2_GetActorLocation()

        -- TODO FHiGameplayAbilityTargetData_ActorArray not include component info, here use root component.
        local CurComp = CurActor:GetComponentByClass(UE.UPrimitiveComponent)
        local PhysicsMaterial = nil
        -- local PhysicsMaterials = UE.TArray(UE.UPhysicalMaterial)
        -- UE.HiCollisionLibrary.GetComponentPhysicsMaterial(CurComp, true, PhysicsMaterials)        
        -- if PhysicsMaterial:Length() > 0 then
        --    PhysicsMaterial = PhysicsMaterials[1]
        -- end

        HitResults:AddUnique(UE.UGameplayStatics.MakeHitResult(true, true, 0, 0,
                                                               TargetLocation,
                                                               TargetLocation,
                                                               UE.FVector(),
                                                               UE.FVector(),
                                                               PhysicsMaterial,
                                                               CurActor,
                                                               CurComp, "", "",
                                                               0, 0, 0,
                                                               UE.FVector(),
                                                               UE.FVector()))
    end

    return HitResults
end

-- Check component is attacking use component tags.
function SkillUtils.IsComponentAttacking(PrimComp)
    for Ind = 1, PrimComp.ComponentTags:Length() do
        if PrimComp.ComponentTags:Get(Ind) == "Attacking" then
            return true
        end
    end

    return false
end

function SkillUtils.FindAbilitySpecFromSkillID(ASC, SkillID)
    local Abilities = ASC.ActivatableAbilities.Items
    for Ind = 1, Abilities:Length() do
        local Spec = Abilities:Get(Ind)
        if Spec.UserData and Spec.UserData.SkillID == SkillID then
            return Spec
        end
    end
end

function SkillUtils.FindAbilitySpecFromHandle(ASC, Handle)
    local Abilities = ASC.ActivatableAbilities.Items
    for Ind = 1, Abilities:Length() do
        local Spec = Abilities:Get(Ind)
        if Spec.Handle == Handle then return Spec end
    end
end

function SkillUtils.FindAbilitySpecFromGAClass(ASC, GAClass)
    local Abilities = ASC.ActivatableAbilities.Items
    for Ind = 1, Abilities:Length() do
        local Spec = Abilities:Get(Ind)
        if Spec and Spec.Ability:IsA(GAClass) then
            return Spec
        end
    end
end

function SkillUtils.FindAbilitySpecHandleFromSkillID(ASC, SkillID)
    local Spec = SkillUtils.FindAbilitySpecFromSkillID(ASC, SkillID)
    if Spec then return Spec.Handle end
end

function SkillUtils.FindAbilityFromSkillID(ASC, SkillID)
    local Spec = SkillUtils.FindAbilitySpecFromSkillID(ASC, SkillID)
    if Spec then return Spec.Ability end
    return nil
end

function SkillUtils.FindAbilityFromGAClass(ASC, GAClass)
    local Spec = SkillUtils.FindAbilitySpecFromGAClass(ASC, GAClass)
    if Spec then
        return Spec.Ability
    end
end

function SkillUtils.FindAbilityInstanceFromSkillID(ASC, SkillID)
    local Spec = SkillUtils.FindAbilitySpecFromSkillID(ASC, SkillID)
    local GA, bInstanced = G.GetGameplayAbilityFromSpecHandle(ASC, Spec.Handle)
    return GA, bInstanced
end

function SkillUtils.FindUserDataFromSkillID(ASC, SkillID)
    local Spec = SkillUtils.FindAbilitySpecFromSkillID(ASC, SkillID)
    if not Spec then return nil end

    return Spec.UserData
end

---@param ASC UHiAbilitySystemComponent
---@param Cmp fun(Spec:FGameplayAbilitySpec):FGameplayAbilitySpec
function SkillUtils.FindAbility(ASC, Cmp)
    local Abilities = ASC.ActivatableAbilities.Items
    for index, Spec in pairs(Abilities) do
        if type(Cmp) == "function" then
            if (Cmp(Spec)) then return Spec end
        end
    end
    return nil
end

function SkillUtils.FindUserDataFromHandle(ASC, Handle)
    local Spec = SkillUtils.FindAbilitySpecFromHandle(ASC, Handle)
    if Spec then return Spec.UserData end

    return nil
end

function SkillUtils.FindSuperSkillID(ASC)
    return SkillUtils.FindSuperSkillIDOfCurrentPlayer(ASC.AvatarActor:GetWorld())
end

function SkillUtils.FindNormalSkillID(WorldContextObject, bAirBattle)
    local SkillData = SkillUtils.GetSkillDataOfCurrentPlayer(WorldContextObject)
    if SkillData then
        local Key = SkillInputTypes.NormalSkill
        if bAirBattle then
            Key = SkillInputTypes.InAirNormalSkill
        end
        if not bAirBattle then 
            local SkillID = SkillUtils.GetSkillModifierOfCurrentPlayer(WorldContextObject, Key)
            if SkillID then
                return SkillID, true
            end
        end
        return SkillData[Key], false
    end
end

function SkillUtils.FindSecondarySkillID(ASC)
    return SkillUtils.FindSecondarySkillIDOfCurrentPlayer(
               ASC.AvatarActor:GetWorld())
end

function SkillUtils.GetSkillDataOfCurrentPlayer(WorldContextObject)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(WorldContextObject, 0)
    if not PlayerController then
        return
    end

    -- Read hero weapon id
    local CharData = HeroData[PlayerController.CurCharType]
    if not CharData then return end

    local WeaponID = CharData["weapon_id"]
    if not WeaponID then return end

    local SkillData = WeaponData[WeaponID]
    return SkillData
end

function SkillUtils.FindSecondarySkillIDOfCurrentPlayer(WorldContextObject)
    local SkillData = SkillUtils.GetSkillDataOfCurrentPlayer(WorldContextObject)
    local SkillID = SkillUtils.GetSkillModifierOfCurrentPlayer(WorldContextObject, SkillInputTypes.SecondarySkill)
    if SkillID then
        return SkillID
    end
    if SkillData then
        return SkillData[SkillInputTypes.SecondarySkill]
    end
end

function SkillUtils.FindBlockSkillIDOfCurrentPlayer(WorldContextObject)
    local SkillData = SkillUtils.GetSkillDataOfCurrentPlayer(WorldContextObject)
    if SkillData then
        return SkillData[SkillInputTypes.BlockSkill]
    end
end

function SkillUtils.FindStrikeBackSkillIDOfCurrentPlayer(WorldContextObject)
    local SkillData = SkillUtils.GetSkillDataOfCurrentPlayer(WorldContextObject)
    if SkillData then
        return SkillData[SkillInputTypes.StrikeBackSkill]
    end
end

function SkillUtils.FindSuperSkillIDOfCurrentPlayer(WorldContextObject)
    local SkillData = SkillUtils.GetSkillDataOfCurrentPlayer(WorldContextObject)
    local SkillID = SkillUtils.GetSkillModifierOfCurrentPlayer(WorldContextObject, SkillInputTypes.SuperSkill)
    if SkillID then
        return SkillID
    end
    if SkillData then
        return SkillData[SkillInputTypes.SuperSkill]
    end
end

function SkillUtils.FindChargeSkillIDOfCurrentPlayer(WorldContextObject, bInAir)
    local SkillData = SkillUtils.GetSkillDataOfCurrentPlayer(WorldContextObject)
    local SkillKey = bInAir and SkillInputTypes.InAirChargeSkill or SkillInputTypes.ChargeSkill
    if SkillData then
        return SkillData[SkillKey]
    end
end

function SkillUtils.GetSkillModifierOfCurrentPlayer(WorldContextObject, InputType)
    local Player = G.GetPlayerCharacter(WorldContextObject, 0)
    if Player and Player.SkillComponent and Player.SkillComponent.SkillInputModifiers and Player.SkillComponent.SkillInputModifiers[InputType] ~= nil then
        return Player.SkillComponent.SkillInputModifiers[InputType]
    end
    return nil
end

function SkillUtils.FilterTargets(Targets, Filter, NeedLock)
    local Filtered = UE.TArray(UE.AActor)
    for Ind = 1, Targets:Length() do
        local CurTarget = Targets:Get(Ind)
        if Filter:FilterActor(CurTarget, NeedLock) then Filtered:Add(CurTarget) end
    end

    return Filtered
end

function SkillUtils.IsAvatar(CurActor)
    return CurActor and CurActor.CharIdentity == Enum.Enum_CharIdentity.Avatar
end

function SkillUtils.IsBakAvatar(CurActor)
    if not CurActor or CurActor.CharIdentity ~= Enum.Enum_CharIdentity.Avatar then
        return false
    end

    if CurActor:GetLocalRole() == UE.ENetRole.ROLE_AutonomousProxy or CurActor:GetRemoteRole() == UE.ENetRole.ROLE_AutonomousProxy then
        return false
    end

    return true
end

function SkillUtils.IsBoss(CurActor)
    return CurActor and CurActor.CharIdentity == Enum.Enum_CharIdentity.Monster and
               CurActor.MonsterType == Enum.Enum_MonsterType.Boss
end


function SkillUtils.HasActivateAbilities(InActor)
    local ASC = InActor:GetAbilitySystemComponent()
    if ASC and ASC:IsValid() then
        if ASC:HasActivateAbilities() then
            return true
        end
    end
    return false
end

function SkillUtils.FindCurWitchSkillID(Actor) 
    local SkillComponent = Actor.SkillComponent
    if not SkillComponent then
        return nil
    end
    local Mgr = SkillComponent.SkillDriver and SkillComponent.SkillDriver:GetAssistSkillManager()
    if not Mgr then
        return nil
    end
    return Mgr:GetCurrentSkillID()
end    

function SkillUtils.FindNextWitchSkillID(Actor) 
    local SkillComponent = Actor.SkillComponent
    if not SkillComponent then
        return nil
    end
    local Mgr = SkillComponent.SkillDriver and SkillComponent.SkillDriver:GetAssistSkillManager()
    if not Mgr then
        return nil
    end
    return Mgr:GetNextSkillID()
end

function SkillUtils.FindAssistSkillID(Actor)
    local PS = Actor.PlayerState
    if not PS or not PS.BP_AssistTeamComponent then
        return
    end
    return PS.BP_AssistTeamComponent.AssistSkillID
end

function SkillUtils.GenCampRelationMap()
    SkillUtils.CampRelationMap = {}
    local AllCamps = {}
    for Camp1Str, InnerData in pairs(camp_relation_data.data) do
        local Camp1 = Enum.Enum_CharCamp[Camp1Str]
        assert(Camp1, string.format("error camp1 %s", Camp1Str))

        table.insert(AllCamps, Camp1)
        SkillUtils.CampRelationMap[Camp1] = {}

        for Camp2Str, Relation in pairs(InnerData) do
            local Camp2 = Enum.Enum_CharCamp[Camp2Str]
            assert(Camp2, string.format("error camp2 %s", Camp2))

            SkillUtils.CampRelationMap[Camp1][Camp2] = Relation
        end
    end

    -- G.log:debug("yj", "GenCampRelationMap 1 %s\n\n", utils.FormatTable(SkillUtils.CampRelationMap, 3))

    for _, CampOuter in pairs(AllCamps) do
        for _, CampInner in pairs(AllCamps) do
            if SkillUtils.CampRelationMap[CampOuter][CampInner] == nil then
                SkillUtils.CampRelationMap[CampOuter][CampInner] = SkillUtils.CampRelationMap[CampInner][CampOuter]
            end
        end
    end

    -- G.log:debug("yj", "GenCampRelationMap 2 %s", utils.FormatTable(SkillUtils.CampRelationMap, 3))
end

function SkillUtils.GetCampRelation(Actor1, Actor2)
    if SkillUtils.CampRelationMap == nil then
        SkillUtils.GenCampRelationMap()
    end

    assert(Actor1.CharCamp, string.format("%s Camp error", G.GetDisplayName(Actor1)))
    assert(Actor2.CharCamp, string.format("%s Camp error", G.GetDisplayName(Actor2)))


    return SkillUtils.CampRelationMap[Actor1.CharCamp][Actor2.CharCamp]
end

function SkillUtils.IsEnemy(Actor1, Actor2)
    if Actor1.CharCamp == nil or Actor2.CharCamp == nil then
        return false
    end
    return SkillUtils.GetCampRelation(Actor1, Actor2) == camp_relation_data.Enemy
end

function SkillUtils.IsAlly(Actor1, Actor2)
    if Actor1.CharCamp == nil or Actor2.CharCamp == nil then
        return false
    end
    return SkillUtils.GetCampRelation(Actor1, Actor2) == camp_relation_data.Ally
end

function SkillUtils.IsNeutral(Actor1, Actor2)
    if Actor1.CharCamp == nil or Actor2.CharCamp == nil then
        return false
    end
    return SkillUtils.GetCampRelation(Actor1, Actor2) == camp_relation_data.Neutral
end

-- 检查指定 class 的 GA 能否释放 (包括 cost、CD、GA 中自定义逻辑)
function SkillUtils.CanActivateSkillOfClass(SelfActor, GAClass)
    local ASC = SelfActor.AbilitySystemComponent
    if not ASC then
        return
    end

    local Spec = SkillUtils.FindAbilitySpecFromGAClass(ASC, GAClass)
    return SkillUtils.CheckActivate(ASC, Spec)
end

-- 检查指定 SkillID 的 GA 能否释放 (包括 cost、CD、GA 中自定义逻辑)
function SkillUtils.CanActivateSkill(SelfActor, SkillID)
    local ASC = SelfActor.AbilitySystemComponent
    if not ASC then
        return
    end
    local Spec = SkillUtils.FindAbilitySpecFromSkillID(ASC, SkillID)
    return SkillUtils.CheckActivate(ASC, Spec)
end

function SkillUtils.CheckActivate(ASC, Spec)
    local GA, bInstanced = G.GetGameplayAbilityFromSpecHandle(ASC, Spec.Handle)
    if not GA then
        return false
    end

    local FailTags = UE.FGameplayTagContainer()
    local bCanActivate = GA:CanActivateAbilityWithHandle(Spec.Handle, ASC:GetAbilityActorInfo(), FailTags)

    local Keys = GA.ActivateFailTagMap:Keys()
    for Ind = 1, Keys:Length() do
        local CurKey = Keys:Get(Ind)
        if UE.UBlueprintGameplayTagLibrary.HasTag(FailTags, CurKey, true) then
            local ErrMsg = GA.ActivateFailTagMap:Find(CurKey)

            -- TODO notify UI.
            utils.PrintString(ErrMsg, UE.FLinearColor(1, 0, 0, 1), 2)
        end
    end

    return bCanActivate
end

function SkillUtils.IsSkillAnimation(Animation)
    local UserDataList = UE.UHiUtilsFunctionLibrary.GetAnimationAssetUserData(Animation, UE.UHiAssetUserData.StaticClass())    
    for Ind = 1, UserDataList:Length() do
        local UserData = UserDataList:Get(Ind)
        if UserData and UserData:IsValid() then     
            return UserData.IsSkill
        end
    end
    return false
end

return SkillUtils
