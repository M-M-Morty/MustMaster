require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local MountActorUIComponent = Component(ComponentBase)

local decorator = MountActorUIComponent.decorator

decorator.message_receiver()
function MountActorUIComponent:OnHealthChanged(NewValue, OldValue)

    if not self.actor.NeedTops then
        return
    end
    
    if NewValue > 0 then
        self.actor.WidgetComponent:SetVisibility(true)
        local Widget = self.actor.WidgetComponent:GetWidget()
        Widget.Character = self.actor
        Widget:UpdateHP()
    else
        self.actor.WidgetComponent:SetVisibility(false)
    end

    self:ShowDamageNumber(OldValue - NewValue)
end

function MountActorUIComponent:ShowDamageNumber(Damage, ImpactPoint)
    -- local DamageNumberWidget = UE.UWidgetBlueprintLibrary.Create(self.actor, UE.UClass.Load("/Game/Test/UI/UI_DamageNumber.UI_DamageNumber_C"))
    -- DamageNumberWidget.DamageNumber = -Damage
    -- local Color = UE.FLinearColor(0, 1.0, 0)
    -- DamageNumberWidget:UpdateColor(Color)

    -- -- Set position
    -- ImpactPoint = self.actor:K2_GetActorLocation()
    -- local ScreenPos = UE.FVector2D()
    -- local PlayerController = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)
    -- UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(PlayerController, ImpactPoint, ScreenPos, false)
    -- DamageNumberWidget:SetPositionInViewport(ScreenPos, false)
    -- DamageNumberWidget:AddToViewport()
end

return MountActorUIComponent
