--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")

---@type BGMComponent_C
local BGMComponent = Component(ComponentBase)
local decorator = BGMComponent.decorator

-- function M:Initialize(Initializer)
-- end

function BGMComponent:ReceiveBeginPlay()
    Super(BGMComponent).ReceiveBeginPlay(self)
    --G.log:info("[hycoldrain]", "BGMComponent:ReceiveBeginPlay")
    self.DelayTimerHandle = nil    
end

decorator.message_receiver()
function BGMComponent:OnSetBGMSwitch(InActor)
    if self.BGM and self.BGM:IsValid() then
        for i = 1, self.BGM.Switch:Length() do
            local Switch = self.BGM.Switch:Get(i)
            if Switch and Switch:IsValid() then
                --G.log:info("[hycoldrain]", "BGMComponent:OnPlayerEnterTrigger---[%s],   [%s]", G.GetDisplayName(InSwitch), G.GetDisplayName(InActor))    
                UE.UAkGameplayStatics.SetSwitch(Switch, InActor, "None", "None")
            end
        end
    end
end

decorator.message_receiver()
function BGMComponent:OnSetAmbientSoundSwitch(InActor)
    if self.AmbientSound and self.AmbientSound:IsValid() then
        for i = 1, self.AmbientSound.Switch:Length() do
            local Switch = self.AmbientSound.Switch:Get(i)
            if Switch and Switch:IsValid() then
                --G.log:info("[hycoldrain]", "BGMComponent:OnPlayerEnterTrigger---[%s],   [%s]", G.GetDisplayName(InSwitch), G.GetDisplayName(InActor))    
                UE.UAkGameplayStatics.SetSwitch(Switch, InActor, "None", "None")
            end
        end
    end    
end

decorator.message_receiver()
function BGMComponent:OnSetBGMRTPC(InActor)
    if self.BGM and self.BGM:IsValid() then
        for i = 1, self.BGM.RTPC:Length() do
            local RTPC = self.BGM.RTPC:Get(i).RTPC
            local RTPC_Value = self.BGM.RTPC:Get(i).RTPC_Value
            if RTPC and RTPC_Value:IsValid() then
                UE.UAkGameplayStatics.SetRTPCValue(RTPC, RTPC_Value, 0, InActor, "None")
            end
        end
    end
end
   
decorator.message_receiver()
function BGMComponent:OnSetAmbientSoundRTPC(InActor)
    if self.AmbientSound and self.AmbientSound:IsValid() then
        for i = 1, self.AmbientSound.RTPC:Length() do
            local RTPC = self.AmbientSound.RTPC:Get(i).RTPC
            local RTPC_Value = self.AmbientSound.RTPC:Get(i).RTPC_Value
            if RTPC and RTPC_Value:IsValid() then
                UE.UAkGameplayStatics.SetRTPCValue(RTPC, RTPC_Value, 0, InActor, "None")
            end
        end
    end
end

decorator.message_receiver()
function BGMComponent:OnSetBGMState()
    if self.BGM and self.BGM:IsValid() then
        for i = 1, self.BGM.State:Length() do
            local State = self.BGM.RTPC:Get(i)            
            if State and State:IsValid() then
                UE.UAkGameplayStatics.SetState(State, "None", "None")
            end
        end
    end
end

decorator.message_receiver()
function BGMComponent:OnSetAmbientSoundState()
    if self.AmbientSound and self.AmbientSound:IsValid() then
        for i = 1, self.AmbientSound.State:Length() do
            local State = self.AmbientSound.State:Get(i)            
            if State and State:IsValid() then
                UE.UAkGameplayStatics.SetState(State, "None", "None")
            end
        end
    end
end


decorator.message_receiver()
function BGMComponent:OnPlayerEnterTrigger(InActor)
    G.log:info("[hycoldrain]", "BGMComponent:OnPlayerEnterTrigger--- [%s], [%s]", G.GetDisplayName(self), G.GetDisplayName(InActor))

    self:OnSetBGMSwitch(InActor)    
    self:OnSetAmbientSoundSwitch(InActor)

    self:OnSetBGMRTPC(InActor)
    self:OnSetAmbientSoundRTPC(InActor)

    self:OnSetBGMState()
    self:OnSetAmbientSoundState()

    if self.BGM and self.BGM:IsValid() then
        if self.BGM.Delay.Enabled then 
            local DelayTime = UE.UKismetMathLibrary.RandomFloatInRange(self.BGM.Delay.Min_Offset, self.BGM.Delay.Max_Offset)    
            self:TryPostAkEventLoop(self.BGM.PlayAkEvent, InActor, DelayTime)
        else
            self:TryPostAkEvent(self.BGM.PlayAkEvent, InActor)
        end    
    end

    if self.AmbientSound and self.AmbientSound:IsValid() then
        self:TryPostAkEvent(self.AmbientSound.PlayAkEvent, InActor)
    end   
end


function BGMComponent:TryPostAkEventLoop(InAkEvent, InActor, DelayTime)
    if InAkEvent and InAkEvent:IsValid() then   
        if not UE.UAkGameplayStatics.IsEventPlayingOnActor(InAkEvent, InActor) then                        
            UE.UAkGameplayStatics.PostEvent(InAkEvent, InActor, 1, {self,  function(CallbackType, CallbackInfo)
                    self:OnAkPostEventCallback(CallbackType, CallbackInfo, InActor, DelayTime)
                end})          
        end
    end
end

function BGMComponent:OnAkPostEventCallback(CallbackType, CallbackInfo, InActor, DelayTime)    
    self.DelayTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self.actor, function() self:TryPostAkEventLoop(self.PlayBGM, InActor) end}, DelayTime, false)
end

function BGMComponent:TryPostAkEvent(InAkEvent, InActor)
    if InAkEvent and InAkEvent:IsValid() then   
        if not UE.UAkGameplayStatics.IsEventPlayingOnActor(InAkEvent, InActor) then
            G.log:info("[hycoldrain]", "UE.UPostEventAsync.TryPostAkEvent--- [%s], [%s]", G.GetDisplayName(InAkEvent), G.GetDisplayName(InActor))
            UE.UAkGameplayStatics.PostEvent(InAkEvent, InActor, 0, nil)          
        end
    end
end

decorator.message_receiver()
function BGMComponent:OnPlayerLeaveTrigger(InActor)  
    G.log:info("[hycoldrain]", "BGMComponent:OnPlayerLeaveTrigger--- [%s]", G.GetDisplayName(InActor))  
    if self.BGM and self.BGM:IsValid() then
        if self.BGM.StopAkEvent then
            UE.UAkGameplayStatics.PostEvent(self.BGM.StopAkEvent, InActor, 0, nil)
        end
    end

    if self.AmbientSound and self.AmbientSound:IsValid() then
        if self.AmbientSound.StopAkEvent then
            UE.UAkGameplayStatics.PostEvent(self.AmbientSound.StopAkEvent, InActor, 0, nil)
        end
    end    
    
    if self.DelayTimerHandle then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
end

function BGMComponent:ReceiveEndPlay()
    Super(BGMComponent).ReceiveEndPlay(self)
    if self.DelayTimerHandle then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
end

return BGMComponent
