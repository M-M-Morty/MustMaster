--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')

---@class UIWaitEventContainer
local UIWaitEventContainer = Class()

function UIWaitEventContainer:ctor()
    self.tbWaitEvent = {}
end

---@param InEventObj UIWaitEventBase
function UIWaitEventContainer:AddWaitEvent(InEventObj)
    if not InEventObj or InEventObj:HasContainer() then
        return
    end

    local ValueExist = TableUtil:FindIf(self.tbWaitEvent, function(ValueInTable)
        return ValueInTable:EventEqual(InEventObj)
    end)
    if not ValueExist then
        table.insert(self.tbWaitEvent, InEventObj)
        InEventObj:BindContainer(self)
    end
end

function UIWaitEventContainer:ClearWaitEvent()
    for _, ev in pairs(self.tbWaitEvent) do
        ev:ReleaseEvent()
    end
    self.tbWaitEvent = {}
end

function UIWaitEventContainer:TriggerWait()
    if self.fnTriggerWaitHandler then
        self.fnTriggerWaitHandler(self)
    end
end

local function TriggerWaitAll(Container)
    for _, ev in pairs(Container.tbWaitEvent) do
        if ev:IsWaitBlocked() then
            return
        end
    end
    Container:WaitCompleted()
end

local function TriggerWaitAny(Container)
    for _, ev in pairs(Container.tbWaitEvent) do
        if not ev:IsWaitBlocked() then
            Container:WaitCompleted()
            break
        end
    end
end

function UIWaitEventContainer:WaitAllEvents(UIObj, fnCompleteCallBack, bClearEventAfterCompleted)
    if not UIObj or not fnCompleteCallBack then
        return
    end
    
    self.CompleteCallBackObj = UIObj
    self.fnCompleteCallBack = fnCompleteCallBack
    self.bClearEventAfterCompleted = bClearEventAfterCompleted
    self.fnTriggerWaitHandler = TriggerWaitAll

    for _, ev in pairs(self.tbWaitEvent) do
        ev:SetActive()
    end
    self:TriggerWait()
end

function UIWaitEventContainer:WaitAnyEvent(UIObj, fnCompleteCallBack, bClearEventAfterCompleted)
    if not UIObj or not fnCompleteCallBack then
        return
    end
    
    self.CompleteCallBackObj = UIObj
    self.fnCompleteCallBack = fnCompleteCallBack
    self.bClearEventAfterCompleted = bClearEventAfterCompleted
    self.fnTriggerWaitHandler = TriggerWaitAny

    for _, ev in pairs(self.tbWaitEvent) do
        ev:SetActive()
    end
    self:TriggerWait()
end

function UIWaitEventContainer:StopWait()
    self.CompleteCallBackObj = nil
    self.fnCompleteCallBack = nil
    self.bClearEventAfterCompleted = nil
    self.fnTriggerWaitHandler = nil
    
    for _, ev in pairs(self.tbWaitEvent) do
        ev:SetUnActive()
    end
end

function UIWaitEventContainer:WaitCompleted()
    local CompleteCallBackObj = self.CompleteCallBackObj
    local fnCompleteCallBack = self.fnCompleteCallBack
    local bClearEventAfterCompleted = self.bClearEventAfterCompleted

    self:StopWait()
    if bClearEventAfterCompleted then
        self:ClearWaitEvent()
    end

    if CompleteCallBackObj and fnCompleteCallBack then
        fnCompleteCallBack(CompleteCallBackObj)
    end
end

return UIWaitEventContainer
