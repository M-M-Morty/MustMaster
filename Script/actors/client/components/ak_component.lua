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

local AkComponent = Component(ComponentBase)
local decorator = AkComponent.decorator

function AkComponent:Initialize(...)
    Super(AkComponent).Initialize(self, ...)    
end

function AkComponent:Start()
    Super(AkComponent).Start(self)
    self.DopplerAudioCounter = 0
    self.AnimNotifyEventMap:Clear()    
    self:SetListenerProbe()
end

function AkComponent:Stop()
    Super(AkComponent).Stop(self)
    self.DopplerAudioCounter = 0
    self.AnimNotifyEventMap:Clear()    
end


function AkComponent:SetListenerProbe()
    if self.actor:IsPlayer() then
        local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
        if CameraManager then
            UE.UAkGameplayStatics.SetDistanceProbe(CameraManager, self.actor)   
        end        
    end
end

decorator.message_receiver()
function AkComponent:AfterSwitchIn(OldPlayer, NewPlayer, ExtraInfo)
    self:SetListenerProbe()
end

function AkComponent:GetDopplerInfo(AkEvent)
    local UserDataList = UE.UHiUtilsFunctionLibrary.GetAkAudioTypeUserDatas(AkEvent, UE.UHiAssetUserData.StaticClass())    
    for Ind = 1, UserDataList:Length() do
        local UserData = UserDataList:Get(Ind)
        if UserData and UserData:IsValid() then     
            if UserData.Type == Enum.BPE_AudioUserDataType.E_DopperEffect then
                return true
            end            
        end
    end
    return false
end

-- CallbackMask :  AkCallbackType  ->  AK_EndOfEvent = 0x0001,
function AkComponent:PostAkEventDoppler(AkEvent, CallbackMask, PostEventCallback, ExternalSources, EventName)           
    local isDopplerEnable = self:GetDopplerInfo(AkEvent)
    if isDopplerEnable then
        local PlayingID = self:PostAkEvent(AkEvent, CallbackMask, {self, self.OnAkPostEventCallback}, ExternalSources, EventName)        
        self.DopplerAudioCounter = self.DopplerAudioCounter + 1
        return PlayingID
    else
        return self:PostAkEvent(AkEvent, CallbackMask, nil, ExternalSources, EventName)        
    end    
end

function AkComponent:ReceiveTick(DeltaSeconds)    
    if self:IsDopplerEnable() then
        self:UpdateDopllerEffect(DeltaSeconds)
    end    
end

function AkComponent:OnAkPostEventCallback(CallbackType, CallbackInfo)    
    if CallbackType == UE.EAkCallbackType.EndOfEvent then
        --G.log:debug("hycoldrain", "AkComponent  OnAkPostEventCallback %s %s ", tostring(CallbackType), tostring(CallbackInfo))
        self.DopplerAudioCounter = self.DopplerAudioCounter - 1
    end    
end

function AkComponent:IsDopplerEnable()
    return self.bForceEnableDoppler or (self.DopplerAudioCounter > 0)
end

decorator.message_receiver()
function AkComponent:OnAkEventByAnimNotify(AkEvent, StopAkEvent)    
    self.AnimNotifyEventMap:Add(AkEvent, StopAkEvent)
    --G.log:debug("hycoldrain", "AkComponent:OnAkEventByAnimNotify %s %s  %s", G.GetDisplayName(AkEvent), G.GetDisplayName(StopAkEvent), tostring(self.AnimNotifyEventMap:Length()))
end

decorator.message_receiver()
function AkComponent:OnReceived_Notify_WwiseDataAsset(InTag, SurfaceType)
    if self.FootstepDataAsset then        
        local SoundDataAsset = self.FootstepDataAsset.MovementDataMap:Find(InTag)        
        G.log:debug("Notify_FootStep", "Received_Notify_WwiseDataAsset  check dataasset %s  %s .....", tostring(InTag.TagName), G.GetDisplayName(SoundDataAsset))
        if SoundDataAsset ~= nil then
            local AkSwitchValue = SoundDataAsset.SurfaceAudios:Find(SurfaceType)
            if AkSwitchValue ~= nil then                
                G.log:debug("Notify_FootStep", "Received_Notify_WwiseDataAsset check akswitch value  %s  %s ....",  tostring(SurfaceType), G.GetDisplayName(AkSwitchValue))
                UE.UAkGameplayStatics.SetSwitch(AkSwitchValue, self.actor, "None", "None")
            end                    
            local AkEvent = SoundDataAsset.AudioEvent
            if AkEvent then
                G.log:debug("Notify_FootStep", "Received_Notify_WwiseDataAsset check akevetn %s .....", G.GetDisplayName(AkEvent))
                UE.UAkGameplayStatics.PostEvent(AkEvent, self.actor, 0, nil)
            end
        end    
    end
end


decorator.message_receiver()
function AkComponent:OnEndAbility()    
     --G.log:debug("hycoldrain", "AkComponent:OnEndAbility %s %s ", self.AnimNotifyEventMap:Length(), G.GetDisplayName(self.actor))
     local keys = self.AnimNotifyEventMap:Keys()
     for i = 1, self.AnimNotifyEventMap:Length() do
         local Event = keys:Get(i)
         local StopEvent = self.AnimNotifyEventMap:Find(Event)
         --G.log:error("hycoldrain", "AkComponent:OnEndAbility %s %s", G.GetDisplayName(Event), G.GetDisplayName(StopEvent))
         if StopEvent and StopEvent:IsValid() then
             self:PostAkEvent(StopEvent, 0, nil, "")
         end
     end
     self.AnimNotifyEventMap:Clear()
end

return AkComponent
