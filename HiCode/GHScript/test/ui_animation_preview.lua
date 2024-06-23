--
-- @COMPANY
-- @AUTHOR
--

local G = require('G')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

---@type AnimPreviewUI_C
local AnimPreviewUI_C = Class(UIWindowBase)

--function AnimPreviewUI_C:Initialize(Initializer)
--end

--function AnimPreviewUI_C:PreConstruct(IsDesignTime)
--end

function AnimPreviewUI_C:OnConstruct()
    self.CloseBtn.OnClicked:Add(self, self.ButtonClose_OnClicked)

    self.inplace_play.OnClicked:Add(self, self.InPlaceWalkPlay_OnClicked)
    self.inplace_rate_Slider.OnValueChanged:Add(self, self.InPlaceWalkRate_Changed)
    self.inplace_rot_Slider.OnValueChanged:Add(self, self.InPlaceWalkRot_Changed)

    self.inplace_runplay.OnClicked:Add(self, self.InPlaceRunPlay_OnClicked)
    self.inplace_runrate_Slider.OnValueChanged:Add(self, self.InPlaceRunRate_Changed)
    self.inplace_runrot_Slider.OnValueChanged:Add(self, self.InPlaceRunRot_Changed)

    self.walk_rate_Slider.OnValueChanged:Add(self, self.WalkRate_Changed)
    self.walkSpeed.OnTextCommitted:Add(self, self.WalkSpeed_Commit)

    self.run_rate_Slider.OnValueChanged:Add(self, self.RunRate_Changed)
    self.runSpeed.OnTextCommitted:Add(self, self.RunSpeed_Commit)
end

--function AnimPreviewUI_C:OnDestruct()
--end

--function AnimPreviewUI_C:Tick(MyGeometry, InDeltaTime)
--end

function AnimPreviewUI_C:ButtonClose_OnClicked()
    self:CloseMyself()
end

function AnimPreviewUI_C:UpdateParams(...)
    self.tarObj = select(1, ...)
    self:UpdateView()
end
function AnimPreviewUI_C:GetPreviewTarget()
    return self.tarObj
end

function AnimPreviewUI_C:UpdateView()
    local previewTag = self.tarObj:GetPreviewTag()
    if previewTag == 'preview_walk_in_place' then
        self.PreviewSwitcher:SetActiveWidgetIndex(0)
        local animInst = self.tarObj.Mesh:GetAnimInstance()
        self.inplace_walkrate:SetText(string.format("%.2f", animInst.GlobalPlayRate))
        self.inplace_rate_Slider:SetValue(animInst.GlobalPlayRate)
        self.inplace_walkrot:SetText(string.format("%.1f", animInst.walkRotation))
        self.inplace_rot_Slider:SetValue(animInst.walkRotation)
    elseif previewTag == 'preview_run_in_place' then
        self.PreviewSwitcher:SetActiveWidgetIndex(1)
        local animInst = self.tarObj.Mesh:GetAnimInstance()
        self.inplace_runrate:SetText(string.format("%.2f", animInst.GlobalPlayRate))
        self.inplace_runrate_Slider:SetValue(animInst.GlobalPlayRate)
        self.inplace_runrot:SetText(string.format("%.1f", animInst.runRotation))
        self.inplace_runrot_Slider:SetValue(animInst.runRotation)
    elseif previewTag == 'preview_walk' then
        self.PreviewSwitcher:SetActiveWidgetIndex(2)
        local animInst = self.tarObj.Mesh:GetAnimInstance()
        self.walk_rate:SetText(string.format("%.2f", animInst.walkPlayRate))
        self.walk_rate_Slider:SetValue(animInst.walkPlayRate)
        self.tarObj:ClientRPC('ReqMaxWalkSpeed')
    elseif previewTag == 'preview_run' then
        self.PreviewSwitcher:SetActiveWidgetIndex(3)
        local animInst = self.tarObj.Mesh:GetAnimInstance()
        self.run_rate:SetText(string.format("%.2f", animInst.runPlayRate))
        self.run_rate_Slider:SetValue(animInst.runPlayRate)
        self.tarObj:ClientRPC('ReqMaxWalkSpeed')
    else
        self.PreviewSwitcher:SetActiveWidget(self.default_switcher_panel)
    end
end

function AnimPreviewUI_C:InPlaceWalkPlay_OnClicked()
    local animInst = self.tarObj.Mesh:GetAnimInstance()
    animInst.Playing = not animInst.Playing
end
function AnimPreviewUI_C:InPlaceWalkRate_Changed(ChangedValue)
    local animInst = self.tarObj.Mesh:GetAnimInstance()
    animInst.GlobalPlayRate = ChangedValue
    self.inplace_walkrate:SetText(string.format("%.2f", ChangedValue))
end
function AnimPreviewUI_C:InPlaceWalkRot_Changed(ChangedValue)
    local animInst = self.tarObj.Mesh:GetAnimInstance()
    animInst.walkRotation = ChangedValue
    self.inplace_walkrot:SetText(string.format("%.1f", ChangedValue))
end


function AnimPreviewUI_C:InPlaceRunPlay_OnClicked()
    local animInst = self.tarObj.Mesh:GetAnimInstance()
    animInst.Running = not animInst.Running
end
function AnimPreviewUI_C:InPlaceRunRate_Changed(ChangedValue)
    local animInst = self.tarObj.Mesh:GetAnimInstance()
    animInst.GlobalPlayRate = ChangedValue
    self.inplace_runrate:SetText(string.format("%.2f", ChangedValue))
end
function AnimPreviewUI_C:InPlaceRunRot_Changed(ChangedValue)
    local animInst = self.tarObj.Mesh:GetAnimInstance()
    animInst.runRotation = ChangedValue
    self.inplace_runrot:SetText(string.format("%.1f", ChangedValue))
end

function AnimPreviewUI_C:WalkRate_Changed(ChangedValue)
    local animInst = self.tarObj.Mesh:GetAnimInstance()
    animInst.walkPlayRate = ChangedValue
    self.walk_rate:SetText(string.format("%.2f", ChangedValue))
end
function AnimPreviewUI_C:WalkSpeed_Commit(text)
    local v = tonumber(text)
    if v and v > 0 then
        self.tarObj:ClientRPC('SetMaxWalkSpeed', v)
    end
end
function AnimPreviewUI_C:UpdateWalkSpeed(v)
    local v = tonumber(v)
    self.walkSpeed:SetText(string.format("%.1f", v))
end

function AnimPreviewUI_C:RunRate_Changed(ChangedValue)
    local animInst = self.tarObj.Mesh:GetAnimInstance()
    animInst.runPlayRate = ChangedValue
    self.run_rate:SetText(string.format("%.2f", ChangedValue))
end
function AnimPreviewUI_C:RunSpeed_Commit(text)
    local v = tonumber(text)
    if v and v > 0 then
        self.tarObj:ClientRPC('SetMaxWalkSpeed', v)
    end
end
function AnimPreviewUI_C:UpdateRunSpeed(v)
    local v = tonumber(v)
    self.runSpeed:SetText(string.format("%.1f", v))
end


return AnimPreviewUI_C
