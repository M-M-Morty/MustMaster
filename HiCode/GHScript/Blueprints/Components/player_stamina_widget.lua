--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UI3DComponent = require('CP0032305_GH.Script.framework.ui.ui_component_base')

---@class BP_PlayerStaminaWidget_C
local M = Class(UI3DComponent)

-- function M:Initialize(Initializer)
-- end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    if self:GetOwner():IsServer() then
        return
    end

    ---@type HudStaminaVM
    self.HudStaminaVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudStaminaVM.UniqueName)
    self:GetWidget():SetVisibility(UE.ESlateVisibility.Collapsed)
end

-- function M:ReceiveEndPlay()
-- end

function M:UpdateStamina(NewValue, OldValue, LimitValue)
    local selfActor = self:GetOwner()
    ---@type WBP_HUD_Stamina_C
    local Widget = self:GetWidget()
    if not self.HudStaminaVM then
        ---@type HudStaminaVM
        self.HudStaminaVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudStaminaVM.UniqueName)
    end
    if not self.HudStaminaVM.curStamina then
        local widget = self:GetWidget()
        self.HudStaminaVM:SetNewStamina(widget)
    end
    if NewValue == OldValue and NewValue == LimitValue then
        return
    end
    if not UE.UKismetSystemLibrary.IsServer(selfActor) then
        Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.HudStaminaVM:SetStaminaValue(NewValue, OldValue, LimitValue)
    end
end

-- function M:ReceiveTick(DeltaSeconds)
--     self.Overridden.ReceiveTick(self, DeltaSeconds)
-- end

return M
