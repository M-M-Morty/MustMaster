--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

-- 管理HUD上的消息提示

local G = require('G')
local UIDebug = require("ui.UILuaDebug")
local UIComponent = require("common.gameframework.player_controller.components.controller_ui_component")

local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@class HudMessageCenter : ViewModelBase
local HudMessageCenter = Class(ViewModelBaseClass)

HudMessageCenter.SkillSlotDef = {
    Center = 1,
    Left = 2,
    Right = 3,
}

HudMessageCenter.SkillTypeDef = {
    Normal = 1,
    Ultimate = 2,
}


local MessageConfig = {}


-- PlayerState about

---@param Tips string
---@param Duration number

function HudMessageCenter:ctor(InName)
    Super(HudMessageCenter).ctor(self, InName)
    MessageConfig.CommonTips =
    {
        UIInfo = UIDef.UIInfo.UI_CommonTips,
    }
    MessageConfig.ImportantTips =
    {
        UIInfo = UIDef.UIInfo.UI_ImportantTips,
    }
    MessageConfig.ControlTips =
    {
        UIInfo = UIDef.UIInfo.UI_ControlTips,
    }
    MessageConfig.BattleResultTips =
    {
        UIInfo = UIDef.UIInfo.UI_BattleResultTips,
    }
    MessageConfig.LocationTips =
    {
        UIInfo = UIDef.UIInfo.UI_LocationTips
    }
    MessageConfig.GetPropTips =
    {
        UIInfo = UIDef.UIInfo.UI_GetPropTips
    }
    MessageConfig.GetSpecTips =
    {
        UIInfo = UIDef.UIInfo.UI_AwardTips
    }
    MessageConfig.TimerDisplay =
    {
        UIInfo = UIDef.UIInfo.UI_TimerDisplay
    }
    MessageConfig.LevelDisplay =
    {
        UIInfo = UIDef.UIInfo.UI_LevelDisplayTips
    }
    MessageConfig.Nagging =
    {
        UIInfo = UIDef.UIInfo.UI_NaggingHUD
    }
    MessageConfig.DamageText =
    {
        UIInfo = UIDef.UIInfo.UI_DamageText
    }
    
    -- PlayerState about
    MessageConfig.PlayerStamina =
    {
        UIInfo = UIDef.UIInfo.UI_StaminaHUD
    }
    MessageConfig.SquadList =
    {
        UIInfo = UIDef.UIInfo.UI_SquadList
    }
    MessageConfig.SkillState =
    {
        UIInfo = UIDef.UIInfo.UI_SkillState
    }
    MessageConfig.PlayerHP =
    {
        UIInfo = UIDef.UIInfo.UI_PlayerHP
    }
    MessageConfig.BlackCurtain =
    {
        UIInfo = UIDef.UIInfo.UI_BlackCurtain
    }
    MessageConfig.PlotText =
    {
        UIInfo = UIDef.UIInfo.UI_PlotText
    }
    MessageConfig.Second_TaskCompleted =
    {
        UIInfo = UIDef.UIInfo.UI_Second_TaskCompleted
    }
    MessageConfig.Interaction_Jar =
    {
        UIInfo = UIDef.UIInfo.UI_Interaction_Jar
    }
    MessageConfig.Interaction_Emitter =
    {
        UIInfo = UIDef.UIInfo.UI_Interaction_Emitter
    }
    MessageConfig.PreBarrage =
    {
        UIInfo = UIDef.UIInfo.UI_PreBarrage
    }
end

function HudMessageCenter:AddCommonTips(Tips, Duration)
    local config = MessageConfig.CommonTips

    ---@type WBP_Tips_Tips2_C
    local UIObject = UIManager:OpenUI(config.UIInfo)
    if UIObject then
        UIObject:AddMessage(Tips, Duration)
    end
end

---@param Tips string
---@param Duration number
function HudMessageCenter:AddImportantTips(Tips, Duration)
    local config = MessageConfig.ImportantTips

    ---@type WBP_Tips_Tips1_C
    local UIObject = UIManager:OpenUI(config.UIInfo)
    if UIObject then
        UIObject:AddMessage(Tips, Duration)
    end
end

---@param Tips string
function HudMessageCenter:ShowControlTips(Tips, InteractKey, InteractCallback)
    local config = MessageConfig.ControlTips
    self.controlTips = UIManager:OpenUI(config.UIInfo, Tips, InteractKey, InteractCallback)
end

function HudMessageCenter:HideControlTips()
    self.controlTips:Close()
end

---@param bWin boolean
---@param Duration number
function HudMessageCenter:SetBattleResult(bWin)
    local config = MessageConfig.BattleResultTips
    UIManager:OpenUI(config.UIInfo, bWin)
end

---@param RegionText string
---@param RegionText string
function HudMessageCenter:ShowLocationTip(RegionText, LangText)
    local config = MessageConfig.LocationTips
    UIManager:OpenUI(config.UIInfo, RegionText, LangText)
end

---@param ItemList TArray_Item_
function HudMessageCenter:PushItemList(ItemList)
    local config = MessageConfig.GetPropTips
    local UIGetProp = UIManager:OpenUI(config.UIInfo)
    if UIGetProp then
        UIGetProp:PushNormalItemList(ItemList)
    end
end

---@param ItemList TArray_Item_
function HudMessageCenter:PushNewItemList(ItemList)
    local config = MessageConfig.GetPropTips
    local UIGetProp = UIManager:OpenUI(config.UIInfo)
    if UIGetProp then
        UIGetProp:PushNewItemList(ItemList)
    end
end

---@param ItemList TArray_Item_
function HudMessageCenter:PushSpecItemList(ItemList)
    local config = MessageConfig.GetSpecTips
    local UIGetSpec = UIManager:OpenUI(config.UIInfo)
    if UIGetSpec then
        UIGetSpec:PushSpecItem(ItemList)
    end
end

---@param DurationTime number
---@param Callback function(boolean)@successed = true, cancelled = false
---@return WBP_HUD_TimerDisplay_C
function HudMessageCenter:ShowTimerDisplay(DurationTime, Callback)
    local config = MessageConfig.TimerDisplay
    local instance = UIManager:OpenUI(config.UIInfo, DurationTime, Callback)
    return instance
end

function HudMessageCenter:CancelTimerDisplay()
    local config = MessageConfig.TimerDisplay
    local UIObject = UIManager:GetUIInstanceIfVisible(config.UIInfo.UIName)
    if UIObject then
        UIObject:InvokeCallback()
    end
end

function HudMessageCenter:ShowChapterDisplay(FinishInfo)
    local config = MessageConfig.LevelDisplay
    UIManager:OpenUI(config.UIInfo, FinishInfo)
end

function HudMessageCenter:ShowNagging(MsgContent)
    G.log:debug("zys", table.concat({ 'HudMessageCenter:ShowNagging(MsgContent)', #MsgContent }))
    local UICommunicationNPCChat = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_CommunicationNPC.UIName)
    if not UICommunicationNPCChat then
        local config = MessageConfig.Nagging
        local UINagging = UIManager:OpenUI(config.UIInfo)
        if UINagging then
            UINagging:SetMsg(MsgContent)
        end
    end
end

---@param bForceClose boolean 是否强制关闭, 否则等这一句结束才关
---@param bNoAnim boolean 结束, 不播动画
function HudMessageCenter:HideNagging(bForceClose, bNoAnim)
    G.log:debug("zys", table.concat({ 'HudMessageCenter:HideNagging()' }))
    local config = MessageConfig.Nagging
    local UINagging = UIManager:GetUIInstanceIfVisible(config.UIInfo.UIName)
    if UINagging then
        UINagging:Close(bForceClose, bNoAnim)
    end
end

function HudMessageCenter:AddActorHurtDamage(enemyInstance, damageNum, damageType, eleType, buffName, IsPlayer)
    local config = MessageConfig.DamageText
    local controller_ui_component = UIComponent:GetUICompoent()

    if controller_ui_component:IsLuaDebugWidget() then
        return
    end

    local UIObject = UIManager:OpenUI(config.UIInfo)
    local content = { damage = math.floor(damageNum), buffName = buffName, eleType = eleType, IsPlayer = IsPlayer }
    if UIObject then
        UIObject:AddActorHurtDamage(enemyInstance, content, damageType)
    end
end

function HudMessageCenter:Add2DLocationHurtDamage(position, damageNum, damageType, eleType, buffName, IsPlayer)
    local config = MessageConfig.DamageText

    local UIObject = UIManager:OpenUI(config.UIInfo)
    local content = { damage = math.floor(damageNum), buffName = buffName, eleType = eleType, IsPlayer = IsPlayer }
    local localposition = UE.FVector2D(position.X, position.Y)
    if UIObject then
        UIObject:Add2DLocationHurtDamage(localposition, content, damageType)
    end
end

function HudMessageCenter:AddLocationHurtDamage(location, damageNum, damageType, eleType, buffName, IsPlayer)
    local config = MessageConfig.DamageText
    local UIObject = UIManager:OpenUI(config.UIInfo)
    local LocalLocation = UE.FVector(location.X, location.Y, location.Z)
    local content = { damage = math.floor(damageNum), buffName = buffName, eleType = eleType, IsPlayer = IsPlayer }
    if UIObject then
        UIObject:AddLocationHurtDamage(LocalLocation, content, damageType)
    end
end

function HudMessageCenter:ShowBossHP(HPmax, HPcurrent, ShieldMax, ShieldCurrent, Name)
    return UIManager:OpenUI(UIDef.UIInfo.UI_BossHP, HPmax, HPcurrent, ShieldMax, ShieldCurrent, Name)
end

function HudMessageCenter:ChangeBossHP(data)
    local bosshp = UIManager:GetUIInstance(UIDef.UIInfo.UI_BossHP.UIName)
    if not bosshp then
        return
    end
    bosshp:ChangeBossHP(data)
end

function HudMessageCenter:AddBossHP(data)
    local bosshp = UIManager:GetUIInstance(UIDef.UIInfo.UI_BossHP.UIName)
    if not bosshp then
        return
    end
    bosshp:BossAddHealth(data)
end

function HudMessageCenter:ShieldUpdate(Tenacity, MaxTenacity)
    local bosshp = UIManager:GetUIInstance(UIDef.UIInfo.UI_BossHP.UIName)
    if not bosshp then
        return
    end
    bosshp:ShieldUpdate(Tenacity, MaxTenacity)
end

function HudMessageCenter:CloseBossHP()
    local bosshp = UIManager:GetUIInstance(UIDef.UIInfo.UI_BossHP.UIName)
    bosshp:Close()
end

-- PlayerState start
function HudMessageCenter:UpdateStamina(NewValue, MaxStamina)
    if not self.Stamina then
        ---@type WBP_HUD_Stamina_C
        self.Stamina = UIManager:OpenUI(UIDef.UIInfo.UI_StaminaHUD, NewValue, MaxStamina)
        return
    end
    -- self.Stamina:ChangeValue(NewValue, MaxStamina)

    -- local Owner = self:GetOwner()
    -- if Owner and Owner:GetWidget().OnOpenStamina then
    --     Owner:GetWidget():OnOpenStamina(NewValue, MaxStamina)
    -- end
end

function HudMessageCenter:CloseStamina()
    if self.Stamina then
        self.Stamina:Close()
    end
    self.Stamina = nil
end

function HudMessageCenter:OpenSquadList(Index, characterDataList)
    self.PlayerSquadList = UIManager:OpenUI(UIDef.UIInfo.UI_SquadList, Index, characterDataList)
end

function HudMessageCenter:SwitchPlayer(Index)
    if self.PlayerSquadList then
        self.PlayerSquadList:SwitchPlayer(Index)
    end
end

function HudMessageCenter:OnSquadListRoleHealthChanged(Index, CurPercent)
    if self.PlayerSquadList then
        self.PlayerSquadList:OnSquadListRoleHealthChanged(Index, CurPercent)
    end
end

function HudMessageCenter:OnSquadListRoleDead(Index)
    if self.PlayerSquadList then
        self.PlayerSquadList:OnSquadListRoleDead(Index)
    end
end

---`brief`打开黑幕界面
---@param InText string
function HudMessageCenter:ShowSubtitleBlackWidget(InText)
    local config = MessageConfig.BlackCurtain
    UIManager:OpenUI(config.UIInfo, InText)
end

---`brief`更改黑幕界面文字
---@param ChangeText string
function HudMessageCenter:SetSubtitleBlackWidget(ChangeText)
    local UIBlackCurtain = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_BlackCurtain.UIName)
    if UIBlackCurtain then
        UIBlackCurtain:SetBlackCurtainText(ChangeText)
    end
end

---`brief`关闭黑幕界面
function HudMessageCenter:CloseSubtitleBlackWidget(PlaySpeed)
    local UIBlackCurtain = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_BlackCurtain.UIName)
    if UIBlackCurtain then
        UIBlackCurtain:BlackCurtainClose(PlaySpeed)
    end
end

---`brief`打开纯剧情界面
---@param InText string
function HudMessageCenter:ShowSubtitleWidget(InText)
    local config = MessageConfig.PlotText
    UIManager:OpenUI(config.UIInfo, InText)
end

---`brief`更改纯剧情界面文字
---@param ChangeText string
function HudMessageCenter:SetSubtitleWidget(ChangeText)
    local UIPlotText = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_PlotText.UIName)
    if UIPlotText then
        UIPlotText:SePlotText(ChangeText)
    end
end

---`brief`关闭纯剧情界面
function HudMessageCenter:CloseSubtitleWidget()
    local UIPlotText = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_PlotText.UIName)
    if UIPlotText then
        UIPlotText:PlotTextClose()
    end
end

function HudMessageCenter:ShowSecondTaskCompleted(MissionText)
    local config = MessageConfig.Second_TaskCompleted
    UIManager:OpenUI(config.UIInfo, MissionText)
end

---`brief`打开摇罐子界面
---@param ObjectInfo string
---@param TextID integer
function HudMessageCenter:ShowInteractionJar(ObjectInfo, TextID, Actor)
    local config = MessageConfig.Interaction_Jar
    UIManager:OpenUI(config.UIInfo, ObjectInfo, TextID, Actor)
end

---`brief`摇罐子结束
---@param Actor BP_Bottle
function HudMessageCenter:OnShakeFinish()
    local UIInteractionJar = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_Interaction_Jar.UIName)
    if UIInteractionJar then
        UIInteractionJar:ButtonOnClickTest()
    end
end

---`brief`打开获得遥控器界面
function HudMessageCenter:ShowInteractionEmitter(ObjectInfo, InText, ImagePath, CallBack, bShowTopTip)
    local config = MessageConfig.Interaction_Emitter
    UIManager:OpenUI(config.UIInfo, ObjectInfo, InText, ImagePath, CallBack, bShowTopTip)
end

---打开预弹幕
---@param FirstFinishTime number    第一阶段结束时间
---@param SecondStartTime number    第二阶段开始时间
---@param SecondFinishTime number   第二阶段结束时间
---@param ThirdStartTime number     第三阶段开始时间
---@param ThirdFinishTime number    第三阶段结束时间
---@param ForthStartTime number     第四阶段开始时间
---@param ForthFinishTime number    第四阶段结束时间
---@param FirstInterval number      第一阶段弹幕间隔时间
---@param SecondInterval number     第一阶段弹幕间隔时间
---@param ThirdInterval number      第一阶段弹幕间隔时间
---@param ForthInterval number      第一阶段弹幕间隔时间
function HudMessageCenter:ShowPreBarrage(FirstFinishTime, SecondStartTime, SecondFinishTime, ThirdStartTime,
                                         ThirdFinishTime,
                                         ForthStartTime, ForthFinishTime, FirstInterval, SecondInterval, ThirdInterval,
                                         ForthInterval)
    local config = MessageConfig.PreBarrage
    UIManager:OpenUI(config.UIInfo, FirstFinishTime, SecondStartTime, SecondFinishTime, ThirdStartTime, ThirdFinishTime,
        ForthStartTime, ForthFinishTime, FirstInterval, SecondInterval, ThirdInterval, ForthInterval)
end

-- PlayerState end
return HudMessageCenter
