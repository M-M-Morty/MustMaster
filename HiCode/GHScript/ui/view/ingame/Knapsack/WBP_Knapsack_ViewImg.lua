--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local PicConst = require("CP0032305_GH.Script.common.pic_const")

---@class WBP_Knapsack_ViewImg : WBP_Knapsack_ViewImg_C
---@field ImageKeys string[]
---@field CurrentIndex integer
---@field CloseCallBack function

---@type WBP_Knapsack_ViewImg_C
local WBP_Knapsack_ViewImg = Class(UIWindowBase)

---@param self WBP_Knapsack_ViewImg
local function OnClickCloseButton(self)
    if self.CloseCallBack then
        self.CloseCallBack()
    end
    -- self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    UIManager:CloseUI(self, true)
end

---@param self WBP_Knapsack_ViewImg
local function RefreshButtonState(self)
    if self.CurrentIndex == 1 then
        self.Btn_PrePage:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.Btn_PrePage:SetVisibility(UE.ESlateVisibility.Visible)
    end
    if self.CurrentIndex == #(self.ImageKeys) then
        self.Btn_NextPage:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.Btn_NextPage:SetVisibility(UE.ESlateVisibility.Visible)
    end
end

---@param self WBP_Knapsack_ViewImg
local function ShowCurrentImage(self)
    local ImageKey = self.ImageKeys[self.CurrentIndex]
    PicConst.SetImageBrush(self.Img_BG01, ImageKey, true)
end

---@param self WBP_Knapsack_ViewImg
local function OnClickPrePage(self)
    self.CurrentIndex = math.max(1, self.CurrentIndex - 1)
    self.WBP_Common_PagePoints:SetCurrent(self.CurrentIndex)
    ShowCurrentImage(self)
    RefreshButtonState(self)
end

---@param self WBP_Knapsack_ViewImg
local function OnClickNextPage(self)
    self.CurrentIndex = math.min(#(self.ImageKeys), self.CurrentIndex + 1)
    self.WBP_Common_PagePoints:SetCurrent(self.CurrentIndex)
    ShowCurrentImage(self)
    RefreshButtonState(self)
end

function WBP_Knapsack_ViewImg:OnConstruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickCloseButton)
    self.Btn_PrePage.OnClicked:Add(self, OnClickPrePage)
    self.Btn_NextPage.OnClicked:Add(self, OnClickNextPage)
end

function WBP_Knapsack_ViewImg:Destruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickCloseButton)
    self.Btn_PrePage.OnClicked:Remove(self, OnClickPrePage)
    self.Btn_NextPage.OnClicked:Remove(self, OnClickNextPage)
end

function WBP_Knapsack_ViewImg:OnShow()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function WBP_Knapsack_ViewImg:OnAnimationFinished(Animation)
    if Animation == self.DX_Out then
        UIManager:CloseUI(self, false)
    end
end

---@param ImageKeys string[]
function WBP_Knapsack_ViewImg:SetImages(ImageKeys)
    self.ImageKeys = ImageKeys
    self.CurrentIndex = 1

    if #(self.ImageKeys) == 1 then
        self.WBP_Common_PagePoints:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.WBP_Common_PagePoints:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WBP_Common_PagePoints:SetMax(#(self.ImageKeys))
    end
    ShowCurrentImage(self)
    RefreshButtonState(self)
end

function WBP_Knapsack_ViewImg:SetCloseCallBack(CallBack)
    self.CloseCallBack = CallBack
end

return WBP_Knapsack_ViewImg
