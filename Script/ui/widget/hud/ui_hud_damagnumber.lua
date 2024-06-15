--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')


---@type WBP_HUD_DamageNumber_C
local WBP_HUD_DamageNumber = Class(UIWidgetBase)

function WBP_HUD_DamageNumber:OnConstruct()
    self.DamageNumberCanvas:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.isIdle = true
end

function WBP_HUD_DamageNumber:Init()

end

function WBP_HUD_DamageNumber:ShowActorHurtContent(enemyInstance, content, damageType)
    self.targetEnemy = enemyInstance
    self.damageType = damageType
    self.showContent = content
    self:ConfigFront()
end

function WBP_HUD_DamageNumber:ShowLocationHurtContent(Location, content, damageType)
    self.targetLocation = Location
    self.damageType = damageType
    self.showContent = content
    self:ConfigFront()
end


function WBP_HUD_DamageNumber:ShowPositionHurtContent(position, content, damageType)
    self.targetPosion = position
    self.damageType = damageType
    self.showContent = content
    self:ConfigFront()
    self:UpdateItem(self.targetPosion)
end

function WBP_HUD_DamageNumber:ConfigFront()
    self.isIdle = false
    self:ChangeEle()
    self.DamageNumberCanvas:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local damageType = self.damageType
    self.randomX = math.random(self.XRandomRadius.X, self.XRandomRadius.Y)
    local angel = math.rad(math.random(self.AngleRadius.X, self.AngleRadius.Y))
    self.randomY = -math.sin(angel) * math.abs(self.randomX)
    if damageType == "Normal" then
        self:ShowNormalDamage()
    end
    if damageType == "Critical" then
        self:ShowCriticalDamage()
    end
    if damageType == "Buff" then
        self:ShowBuffDamage()
    end
    if damageType == "BuffName" then
        self:ShowBuffName()
    end
end

function WBP_HUD_DamageNumber:IsIdle()
    return self.isIdle
end

function WBP_HUD_DamageNumber:GetShowType()
    return self.damageType
end

function WBP_HUD_DamageNumber:GetIsPlayer()
    return self.showContent.IsPlayer
end

function WBP_HUD_DamageNumber:ShowNormalDamage()
    -- math.randomseed(os.time())
    self.WidgetSwitcher_zi:SetActiveWidgetIndex(0);
    self.TextBlock_0:SetText(tostring(self.showContent.damage))
    if not self.showContent.IsPlayer then
        self:PlayAnimation(self.DX_boss_putong, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
        self:BindToAnimationFinished(self.DX_boss_putong,{self, self.AnimaEnd})

    else
        self:PlayAnimation(self.DX_juese_putong, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
        self:BindToAnimationFinished(self.DX_juese_putong,{self, self.AnimaEnd})
    end
end

function WBP_HUD_DamageNumber:ShowCriticalDamage()
    self.TextBlock_1:SetText(tostring(self.showContent.damage))
    if not self.showContent.IsPlayer then
        self:PlayAnimation(self.DX_boss_baoji, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
        self:BindToAnimationFinished(self.DX_boss_baoji,{self, self.AnimaEnd}) 
    else
        self:PlayAnimation(self.DX_juese_baoji, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
        self:BindToAnimationFinished(self.DX_juese_baoji,{self, self.AnimaEnd})
    end
end

function WBP_HUD_DamageNumber:ShowBuffDamage()
    self.TextBlock_0:SetText(tostring(self.showContent.damage))
    self:PlayAnimation(self.Damage, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    self:BindToAnimationFinished(self.Damage,{self, self.AnimaEnd})
end

function WBP_HUD_DamageNumber:ShowBuffName()
    self.TextBlock_0:SetText(tostring(self.showContent.buffName))
    self:PlayAnimation(self.DX_wenzi, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    self:BindToAnimationFinished(self.DX_wenzi,{self, self.AnimaEnd})
end

function WBP_HUD_DamageNumber:ChangeEle()
    local ColorType = self.DamageColor:Find(self.showContent.eleType).Color
    self.TextBlock_1:SetColorAndOpacity(ColorType)
    self.TextBlock_0:SetColorAndOpacity(ColorType)
    if self.showContent.eleType == Enum.Enum_DamageNumber.AddHealth then
        self.showContent.damage = "+" .. self.showContent.damage
    end
end

function WBP_HUD_DamageNumber:UpdateItem(ScreenLocation)
    local targetLocation = UE.FVector2D(0, 0)
    targetLocation.Y = ScreenLocation.Y + self.randomY
    targetLocation.X = ScreenLocation.X + self.randomX
    self.Slot:SetPosition(targetLocation)

end


function WBP_HUD_DamageNumber:AnimaEnd()
    self.isIdle = true
    self.targetEnemy = nil
    self.targetPosion = nil
    self.targetLocation = nil
end

function WBP_HUD_DamageNumber:GetEnemyInstance()
    return self.targetEnemy
end

return WBP_HUD_DamageNumber
