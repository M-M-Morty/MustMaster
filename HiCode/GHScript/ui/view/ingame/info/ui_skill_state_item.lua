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
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local utils = require("common.utils")
local SkillUtils = require('common.skill_utils')
local SkillState = require("CP0032305_GH.Script.ui.view.ingame.info.ui_skill_state")
local SkillData = require("common.data.skill_list_data").data

local TIMER_INTERVAL = 0.1             -- timer的时间间隔
local MULTI_CHECK_TIME = 0.6           -- 多段技能的是否成功检查的延迟
local THROW_SKILL_ID = 4008            -- 抛投技能的id
local CHR_ID_WALI = 4                  -- 瓦利人物id
local SuperSkillOpacity = 0.6          -- 大招能量ui的透明度
local THROW_SKILL_ID = 4008            -- 抛投技能的id

---@class WBP_HUD_SkillState_Item: WBP_HUD_SkillState_Item_C
---@field tbSkillInfo table
local WBP_HUD_SkillState_Item = Class(UIWidgetBase)

---@param self WBP_HUD_SkillState_Item
---@param bShow boolean
local function SetInsideCDVisible(self, bShow)
    if bShow then
        self.Image_Schedule_Skill_Big:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Text_Block_CD:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Image_Schedule_Skill_Big:SetVisibility(UE.ESlateVisibility.Hidden)
        self.Text_Block_CD:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

---`brief`技能开始进入cd
---@param self WBP_HUD_SkillState_Item
---@param bNotPlayAnim boolean
local function CDBegin(self, bNotPlayAnim)
    SetInsideCDVisible(self, true)
    if not bNotPlayAnim then
        self:PlayAnimation(self.DX_Skill_Block_CD_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
    self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, false)
    self.Img_SkillIcon:SetRenderOpacity(self.MainUI.IconOpcityOnCD)
    self.Skill_Ultimate:SetRenderOpacity(self.MainUI.IconOpcityOnCD)
    self.CacheLast.Opacity = self.MainUI.IconOpcityOnCD
end

---`brief`技能cd结束
---@param self WBP_HUD_SkillState_Item
---@param bNotPlayAnim boolean
local function CDEnd(self, bNotPlayAnim)
    SetInsideCDVisible(self, false)
    if not bNotPlayAnim then
        self:PlayAnimation(self.DX_Skill_Block_CD_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end 
    self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, true)
    self.Img_SkillIcon:SetRenderOpacity(1)
    self.Skill_Ultimate:SetRenderOpacity(1)
    self.CacheLast.Opacity = 1
end

---`brief`进入技能的持续buff
---@param self WBP_HUD_SkillState_Item
local function SustainBegin(self)
    self.Image_Block_StrikeBack_Schedule_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Img_SkillIcon:SetRenderOpacity(self.MainUI.IconOpcityOnCD)
    self.CacheLast.Opacity = self.MainUI.IconOpcityOnCD
    self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, false)

    SetInsideCDVisible(self, false)
end

---`brief`退出技能的持续buff
---@param self WBP_HUD_SkillState_Item
local function SustainEnd(self)
    self.Image_Block_StrikeBack_Schedule_1:SetVisibility(UE.ESlateVisibility.Hidden)
end

---`brief`临时方法, 初始化技能的图标
---@param self WBP_HUD_SkillState_Item
---@param Icon number
local function SetSKillIcon(self, Icon)
    self.WBP_HUD_SkillIcon_3.Swithcher_SkillIcon:SetActiveWidgetIndex(Icon)
    self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, true)
end

---@param self WBP_HUD_SkillState_Item
---@param TimeRemaining number
---@param CooldownDuration number
local function UpdateNormalCD(self, TimeRemaining, CooldownDuration)
    self.Image_Schedule_Skill_Big:GetDynamicMaterial():SetScalarParameterValue('percent', tonumber(string.format('%.4f', 1 - TimeRemaining / CooldownDuration))) -- 浮点精度过高会无效
    self.Text_Block_CD:SetText(string.format('%.1f', TimeRemaining))
end

---@param self WBP_HUD_SkillState_Item
---@param Ability number
---@param Handle FGameplayAbilitySpecHandle
---@param ActorInfo FGameplayAbilityActorInfo
---@param ASC UAbilitySystemComponent
local function UpdateBlockSkill(self, Ability, Handle, ActorInfo, ASC)
    local bInstanced
    Ability, bInstanced = UE.UAbilitySystemBlueprintLibrary.GetGameplayAbilityFromSpecHandle(ASC, Handle)
    local TimeRemaining, CooldownDuration = Ability:GetCooldownRemainingAndDuration(Handle, ActorInfo)
    if TimeRemaining > 0 then
        local MaxValue = (Ability.WithStandTime * 1000)
        if not self.WithStandStartTime then
            self.WithStandStartTime = UE.UKismetMathLibrary.Now()
        end
        local CurValue = utils.GetMillisElapsed(self.WithStandStartTime, UE.UKismetMathLibrary.Now())
        if CurValue < MaxValue then
            SustainBegin(self)
            self.Image_Block_StrikeBack_Schedule_1:GetDynamicMaterial():SetScalarParameterValue('percent', tonumber(string.format('%.4f', CurValue / MaxValue)))
            return
        end
        if self.CacheLast.TimeRemaining <= 0 then
            SustainEnd(self)
            CDBegin(self)
            if not self.CacheLast.RealCD or self.CacheLast.RealCD < TimeRemaining then
                self.CacheLast.RealCD = TimeRemaining
            end
        end
        UpdateNormalCD(self, TimeRemaining, self.CacheLast.RealCD)
        self.CacheLast.TimeRemaining = TimeRemaining
    else
        if self.CacheLast.TimeRemaining > 0 then
            self.WithStandStartTime = nil
            self.CacheLast.RealCD = 0
            self.CacheLast.TimeRemaining = 0
            CDEnd(self)
        end
    end
end

---@param self WBP_HUD_SkillState_Item
---@param Ability number
---@param Handle FGameplayAbilitySpecHandle
---@param ActorInfo FGameplayAbilityActorInfo
local function UpdateDefaultSkill(self, Ability, Handle, ActorInfo)
    local TimeRemaining, CooldownDuration = Ability:GetCooldownRemainingAndDuration(Handle, ActorInfo)
    if TimeRemaining > 0 and self.CacheLast.TimeRemaining == 0 then
        local vm = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.ThrowSkillVM.UniqueName)
        vm:SetCanAllThrowPointShow(false)
        CDBegin(self)
    elseif TimeRemaining <= 0 and self.CacheLast.TimeRemaining > 0 then
        local vm = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.ThrowSkillVM.UniqueName)
        vm:SetCanAllThrowPointShow(true)
        CDEnd(self)
    end
    self.CacheLast.TimeRemaining = TimeRemaining
    if TimeRemaining > 0 then
        self.Img_SkillIcon:SetRenderOpacity(self.MainUI.IconOpcityOnCD)
    end
    UpdateNormalCD(self, TimeRemaining, CooldownDuration)
end

---`biref`更新大招显示效果
---@param self WBP_HUD_SkillState_Item
---@param Ability number
---@param Handle FGameplayAbilitySpecHandle
---@param ActorInfo FGameplayAbilityActorInfo
local function UpdateSuperSkill(self, Ability, Handle, ActorInfo, ASC)
    -- 大招的CD
    local TimeRemaining, CooldownDuration = Ability:GetCooldownRemainingAndDuration(Handle, ActorInfo)
    if TimeRemaining > 0 and self.CacheLast.TimeRemaining == 0 then
        CDBegin(self)
    elseif TimeRemaining <= 0 and self.CacheLast.TimeRemaining > 0 then
        CDEnd(self)
    end
    self.CacheLast.TimeRemaining = TimeRemaining
    UpdateNormalCD(self, TimeRemaining, CooldownDuration)
end

---`brief`设置技能图标
---@param self WBP_HUD_SkillState_Item
---@param SkillID number
local function SetSKillImage(self, SkillID)
    if self.CacheLast.SwitchIcon then
        return
    end
    if not SkillID then
        self.ImgSkillIcon:SetVisibility(UE.ESlateVisibility.Hidden)
        self.Img_SkillIcon:SetVisibility(UE.ESlateVisibility.Hidden)
        self.Img_NoneSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        return
    else
        self.Img_SkillIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Img_NoneSkill:SetVisibility(UE.ESlateVisibility.Hidden)
        if SkillData then
            local Path = tostring(SkillData[SkillID].icon_path)
            if Path and Path ~= '1' then
                self.Img_SkillIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                self.Img_SkillIconProxy:SetImageTexturePath(Path)
            end
        end
    end
end

local function SwitchSkillIcon(self, SkillID)
    if not self.CacheLast.SkillIDForSwitch then
        self.CacheLast.SkillIDForSwitch = SkillID
        return
    end
    if self.CacheLast.SkillIDForSwitch == SkillID then
        return
    end
    if SkillData then
        local Path = tostring(SkillData[SkillID].icon_path)
        local Path_Old = tostring(SkillData[self.CacheLast.SkillIDForSwitch].icon_path)
        if Path and Path ~= '1' then
            self.Img_SkillIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Img_SkillIconProxy:SetImageTexturePath(Path_Old)
            local PlayAnimProxy = nil
            if self.CacheLast.Opacity < 1 then
                PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillSwitchOut_Op, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
            else
                PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillSwitchOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
            end
            PlayAnimProxy.Finished:Add(self, function()
                self.Img_SkillIconProxy:SetImageTexturePath(Path)
                local PlayAnimProxy_In
                if self.CacheLast.Opacity < 1 then
                    PlayAnimProxy_In = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillSwitchIn_Op, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
                else
                    PlayAnimProxy_In = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), self, self.DX_SkillSwitchIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
                end
                PlayAnimProxy_In.Finished:Add(self, function()
                end)
            end)
            self.CacheLast.SkillIDForSwitch = SkillID
        end
    end
end

---@param self WBP_HUD_SkillState_Item
---@param Ability number
---@param Handle FGameplayAbilitySpecHandle
---@param ActorInfo FGameplayAbilityActorInfo
local function UpdateMultiStateSkill(self, Ability, Handle, ActorInfo, ASC)
    local bInstanced
    Ability ,bInstanced = UE.UAbilitySystemBlueprintLibrary.GetGameplayAbilityFromSpecHandle(ASC, Handle)
    local bHasBuff, CurSKillID = Ability:GetCurrentStageAbility()
    if not CurSKillID or CurSKillID <= 0 then
        CurSKillID = self.CacheLast.SkillID
    end
    if self.CacheLast.CheckTask and self.CacheLast.CheckTask > 0 then
        self.CacheLast.CheckTask = self.CacheLast.CheckTask - TIMER_INTERVAL
        if self.CacheLast.CheckTask < 0 then
            self.MarkNotShow = false
            self.CacheLast.CheckTask = nil
        end
    end
    if bHasBuff then
        SustainBegin(self)
        SwitchSkillIcon(self, CurSKillID)
        -- SetSKillImage(self, CurSKillID)
        local TimeRemaining, CooldownDuration = Ability:GetTriggerBuffLeftTimeAndDuration()
        if CooldownDuration > self.CacheLast.CooldownDuration then
            self.MarkNotShow = false

            self.CacheLast.Diff = CooldownDuration - self.CacheLast.CooldownDuration
            self.CacheLast.BaseCD = self.CacheLast.CooldownDuration
        end
        if self.CacheLast.Diff then
            self.Img_SkillIcon:SetRenderOpacity(1)
            self.CacheLast.Opacity = 1
            self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, true)
            -- 视觉要求不显示cd
            -- self.Image_Block_StrikeBack_Schedule_1:GetDynamicMaterial():SetScalarParameterValue('percent', tonumber(string.format('%.4f', 1 - (TimeRemaining - self.CacheLast.BaseCD) / (CooldownDuration - self.CacheLast.BaseCD))))
            self.Image_Block_StrikeBack_Schedule_1:GetDynamicMaterial():SetScalarParameterValue('percent', tonumber(string.format('%.4f', 1)))

        end
        self.CacheLast.TimeRemaining = TimeRemaining
        self.CacheLast.CooldownDuration = CooldownDuration
        return
    else
        self.CacheLast.Diff = nil
        local TimeRemaining, CooldownDuration = Ability:GetCooldownRemainingAndDuration(Handle, ActorInfo)
        if TimeRemaining > 0 and CooldownDuration > 0 then
            SwitchSkillIcon(self, CurSKillID)
            if not self.MarkNotShow then            
                SetInsideCDVisible(self, true)
            end
            self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, false)
            self.Img_SkillIcon:SetRenderOpacity(self.MainUI.IconOpcityOnCD)
            self.CacheLast.Opacity = self.MainUI.IconOpcityOnCD
            SustainEnd(self)
        end
        if TimeRemaining > 0 and self.CacheLast.TimeRemaining == 0 then
            CDBegin(self)
            self.CacheLast.CheckTask = MULTI_CHECK_TIME
            SetInsideCDVisible(self, false)
            self.MarkNotShow = true
        elseif TimeRemaining <= 0 and self.CacheLast.TimeRemaining > 0 then
            CDEnd(self)
        end
        UpdateNormalCD(self, TimeRemaining, CooldownDuration)
        self.CacheLast.TimeRemaining = TimeRemaining
        self.CacheLast.CooldownDuration = CooldownDuration
    end
end

---@param SlotIndex number
---@param ASC UAbilitySystemComponent
local function FindID(SlotIndex, ASC)
    if SlotIndex == SkillState.SkillSlotDef.Super then
        return SkillUtils.FindSuperSkillID(ASC)
    elseif  SlotIndex == SkillState.SkillSlotDef.Secondary then
        return SkillUtils.FindSecondarySkillID(ASC)
    elseif  SlotIndex == SkillState.SkillSlotDef.Right and SkillUtils.FindBlockSkillIDOfCurrentPlayer then
        return SkillUtils.FindBlockSkillIDOfCurrentPlayer(UIManager.GameWorld)
    end
end

---`brief`策划要求ban掉十五夜大招
---@return boolean
local function IsShiwuyeSuper(self)
    if self.CurPlayer == 5 and self.SlotIndex == SkillState.SkillSlotDef.Super then
        return true
    else
        return false
    end
end

---`brief`当前角色可以抛投
---@return boolean
local function IsChrCanThrow(self)
    if self.CurPlayer == 4 then
        return true 
    else
        return false 
    end
end

---@param self WBP_HUD_SkillState_Item
local function RefreshInfo(self)
    local SlotIndex, Player, ASC, SkillID, GASpec, Handle, Ability, ActorInfo, bShowX
    Player = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    if not Player or not self.SlotIndex then
        return false
    end
    SlotIndex = self.SlotIndex
    ASC = Player:GetHiAbilitySystemComponent()
    if not ASC then
        return false
    end
    SkillID = FindID(SlotIndex, ASC)
    if IsShiwuyeSuper(self) then
        SkillID = nil
        self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, true, true)
        self.Skill_Ultimate:SetVisibility(UE.ESlateVisibility.Hidden)
    else
        self.Skill_Ultimate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    SetSKillImage(self, SkillID)
    if not SkillID then
        self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, true, true)
        return false
    end
    self.CacheLast.SkillID = SkillID
    GASpec = SkillUtils.FindAbilitySpecFromSkillID(ASC, SkillID)
    if not GASpec then
        return false
    end
    Handle = GASpec.Handle
    Ability = GASpec.Ability
    ActorInfo = ASC:GetAbilityActorInfo()
    if not Handle or not Ability or not ActorInfo then
        return false
    end
    if Ability.SkillType == Enum.Enum_SkillType.Block then -- 6 格挡
        self.CacheLast.SwitchIcon = false
        UpdateBlockSkill(self, Ability, Handle, ActorInfo, ASC)
    elseif Ability.SkillType == Enum.Enum_SkillType.Super then -- 8 大招
        self.CacheLast.SwitchIcon = false
        UpdateSuperSkill(self, Ability, Handle, ActorInfo, ASC)
    -- elseif Ability.SkillType == Enum.Enum_SkillType.SecondarySkill then -- 17 小技能
    elseif Ability.SkillType == Enum.Enum_SkillType.Default then -- 20 默认技能
        self.CacheLast.SwitchIcon = false
        UpdateDefaultSkill(self, Ability, Handle, ActorInfo)
    elseif Ability.SkillType == Enum.Enum_SkillType.MultiStage then -- 21 多段技能
        self.CacheLast.SwitchIcon = true
        UpdateMultiStateSkill(self, Ability, Handle, ActorInfo, ASC)
    else -- 其他未处理到的暂用默认技能处理
        self.CacheLast.SwitchIcon = false
        UpdateDefaultSkill(self, Ability, Handle, ActorInfo)
    end
    return true
end

---`brief`初始化用户控件
---@param self WBP_HUD_SkillState_Item
local function InitWidget(self)
    -- 老的技能图标用户控件, 现在全部使用策划配表的图素路径, 此控件后面可以删掉
    self.WBP_HUD_SkillIcon_3:SetVisibility(UE.ESlateVisibility.Hidden)
    -- 固定隐藏掉无关的大招能量相关的用户控件
    self.Ultimate_Ready:SetVisibility(UE.ESlateVisibility.Hidden)
    -- 固定隐藏掉视觉暂时不需要的冷却遮罩控件
    self.Image_Schedule_Skill_CDMask:SetVisibility(UE.ESlateVisibility.Hidden)

    -- 初始化隐藏有用的大招能量相关的用户控件
    self.Ultimate_Accumulate:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Skill_Ultimate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- 新的技能图标用户控件初始化
    self.Img_SkillIcon:SetRenderOpacity(1)
    self.CacheLast.Opacity = 1
end

---@param self WBP_HUD_SkillState_Item
local function BuildWidgetProxy(self)
    if self.SlotIndex == SkillState.SkillSlotDef.Super then
        ---@type UIWidgetField
        self.OnMaxPowerValChangedField = self:CreateUserWidgetField(self.OnMaxPowerValChanged)
        ---@type UIWidgetField
        self.OnPowerValChangedField = self:CreateUserWidgetField(self.OnPowerValChanged)
    end
end

---@param self WBP_HUD_SkillState_Item
local function InitViewModel(self)
    if self.SlotIndex == SkillState.SkillSlotDef.Super then
        ---@type PlayerSkillVM
        local VM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.PlayerSkillVM.UniqueName)
        ViewModelBinder:BindViewModel(self.OnMaxPowerValChangedField, VM.MaxPowerField, ViewModelBinder.BindWayToWidget)
        ViewModelBinder:BindViewModel(self.OnPowerValChangedField, VM.PowerField, ViewModelBinder.BindWayToWidget)
    end
end

---@param self WBP_HUD_SkillState_Item
---@param bShow boolean
local function UpdateXVisible(self, bShow)
    self.Img_NoneSkill:SetVisibility(bShow and UE.ESlateVisibility.Hidden or UE.ESlateVisibility.SelfHitTestInvisible)
end

---@param self WBP_HUD_SkillState_Item
---@param bShow boolean
local function RefreshEnergyUI(self, bShow)
    if bShow then -- 满能量
        if IsShiwuyeSuper(self) then
            self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, true, true)
        else
            self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, true)
        end
        self.Img_SkillIcon:SetRenderOpacity(1)
        self.CvsEnergyAnnex:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.RetainerBox:SetVisibility(UE.ESlateVisibility.Hidden)
        if not self:IsAnimationPlaying(self.DX_UltimateReadyLoop) then
            self:PlayAnimation(self.DX_UltimateReadyLoop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1, true)
        end
    else
        if not IsShiwuyeSuper(self) then
            self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, false)
        end
        self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, false)
        self.Img_SkillIcon:SetRenderOpacity(SuperSkillOpacity)
        self.CvsEnergyAnnex:SetVisibility(UE.ESlateVisibility.Hidden)
        self.RetainerBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:StopAnimationsAndLatentActions()
    end
end

---`brief`计算共同能量显示需要的高度(从图片高度抹平到圆高度)
---@param Value number 能量百分比
---@param number 显示百分比
local function CalcEnergyCycleHeight(self, Value)
    return self.EnergyInfo.CurEnergyPercent * (self.EnergyInfo.TarSize / self.EnergyInfo.CurSize) + (self.EnergyInfo.CurSize - self.EnergyInfo.TarSize) / 200
end

---@param self WBP_HUD_SkillState_Item
local function UpdateEnergyInfo(self)
    if self.SlotIndex ~= SkillState.SkillSlotDef.Super then
        return
    end
    if math.abs(self.EnergyInfo.CurEnergyPercent - self.EnergyInfo.TarEnergyPercent) < TIMER_INTERVAL / 2 then
        self.EnergyInfo.CurEnergyPercent = self.EnergyInfo.TarEnergyPercent
    elseif self.EnergyInfo.CurEnergyPercent < self.EnergyInfo.TarEnergyPercent then
        self.EnergyInfo.CurEnergyPercent = self.EnergyInfo.CurEnergyPercent + TIMER_INTERVAL / 2
    elseif self.EnergyInfo.CurEnergyPercent > self.EnergyInfo.TarEnergyPercent then
        self.EnergyInfo.CurEnergyPercent = self.EnergyInfo.CurEnergyPercent - TIMER_INTERVAL / 2
    end
    self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('progress', CalcEnergyCycleHeight(self, self.EnergyInfo.CurEnergyPercent))
    RefreshEnergyUI(self, self.EnergyInfo.CurEnergyPercent == 1)
end

--function WBP_HUD_SkillState_Item:Initialize(Initializer)
--end

--function WBP_HUD_SkillState_Item:PreConstruct(IsDesignTime)
--end

function WBP_HUD_SkillState_Item:OnConstruct()
    self.CacheLast = {
        TimeRemaining = 0,
        CooldownDuration = 0
    }
    self.EnergyInfo = {
        TarSize = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.Img_CommonEnergy_LightBG):GetSize().X,
        CurSize = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.Img_Ultimate_Accumulate_02):GetSize().X,
        TarEnergyPercent = 0,
        CurEnergyPercent = 0
    }
    self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('progress', 0)
    self.TimeRemaining = 0
    self.tbSkillInfo = {}
    self.CurPlayer = 1

    self.Img_SkillIconProxy = WidgetProxys:CreateWidgetProxy(self.Img_SkillIcon)
    InitWidget(self)
    G.log:debug("zys", "WBP_HUD_SkillState_Item:OnConstruct()")
end

function WBP_HUD_SkillState_Item:TimerLoop()
    local Result = RefreshInfo(self)
    UpdateXVisible(self, Result)
    UpdateEnergyInfo(self)
end

---`brief`外部调用, 当切换角色时刷新信息, 重置技能显示
---@param NewCharType number
---@param OldCharType number
function WBP_HUD_SkillState_Item:OnSwitchPlayer(NewCharType, OldCharType)
    G.log:debug("zys", "WBP_HUD_SkillState_Item:OnSwitchPlayer(NewCharType, OldCharType)")
    self:StopAnimationsAndLatentActions()
    self.CurPlayer = NewCharType
    self.Image_Schedule_Skill_Big:GetDynamicMaterial():SetScalarParameterValue('percent', 1) -- 浮点精度过高会无效
    self.Text_Block_CD:SetText(' ')
    SustainEnd(self)
    self.WBP_HUD_SkillIcon_3:SetRenderOpacity(1)
    self.Img_SkillIcon:SetRenderOpacity(1)
    self.CacheLast.Opacity = 1
    self.Image_Block_StrikeBack_Schedule_1:GetDynamicMaterial():SetScalarParameterValue('percent', 1)
    self.MainUI:UpdateKeyboardIcon(self.SlotIndex, self.InputKeys, true)
    self.CacheLast.SwitchIcon = false
    local vm = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.ThrowSkillVM.UniqueName)
    if IsChrCanThrow(self) then
        vm:SetCanAllThrowPointShow(true)
    else
        vm:SetCanAllThrowPointShow(false)
    end
end

-- function WBP_HUD_SkillState_Item:Tick(MyGeometry, InDeltaTime)
-- end

function WBP_HUD_SkillState_Item:InitWidgetInfo(MainUI, InputKeys, SlotIndex, SkillIconIndex)
    self.MainUI = MainUI
    self.InputKeys = InputKeys
    self.SlotIndex = SlotIndex
    SetSKillIcon(self, SkillIconIndex)
    BuildWidgetProxy(self)
    InitViewModel(self)
end

---@private VM field的回调
function WBP_HUD_SkillState_Item:OnPowerValChanged(Data)
    if not self.EnergyInfo.MaxPower or not Data then
        return
    end
    self.EnergyInfo.TarEnergyPercent = Data / self.EnergyInfo.MaxPower
    self.Ultimate_Accumulate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

---@private VM field的回调
function WBP_HUD_SkillState_Item:OnMaxPowerValChanged(Data)
    self.EnergyInfo.MaxPower = Data
end

return WBP_HUD_SkillState_Item