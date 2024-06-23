--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')

---@class UIWaitEventBase
---@field bActive boolean
---@field UIObj table
---@field InContainer UIWaitEventContainer
local UIWaitEventBase = Class()

function UIWaitEventBase:ctor(UIObj)
    self.bActive = false
    self.UIObj = UIObj
    self.InContainer = nil
end

function UIWaitEventBase:ReleaseEvent()
    self:UnBindContainer()
    self:OnReleaseEvent()
    self.UIObj = nil
end

function UIWaitEventBase:IsActive()
    return self.bActive
end

function UIWaitEventBase:SetActive()
    if not self:IsActive() then
        self.bActive = true
        self:OnActive()
    end
end

function UIWaitEventBase:SetUnActive()
    if self:IsActive() then
        self.bActive = false
        self:OnUnActive()
    end
end

function UIWaitEventBase:IsWaitBlockedImpl()
    return false
end

function UIWaitEventBase:IsWaitBlocked()
    if not self.bActive then
        return false
    end

    return self:IsWaitBlockedImpl()
end

function UIWaitEventBase:EventEqualImpl(OtherEvent)
    return false
end

function UIWaitEventBase:EventEqual(OtherEvent)
    if self.__class__ == OtherEvent.__class__ then
        return self:EventEqualImpl(OtherEvent)
    end
end

function UIWaitEventBase:BindContainer(InContainer)
    if not self:HasContainer() then
        self.InContainer = InContainer
    end
end

function UIWaitEventBase:UnBindContainer()
    self:SetUnActive()
    self.InContainer = nil
end

function UIWaitEventBase:HasContainer()
    return self.InContainer and true or false
end

function UIWaitEventBase:ContainerTriggerWait()
    if self:HasContainer() then
        self.InContainer:TriggerWait()
    end
end

return UIWaitEventBase
