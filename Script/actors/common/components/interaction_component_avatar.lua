local string = require("string")
local G = require("G")
local InteractionComponentCharacter = require("actors.common.components.interaction_component_character")
local Component = require("common.component")
local check_table = require("common.data.state_conflict_data")

local InteractionComponent_Avatar = Component(InteractionComponentCharacter)
local decorator = InteractionComponent_Avatar.decorator

local CaptureTickFrame = 10
function InteractionComponent_Avatar:Initialize(...)
    Super(InteractionComponent_Avatar).Initialize(self, ...)
end

function InteractionComponent_Avatar:ReceiveBeginPlay()
    Super(InteractionComponent_Avatar).ReceiveBeginPlay(self)

    self.FrameCount = 0
end

function InteractionComponent_Avatar:ReceiveTick(DeltaSeconds)
    self.FrameCount = self.FrameCount + 1
    Super(InteractionComponent_Avatar).ReceiveTick(self, DeltaSeconds)

    if self.actor:IsPlayer() or self.actor:IsServer() and self.FrameCount % CaptureTickFrame == 0 then
        self:ShowTargetCanCapture()
    end
end

function InteractionComponent_Avatar:ShowTargetCanCapture()
    local BlockSkillID = SkillUtils.FindBlockSkillIDOfCurrentPlayer(self.actor:GetWorld())
    if not BlockSkillID then
        return
    end

    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local SpecHandle = SkillUtils.FindAbilitySpecHandleFromSkillID(ASC, BlockSkillID)
    if SpecHandle and SpecHandle.Handle ~= -1 then
        local GA, bInstanced = G.GetGameplayAbilityFromSpecHandle(ASC, SpecHandle)
        if GA and GA.SkillType == Enum.Enum_SkillType.CaptureAndThrow then
            -- Has capture GA.
            local CaptureTarget = GA:GetCaptureTarget()
            if self.TargetCanCapture and self.TargetCanCapture ~= CaptureTarget then
                G.log:debug(self.__TAG__, "Actor: %s, ShowCapture false", G.GetObjectName(self.TargetCanCapture))
                self.TargetCanCapture:SendMessage("ShowCapture", false)
                self.TargetCanCapture = nil
            end

            if CaptureTarget and self.TargetCanCapture ~= CaptureTarget then
                G.log:debug(self.__TAG__, "Actor: %s, ShowCapture true", G.GetObjectName(CaptureTarget))
                CaptureTarget:SendMessage("ShowCapture", true)
                self.TargetCanCapture = CaptureTarget
            end
        end
    end
end

function InteractionComponent_Avatar:OnAbsorb(Instigator, Duration, TargetLocation, TargetSocketName, bDynamicFollow)
    Super(InteractionComponent_Avatar).OnAbsorb(self, Instigator, Duration, TargetLocation, TargetSocketName, bDynamicFollow)

    self:SendMessage("EnterState", check_table.State_ForbidMove)
    self:SendMessage("EnterState", check_table.State_ForbidSkill)
    self:SendMessage("BreakSkill")
end

function InteractionComponent_Avatar:OnAbsorbEnd()
    Super(InteractionComponent_Avatar).OnAbsorbEnd(self)

    self:OnCapture(self.CaptureBy)
end

function InteractionComponent_Avatar:OnCapture(Instigator)
    Super(InteractionComponent_Avatar).OnCapture(self, Instigator)

    self:SendMessage("EnterState", check_table.State_ForbidMove)
    self:SendMessage("EnterState", check_table.State_ForbidSkill)
end

function InteractionComponent_Avatar:OnThrowEnd(bIsOnFloor)
    if self.bThrowEnded then
        return
    end

    Super(InteractionComponent_Avatar).OnThrowEnd(self,bIsOnFloor)

    -- 延时保底，避免卡在无法移动和攻击的状态中
    utils.DoDelay(self.actor, 1.0, 
        function()
            self:SendMessage("EndState", check_table.State_ForbidMove)
            self:SendMessage("EndState", check_table.State_ForbidSkill)
        end)

    -- 通过State_OnThrowEnd状态Break来打断OnThrowEnd Montage
    self:SendMessage("EnterState", check_table.State_OnThrowEnd)
end

decorator.message_receiver()
function InteractionComponent_Avatar:BreakOnThrowEnd(reason)
	G.log:debug("yj", "InteractionComponent_Avatar:BreakOnThrowEnd %s", reason)
	self.actor.AppearanceComponent:Replicated_StopMontage(self.OnThrowEndMontage, 0.25)
end

return InteractionComponent_Avatar
