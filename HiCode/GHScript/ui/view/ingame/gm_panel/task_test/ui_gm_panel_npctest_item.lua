
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local BagModule = require('CP0032305_GH.Script.system_simulator.bag.bag_sim_module')
local utils = require("common.utils")

---@type WBP_GMPanel_NpcTestItem_C
local M = Class(UIWidgetListItemBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
    self:InitWidget()
end

---@param ListItemObject UICommonItemObj_C
function M:OnListItemObjectSet(ListItemObject)
    ---@type ViewModelInterface
    self.ItemValue = ListItemObject.ItemValue:GetFieldValue()
    self.NpcTitle:SetText(self.ItemValue.Title)
end

function M:InitWidget()
    self.DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    self.NpcInteractButton.OnClicked:Add(self, self.OnClicked_Communication)
end

local mission_system_sample = require('CP0032305_GH.Script.system_simulator.mission_system.mission_system_sample')

function M:OnClicked_Communication()
    local DialogueKey = self.ItemValue.DialogueKey
    
    local DialogueObject
    if DialogueKey == 'DialogTest1' then
        DialogueObject = mission_system_sample:CreateDialogue1()
    elseif DialogueKey == 'DialogTest2' then
        DialogueObject = mission_system_sample:CreateDialogue2()
    elseif DialogueKey == 'UIBarrage' then
        local BrgVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.BarrageVM.UniqueName)
        BrgVM:OpenBrgSeq4(mission_system_sample:Test_BrgSeq4())
    elseif  DialogueKey == 'UIScreenCreditList' then
        local BrgVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.BarrageVM.UniqueName)
        BrgVM:OpenScreenCreditList(mission_system_sample:Test_ScreenCreditList())
    elseif  DialogueKey == 'TestPower' then
        local Player = UE.UGameplayStatics.GetPlayerCharacter(UIManager.GameWorld, 0)
        local power = math.floor(math.random( 0, 100))
        if not self.power then
            self.power = 0
        end
        if power > 85 then
            power = 100
        end
        Player:SendMessage("OnPowerChanged", power, self.power)
        self.power = power
    elseif DialogueKey == 'Situation' then
        local UI = UIManager:OpenUI(UIDef.UIInfo.UI_Situation_Chat)
        UI:DisplaySituationChat('名字', '', '内容内容内容内容内容内容内容内容内容内容内容内容内容内容内容内容',function ()
            UnLua.LogWarn("zys 测试完成")
        end)
        utils.DoDelay(UIManager.GameWorld, 5, function()
            UI:DisplaySituationChat('名字123', '', '吾问无为谓吾问无为谓吾问无为谓无',function ()
                UnLua.LogWarn("zys 测试完成222")
            end)
        end)
    end

    if DialogueObject then
        self.DialogueVM:SetDialogUIContext(UIDef.UIInfo.UI_CommunicationNPC)
        self.DialogueVM:OpenDialogInstance(DialogueObject)
    end

    local UIInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_GMPanel.UIName)
    if UIInstance then
        UIInstance:ToggleButton_OnClicked()
    end
end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return M
