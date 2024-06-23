--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

local SettlementEvent = "Play_MusicGame_UI_Settlement"

---@class WBP_Common_MiniGames_SettlementPopUp_C
local UICommonSettlement = Class(UIWidgetBase)

--function UICommonSettlement:Initialize(Initializer)
--end

--function UICommonSettlement:PreConstruct(IsDesignTime)
--end

-- function UICommonSettlement:Construct()
-- end

function UICommonSettlement:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
end

function UICommonSettlement:OnShow()
    self:PlayAKEventByName(SettlementEvent)
    self:PlayInAnimation()
end

function UICommonSettlement:InitWidget()
    ---@type WBP_Common_MiniGames_SettlementPopUp_Description_C
    self.WBP_Common_SettlementDescription = self.WBP_Common_MiniGames_SettlementPopUp_Description
end

function UICommonSettlement:BuildWidgetProxy()
    ---@type UTileViewProxy
    self.List_EvaluateProxy = WidgetProxys:CreateWidgetProxy(self.List_Evaluate)
    ---@type UTileViewProxy
    self.Tile_RewardPropsProxy = WidgetProxys:CreateWidgetProxy(self.Tile_RewardProps)
end

function UICommonSettlement:SetPanelListData(DesriptionList, EvaluateList, PropItem)
    self:SetDescriptionListData(DesriptionList)
    self:SetListState(self.List_Evaluate, self.List_EvaluateProxy, EvaluateList)
    self:SetListState(self.Tile_RewardProps, self.Tile_RewardPropsProxy, PropItem)
end

function UICommonSettlement:SetDescriptionListData(DesriptionList)
    if self:GetListLength(DesriptionList) then
        self.WBP_Common_SettlementDescription:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WBP_Common_SettlementDescription:SetListData(DesriptionList)
    else
        self.WBP_Common_SettlementDescription:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function UICommonSettlement:SetListState(listInstance, listProxy, listValue)
    if self:GetListLength(listValue) then
        listInstance:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        listProxy:SetListItems(listValue)
    else
        listInstance:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if listInstance == self.Tile_RewardProps then
        if self:GetListLength(listValue) then
            self:SetRewardListVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self:SetRewardListVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function UICommonSettlement:GetListLength(list)
    if not list or type(list) ~= "table" then
        return
    end
    if #list > 0 then
        return true
    else
        return false
    end
end

function UICommonSettlement:SetBtnExitOnClick(thisSelf, func)
    self.WBP_Btn_Exit.OnClicked:Add(thisSelf, func)
end

function UICommonSettlement:SetBtnPlayAgainOnClick(thisSelf, func)
    self.WBP_Btn_PlayAgain.OnClicked:Add(thisSelf, func)
end

function UICommonSettlement:SetSideTagVisibility(bShow)
    self.WBP_Common_MiniGames_SideTag:SetVisibility(bShow)
    self.WBP_Common_MiniGames_SideTag:PlayInAnimation()
end

function UICommonSettlement:SetMusicNameText(text)
    self.Txt_MusicName:SetText(text)
end

function UICommonSettlement:SetScoreText(text)
    self.Txt_Score:SetText(text)
end

function UICommonSettlement:SetRewardListVisibility(bShow)
    self.Canvas_Obtain:SetVisibility(bShow)
    self.Tile_RewardProps:SetVisibility(bShow)
end

function UICommonSettlement:SetCloseBtnVisibility(bShow)
    self.WBP_Common_RightPopupWindow:SetCloseBtnVisibility(bShow)
end

function UICommonSettlement:PlayInAnimation()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function UICommonSettlement:PlayOutAnimation()
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    if self.WBP_Common_MiniGames_SideTag:IsVisible() then
        self.WBP_Common_MiniGames_SideTag:PlayOutAnimation()
    end
end

function UICommonSettlement:PlayAKEventByName(AKname)
    local FunctionLib = FunctionUtil:GlobalUClass('GH_FunctionLib')
    if FunctionLib then
        local bExit, Row = FunctionLib.GetTapAkEventPathByRowName(AKname)
        if bExit then
            self.AKEvent = UE.UObject.Load(tostring(Row.AKEvent))
            UE.UAkGameplayStatics.PostEvent(self.AKEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    end
end

--function UICommonSettlement:Tick(MyGeometry, InDeltaTime)
--end

return UICommonSettlement
