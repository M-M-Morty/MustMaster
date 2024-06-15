require "UnLua"

local G = require("G")

local TrapActorBase = require("actors.common.trap.TrapActorBase")

local TrapActorSafeArea = Class(TrapActorBase)

local ServerFPS = 10
local ClientFPS = 30


function TrapActorSafeArea:ReceiveBeginPlay()
    Super(TrapActorSafeArea).ReceiveBeginPlay(self)

    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.K2_DestroyActor}, self.LifeTime, false)
end

function TrapActorSafeArea:Real_OnActorBeginOverlap(OtherActor)
    if OtherActor.CharIdentity == Enum.Enum_CharIdentity.Player then
        OtherActor:SendMessage("GoldenBody", true)
    end

    if self.RecoverHpTimerHandler == nil then
        self.RecoverHpTimerHandler = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.RecoverHpTimer}, 1, true)
    end

    -- G.log:error("yj", "TrapActorSafeArea OnActorBeginOverlap OtherActor.%s, InnerActors Length.%s", OtherActor:GetDisplayName(), self.InnerActors:Length())
end

function TrapActorSafeArea:Real_OnActorEndOverlap(OtherActor)
    if OtherActor.CharIdentity == Enum.Enum_CharIdentity.Player then
        OtherActor:SendMessage("GoldenBody", false)
    end

    if self.InnerActors:Length() == 0 then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.RecoverHpTimerHandler)
        self.RecoverHpTimerHandler = nil
    end

    -- G.log:error("yj", "TrapActorSafeArea OnActorEndOverlap OtherActor.%s, InnerActors Length.%s", OtherActor:GetDisplayName(), self.InnerActors:Length())
end

function TrapActorSafeArea:RecoverHpTimer()
    local Array = self.InnerActors:ToArray()
    for idx = 1, Array:Length() do
        local InnerActor = Array:Get(idx)
        if InnerActor.CharIdentity == Enum.Enum_CharIdentity.Player then
            local ASC = InnerActor:GetAbilitySystemComponent()
            local GESpecHandle = ASC:MakeOutgoingSpec(self.RecoverGE, 1, UE.FGameplayEffectContextHandle())
            ASC:BP_ApplyGameplayEffectSpecToSelf(GESpecHandle)
        end
    end
end

function TrapActorSafeArea:ReceiveEndPlay()
    Super(TrapActorSafeArea).ReceiveEndPlay(self)
    if not self:IsServer() then
        return
    end

    local Array = self.InnerActors:ToArray()
    for idx = 1, Array:Length() do
        local InnerActor = Array:Get(idx)
        InnerActor:SendMessage("GoldenBody", false)
    end

    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.RecoverHpTimerHandler)
    self.RecoverHpTimerHandler = nil
end


return TrapActorSafeArea
