--
-- @COMPANY GHGame
-- @AUTHOR zhengyanshuai
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local InputDef = require('CP0032305_GH.Script.common.input_define')

---@type WBP_Tips_ControlTips_C
local WBP_Tips_Control = Class(UIWindowBase)

--function WBP_Tips_Control:Initialize(Initializer)
--end

--function WBP_Tips_Control:PreConstruct(IsDesignTime)
--end

function WBP_Tips_Control:OnConstruct()
end

--function WBP_Tips_Control:Tick(MyGeometry, InDeltaTime)
--end

---@param Tips string
---@param InteractKey string@input_define.lua中定义的Keys
function WBP_Tips_Control:UpdateParams(Tips, InteractKey, InteractCallback)
    for i = 1, 8 do
        self["SizeBox_PCKey"..i]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self.Txt_Content3:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.SizeBox_PCKey1:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.Txt_Content1:SetText('按下')
    self.Txt_Content2:SetText(Tips)
    local dict = self.WBP_Common_PCkey1.PCKeyDict
    if dict[InteractKey] then
        self.WBP_Common_PCkey1:SetPCkeyText("Adaption","Image",InteractKey)
    else
        self.WBP_Common_PCkey1.TextNormal:SetText(InteractKey)
    end
    -- self.Text_Key:SetText(InputDef:ActionNameToKeyName(InteractKey))
    self.InteractKey = InteractKey
    self.InteractCallback = InteractCallback
end

function WBP_Tips_Control:SetInteractCallback(InteractCallback)
    self.InteractCallback = InteractCallback
end

function WBP_Tips_Control:OnShow()
    UIManager:RegisterPressedKeyDelegate(self, self.OnPressKeyEvent)
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_Tips_Control:Close()
    UIManager:UnRegisterPressedKeyDelegate(self)
    self:PlayAnimation(self.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_Tips_Control:OnPressKeyEvent(KeyName)
    if KeyName == self.InteractKey then
        if self.InteractCallback then
            self.InteractCallback()
        end
        self:PlayAnimation(self.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        return true
    end
end

function WBP_Tips_Control:SpecialOpen(content)
    -- 一共有8个key，::内是按钮
    -- 务必保证有8个key,对应位置上的key为空时以下为调用案例
    -- local ui = UIManager:OpenUI(UIDef.UIInfo.UI_ControlTips)
    -- ui:SpecialOpen("test:n::n:::::haoye::::::::")
    local pattern = ':(.-):'
    self.keys = {}
    self.content = {}
    if content[1] == ':' then
        content = " "..content
    end
    for match in content:gmatch(pattern) do
        table.insert(self.keys, match)
    end
    for nonMatch in content:gsub(pattern, "\n"):gmatch("[^\n]+") do
        table.insert(self.content, nonMatch)
    end
    self:SetKeys()
    self:SetContent()
end

function WBP_Tips_Control:SetKeys()
    for i = 1, 8 do
        self["SizeBox_PCKey"..i]:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    end
    for i = 1, #self.keys do
        if self.keys[i] == '' then
            self["SizeBox_PCKey"..i]:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        local dict = self["WBP_Common_PCkey" .. i].PCKeyDict
        if dict[self.keys[i]] then
            self["WBP_Common_PCkey" .. i]:SetPCkeyText("Normal","Image",self.keys[i])
        else
            self["WBP_Common_PCkey" .. i]:SetPCkeyText("Normal","Text",self.keys[i])
        end
    end
end

function WBP_Tips_Control:SetContent()
    for i = 1, 3 do
        self["Txt_Content"..i]:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    end
    
    for i = 1, 3 do
        if #self.content < i then
            self["Txt_Content"..i]:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self["Txt_Content" .. i]:SetText(self.content[i])
        end
    end
end
function WBP_Tips_Control:DXEventShowEnd()
    self:CloseMyself()
    
end
return WBP_Tips_Control
