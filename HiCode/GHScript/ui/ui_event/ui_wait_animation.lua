--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local UIWaitEventBase = require('CP0032305_GH.Script.ui.ui_event.ui_wait_event_base')

---@class UIWaitAnimation
local UIWaitAnimation = Class(UIWaitEventBase)

function UIWaitAnimation:ctor(UIObj)
    Super(UIWaitAnimation).ctor(self, UIObj)
    self.AnimationObj = nil

    self.AnimationFinishedCallback = function(UIObj)
        self:SetUnActive()
        self:ContainerTriggerWait()
    end
end

---@param bPlayWhenActive boolean @Event Active自动开始播放，默认为true
---@param StartAtTime boolean
---@param PlayMode EUMGSequencePlayMode
---@param PlaybackSpeed float
function UIWaitAnimation:SetWaitAnimation(AnimationObj, bPlayWhenActive, StartAtTime, PlayMode, PlaybackSpeed)
    if AnimationObj then
        self.AnimationObj = AnimationObj
        if bPlayWhenActive == false then
            self.bPlayWhenActive = false
        else
            self.bPlayWhenActive = true
        end
        self.StartAtTime = StartAtTime or 0.0
        self.PlayMode = PlayMode or UE.EUMGSequencePlayMode.Forward
        self.PlaybackSpeed = PlaybackSpeed or 1.0
    end
end

function UIWaitAnimation:IsWaitBlockedImpl()
    return self.AnimationObj and true or false
end

function UIWaitAnimation:EventEqualImpl(OtherEvent)
    if self.AnimationObj and OtherEvent.AnimationObj then
        return self.AnimationObj == OtherEvent.AnimationObj
    end
end

function UIWaitAnimation:OnActive()
    if self.UIObj and self.AnimationObj then
        self.WidgetAnimationDynamicEvent = { self.UIObj, self.AnimationFinishedCallback }
        self.UIObj:BindToAnimationFinished(self.AnimationObj, self.WidgetAnimationDynamicEvent)
        if self.bPlayWhenActive then
            self.UIObj:PlayAnimation(self.AnimationObj, self.StartAtTime, 1, self.PlayMode, self.PlaybackSpeed, false)
        end
    end
end

function UIWaitAnimation:OnUnActive()
    if self.UIObj and self.WidgetAnimationDynamicEvent then
        self.UIObj:UnbindFromAnimationFinished(self.AnimationObj, self.WidgetAnimationDynamicEvent)
        self.WidgetAnimationDynamicEvent = nil
    end
end

function UIWaitAnimation:OnReleaseEvent()
    self.AnimationObj = nil
end

return UIWaitAnimation
