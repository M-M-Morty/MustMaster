require "UnLua"

local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local check_table = require("common.data.state_conflict_data")

local SkillWithStand = Component(ComponentBase)
local decorator = SkillWithStand.decorator


function SkillWithStand:Initialize(...)
    Super(SkillWithStand).Initialize(self, ...)
end

function SkillWithStand:Start()
    Super(SkillWithStand).Start(self)
end

function SkillWithStand:Stop()
    Super(SkillWithStand).Stop(self)
end

decorator.message_receiver()
function SkillWithStand:PostReceivePossessed()
    -- Run on Server
    -- Component ReceivePossessed的顺序是不固定的...所以用PostReceivePossessed

    -- G.log:debug("yj", "PostReceivePossessed %s - %s", G.GetDisplayName(self.actor), G.GetHiAbilitySystemComponent(self.actor))
    self:RegisterGameplayTagCB("Ability.Skill.Defend.SetSpeedScale", UE.EGameplayTagEventType.NewOrRemoved, "OnSetSpeedScaleTagNewOrRemoved")
end

decorator.message_receiver()
function SkillWithStand:OnReceiveTick(DeltaSeconds)
    -- Run on Server and Client

    if self.actor:IsClient() then
        return
    end

    local NowMS = G.GetNowTimestampMs()
    if self.EndWithStandTime and self.EndWithStandTime < NowMS then
        self:Server_BreakWithStand_RPC()
        self.EndWithStandTime = nil
    end
end

decorator.message_receiver()
function SkillWithStand:EnterWithStand(WithStandAbility)
    -- Run on Server and Client

    self.WithStandAbility = WithStandAbility

    self.EndWithStandTime = G.GetNowTimestampMs() + self.WithStandAbility.WithStandTime * 1000

    self.EndExtremeWithStandTime = G.GetNowTimestampMs() + self.WithStandAbility.ExtremeWithStandTime * 1000

    if self.WithStandAbility.IsMoveWithStand then
        self:SendMessage("EnterState", check_table.State_MoveWithStand)
    else
        self:SendMessage("EnterState", check_table.State_WithStand)
    end

    self.WithStandStrikeBackCnt = 0
    self:Client_UpdateStrikeBackQteSchedule_RPC(self.WithStandStrikeBackCnt)

    if self.actor:IsClient() then
        -- G.log:debug("yj", "EnterWithStand 1122 %s", G.GetDisplayName(self.MoveWithStandMontage))
        self.actor:Replicated_PlayMontage(self.MoveWithStandMontage, 1.0)
    else
        local CurSpeedScale = self.actor.AppearanceComponent:GetSpeedScale()
        self.actor.AppearanceComponent:Multicast_SetSpeedScale(CurSpeedScale - self.WithStandAbility.SpeedScaleSub, false)
    end
end

decorator.message_receiver()
function SkillWithStand:EndWithStand()
    -- Run on Server and Client

    if not self.WithStandAbility then
        return
    end

    if self.WithStandAbility.IsMoveWithStand then
        self:SendMessage("EndState", check_table.State_MoveWithStand)
    else
        self:SendMessage("EndState", check_table.State_WithStand)
    end

    self.actor.CanUseStrikeBack = nil

    self.WithStandStrikeBackCnt = -1
    self:Client_UpdateStrikeBackQteSchedule_RPC(self.WithStandStrikeBackCnt)

    if self.actor:IsClient() then
        -- G.log:debug("yj", "EndWithStand %s", G.GetDisplayName(self.MoveWithStandMontage))
        self.actor:Replicated_StopMontage(self.MoveWithStandMontage, 0.3)
    else
        local CurSpeedScale = self.actor.AppearanceComponent:GetSpeedScale()
        self.actor.AppearanceComponent:Multicast_SetSpeedScale(CurSpeedScale + self.WithStandAbility.SpeedScaleSub, false)
    end
    
    self.WithStandAbility = nil
end

decorator.message_receiver()
function SkillWithStand:BreakWithStand(reason)
    -- Run on Client
    self:Server_BreakWithStand()
end

function SkillWithStand:Server_BreakWithStand_RPC()
    local ASC = self.actor:GetAbilitySystemComponent()
    local BreakWithStandGEClass = UE.UClass.Load("/Game/Blueprints/Skill/GE/GE_BreakWithStand.GE_BreakWithStand_C")
    local BreakWithStandGESpecHandle = ASC:MakeOutgoingSpec(BreakWithStandGEClass, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(BreakWithStandGESpecHandle)
end

decorator.message_receiver()
function SkillWithStand:OnDamaged(Damage, HitInfo, InstigatorCharacter, DamageCauser, DamageAbility, DamageGESpec)
    -- Run on Server and Client

    if self.actor:IsClient() then
        return
    end

    if not DamageAbility or not self.WithStandAbility then
        return
    end

    if utils.IsWithStandSuccess(DamageCauser, self.actor) then

        -- G.log:debug("yj", "SkillWithStand:OnDamaged InWithStand.%s - %s", G.GetDisplayName(DamageAbility), G.GetDisplayName(DamageCauser))

        self:HandleWithStand(DamageCauser, DamageAbility)

    elseif self.EndWithStandTime then

        -- 招架失败 - 破招
        self:Server_BreakWithStand_RPC()
        self.EndWithStandTime = nil
    end
end

function SkillWithStand:HandleWithStand(SourceActor, SourceAbility)
    -- Run on Server

    -- if SourceAbility.IsCloseIn then
    --     -- 远程技能没有被招架表现
        SourceActor:SendMessage("HandleBeWithStand", self.actor)
    -- end

    local NowMS = G.GetNowTimestampMs()
    if self.EndWithStandTime - NowMS < self.WithStandAbility.WithStandDelayEndTime * 1000 then
        -- end time delay
        self.EndWithStandTime = self.EndWithStandTime + self.WithStandAbility.WithStandDelayEndTime * 1000
    end

    -- 触发招架效果
    self.WithStandType = "Normal"

    if SourceAbility.IsCloseIn then
        -- 招架近程技能
        self.SpeedScale = self.WithStandAbility.SpeedScaleClose
    else
        -- 招架远程技能
        self.SpeedScale = self.WithStandAbility.SpeedScaleFar

        -- 极限招架
        if NowMS < self.EndExtremeWithStandTime then
            self:HandleExtremeWithStand(SourceActor, SourceAbility)
        end
    end

    -- 招架反击
    self.WithStandStrikeBackCnt = self.WithStandStrikeBackCnt + 1
    self:Client_UpdateStrikeBackQteSchedule(self.WithStandStrikeBackCnt)

    if self.WithStandStrikeBackCnt >= self.WithStandAbility.WithStandStrikeBackCnt then
        self:HandleWithStandStrikeBack()
    end

    -- 招架动画表现
    self:Client_HandleWithStand(self.WithStandType)

    -- G.log:debug("yj", "SkillWithStand:HandleWithStand %s - %s - %s", self.SpeedScale, self.WithStandAbility.SpeedScaleClose, self.WithStandAbility.SpeedScaleFar)

    -- 招架减速
    local ASC = self.actor:GetAbilitySystemComponent()
    local BlockGEClass = UE.UClass.Load("/Game/Blueprints/Skill/GE/GE_SlowSpeedByWithStand.GE_SlowSpeedByWithStand_C")
    local BlockGESpecHandle = ASC:MakeOutgoingSpec(BlockGEClass, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(BlockGESpecHandle)
end

function SkillWithStand:HandleExtremeWithStand(SourceActor, SourceAbility)
    -- G.log:debug("yj", "SkillWithStand:HandleExtremeWithStand")

    if self.HitByProjectile then

        self.HitByProjectile:OnBeExtremeWithStand(self.actor)

        local ProjectLocation = self.HitByProjectile:K2_GetActorLocation()
        local SelfLocation = self.actor:K2_GetActorLocation()
        local SelfForward = self.actor:GetActorForwardVector()

        if UE.UHiCollisionLibrary.CheckInDirectionBySection(ProjectLocation, SelfLocation, SelfForward, 0, 59) then
            self.WithStandType = "Extreme_R"
        elseif UE.UHiCollisionLibrary.CheckInDirectionBySection(ProjectLocation, SelfLocation, SelfForward, 59, 119) then
            self.WithStandType = "Extreme_M"
        else
            self.WithStandType = "Extreme_L"
        end
    end

    self.SpeedScale = self.WithStandAbility.SpeedScaleExtreme

    SourceActor:SendMessage("HandleBeExtremeWithStand", self.actor)
end

function SkillWithStand:HandleWithStandStrikeBack()
    -- Run on Server

    -- self.actor.CanUseStrikeBack = true

    -- self:Client_HandleWithStandStrikeBack()
end

function SkillWithStand:Client_HandleWithStandStrikeBack_RPC()
    self.actor.CanUseStrikeBack = true
end

decorator.message_receiver()
function SkillWithStand:BeforeHandleHitDamageableApplyGE(SourceActor)
    -- 特判...
    if SourceActor.IsMovingType then
        self.HitByProjectile = SourceActor
    end
end

decorator.message_receiver()
function SkillWithStand:AfterHandleHitDamageableApplyGE(SourceActor)
    self.HitByProjectile = nil
end

function SkillWithStand:Client_UpdateStrikeBackQteSchedule_RPC(WithStandStrikeBackCnt)
    if not self.WithStandAbility then
        return
    end
    self:SendMessage("OnStrikeBackQteScheduleChanged", WithStandStrikeBackCnt, self.WithStandAbility.WithStandStrikeBackCnt, self.WithStandAbility.WithStandTime, self.WithStandAbility.ExtremeWithStandTime)
end

function SkillWithStand:Client_HandleWithStand_RPC(WithStandType)
    -- Run on Client
    -- Replicated_PlayMontage must call from client

    -- G.log:debug("yj", "Client_HandleWithStand_RPC %s", WithStandType)

    local WithStandMontages = nil

    if WithStandType == "Normal" then
        WithStandMontages = self.actor.HitComponent.WithStandMontages
    elseif WithStandType == "Extreme_M" then
        WithStandMontages = self.actor.HitComponent.ExtremeWithStandMontages_M
    elseif WithStandType == "Extreme_L" then
        WithStandMontages = self.actor.HitComponent.ExtremeWithStandMontages_L
    elseif WithStandType == "Extreme_R" then
        WithStandMontages = self.actor.HitComponent.ExtremeWithStandMontages_R
    end

    if WithStandMontages:Length() ~= 0 then
        local idx = math.random(1, WithStandMontages:Length())
        self.actor:Replicated_PlayMontage(WithStandMontages[idx], 1.0)
    end

    -- G.log:debug("yj", "SkillWithStand:HandleWithStand %s %s", WithStandMontages[idx], WithStandMontages[idx]:GetName())

    -- 招架音效
    local AkGameObject = UE.UAkGameplayStatics.GetAkComponent(self.actor.Mesh)
    for i = 1, self.actor.HitComponent.WithStandAkEvents:Length() do
        AkGameObject:PostAkEvent(self.actor.HitComponent.WithStandAkEvents:Get(i))
    end
end

decorator.message_receiver()
function SkillWithStand:HandleBeWithStand(TargetActor)
    -- Run on Server
    -- G.log:debug("yj", "SkillWithStand1:HandleBeWithStand %s", TargetActor:GetDamageScale())

    local BeWithStandMontages = self.actor.HitComponent.BeWithStandMontages
    if BeWithStandMontages:Length() == 0 then
        return
    end

    local idx = math.random(1, BeWithStandMontages:Length())
    self.actor.AppearanceComponent:Server_PlayMontage(BeWithStandMontages[idx], 1.0)
end

function SkillWithStand:OnSetSpeedScaleTagNewOrRemoved(Tag, NewCount)

    if NewCount > 0 then
        local CurSpeedScale = self.actor.AppearanceComponent:GetSpeedScale()
        self.SpeedScaleSub = CurSpeedScale - self.SpeedScale
        -- self.actor.AppearanceComponent:SetSpeedScale(CurSpeedScale - self.SpeedScaleSub)
        self.actor.AppearanceComponent:Multicast_SetSpeedScale(CurSpeedScale - self.SpeedScaleSub, false)

        if CurSpeedScale - self.SpeedScaleSub < 0.0001 then
            self.actor.CharacterMovement.Velocity = UE.FVector(0, 0, 0)
        end
        -- G.log:debug("yj", "SkillWithStand:OnSetSpeedScaleTagNewOrRemoved 1 TagName.%s CurSpeedScale(%s) - SpeedScaleSub(%s) = Cur.%s", Tag.TagName, CurSpeedScale, self.SpeedScaleSub, self.actor.AppearanceComponent:GetSpeedScale())

    elseif NewCount == 0 then
        local CurSpeedScale = self.actor.AppearanceComponent:GetSpeedScale()
        -- local SpeedScaleSub = 1.0 - self.SpeedScale
        -- self.actor.AppearanceComponent:SetSpeedScale(CurSpeedScale + self.SpeedScaleSub)
        self.actor.AppearanceComponent:Multicast_SetSpeedScale(CurSpeedScale + self.SpeedScaleSub, false)
        -- G.log:debug("yj", "SkillWithStand:OnSetSpeedScaleTagNewOrRemoved 2 TagName.%s CurSpeedScale(%s) + SpeedScaleSub(%s) = Cur.%s", Tag.TagName, CurSpeedScale, self.SpeedScaleSub, self.actor.AppearanceComponent:GetSpeedScale())
    end
    
end

return SkillWithStand
