--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ConstPic = require("CP0032305_GH.Script.common.pic_const")

local PROGRESS_FRONT_WIDTH_OFFSET = 10

---@return integer
local function GetLoadingProgress()
    local LoadingUtils = require("common.utils.loading_utils")
    if LoadingUtils then
        return LoadingUtils:GetLoadingPrgress()
    end
    return 0
end

---@class WBP_Firm_Loading : WBP_Firm_Loading_C
---@field CanUpdateProgress boolean
---@type WBP_Firm_Loading
local WBP_Firm_Loading = Class(UIWindowBase)

---@param self WBP_Firm_Loading
local function BeginUpdate(self)
    self.CanUpdateProgress = true
end

---@param self WBP_Firm_Loading
---@param Percent float
local function UpdateProgress(self, Percent)
    self.ProgressBar_Loading:SetPercent(Percent)

    local Geometry = self.ProgressBar_Loading:GetCachedGeometry()
    local ProgressWidth = UE.USlateBlueprintLibrary.GetLocalSize(Geometry).X;
    local CanvasSlot = self.Cvs_LoadingFront.Slot
    local FrontWidth = CanvasSlot:GetSize().X
    local PosX = math.min(ProgressWidth, ProgressWidth * Percent - FrontWidth + PROGRESS_FRONT_WIDTH_OFFSET)
    CanvasSlot:SetPosition(UE.FVector2D(PosX + PROGRESS_FRONT_WIDTH_OFFSET, 0))
end

function WBP_Firm_Loading:Construct()
    self.CanUpdateProgress = false
end

function WBP_Firm_Loading:Destruct()
end

---@param MyGeometry FGeometry
---@param InDeltaTime float
function WBP_Firm_Loading:Tick(MyGeometry, InDeltaTime)
    if not self.CanUpdateProgress then
        return
    end

    local CurProgress = GetLoadingProgress()
    UpdateProgress(self, CurProgress)

    if CurProgress >= 1 then
        self.CanUpdateProgress = false
        self:CloseUI()
    end
end

function WBP_Firm_Loading:CloseUI()
    UIManager:CloseUI(self, true)
end

function WBP_Firm_Loading:OnShow()
    self.CanUpdateProgress = false
    UpdateProgress(self, 0)

    if self.DX_In then
        self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end

    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, BeginUpdate }, 0.1, false)
end

---Called when an animation has either played all the way through or is stopped
---@param Animation UWidgetAnimation
---@return void
function WBP_Firm_Loading:OnAnimationFinished(Animation)
    if Animation == self.DX_In then
        self:PlayAnimation(self.DX_Loop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
    if Animation == self.DX_Out then
        UIManager:CloseUI(self)
    end
end

---@param BgIndex integer
function WBP_Firm_Loading:UpdateParams(BgIndex)
    G.log:debug("ghgame", "WBP_Firm_Loading:UpdateParams, BgIndex=%s", tostring(BgIndex))
    if BgIndex == nil then
        BgIndex = 1
    end
    ConstPic.SetImageBrush(self.Img_LoadingBG, "LOADING_BG_" .. BgIndex)
end

return WBP_Firm_Loading
