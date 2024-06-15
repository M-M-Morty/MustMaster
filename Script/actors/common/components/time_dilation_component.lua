require "UnLua"
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local TimeDilationComponent = Component(ComponentBase)
local decorator = TimeDilationComponent.decorator

MinDilationThreshold = 0.01


function TimeDilationComponent:Start()
    Super(TimeDilationComponent).Start(self)

    self:ClearTimeDilationInfo()

    self.bDilationTime = false

    self.bWitchTime = false
end

function TimeDilationComponent:Stop()
    Super(TimeDilationComponent).Stop(self)

    local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())

    self:ClearTimeDilationInfo()
end

function TimeDilationComponent:InternalSetTimeDilation(duration, time_dilation, time_dilation_curve, delay, priority)


    if self.set_dilation_timer or self.delay_timer then
        if self.priority > 0 and priority > self.priority then
            return
        else
            local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())
            if self.set_dilation_timer then
                GameState:ClearAndInvalidateTimerHandle(self.actor, self.set_dilation_timer)
                self.set_dilation_timer = nil
            end
            if self.delay_timer then
                GameState:ClearAndInvalidateTimerHandle(self.actor, self.delay_timer)
                self.delay_timer = nil
            end
        end
    end

    self.priority = priority
    self.duration = duration
    self.time_dilation = time_dilation
    self.time_dilation_curve = time_dilation_curve
    self.bDilationTime = true

    if delay > 0.001 then
        local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())
        self.delay_timer = GameState:SetTimerDelegate({self, self.OnSetTimeDilationStart}, delay, false)
    else
        self:OnSetTimeDilationStart()
    end
end

decorator.message_receiver()
function TimeDilationComponent:SetTimeDilation(duration, time_dilation, delay, priority)
    --G.log:error("devin", "TimeDilationComponent:SetTimeDilation %s %s %s %s", tostring(self), tostring(self.actor.Object), tostring(self.actor:GetLocalRole()), debug.traceback())
    assert(time_dilation >= 0)
    assert(delay >= 0)
    self:InternalSetTimeDilation(duration, time_dilation, nil, delay, priority)
end

decorator.message_receiver()
function TimeDilationComponent:SetTimeDilationByCurve(duration, time_dilation_curve, delay, priority)
    --G.log:error("devin", "TimeDilationComponent:SetTimeDilationByCurve %s", tostring(self))
    assert(time_dilation_curve)
    assert(delay >= 0)
    self:InternalSetTimeDilation(duration, 0, time_dilation_curve, delay, priority)
end


function TimeDilationComponent:OnSetTimeDilationStart()

    --G.log:error("devin", "TimeDilationComponent:OnSetTimeDilationStart %s", tostring(self))
    local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())

    if self.delay_timer then
        GameState:ClearAndInvalidateTimerHandle(self.actor, self.delay_timer)
        self.delay_timer = nil
    end

    if self.time_dilation_curve then
        self.total_time = 0
        self:SetActorTimeDilation(self.time_dilation_curve:GetFloatValue(0))
        self.set_dilation_timer = GameState:SetTimerForNextTickDelegate({self, self.OnSetTimeDilationTick})
    else
        self:SetActorTimeDilation(self.time_dilation)
        self.set_dilation_timer = GameState:SetTimerDelegate({self, self.OnSetTimeDilationEnd}, self.duration, false)
    end    
end

function TimeDilationComponent:OnSetTimeDilationEnd()
    self:ClearTimeDilationInfo()
end

function TimeDilationComponent:OnSetTimeDilationTick()

    local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())

    self.total_time = self.total_time + GameState:GetDeltaRealTimeSeconds()

    --G.log:error("devin", "TimeDilationComponent:OnSetTimeDilationTick %s %s %f %f %d %f", tostring(self), tostring(self.actor.Object), self.duration, self.total_time, self.priority, UE.UGameplayStatics.GetWorldDeltaSeconds(self.actor))

    if self.total_time > self.duration then
        GameState:ClearAndInvalidateTimerHandle(self.actor, self.set_dilation_timer)
        self:OnSetTimeDilationEnd()
        --G.log:error("devin", "TimeDilationComponent:OnSetTimeDilationTick 111 %s", tostring(self))
        return
    else
        --G.log:error("devin", "TimeDilationComponent:OnSetTimeDilationTick 222 %s", tostring(self))
        GameState:ClearTimerHandle(self.actor, self.set_dilation_timer)
        self.set_dilation_timer = GameState:SetTimerForNextTickDelegate({self.actor, self.actor.OnSetTimeDilationTick})
    end

    --G.log:error("devin", "TimeDilationComponent:OnSetTimeDilationTick 333 %s", tostring(self))
    self:SetActorTimeDilation(self.time_dilation_curve:GetFloatValue(self.total_time))
    
end

decorator.message_receiver()
function TimeDilationComponent:RefreshWitchTime(value)
    if self.bDilationTime then
        self:ClearTimeDilationInfo()
    end
    -- if not self.bWitchTime then
    --     G.log:error("devin", "TimeDilationComponent:RefreshWitchTime %s %s", tostring(self), tostring(self.actor:IsClient()))
    -- end
    self.bWitchTime = true
    self:SetActorTimeDilation(value)
end

decorator.message_receiver()
function TimeDilationComponent:StopWitchTime()
    -- G.log:error("devin", "TimeDilationComponent:StopWitchTime 333 %s %s", tostring(self), tostring(self.actor:IsClient()))
    if self.bWitchTime then
        -- G.log:error("devin", "TimeDilationComponent:StopWitchTime 444 %s %s", tostring(self), tostring(self.actor:IsClient()))
        self:SetActorTimeDilation(1.0)
        self.bWitchTime = false
    end
end

function TimeDilationComponent:SetActorTimeDilation(value)
    if value < MinDilationThreshold then
        -- G.log:info("zale", "The Dilation value %s is set too small and will be replaced by 0.01", value, MinDilationThreshold)
        value = MinDilationThreshold
    end
    self.actor.CustomTimeDilation = value
    self:SendMessage("OnSetActorTimeDilation", value)
end

function TimeDilationComponent:ClearTimeDilationInfo()
    self:SetActorTimeDilation(1.0)
    local GameState = UE.UGameplayStatics.GetGameState(self.actor:GetWorld())
    if self.set_dilation_timer then
        GameState:ClearAndInvalidateTimerHandle(self.actor, self.set_dilation_timer)
        self.set_dilation_timer = nil
    end

    if self.delay_timer then
        GameState:ClearAndInvalidateTimerHandle(self.actor, self.delay_timer)
        self.delay_timer = nil
    end
    self.time_dilation_curve = nil
    self.time_dilation = 0
    self.duration = 0
    self.total_time = 0
    self.priority = -1
    self.bDilationTime = false
end

decorator.message_receiver()
function TimeDilationComponent:ForceClearTimerDilation()
    self:ClearTimeDilationInfo()
end

decorator.message_receiver()
function TimeDilationComponent:OnKnockTargets(TargetActors, KnockInfo)
    if self.bWitchTime then
        return
    end
    --G.log:error("devin", "TimeDilationComponent:OnKnockTarget %s", debug.traceback())
    local TimeDilations = KnockInfo.TimeDilation
    for TimeDilationIndex = 1, TimeDilations:Length() do
        local TimeDilation = TimeDilations[TimeDilationIndex]
        local TimeDilationType = TimeDilation.TimeDilationType
        if TimeDilationType == Enum.Enum_TimeDilationType.Caster then
            --G.log:error("devin", "TimeDilationComponent:OnKnockTarget 111 %f %f %f %f", TimeDilation.TimeDilationDuration, TimeDilation.TimeDilationValue, TimeDilation.TimeDilationDelay, TimeDilation.TimeDilationPriority)
            if TimeDilation.TimeDilationCurve then
                self:SetTimeDilationByCurve(TimeDilation.TimeDilationDuration, TimeDilation.TimeDilationCurve, TimeDilation.TimeDilationDelay, TimeDilation.TimeDilationPriority)
            else
                self:SetTimeDilation(TimeDilation.TimeDilationDuration, TimeDilation.TimeDilationValue, TimeDilation.TimeDilationDelay, TimeDilation.TimeDilationPriority)
            end
        elseif TimeDilationType == Enum.Enum_TimeDilationType.Global then
            local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(self)
            if TimeDilationActor then
                TimeDilationActor:SetTimeDilation(TimeDilation)
            end
        end

    end
end

decorator.message_receiver()
function TimeDilationComponent:OnKnock(InstigatorCharacter, DamageCauser, KnockInfo)
    if self.bWitchTime then
        return
    end
    --G.log:error("devin", "TimeDilationComponent:OnKnock")
    local TimeDilations = KnockInfo.TimeDilation
    for TimeDilationIndex = 1, TimeDilations:Length() do
        local TimeDilation = TimeDilations[TimeDilationIndex]
        local TimeDilationType = TimeDilation.TimeDilationType
        if TimeDilationType == Enum.Enum_TimeDilationType.Target then
            --G.log:error("devin", "TimeDilationComponent:OnKnock 111 %f %f %f %f", TimeDilation.TimeDilationDuration, TimeDilation.TimeDilationValue, TimeDilation.TimeDilationDelay, TimeDilation.TimeDilationPriority)
            if TimeDilation.TimeDilationCurve then
                self:SetTimeDilationByCurve(TimeDilation.TimeDilationDuration, TimeDilation.TimeDilationCurve, TimeDilation.TimeDilationDelay, TimeDilation.TimeDilationPriority)
            else
                self:SetTimeDilation(TimeDilation.TimeDilationDuration, TimeDilation.TimeDilationValue, TimeDilation.TimeDilationDelay, TimeDilation.TimeDilationPriority)
            end
        end
    end
end

return TimeDilationComponent
