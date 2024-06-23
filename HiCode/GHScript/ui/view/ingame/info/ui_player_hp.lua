--
-- @COMPANY GHGame
-- @AUTHOR wangyuexi
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')
local SkillData = require("common.data.skill_list_data").data
local SkillUtils = require('common.skill_utils')

---@class WBP_HUD_PlayerHP_Item_C
local UIPlayerHP = Class(UIWidgetBase)
UIPlayerHP.CurWitchSkillIndex = 1
local WitchSkillNormal = {
    [1] =
    '/Game/CP0032305_GH/UI/Texture/HUD/Noatlas/T_HUD_Img_StrangeTalk_Ghost_Normal.T_HUD_Img_StrangeTalk_Ghost_Normal',
    [2] =
    '/Game/CP0032305_GH/UI/Texture/HUD/Noatlas/T_HUD_Img_StrangeTalk_Scarecrow_Normal.T_HUD_Img_StrangeTalk_Scarecrow_Normal'
}
local WitchSkillActivation = {
    [1] =
    '/Game/CP0032305_GH/UI/Texture/HUD/Noatlas/T_HUD_Img_StrangeTalk_Ghost_Activation.T_HUD_Img_StrangeTalk_Ghost_Activation',
    [2] =
    '/Game/CP0032305_GH/UI/Texture/HUD/Noatlas/T_HUD_Img_StrangeTalk_Scarecrow_Activation.T_HUD_Img_StrangeTalk_Scarecrow_Activation',
}
local PlayerState =
{
    Normal = 0,
    Dying = 1,
}

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end

-- function UIPlayerHP:OnConstruct()
-- end

--- 播放界面的入场出场动画
---@param bIn boolean 是否是界面入场动画
function UIPlayerHP:PlayInOutAnim(bIn)
    ---@type UWidgetAnimation
    local CurAnim = bIn and self.DX_In or self.DX_Out
    self:PlayAnimation(CurAnim, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

--- 播放濒死动画
function UIPlayerHP:StartPlayDyingAnim()
    self:PlayAnimation(self.DX_DyingLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

--- 停止播放濒死动画
function UIPlayerHP:StopPlayDyingAnim()
    self:StopAnimation(self.DX_DyingLoop)
end

---@param level number
---@param dyingLimit number
---@param curHealth number
---@param healthLimit number
function UIPlayerHP:OnShow(level, dyingLimit, curHealth, healthLimit)
    self:PlayInOutAnim(true)
    self:HideBloodAnimation()
    self:SetHpData(level, dyingLimit, curHealth, healthLimit)
    self:SetPlayerHealthTextOnly(self.CurHealth)
end

---@param level number
---@param dyingLimit number
---@param curHealth number
---@param healthLimit number
function UIPlayerHP:OnSwitchPlayerHp(level, dyingLimit, curHealth, healthLimit)
    self:HideBloodAnimation()
    self:SetHpData(level, dyingLimit, curHealth, healthLimit)
    self:SetPlayerHealthTextOnly(self.CurHealth)
end

---@param level number
---@param dyingLimit number
---@param curHealth number
---@param healthLimit number
function UIPlayerHP:SetHpData(level, dyingLimit, curHealth, healthLimit)
    self.Level = level
    self.DyingLimit = healthLimit * 0.2 -- 总血量的20%
    self.CurHealth = curHealth
    self.HealthLimit = healthLimit
    -- self.CurTenacity = curTenacity
    -- self.TenacityLimit = tenacityLimit
    self.PlaySpeed = 0.2
    self.Duration = 1
    self.LevelName:SetText("Lv" .. self.Level)
    -- self:SetPlayerTenacity(self.CurTenacity, self.TenacityLimit)
    self:InitHudBuffer()
end

function UIPlayerHP:InitHudBuffer()
    self.WBP_HUD_Buff:OnShow()
    -- self:SwitchNextWitchSkill()
    UIManager.UINotifier:BindNotification(UIEventDef.WitchSkillTrigger, self, self.SwitchNextWitchSkill)
    UIManager.UINotifier:BindNotification(UIEventDef.RefreshWitchSkillUI, self, self.RefreshWitchSkill)
    -- UIManager.UINotifier:BindNotification(UIEventDef.LoadPlayerActor,self,self.RefreshWitchSkill)
end

function UIPlayerHP:OnHide()
    self.WBP_HUD_Buff:OnHide()
    self:PlayInOutAnim(false)
end

---@param healthLimit number
function UIPlayerHP:SetHealthLimit(healthLimit)
    if self.HealthLimit == healthLimit then
        return
    end
    self.HealthLimit = healthLimit
end

---@param tenacityLimit number
function UIPlayerHP:SetTenacityLimit(tenacityLimit)
    if self.TenacityLimit == tenacityLimit then
        return
    end
    self.TenacityLimit = tenacityLimit
end

---@param curHealth number
function UIPlayerHP:SetPlayerHealthTextOnly(curHealth)
    if not curHealth then
        return
    end
    self.CurHealth = curHealth
    if self.CurHealth < 0 then
        self.CurHealth = 0
    end
    if self.CurHealth > self.HealthLimit then
        self.CurHealth = self.HealthLimit
    end

    self.HealthNum:SetText(math.floor(self.CurHealth) .. '/' .. math.floor(self.HealthLimit))
    self:SetHpText()

    if self.CurHealth < self.DyingLimit then
        self:OnChangeRed()
    else
        self:OnChangeGreen()
    end

    self.FormerHealth = self.CurHealth
end

---@param curHealth number
function UIPlayerHP:SetPlayerHealth(curHealth)
    if not curHealth then
        return
    end
    self.CurHealth = curHealth
    if self.CurHealth < 0 then
        self.CurHealth = 0
    end
    if self.CurHealth > self.HealthLimit then
        self.CurHealth = self.HealthLimit
    end

    self.HealthNum:SetText(math.floor(self.CurHealth) .. '/' .. math.floor(self.HealthLimit))

    if self.CurHealth < self.DyingLimit then
        self:OnChangeRed()
    else
        self:OnChangeGreen()
    end

    self:GetHpBuffer()
end

function UIPlayerHP:SetHpText()
    self.HPBar_Normal:SetPercent(self.CurHealth / self.HealthLimit)
end

function UIPlayerHP:GetHpBuffer()
    if not self.FormerHealth then
        self.FormerHealth = self.CurHealth
        self:SetHpText()
        return
    end
    if self.FormerHealth > self.HealthLimit or self.FormerHealth < 0 then
        self.FormerHealth = self.CurHealth
        return
    end
    if self.FormerHealth == self.CurHealth then
        self:SetHpText()
    end
    if self.FormerHealth > self.CurHealth then
        if self.CurHealth == 0 then
            self.FormerHealth = self.CurHealth
        end
        self:SetHpText()
        self:OnCloseBloodBuffer(self.DX_HPBarBuffer_LoseBlood)
        self:OnLoseBlood()
    end
    if self.FormerHealth < self.CurHealth then
        self:OnCloseBloodBuffer(self.DX_HPBarBuffer_AddBlood)
        self:OnAddBlood()
        self.FormerHealth = self.CurHealth
    end
end

---@param curTenacity number
function UIPlayerHP:SetPlayerTenacity(curTenacity)
    if not curTenacity then
        return
    end
    self.CurTenacity = curTenacity
    if self.CurTenacity > self.TenacityLimit then
        self.CurTenacity = self.TenacityLimit
    end
    self.TenacityBar:SetPercent(self.CurTenacity / self.TenacityLimit)
end

function UIPlayerHP:OnLoseBlood()
    self.StartAtTime = 1 - (self.FormerHealth / self.HealthLimit)
    self.EndAtTime = 1 - (self.CurHealth / self.HealthLimit)
    self.HPBarBuffer:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:OnPlayLoseBloodAnimation()
    self.FormerHealth = self.CurHealth
end

function UIPlayerHP:OnAddBlood()
    self.StartAtTime = self.FormerHealth / self.HealthLimit
    self.EndAtTime = self.CurHealth / self.HealthLimit

    self.HPBarBuffer:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:UnbindAllFromAnimationFinished(self.DX_HPBarBuffer_AddBlood)
    self:BindToAnimationFinished(self.DX_HPBarBuffer_AddBlood, { self, self.SetHpText })

    self:OnPlayAddBloodAnimation()
    self.FormerHealth = self.CurHealth
end

function UIPlayerHP:OnPlayLoseBloodAnimation()
    self:StopAnimation(self.DX_HPBarBuffer_LoseBlood)
    self:StopAnimation(self.DX_HPBarBuffer_AddBlood)
    self:PlayAnimationTimeRange(self.DX_HPBarBuffer_LoseBlood, self.StartAtTime, self.EndAtTime, 1,
        UE.EUMGSequencePlayMode.Forward, self.PlaySpeed, false)
end

function UIPlayerHP:OnPlayAddBloodAnimation()
    self:StopAnimation(self.DX_HPBarBuffer_LoseBlood)
    self:StopAnimation(self.DX_HPBarBuffer_AddBlood)
    self:PlayAnimationTimeRange(self.DX_HPBarBuffer_AddBlood, self.StartAtTime, self.EndAtTime, 1,
        UE.EUMGSequencePlayMode.Forward, self.PlaySpeed, false)
end

function UIPlayerHP:OnCloseBloodBuffer(AnimationName)
    self:UnbindAllFromAnimationFinished(AnimationName)
    self:BindToAnimationFinished(AnimationName, {self, self.HideBloodAnimation})
end

function UIPlayerHP:HideBloodAnimation()
    self:StopAnimation(self.DX_HPBarBuffer_LoseBlood)
    self:StopAnimation(self.DX_HPBarBuffer_AddBlood)
    -- self.HpBar_Dying_Bg:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.HPBarBuffer:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UIPlayerHP:OnChangeRed()
    self.HpBar_Dying_Bg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.HPBarBuffer:GetDynamicMaterial():SetVectorParameterValue('Buffer_Color', self.DyingColor)
    self.HpBar_Normal:SetFillColorAndOpacity(self.RedColor)
end

function UIPlayerHP:OnChangeGreen()
    self.HpBar_Dying_Bg:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.HPBarBuffer:GetDynamicMaterial():SetVectorParameterValue('Buffer_Color', self.NormalColor)
    self.HpBar_Normal:SetFillColorAndOpacity(self.GreenColor)
end

function UIPlayerHP:OnClosePlayerHp()
    self:CloseMyself()
end

function UIPlayerHP:SwitchNextWitchSkill()
    self:PlayAnimation(self.DX_STLightOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UIPlayerHP:RefreshWitchSkill(curID, nextID)
    self:ChangeImage(curID, nextID)
end

function UIPlayerHP:OnChangeWitchSkill()
    local Player = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    local curID = SkillUtils.FindCurWitchSkillID(Player)
    local nextID = SkillUtils.FindNextWitchSkillID(Player)
    self:ChangeImage(curID, nextID)
end

function UIPlayerHP:ChangeImage(curID, nextID)
    local curImg = self:GetSKillImage(curID)
    local nextImg = self:GetSKillImage(nextID)
    local curImgNormal = self:GetSKillImageNormal(curID)
    local nextImgNormal = self:GetSKillImageNormal(nextID)
    if curImg and curImgNormal then
        self.Img_CurWitchSkill_Normal:SetRenderOpacity(1)
        self.Img_CurWitchSkill_Activation:SetRenderOpacity(0)
        self.Img_CurWitchSkill_Normal:SetBrushResourceObject(self:SetWitchResource(curImgNormal))
        self.Img_CurWitchSkill_Activation:SetBrushResourceObject(self:SetWitchResource(curImg))
    else
        self.Img_CurWitchSkill_Normal:SetRenderOpacity(0)
        self.Img_CurWitchSkill_Activation:SetRenderOpacity(0)
    end
    if nextImg and nextImgNormal then
        self.Img_NextWitchSkill_Normal:SetRenderOpacity(1)
        self.Img_NextWitchSkill_Activation:SetRenderOpacity(0)
        self.Img_NextWitchSkill_Normal:SetBrushResourceObject(self:SetWitchResource(nextImgNormal))
        self.Img_NextWitchSkill_Activation:SetBrushResourceObject(self:SetWitchResource(nextImg))
    else
        self.Img_NextWitchSkill_Normal:SetRenderOpacity(0)
        self.Img_NextWitchSkill_Activation:SetRenderOpacity(0)
    end
    self:PlayAnimation(self.DX_STLightIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UIPlayerHP:SetWitchResource(imgPath)
    return UE.UObject.Load(imgPath)
end

-- function UIPlayerHP:Tick(MyGeometry, InDeltaTime)
-- end

function UIPlayerHP:GetSKillImage(SkillID)
    if not SkillID then
        return
    else
        if SkillData then
            local Path = tostring(SkillData[SkillID].icon_path)
            if Path and Path ~= '1' then
                return Path
            end
        end
    end
end

function UIPlayerHP:GetSKillImageNormal(SkillID)
    if not SkillID then
        return
    else
        if SkillData then
            local Path = tostring(SkillData[SkillID].icon_path_Normal)
            if Path and Path ~= '1' then
                return Path
            end
        end
    end
end

return UIPlayerHP
