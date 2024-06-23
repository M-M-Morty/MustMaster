--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local hero_initial_data = require("common.data.hero_initial_data").data

local HPLENGTH
---@type WBP_HUD_SquadList_Item_C
local UISquadListItem = Class(UIWindowBase)

--function UISquadListItem:Initialize(Initializer)
--end

--function UISquadListItem:PreConstruct(IsDesignTime)
--end

function UISquadListItem:OnConstruct()

end

function UISquadListItem:OnShow()

end

function UISquadListItem:Init(index, actor)
    self.actor = actor
    self.HPState = { Normal = 0, Crisis = 1, Dead = 2 }
    local controller = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    self.teamInfo = controller.ControllerSwitchPlayerComponent.TeamInfo
    self.characterType = self.teamInfo:Get(index)
    self.name = hero_initial_data[self.characterType].name
    self.index = index
    self.durCDTime = 0
    self.WBP_Common_PCkey_1:SetPCkeyText("Normal", "Text", index)
    if hero_initial_data[self.characterType].icon_path then
        self.Img_Avatar:GetDynamicMaterial():SetTextureParameterValue('Texture',
            UE.UObject.Load(hero_initial_data[self.characterType].icon_path))
    end
    self.Img_Avatar:GetDynamicMaterial():SetScalarParameterValue('Desaturation', 0)
    self.DX_Additive_Inst_1_a:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_HUD_SkillState_Item:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Avatar_State:SetActiveWidgetIndex(0)
    self.WBP_Common_PCkey_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.WBP_Common_PCkey_F1.Zishiying_Btn_remind:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.WBP_Common_PCkey_F1.ZishiyingText:SetText("F" .. index)
    self.PlayerBtn.OnClicked:Add(self, self.OnClick)
end

-- function UISquadListItem:FindAvataTexture(name)
--     return UE.UObject.Load("/Game/CP0032305_GH/UI/UI_Common/Texture/NoAtlas/Hero_Avatar/T_HUD_Fighting_Img_"..name.."_01.T_HUD_Fighting_Img_"..name.."_01")

-- end
function UISquadListItem:OnClick()
    self.actor.ControllerSwitchPlayerComponent:Input_SwitchPlayer(self.index, false)
end

function UISquadListItem:BeSelect()
    self:PlayAnimation(self.DX_PlayerSelected, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    self.CD:SetVisibility(UE.ESlateVisibility.Hidden)
    -- self.WBP_HUD_SkillState_Item:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_Common_PCkey_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WBP_Common_PCkey_F1:SetVisibility(UE.ESlateVisibility.Hidden)
    self.RoleBlood:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Avatar_State:SetActiveWidgetIndex(1)
    self.Img_Avatar:GetDynamicMaterial():SetScalarParameterValue('Desaturation', 0)
end

function UISquadListItem:NotBeSelect(isCD)
    if self.isDead then
        return
    end
    self.CD:SetVisibility(UE.ESlateVisibility.Hidden)
    -- self.WBP_HUD_SkillState_Item:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WBP_Common_PCkey_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.WBP_Common_PCkey_F1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.RoleBlood:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)临时注释，等有表之后打开
    -- self.RoleBlood:SetActiveWidgetIndex(self.HPState.Normal) 临时注释，等有表之后打开
    self.Avatar_State:SetActiveWidgetIndex(0)
    self.Img_Avatar:GetDynamicMaterial():SetScalarParameterValue('Desaturation', 0)

    if not isCD then
        self.Img_Avatar:SetRenderOpacity(1)
        return
    end
    self.Img_Avatar:SetRenderOpacity(0.4)
    self.isCD = true
    local controller = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    self.switchCD =controller:GetSwitchPlayerCD(self.characterType) 
    self.durCDTime = self.switchCD
    self.CD:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function UISquadListItem:RoleDead()
    -- self.durDeadCDTime = self.DeadCDTime
    self.isDead = true
    self.CD:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Avatar_State:SetActiveWidgetIndex(0)
    self.Img_Avatar:GetDynamicMaterial():SetScalarParameterValue('Desaturation', 1)
    -- self.WBP_HUD_SkillState_Item:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_Common_PCkey_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.WBP_Common_PCkey_F1:SetVisibility(UE.ESlateVisibility.Hidden)
    -- self.RoleBlood:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)临时注释，等有表之后打开
    -- self.RoleBlood:SetActiveWidgetIndex(self.HPState.Dead) 临时注释，等有表之后打开
    self.Avatar_State:SetActiveWidgetIndex(0)
end

function UISquadListItem:RoleHealthChanged(CurPercent)
    if CurPercent > 0.1 then
        self.RoleBlood:SetActiveWidgetIndex(self.HPState.Normal)
        self.RoleBlood_Green:SetPercent(CurPercent)
        self.RoleBlood_Crisis_Red:SetPercent(CurPercent)
    else
        self.RoleBlood:SetActiveWidgetIndex(self.HPState.Crisis)
        self.RoleBlood_Green:SetPercent(CurPercent)
        self.RoleBlood_Crisis_Red:SetPercent(CurPercent)
    end
end

function UISquadListItem:SquadItemUpdate(InDeltaTime)
    if self.isDead then
        self.CD:SetVisibility(UE.ESlateVisibility.Hidden)
        return
    end
    -- if self.isDead then
    --     self.durDeadCDTime = self.durDeadCDTime - InDeltaTime
    --     self.durCDTime = self.durCDTime - InDeltaTime
    --     if self.durDeadCDTime < 0.015 then
    --         self.isDead = false
    --         if self.durCDTime > 0.015 then
    --             self:NotBeSelect(true)
    --         else
    --             self:NotBeSelect(false)
    --         end
    --     end
    --     self.Teamlist_Progress_CD01:GetDynamicMaterial():SetScalarParameterValue('percent', tonumber(string.format('%.4f', 1 - self.durDeadCDTime / self.DeadCDTime)))
    --     self.Teamlist_Progress_CD02:GetDynamicMaterial():SetScalarParameterValue('percent', tonumber(string.format('%.4f', self.durDeadCDTime / self.DeadCDTime)))
    --     self.CDText:SetText(string.format("%.1f", self.durDeadCDTime))
    --     return
    -- end
    if self.durCDTime > 0.015 then
        self.durCDTime = self.durCDTime - InDeltaTime
        if self.durCDTime < 0.015 then
            self.isDead = false
            self:NotBeSelect(false)
            return
        end
        self.Teamlist_Progress_CD01:GetDynamicMaterial():SetScalarParameterValue('percent',
            tonumber(string.format('%.4f', 1 - self.durCDTime / self.switchCD)))
        self.Teamlist_Progress_CD02:GetDynamicMaterial():SetScalarParameterValue('percent',
            tonumber(string.format('%.4f', self.durCDTime / self.switchCD)))
        self.CDText:SetText(string.format("%.1f", self.durCDTime))
    end
end

function UISquadListItem:Close()
    self:CloseMyself()
end

return UISquadListItem
