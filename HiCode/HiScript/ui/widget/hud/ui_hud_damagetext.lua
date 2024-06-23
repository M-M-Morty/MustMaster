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
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')


---@type WBP_HUD_DamageText_C
local WBP_HUD_DamageText = Class(UIWindowBase)

function WBP_HUD_DamageText:OnConstruct()
    self.PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(self, 0)
    self.UEPlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    --初始化预制10个prefab
    for i = 1, 10 do
        local NewWidget = UE.NewObject(UIManager:ClassRes("DamageNumber"), self)
        local NewSlot = self.DamagePanelContainer:AddChildToCanvas(NewWidget)
        NewSlot:SetAutoSize(true)
        NewSlot:SetAlignment(UE.FVector2D(0.5, 0.5))
        self.DamageTextItemArray:Add(NewWidget)
    end
end

function WBP_HUD_DamageText:AddActorHurtDamage(enemyInstance, content, damageType)
    local item
    if (not enemyInstance) or (not content) or (not damageType) then
        return
    end
    if damageType == "Buff" then
        item = self:NewOrFindItem()
        item:ShowActorHurtContent(enemyInstance, content, "BuffName")
    end

    item = self:NewOrFindItem()
    item:ShowActorHurtContent(enemyInstance, content, damageType)
    self:SetLocationInfo(item)
end

function WBP_HUD_DamageText:Add2DLocationHurtDamage(position, content, damageType)
    local item
    if (not position) or (not content) or (not damageType) then
        return
    end
    if damageType == "Buff" then
        item = self:NewOrFindItem()
        item:ShowPositionHurtContent(position, content, "BuffName")
    end

    item = self:NewOrFindItem()
    item:ShowPositionHurtContent(position, content, damageType)
end

function WBP_HUD_DamageText:AddLocationHurtDamage(location, content, damageType)
    local item
    if (not location) or (not content) or (not damageType) then
        return
    end
    if damageType == "Buff" then
        item = self:NewOrFindItem()
        item:ShowLocationHurtContent(location, content, "BuffName")
    end

    item = self:NewOrFindItem()
    item:ShowLocationHurtContent(location, content, damageType)
    self:SetLocationInfo(item)
end

function WBP_HUD_DamageText:NewOrFindItem()
    local Num = self.DamageTextItemArray:Length()
    for i = 1, Num do
        local Widget = self.DamageTextItemArray:Get(i)
        if Widget:IsIdle() then
            return Widget
        end
    end
    local NewWidget = UE.NewObject(UIManager:ClassRes("DamageNumber"), self)
    local NewSlot = self.DamagePanelContainer:AddChildToCanvas(NewWidget)
    NewSlot:SetAutoSize(true)
    NewSlot:SetAlignment(UE.FVector2D(0.5, 0.5))
    self.DamageTextItemArray:Add(NewWidget)
    return NewWidget;
end



function WBP_HUD_DamageText:SetLocationInfo(Item)
    local ActorLocation
    local Geo
    if Item.targetLocation then
        ActorLocation = Item.targetLocation
    end
    if self.PlayerPawn and Item.targetEnemy then
        if Item.targetEnemy.GetHudWorldLocation then
            ActorLocation = Item.targetEnemy:GetHudWorldLocation()
        else
            ActorLocation = Item.targetEnemy:K2_GetActorLocation()
        end
    end

    if ActorLocation then
        local Location = UE.FVector2D()
        UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(self.UEPlayerController,
            ActorLocation,
            Location, true)
        local ViewPortLocation = UE.FVector2D()
        local type = Item:GetShowType()
        local bIsPlayer = Item:GetIsPlayer()
        if bIsPlayer then
            if type == "BuffName" then
                Geo = self.PlayerBuffName:GetCachedGeometry()
                ViewPortLocation = UE.USlateBlueprintLibrary.GetLocalTopLeft(Geo) + Location
            end
            if type == "Normal" then
                Geo = self.PlayerNormal:GetCachedGeometry()
                ViewPortLocation = UE.USlateBlueprintLibrary.GetLocalTopLeft(Geo) + Location
            end
            if type == "Critical" then
                Geo = self.PlayerCritical:GetCachedGeometry()
                ViewPortLocation = UE.USlateBlueprintLibrary.GetLocalTopLeft(Geo) + Location
            end
            if type == "Buff" then
                Geo = self.PlayerBuff:GetCachedGeometry()
                ViewPortLocation = UE.USlateBlueprintLibrary.GetLocalTopLeft(Geo) + Location
            end
            if Item.showContent.eleType == "AddHealth" then
                Geo = self.PlayerAddHealth:GetCachedGeometry()
                ViewPortLocation = UE.USlateBlueprintLibrary.GetLocalTopLeft(Geo) + Location
            end
        else
            if type == "BuffName" then
                Geo = self.MonsterBuffName:GetCachedGeometry()
                ViewPortLocation = UE.USlateBlueprintLibrary.GetLocalTopLeft(Geo) + Location
            end
            if type == "Normal" then
                Geo = self.MonsterNormal:GetCachedGeometry()
                ViewPortLocation = UE.USlateBlueprintLibrary.GetLocalTopLeft(Geo) + Location
            end
            if type == "Critical" then
                Geo = self.MonsterCritical:GetCachedGeometry()
                ViewPortLocation = UE.USlateBlueprintLibrary.GetLocalTopLeft(Geo) + Location
            end
            if type == "Buff" then
                Geo = self.MonsterBuff:GetCachedGeometry()
                ViewPortLocation = UE.USlateBlueprintLibrary.GetLocalTopLeft(Geo) + Location
            end
        end
        Item:UpdateItem(ViewPortLocation)
    end
end

return WBP_HUD_DamageText
