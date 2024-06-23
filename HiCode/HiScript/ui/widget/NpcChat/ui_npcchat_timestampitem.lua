--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local ConstText = require("CP0032305_GH.Script.common.text_const")

local M = Component(ComponentBase)

function M:OnDestruct()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
end

function M:InitItem(VM)
    self.VM = VM
    self:SetTimeText(VM.Text_Timestamp:GetFieldValue())

    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.UpdateItem},60,true)
end

function M:UpdateItem()
    local NewTimestamp = os.time()
    local TimeStampInfo
    if NewTimestamp - tonumber(self.VM.SendTime)  < 120 then
        TimeStampInfo = ConstText.GetConstText("CHATROOM_TIMETAG_JUSTNOW")
    elseif NewTimestamp - tonumber(self.VM.SendTime) < 86400 then
        TimeStampInfo = os.date("%H:%M", self.VM.SendTime)
    elseif NewTimestamp - tonumber(self.VM.SendTime) < 31536000 then
        TimeStampInfo = os.date("%m月%d日 %H:%M", self.VM.SendTime)
    else
        TimeStampInfo = os.date("%Y年%m月%d日 %H:%M:", self.VM.SendTime)
    end
    self:SetTimeText(TimeStampInfo)
end

return M
