--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type WBP_CommonButton_C
local M = Class()

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:Construct()
    self.CurrentTintColor = UE.FLinearColor(1.0, 1.0, 1.0, 1.0)

    self.HoverCurrentTime = 0
    self:SetHoverAnimationTime(self.HoverAnimationTime)
    self.HoverDefaultScale = UE.FVector(self.HoverScale.X, self.HoverScale.Y, 0)
    self.HoverPlayMode = 0
    self.HoverSourceScale = UE.FVector(1.0, 1.0, 0)
    self.HoverTargetScale = UE.FVector(1.0, 1.0, 0)
    self.HoverSourceColor = UE.FLinearColor()
    self.HoverTargetColor = UE.FLinearColor()
    
    self.bIsPressing = false
    self.PressCurrentTime = 0
    self:SetPressAnimationTime(self.PressAnimationTime)
    self.PressDefaultScale = UE.FVector(self.PressScale.X, self.PressScale.Y, 0)
    self.PressPlayMode = 0
    self.PressSourceScale = UE.FVector(1.0, 1.0, 0)
    self.PressTargetScale = UE.FVector(1.0, 1.0, 0)
    self.PressSourceColor = UE.FLinearColor()
    self.PressTargetColor = UE.FLinearColor()

    self.Button.OnClicked:Add(self, self.Button_OnClicked)
    self.Button.OnPressed:Add(self, self.Button_OnPressed)
    self.Button.OnReleased:Add(self, self.Button_OnReleased)
    self.Button.OnHovered:Add(self, self.Button_OnHovered)
    self.Button.OnUnhovered:Add(self, self.Button_OnUnhovered)
end

--function M:Tick(MyGeometry, InDeltaTime)
--end

function M:SetHoverAnimationTime(InTime)
    self.HoverAnimationTime = InTime
    if self.HoverAnimationTime > 0 then
        self.HoverPlaybackSpeed = 1.0 / self.HoverAnimationTime
    else
        self.HoverPlaybackSpeed = -1
    end
end

function M:SetPressAnimationTime(InTime)
    self.PressAnimationTime = InTime
    if self.PressAnimationTime > 0 then
        self.PressPlaybackSpeed = 1.0 / self.PressAnimationTime
    else
        self.PressPlaybackSpeed = -1
    end
end

function M:Button_OnClicked()
    if self.OnClicked:IsBound() then
        self.OnClicked:Broadcast()
    end
end

function M:Button_OnPressed()
    self.PressCurrentTime = 0
    self.HoverCurrentTime = 0
    if self.OnPressed:IsBound() then
        self.OnPressed:Broadcast()
    end
    self:PauseAnimation(self.HoverAnimation)

    if self.Button:GetIsEnabled() then
        if UE.UKismetSystemLibrary.IsValid(self['Press Ak Event']) then
            UE.UAkGameplayStatics.PostEvent(self['Press Ak Event'], UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    else
        if UE.UKismetSystemLibrary.IsValid(self['Disable Ak Event']) then
            UE.UAkGameplayStatics.PostEvent(self['Disable Ak Event'], UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
        end
    end
        

    if self.PressPlaybackSpeed > 0 then
        self.bIsPressing = true
        self.PressPlayMode = UE.EUMGSequencePlayMode.Forward
        local RenderScale = self.RootPanel.RenderTransform.Scale
        self.PressSourceScale = UE.FVector(RenderScale.X, RenderScale.Y, 0)
        self.PressTargetScale = self.PressDefaultScale
        self.PressSourceColor = self.CurrentTintColor
        self.PressTargetColor = self.PressedTintColor
        
        self:PlayAnimation(self.PressAnimation, 0, 1, self.PressPlayMode, self.PressPlaybackSpeed, false)
    end
end

function M:Button_OnReleased()
    self.PressCurrentTime = 0
    self.HoverCurrentTime = 0
    if self.OnReleased:IsBound() then
        self.OnReleased:Broadcast()
    end

    self.bIsPressing = false
    if self.Button:IsHovered() then
        self:PauseAnimation(self.PressAnimation)

        if self.HoverPlaybackSpeed > 0 then
            self.HoverPlayMode = UE.EUMGSequencePlayMode.Forward
            local RenderScale = self.RootPanel.RenderTransform.Scale
            self.HoverSourceScale = UE.FVector(RenderScale.X, RenderScale.Y, 0)
            self.HoverTargetScale = self.HoverDefaultScale
            self.HoverSourceColor = self.CurrentTintColor
            self.HoverTargetColor = self.HoveredTintColor
            self:PlayAnimation(self.HoverAnimation, 0, 1, self.HoverPlayMode, self.HoverPlaybackSpeed, false)
        elseif self.PressPlaybackSpeed > 0 then
            local RenderScale = self.RootPanel.RenderTransform.Scale
            self.PressSourceScale = UE.FVector(RenderScale.X, RenderScale.Y, 0)
            self.PressTargetScale = UE.FVector(1.0, 1.0, 0)
            self.PressSourceColor = self.CurrentTintColor
            self.PressTargetColor = self.NormalTintColor

            self.PressPlayMode = UE.EUMGSequencePlayMode.Reverse
            self:PlayAnimation(self.PressAnimation, 0, 1, self.PressPlayMode, self.PressPlaybackSpeed, false)
        end
    else
        self:PauseAnimation(self.HoverAnimation)

        if self.PressPlaybackSpeed > 0 then
            local RenderScale = self.RootPanel.RenderTransform.Scale
            self.PressSourceScale = UE.FVector(RenderScale.X, RenderScale.Y, 0)
            self.PressTargetScale = UE.FVector(1.0, 1.0, 0)
            self.PressSourceColor = self.CurrentTintColor
            self.PressTargetColor = self.NormalTintColor

            self.PressPlayMode = UE.EUMGSequencePlayMode.Reverse
            self:PlayAnimation(self.PressAnimation, 0, 1, self.PressPlayMode, self.PressPlaybackSpeed, false)
        end
    end
end

function M:Button_OnHovered()
    self.PressCurrentTime = 0
    self.HoverCurrentTime = 0
    if self.OnHovered:IsBound() then
        self.OnHovered:Broadcast()
    end

    if UE.UKismetSystemLibrary.IsValid(self['Hover Ak Event']) then
        UE.UAkGameplayStatics.PostEvent(self['Hover Ak Event'], UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
    end
    
    if not self.bIsPressing then
        self:PauseAnimation(self.PressAnimation)

        if self.HoverPlaybackSpeed > 0 then
            local RenderScale = self.RootPanel.RenderTransform.Scale
            self.HoverSourceScale = UE.FVector(RenderScale.X, RenderScale.Y, 0)
            self.HoverTargetScale = self.HoverDefaultScale
            self.HoverSourceColor = self.CurrentTintColor
            self.HoverTargetColor = self.HoveredTintColor
            self.HoverPlayMode = UE.EUMGSequencePlayMode.Forward
            self:PlayAnimation(self.HoverAnimation, 0, 1, self.HoverPlayMode, self.HoverPlaybackSpeed, false)
        end
    end
end

function M:Button_OnUnhovered()
    self.PressCurrentTime = 0
    self.HoverCurrentTime = 0
    if self.OnUnhovered:IsBound() then
        self.OnUnhovered:Broadcast()
    end
    if not self.bIsPressing then
        self:PauseAnimation(self.PressAnimation)

        if self.HoverPlaybackSpeed > 0 then
            local RenderScale = self.RootPanel.RenderTransform.Scale
            self.HoverSourceScale = UE.FVector(RenderScale.X, RenderScale.Y, 0)
            self.HoverTargetScale = UE.FVector(1, 1, 0)
            self.HoverSourceColor = self.CurrentTintColor
            self.HoverTargetColor = self.NormalTintColor
            self.HoverPlayMode = UE.EUMGSequencePlayMode.Reverse
            self:PlayAnimation(self.HoverAnimation, 0, 1, self.HoverPlayMode, self.HoverPlaybackSpeed, false)
        end
    end
end

---@param AnimationWidget UCanvasPanel
function M:PressRepeater(CanvasPanel)
    self.PressCurrentTime = self:GetAnimationCurrentTime(self.PressAnimation) == 0 and self.PressCurrentTime or self:GetAnimationCurrentTime(self.PressAnimation)
    if self.PressPlayMode == UE.EUMGSequencePlayMode.Forward then
        local LerpScale = UE.UKismetMathLibrary.VLerp(self.PressSourceScale, self.PressTargetScale, self.PressCurrentTime)
        self.RootPanel:SetRenderScale(UE.FVector2D(LerpScale.X, LerpScale.Y))

        local LerpColor = UE.UKismetMathLibrary.LinearColorLerp(self.PressSourceColor, self.PressTargetColor, self.PressCurrentTime)
        self:SetCurrentTintColor(LerpColor)
    else
        local LerpScale = UE.UKismetMathLibrary.VLerp(self.PressTargetScale, self.PressSourceScale, self.PressCurrentTime)
        self.RootPanel:SetRenderScale(UE.FVector2D(LerpScale.X, LerpScale.Y))

        local LerpColor = UE.UKismetMathLibrary.LinearColorLerp(self.PressTargetColor, self.PressSourceColor, self.PressCurrentTime)
        self:SetCurrentTintColor(LerpColor)
    end
end

---@param AnimationWidget UCanvasPanel
function M:HoverRepeater(CanvasPanel)
    self.HoverCurrentTime = self:GetAnimationCurrentTime(self.HoverAnimation) == 0 and self.HoverCurrentTime or self:GetAnimationCurrentTime(self.HoverAnimation)

    if self.HoverPlayMode == UE.EUMGSequencePlayMode.Forward then
        local LerpScale = UE.UKismetMathLibrary.VLerp(self.HoverSourceScale, self.HoverTargetScale, self.HoverCurrentTime)
        self.RootPanel:SetRenderScale(UE.FVector2D(LerpScale.X, LerpScale.Y))

        local LerpColor = UE.UKismetMathLibrary.LinearColorLerp(self.HoverSourceColor, self.HoverTargetColor, self.HoverCurrentTime)
        self:SetCurrentTintColor(LerpColor)
    else
        local LerpScale = UE.UKismetMathLibrary.VLerp(self.HoverTargetScale, self.HoverSourceScale, self.HoverCurrentTime)
        self.RootPanel:SetRenderScale(UE.FVector2D(LerpScale.X, LerpScale.Y))

        local LerpColor = UE.UKismetMathLibrary.LinearColorLerp(self.HoverTargetColor, self.HoverSourceColor, self.HoverCurrentTime)
        self:SetCurrentTintColor(LerpColor)
    end
end

function M:SetCurrentTintColor(Color)
    self.CurrentTintColor = Color
    self:SetTintColor(Color)
end

---`brief`按下,仅播放动画
function M:Button_OnKeyboardPressed()
    self:PauseAnimation(self.HoverAnimation)
    if self.PressPlaybackSpeed > 0 then
        self.bIsPressing = true
        self.PressPlayMode = UE.EUMGSequencePlayMode.Forward
        local RenderScale = self.RootPanel.RenderTransform.Scale
        self.PressSourceScale = UE.FVector(RenderScale.X, RenderScale.Y, 0)
        self.PressTargetScale = self.PressDefaultScale
        self.PressSourceColor = self.CurrentTintColor
        self.PressTargetColor = self.PressedTintColor
        self:PlayAnimation(self.PressAnimation, 0, 1, self.PressPlayMode, self.PressPlaybackSpeed, false)
    end
end

return M
