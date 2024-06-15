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
local PicConst = require("CP0032305_GH.Script.common.pic_const")

---@class WBP_Tips_LevelDisplay: WBP_Tips_LevelDisplay_C
local WBP_Tips_LevelDisplay = Class(UIWindowBase)

local function ShowLevelInfo(self, Info)
    self.Text_Title:SetText(Info:GetTitle())
    self.Text_Level:SetText(Info:GetContent())
    self.Text_Lang:SetText(Info:GetEnglishContent())
    self.Text_LevelStatus:SetText(Info:GetState())
    PicConst.SetImageBrush(self.Img_ChaptreBG, Info:GetTitleIconKey())
end

local function OnFinish(self)
    G.log:debug("zys", "WBP_Tips_LevelDisplay:OnFinish()")
    self:CloseMyself()
end

local function BeginShow(self, Info)
    self:StopAnimationsAndLatentActions()
    ShowLevelInfo(self, Info)
    self:PlayAnimation(self.DX_MissionFinish, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self:BindToAnimationFinished(self.DX_MissionFinish,{self, OnFinish})
end

--function WBP_Tips_LevelDisplay:Initialize(Initializer)
--end

--function WBP_Tips_LevelDisplay:PreConstruct(IsDesignTime)
--end

function WBP_Tips_LevelDisplay:OnConstruct()
end

-- function WBP_Tips_LevelDisplay:OnShow()
    -- self:StopAnimationsAndLatentActions()
    -- self:PlayAnimation(self.DX_MissionStart, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
-- end

-- function WBP_Tips_LevelDisplay:OnHide()
-- end

function WBP_Tips_LevelDisplay:UpdateParams(Info)
    BeginShow(self, Info)
end

--function WBP_Tips_LevelDisplay:Tick(MyGeometry, InDeltaTime)
--end

-- function WBP_Tips_LevelDisplay:DXEventMissionFinishEnd()
--     self:CloseMyself()
-- end

-- function WBP_Tips_LevelDisplay:DXEventMissionStartEnd()
-- end

return WBP_Tips_LevelDisplay
