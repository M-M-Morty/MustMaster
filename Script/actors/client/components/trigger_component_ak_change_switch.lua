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

---@type BP_AkComponent_C

local TriggerComponentAkChangeSwitch = Component(ComponentBase)

function TriggerComponentAkChangeSwitch:FilterClientPlayer(InActor)
    G.log:debug("hycoldrain", "TriggerComponentAkChangeSwitch:FilterClientPlayer %s ", G.GetDisplayName(self.actor))
    return self.actor:IsTargetActorValidToNotify(InActor) and (InActor:IsClientPlayer() or UE.UKismetSystemLibrary.IsStandalone(InActor))
end

function TriggerComponentAkChangeSwitch:SetAkParamsByDataAsset(DataAsset, InActor)
    for i = 1, DataAsset.Switch:Length() do
        local Switch = DataAsset.Switch:Get(i)
        UE.UAkGameplayStatics.SetSwitch(Switch, InActor, "None", "None")
    end

    for i = 1, DataAsset.RTPC:Length() do
        local RTPC = DataAsset.RTPC:Get(i).RTPC
        local RTPC_Value = DataAsset.RTPC:Get(i).RTPC_Value
        UE.UAkGameplayStatics.SetRTPCValue(RTPC, RTPC_Value, 0, InActor, "None")
    end

    for i = 1, DataAsset.State:Length() do
        local State = DataAsset.State:Get(i)            
        UE.UAkGameplayStatics.SetState(State, "None", "None")
    end
end

function TriggerComponentAkChangeSwitch:ReviceComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)    
    if OtherActor and OtherActor:IsValid() then      
        if self:FilterClientPlayer(OtherActor) then  
            if self.BGM and self.BGM:IsValid() then
                self:SetAkParamsByDataAsset(self.BGM, OtherActor)
            end
            if self.AmbientSound and self.AmbientSound:IsValid() then
                self:SetAkParamsByDataAsset(self.AmbientSound, OtherActor)
            end
        end
    end
end

function TriggerComponentAkChangeSwitch:ReviceComponentEndOverlap(OverlappedComp, OtherActor, OtherComp, OtherBodyIndex)    
    if OtherActor and OtherActor:IsValid() then 
        if self:FilterClientPlayer(OtherActor) then
            --G.log:debug("hycoldrain", "ReviceComponentEndOverlap %s   %s ", G.GetDisplayName(self.AttachParent), G.GetDisplayName(self.AttachParent.BGM))    
            if self.AttachParent and self.AttachParent:IsValid() then
                local CurActor = self:GetOwner()
                local DA_BGM = self.AttachParent.BGM
                if DA_BGM then                    
                    self:SetAkParamsByDataAsset(DA_BGM, OtherActor)
                    if DA_BGM.Switch:Length() == 0 then
                        CurActor:SendMessage("OnSetBGMSwitch", OtherActor)
                    end
                    if DA_BGM.RTPC:Length() == 0 then
                        CurActor:SendMessage("OnSetBGMRTPC", OtherActor)
                    end
                    if DA_BGM.State:Length() == 0 then
                        CurActor:SendMessage("OnSetBGMState")
                    end
                else                    
                    if CurActor and CurActor:IsValid() then
                        CurActor:SendMessage("OnSetBGMSwitch", OtherActor)
                        CurActor:SendMessage("OnSetBGMRTPC", OtherActor)
                        CurActor:SendMessage("OnSetBGMState")
                    end
                end

                local DA_AmbientSound = self.AttachParent.AmbientSound
                if DA_AmbientSound then
                    self:SetAkParamsByDataAsset(DA_AmbientSound, OtherActor)
                    if DA_AmbientSound.Switch:Length() == 0 then
                        CurActor:SendMessage("OnSetAmbientSoundSwitch", OtherActor)
                    end
                    if DA_AmbientSound.RTPC:Length() == 0 then
                        CurActor:SendMessage("OnSetAmbientSoundRTPC", OtherActor)
                    end
                    if DA_AmbientSound.State:Length() == 0 then
                        CurActor:SendMessage("OnSetAmbientSoundState")
                    end
                else                   
                    if CurActor and CurActor:IsValid() then
                        CurActor:SendMessage("OnSetAmbientSoundSwitch", OtherActor)
                        CurActor:SendMessage("OnSetAmbientSoundRTPC", OtherActor)
                        CurActor:SendMessage("OnSetAmbientSoundState")
                    end
                end                
            end
        end
    end
end

return TriggerComponentAkChangeSwitch
