local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local CharacterStateComponent = Component(ComponentBase)
local decorator = CharacterStateComponent.decorator

function CharacterStateComponent:Initialize(...)
    Super(CharacterStateComponent).Initialize(self, ...)
end

function CharacterStateComponent:Start()
    Super(CharacterStateComponent).Start(self)
end

function CharacterStateComponent:ReceiveBeginPlay()
    Super(CharacterStateComponent).ReceiveBeginPlay(self)
    self.SkillStateCount = 0
    self.__TAG__ = string.format("CharacterStateComponent(%s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

function CharacterStateComponent:Stop()
    Super(CharacterStateComponent).Stop(self)
end

function CharacterStateComponent:SetSkillState(bSkill, IdleActingBehavior)
    G.log:debug(self.__TAG__, "Actor: %s set skill state: %s", G.GetDisplayName(self.actor), bSkill)

    self.bSkill = bSkill
    if self.actor and UE.UKismetSystemLibrary.IsValid(self.actor) then
        if bSkill and self.SkillStateCount == 0 then
            self.actor.AppearanceComponent:EnterSkillAnimWithIdleActing(IdleActingBehavior)
        elseif not bSkill and self.SkillStateCount == 1 then
            self.actor.AppearanceComponent:LeaveSkillAnimWithIdleActing(IdleActingBehavior)
        end
    end

    if bSkill then
        self.SkillStateCount = self.SkillStateCount + 1
    else
        self.SkillStateCount = self.SkillStateCount - 1
    end
end

function CharacterStateComponent:SetCameraBehaviorState(SkillCameraState)
    -- G.log:debug(self.__TAG__, "Actor: %s set skill camera state: %s", G.GetDisplayName(self.actor), SkillCameraState)
    self.SkillCameraState = SkillCameraState
end

function CharacterStateComponent:IsSkillState()
    return self.bSkill
end

function CharacterStateComponent:SetHitState(bHit)
    G.log:debug(self.__TAG__, "Actor: %s set hit state: %s", G.GetDisplayName(self.actor), bHit)
    self.bHit = bHit
end

function CharacterStateComponent:SetInVehicle(bInVehicle)
    G.log:debug(self.__TAG__, "Actor: %s set bInVehicle: %s", G.GetDisplayName(self.actor), bInVehicle)
    self.InVehicle = bInVehicle
end

function CharacterStateComponent:IsInVehicle()
    return self.InVehicle
end

function CharacterStateComponent:IsHitState()
    return self.bHit
end

function CharacterStateComponent:SetBossBattleState(bIsInBossBattleState, Target)
    G.log:debug(self.__TAG__, "ChangeState %s %s", bIsInBossBattleState, G.GetDisplayName(Target))

    self.InBossBattleState = bIsInBossBattleState
    local PlayerController = self.actor.PlayerState:GetPlayerController()
    PlayerController.PlayerCameraManager:SetBossBattleState(bIsInBossBattleState, Target)
end

decorator.message_receiver()
function CharacterStateComponent:OnEnterBossBattleState(Target)
    self:SetBossBattleState(true, Target)
end

decorator.message_receiver()
function CharacterStateComponent:OnLeaveBossBattleState(Target)
    self:SetBossBattleState(false, Target)
end

decorator.message_receiver()
function CharacterStateComponent:SetInBattleState(bInBattle)
    G.log:debug(self.__TAG__, "SetInBattleState %s", tostring(bInBattle))
    local ASC = G.GetHiAbilitySystemComponent(self.actor)

    if bInBattle then
        ASC:BP_ApplyGameplayEffectToSelf(self.InBattleGE, 0.0, nil)
    else
        ASC:RemoveActiveGameplayEffectBySourceEffect(self.InBattleGE, nil, -1)
    end
end

decorator.message_receiver()
function CharacterStateComponent:OnGround(Target)
    local AbilitySystemComponent = G.GetHiAbilitySystemComponent(self.actor)
    AbilitySystemComponent:BP_ApplyGameplayEffectToSelf(self.OnGroundGE, 0.0, nil)
end

decorator.message_receiver()
function CharacterStateComponent:InAir(Target)
    local AbilitySystemComponent = G.GetHiAbilitySystemComponent(self.actor)
    AbilitySystemComponent:BP_ApplyGameplayEffectToSelf(self.InAirGE, 0.0, nil)
end

function CharacterStateComponent:SetRushAttach(bRushAttach)
    G.log:debug(self.__TAG__, "Actor: %s set rush attach: %s", G.GetDisplayName(self.actor), bRushAttach)
    self.bRushAttach = bRushAttach
end

function CharacterStateComponent:IsRushAttach()
    return self.bRushAttach
end

function CharacterStateComponent:SetHitFly(bHitFly)
    G.log:debug(self.__TAG__, "Actor: %s set hit fly state: %s", G.GetDisplayName(self.actor), bHitFly)
    self.HitFly = bHitFly
end

function CharacterStateComponent:SetInKnock(bInKnock)
    if self.bInKnock == bInKnock then
        return
    end

    G.log:debug(self.__TAG__, "Actor: %s set InKnock state: %s", G.GetObjectName(self.actor), bInKnock)
    self.bInKnock = bInKnock

    if bInKnock then
        self:SendMessage("OnBeginInKnock")
    else
        self:SendMessage("OnEndInKnock")
    end
end

return CharacterStateComponent
