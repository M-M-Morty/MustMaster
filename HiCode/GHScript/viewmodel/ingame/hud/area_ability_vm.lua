--


local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local DialogueObjectModule = require("mission.dialogue_object")
local EdUtils = require("common.utils.ed_utils")


local MadukLampType = {
    None = 0,
    MadukLamp = 1,
    Replicator = 2,
}

---@class AreaAbilityVM : ViewModelBase
local AreaAbilityVM = Class(ViewModelBaseClass)

function AreaAbilityVM:ctor()

    G.log:debug("zys", "Construct AreaAbilityVM")
end

---`brief`重新绑定主界面左侧复制器按钮回调
---@param fnCB fun()
function AreaAbilityVM:BindInterfaceCopyerBtnCB(fnCB)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface:BindCopyerBtnCB(fnCB)
    end
end

---`brief`重新绑定主界面右侧区域能力按钮回调
---@param fnCB fun()
function AreaAbilityVM:BindInterfaceAreaAbilityBtnCB(fnCB)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface:BindAreaAbilityBtnCB(fnCB)
    end
end

function AreaAbilityVM:SetAreaAbilityType(areaAbilityType)
    if self.areaAbilityType ~= areaAbilityType then
        local Row = EdUtils:GetAreaAbilityDataTableRow(areaAbilityType)
        if Row.TypeTextKey then
            local picKey = Row.TypeNameIcon
            local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
            if UIMainInterface then
                UIMainInterface:SetAreaAbilityIcon(picKey)
            end
            self.areaAbilityType = areaAbilityType
        end
    end
end

---`brief`打开复制器界面,调整主界面复制器图标状态,绑定此界面的具体回调
---@param fnUsetCallback fun() 当鼠标点击复制按钮时
---@param fnCloseCallback fun() 当鼠标点击关闭按钮时
---@return boolean 是否打开成功(如当前技能已是其他类型, 则忽略此次Open)
function AreaAbilityVM:OpenCopyerPanel(fnUseCallback, fnCloseCallback)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        if not UIMainInterface.WBP_HUD_SkillState:OpenCopyerPanel() then
            return false
        end
        UIMainInterface.WBP_HUD_SkillState:BindCopyerUseBtnCB(fnUseCallback)
        self.closeCopyerCB = fnCloseCallback
        UIManager:OpenUI(UIDef.UIInfo.UI_MadukLamp_Main, MadukLampType.Replicator)
    end
    if UIMainInterface then
        --self:SetAreaAbilityUsing(true)
        --self:SetAreaCopyerUsable(false)
    end
    return true
end

---`brief`关闭复制器界面,调整主界面复制器图标状态,Unbind所有回调
function AreaAbilityVM:CloseCopyerPanel()
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:CloseCopyerPanel()
        UIMainInterface.WBP_HUD_SkillState:BindCopyerUseBtnCB()
        UIMainInterface.WBP_HUD_SkillState:BindCopyerCloseBtnCB()
    end
    if UIMainInterface then
        --self:SetAreaAbilityUsing(false)
        --self:SetAreaCopyerUsable(true)
    end
    if self.closeCopyerCB then
        self.closeCopyerCB()
        self.closeCopyerCB = nil
    end
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:Close()
    end

end

---`brief`打开区域能力界面,调整主界面区域能力图标状态,绑定此界面的具体回调
---@param fnUseCallback fun() 当鼠标点击对他人使用按钮时
---@param fnSelfCallback fun() 当鼠标点击对自己使用按钮时
---@param fnCloseCallback fun() 当鼠标点击关闭按钮时
---@return boolean 是否打开成功(如当前技能已是其他类型, 则忽略此次Open)
function AreaAbilityVM:OpenAreaAbilityPanel(fnUseCallback, fnSelfCallback, fnCloseCallback)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        if not UIMainInterface.WBP_HUD_SkillState:OpenAreaAbilityPanel() then
            return false
        end
        UIMainInterface.WBP_HUD_SkillState:BindAreaAbilityUseBtnCB(fnUseCallback)
        UIMainInterface.WBP_HUD_SkillState:BindAreaAbilitySelfBtnCB(fnSelfCallback)
        self.closeAreaAbilityCB = fnCloseCallback
        UIManager:OpenUI(UIDef.UIInfo.UI_MadukLamp_Main, MadukLampType.Replicator)
    end
    if UIMainInterface then
        --self:SetAreaAbilityUsing(true)
        --self:SetAreaCopyerUsable(false)
    end
    return true
end

---`brief`关闭区域能力界面,调整主界面区域能力图标状态,Unbind所有回调
function AreaAbilityVM:CloseAreaAbilityPanel()
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:CloseAreaAbilityPanel()
        UIMainInterface.WBP_HUD_SkillState:BindAreaAbilityUseBtnCB()
        UIMainInterface.WBP_HUD_SkillState:BindAreaAbilitySelfBtnCB()
        UIMainInterface.WBP_HUD_SkillState:BindAreaAbilityCloseBtnCB()
    end
    if UIMainInterface then
        --self:SetAreaAbilityUsing(false)
        --self:SetAreaCopyerUsable(true)
    end
    if self.closeAreaAbilityCB then
        self.closeAreaAbilityCB()
        self.closeAreaAbilityCB = nil
    end
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:Close()
    end
end

---`brief`打开马杜克灯界面并绑定此界面的具体回调
---@param fnUseCallback fun() 当鼠标点击马杜克灯按钮时
---@param fnCloseCallback fun() 当鼠标点击关闭按钮时
---@return boolean 是否打开成功(如当前技能已是其他类型, 则忽略此次Open)
function AreaAbilityVM:OpenMadukPanel(fnUseCallback, fnCloseCallback)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        if not UIMainInterface.WBP_HUD_SkillState:OpenMadukPanel() then
            return false
        end
        UIMainInterface.WBP_HUD_SkillState:BindMadukUseBtnCB(fnUseCallback)
        UIMainInterface.WBP_HUD_SkillState:BindMadukCloseBtnCB(fnCloseCallback)
        UIManager:OpenUI(UIDef.UIInfo.UI_MadukLamp_Main, MadukLampType.MadukLamp)
    end
    return true
end

---`brief`关闭马杜克灯界面并Unbind所有回调
function AreaAbilityVM:CloseMadukPanel()
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:CloseMadukPanel()
        UIMainInterface.WBP_HUD_SkillState:BindMadukUseBtnCB()
        UIMainInterface.WBP_HUD_SkillState:BindMadukCloseBtnCB()
        local lamp = UIManager:GetUIInstance(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
        if lamp then
            lamp:Close()
        end
    end
end

---`brief`设置当前瞄准
---@param bAimed boolean
function AreaAbilityVM:SetAimed(bAimed)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:SetCopyerAimed(bAimed)
    end
end

---`brief`设置当前是否能使用X
---@param bAimed boolean
function AreaAbilityVM:SetCanExist(flag)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:SetCanExist(flag)
    end
end

---`brief`重新绑定复制器复制按钮回调
function AreaAbilityVM:UpdateCopyerUseCB(fnCB)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:BindCopyerUseBtnCB(fnCB)
    end
end

---`brief`重新绑定复制器关闭按钮回调
function AreaAbilityVM:UpdateCopyerCloseCB(fnCB)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:BindCopyerCloseBtnCB(fnCB)
    end
end

---`brief`重新绑定区域能力对别人使用按钮回调
function AreaAbilityVM:UpdateAreaAbilityUseCB(fnCB)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:BindAreaAbilityUseBtnCB(fnCB)
    end
end

---`brief`重新绑定区域能力对自己使用按钮回调
function AreaAbilityVM:UpdateAreaAbilitySelfCB(fnCB)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:BindAreaAbilitySelfBtnCB(fnCB)
    end
end

---`brief`重新绑定区域能力关闭按钮回调
function AreaAbilityVM:UpdateAreaAbilityCloseCB(fnCB)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:BindAreaAbilityCloseBtnCB(fnCB)
    end
end

---`brief`重新绑定马杜克灯使用按钮回调
function AreaAbilityVM:UpdateMadukUseCB(fnCB)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:BindMadukUseBtnCB(fnCB)
    end
end

---`brief`重新绑定马杜克灯关闭按钮回调
function AreaAbilityVM:UpdateMadukCloseCB(fnCB)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface.WBP_HUD_SkillState:BindMadukCloseBtnCB(fnCB)
    end
end

---`brief`设置马杜克灯瞄准状态
function AreaAbilityVM:EnterMadukLampAimState()
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:EnterMadukLampAimState()
    end
end

---`brief`设置马杜克灯正常状态
function AreaAbilityVM:EnterMadukLampNomalState()
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:EnterMadukLampNomalState()
    end
end

---`brief`设置马杜克灯聚焦状态
function AreaAbilityVM:EnterMadukLampFocusState()
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:EnterMadukLampFocusState()
    end
end

---`brief`设置马杜克灯非聚焦状态
function AreaAbilityVM:EnterMadukLampUnFocusState()
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:EnterMadukLampUnFocusState()
    end
end

---`brief`设置复制器正常状态
function AreaAbilityVM:EnterReplicatorNomalState()
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:EnterReplicatorNomalState()
    end
end

---`brief`设置复制器瞄准状态
function AreaAbilityVM:EnterReplicatorAimState()
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:EnterReplicatorAimState()
    end
end

---`brief`设置复制器非聚焦状态
function AreaAbilityVM:EnterReplicatorUnFocusState()
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:EnterReplicatorUnFocusState()
    end
end

---`brief`设置复制器聚焦状态
function AreaAbilityVM:EnterReplicatorFocusState()
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:EnterReplicatorFocusState()
    end
end

---`brief`设置马杜克灯信息
---@param name string
---@param icon string
function AreaAbilityVM:SetShineInfo(name, icon)
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:SetShineInfo(name, icon)
    end
end

function AreaAbilityVM:HideShineInfo()
    local UI_MadukLamp = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MadukLamp_Main.UIName)
    if UI_MadukLamp then
        UI_MadukLamp:HideShineInfo();
    end
end

---`brief`设置区域能力使用中
---@param bUsing boolean 是否使用中
function AreaAbilityVM:SetAreaAbilityUsing(bUsing)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface:SetAreaAbilityUsing(bUsing)
    end
end

---`brief`设置复制器可用性
---@param bUsing boolean 是否可用
function AreaAbilityVM:SetAreaCopyerUsable(bUsable)
    local UIMainInterface = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if UIMainInterface then
        UIMainInterface:SetAreaCopyerUsable(bUsable)
    end
end

AreaAbilityVM.MadukLampType = MadukLampType
return AreaAbilityVM
