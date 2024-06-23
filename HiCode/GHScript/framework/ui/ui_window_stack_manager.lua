--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local G = require("G")
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')


local WindowStackManager = {}
WindowStackManager.tbFirstPageStack = {}
WindowStackManager.tbSecondaryPageStack = {}
WindowStackManager.tbThirdPageStack = {}
WindowStackManager.currentInfo = nil


function WindowStackManager:Push(UIInfo)
    if not UIInfo then
        return
    end
    if UIInfo.PageLevel ==  Enum.Enum_UILevel.SecondaryPage then
        self:PushStack(self.tbSecondaryPageStack, UIInfo)
    elseif UIInfo.PageLevel == Enum.Enum_UILevel.ThreeLevelPage then
        table.insert(self.tbThirdPageStack, UIInfo.UIName)
    elseif UIInfo.PageLevel == Enum.Enum_UILevel.FirstPage then
        table.insert(self.tbFirstPageStack, UIInfo.UIName)
    end
    self:AddUIIMC()
end


function WindowStackManager:AddUIIMC()
    if not self:TopInstance() then
        return
    end
    self.GameWorld = UIManager.GameWorld
    local UEPlayerController = UE.UGameplayStatics.GetPlayerController(self.GameWorld, 0)
    if not UEPlayerController then
        return
    end
    local IMC = self:TopInstance().UIInfo.IMC
    local UIName = self:TopInstance().UIInfo.UIName
    if IMC == "" or IMC == nil then 
        return
    end
    if UEPlayerController.ControllerUIComponent then
        UEPlayerController.ControllerUIComponent:RegisterUIIMC(UIName,{IMC,},{})
    end
end

function WindowStackManager:RemoveUIIMC(UIInfo)
    local IMC = UIInfo.IMC
    if not IMC then
        return
    end
    local UEPlayerController = UE.UGameplayStatics.GetPlayerController(self.GameWorld, 0)
    if not UEPlayerController then
        return
    end
    if IMC == "" or IMC == nil then
        return
    end
    if UEPlayerController.ControllerUIComponent then
        UEPlayerController.ControllerUIComponent:UnRegisterUIIMC(UIInfo.UIName)
    end
end

function WindowStackManager:RemoveInfo(UIInfo)
    if not UIInfo then
        return
    end
    self:RemoveUIIMC(UIInfo)
    if UIInfo.PageLevel ==  Enum.Enum_UILevel.SecondaryPage then
        self:PopStack(self.tbSecondaryPageStack, UIInfo)
    elseif UIInfo.PageLevel == Enum.Enum_UILevel.ThreeLevelPage then
        TableUtil:ArrayRemoveValue(self.tbThirdPageStack, UIInfo.UIName)
    elseif UIInfo.PageLevel == Enum.Enum_UILevel.FirstPage then
        TableUtil:ArrayRemoveValue(self.tbFirstPageStack, UIInfo.UIName)
    end
    self:AddUIIMC()
end

function WindowStackManager:PushStack(stack, info)
    TableUtil:ArrayRemoveValue(stack, info.UIName)
    for i,v in ipairs(stack) do
        local ins = UIManager:GetUIInstanceIfVisible(v)
        if ins then
            ins:BeginHide(false)
        end
    end
    table.insert(stack, info.UIName)
end

function WindowStackManager:PopStack(stack, info)
    local a = TableUtil:ArrayRemoveValue(stack, info.UIName)
    for i = #stack, 1, -1 do
        local ins = UIManager:GetUIInstance(stack[i])
        if ins then
            ins:BeginShow()
            return
        else
            TableUtil:ArrayRemoveValue(stack, stack[i])
        end
    end
end

function WindowStackManager:ClearStack()
    for i,v in ipairs(self.tbSecondaryPageStack) do
        local ins = UIManager:GetUIInstance(v.UIName)
        if ins then
            ins:BeginHide(true)
        end
    end
    self.tbSecondaryPageStack = {}

    self:ClearAllThirdPagesStack()
end

function WindowStackManager:ClearAllThirdPagesStack()
    for i,v in ipairs(self.tbThirdPageStack) do
        local ins = UIManager:GetUIInstance(v)
        if ins then
            ins:BeginHide(true)
        end
    end
    self.tbThirdPageStack = {}
end

function WindowStackManager:TopInstance()
    local top = self.tbThirdPageStack[#self.tbThirdPageStack]
    if top then
        return UIManager:GetUIInstance(top)
    end
    top = self.tbSecondaryPageStack[#self.tbSecondaryPageStack]
    if top then
        return UIManager:GetUIInstance(top)
    end
    top = self.tbFirstPageStack[#self.tbFirstPageStack]
    if top then
        return UIManager:GetUIInstance(top)
    end

    return nil
    
end

return WindowStackManager
