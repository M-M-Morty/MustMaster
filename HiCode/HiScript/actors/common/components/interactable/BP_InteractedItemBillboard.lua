local G = require('G')
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local UIConstData = require("common.data.ui_const_data").data

---@type BP_InteractedItemBillboard_C
local InteractedItemBillboard = Component(ComponentBase)

function InteractedItemBillboard:Initialize(Initializer)
    Super(InteractedItemBillboard).Initialize(self, Initializer)
end

function InteractedItemBillboard:ReceiveBeginPlay()
    Super(InteractedItemBillboard).ReceiveBeginPlay(self)
    -- 目前仅用来显示任务的icon, 所以默认SetVisibility(false)，有任务的时候再打开, 提高性能。
    if self.actor:IsClient() then
        self:OpenBillboard("", "", "")
        self:SetVisibility(false)
    end
end

function InteractedItemBillboard:OpenBillboard(name, bubble, title)
    if self:GetWidget().OpenHudNPC == nil then
        return
    end
    self:GetWidget():OpenHudNPC(name, bubble, title)
end

function InteractedItemBillboard:MarkTracked(MissionType, MissionState)
    if self.enabled then
        local HeadWidget = self:GetWidget()
        ---由于item的billboard默认SetVisibility(false),隐藏后需要先设置true
        self:SetBillboardVisibility(true)
        if HeadWidget then
            HeadWidget:ShowTaskIcon(MissionType, MissionState)
        end
    end
end

function InteractedItemBillboard:SetBillboardVisibility(bIsVisible)
    ---被uimanager统一隐藏 bVisible为false，则弱追踪不进行SetVisibility
    if bIsVisible then
        if not self.bHidden3DUI then
            self:SetVisibility(bIsVisible)
        end
    else
        self:SetVisibility(bIsVisible)
    end
end

function InteractedItemBillboard:UnMarkTracked()
    if self.enabled then
        local HeadWidget = self:GetWidget()
        if HeadWidget then
            HeadWidget:HideTaskIcon()
        end
        self:SetBillboardVisibility(false)
    end
end

return InteractedItemBillboard
