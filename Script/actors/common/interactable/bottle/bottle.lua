--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR KyainZhang
-- @DATE 2023/11/2
--

---@type

require "UnLua"
local G = require("G")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local ActorBase = require("actors.common.interactable.base.interacted_item")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end


function M:SendCard()
    local PC = UE.UGameplayStatics.GetPlayerController(self,0)
    PC.ItemManager:AddItemByExcelID(180102,1)
end


function M:SetShakeFalse()
    self.Player_Start_Interacte = false
end


--显示摇罐子UI
function M:ShowInteractionUI()
    local TextID = 1018
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if not HudMessageCenterVM then
        return
    end
    local ObjectInfo = "电话卡"
    HudMessageCenterVM:ShowInteractionJar(ObjectInfo,TextID,self) 
end


--显示晃出小卡片后的UI
function M:ShowCardUI()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    HudMessageCenterVM:OnShakeFinish()
end


return M