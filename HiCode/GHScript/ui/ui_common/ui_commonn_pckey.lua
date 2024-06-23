--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')

local PCKeyDict = {
    ['左键'] = 'T_Icon_ClickLeft_Highlight_png',
    ['右键'] = 'T_Icon_ClickRight_Highlight_png',
    ['SpaceBar'] = 'T_Icon_BlankSpace_png',
}
---@type WBP_Common_PCkey_C
local M = Class(UIWidgetBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
end

--function M:Tick(MyGeometry, InDeltaTime)
--end
function M:SetPCkeyText(type, contentType, content)
    self.ImgBg:SetBrushResourceObject(UE.UObject.Load('/Game/CP0032305_GH/UI/UI_Common/Texture/Atlas/Frames/T_Icon_Black_png.T_Icon_Black_png'))
    if type == 'Adaption' then
        self.WidgetSwitcherBg:SetActiveWidgetIndex(0)
    elseif type == 'Normal' then
        self.WidgetSwitcherBg:SetActiveWidgetIndex(1)
    end
    if contentType == 'Text' then
        self.WidgetSwitcherAdaption:SetActiveWidgetIndex(1)
        self.TextAdaption:SetText(content)
        self.WidgetSwitcherNormal:SetActiveWidgetIndex(1)
        self.TextNormal:SetText(content)
    elseif contentType == 'Image' then
        self.WidgetSwitcherAdaption:SetActiveWidgetIndex(0)
        self.WidgetSwitcherNormal:SetActiveWidgetIndex(0)
        self.ImageAdaption:SetBrushResourceObject(self:GetTexture(content))
        self.ImageNormal:SetBrushResourceObject(self:GetTexture(content))
    end
end

function M:GetTexture(name)
    if name == 'SpaceBar' then
        self.AdaptionBg.Background.ResourceObject = UE.UObject.Load('/Game/CP0032305_GH/UI/UI_Common/Texture/Atlas/Frames/T_Icon_White_png.T_Icon_White_png')
    else
        self.AdaptionBg.Background.ResourceObject = UE.UObject.Load('/Game/CP0032305_GH/UI/UI_Common/Texture/Atlas/Frames/T_Icon_Black_png.T_Icon_Black_png')
    end
    local path = '/Game/CP0032305_GH/UI/UI_Common/Texture/Atlas/Frames/'..PCKeyDict[name]..'.'..PCKeyDict[name]
    return UE.UObject.Load(path)
end

function M:PlayAkEvent()
    if UE.UKismetSystemLibrary.IsValid(self['Press Ak Event']) then
        UE.UAkGameplaystatics.PostEvent(self['Press Ak Event'], UE.UGameplaystatics.GetplayerPawn(self, 0), nil, nil, true)
    end
end

--- 蓝图方法 SetTextColor(FString CfgColorName)


M.PCKeyDict = PCKeyDict
return M
