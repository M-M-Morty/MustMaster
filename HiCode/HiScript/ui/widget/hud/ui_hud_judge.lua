--
-- @COMPANY GHGame
-- @AUTHOR wangyuexi
--

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local G = require('G')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
---@class WBP_HUD_Judge_C
local UIHudJudge = Class(UIWindowBase)

local INPUT_TAG = "WBP_HUD_Judge_C"

--function UIHudJudge:Initialize(Initializer)
--end

--function UIHudJudge:PreConstruct(IsDesignTime)
--end

function UIHudJudge:Construct()
    self.bIsDestroying = false
    local controller = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    ---注册judge imc，屏蔽切人imc，防止切人触发了超级登场
    controller:SendMessage("RegisterIMC", UIDef.UIInfo.UI_Judge.UIName,{"Judge",},{"SwitchPlayer"})
end

--function UIHudJudge:Tick(MyGeometry, InDeltaTime)
--end

function UIHudJudge:IsDestroying()
    return self.bIsDestroying
end

function UIHudJudge:InitWidget(TargetActor, Duration)
    if self:IsDestroying() then
        return
    end
    self:StopAnimationsAndLatentActions()
    self:PlayAnimation(self.DX_QTE_chuxian, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    
    self.Judge_Btn.Button.OnClicked:Add(self, self.JudgeTarget)

    self.TargetActor = TargetActor

    -- self:StopTimer()
    -- self.DurationTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnDurationTimeOut }, Duration, false)
end

function UIHudJudge:DestoryWidget()
    if not self.bIsDestroying then
        self.bIsDestroying = true

        -- if self.IMCNode then
        --     UIManager:RemoveIMCNode(self.IMCNode)
        -- end

        self.TargetActor = nil

        -- self:StopTimer()
        self:StopAnimationsAndLatentActions()

        local CloseAnimation = self.DX_QTE_dianji
        self:UnbindAllFromAnimationFinished(CloseAnimation)
        self:BindToAnimationFinished(CloseAnimation, {self, self.OnCloseAnimationCompleted})
        self:PlayAnimation(CloseAnimation, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    end
end

function UIHudJudge:OnDestroy()
    local controller = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    controller:SendMessage("UnregisterIMC", UIDef.UIInfo.UI_Judge.UIName)
end

function UIHudJudge:OnCloseAnimationCompleted()
    self:RemoveFromViewport()
end

function UIHudJudge:StopTimer()
    if self.DurationTimer then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DurationTimer)
        self.DurationTimer = nil
    end
end

function UIHudJudge:JudgeTarget()
    if self.TargetActor and self.TargetActor:IsValid() then
        G.log:debug("gh_ui", "UIHudJudge Try begin judge: %s", self.TargetActor:GetDisplayName())
        local HudMsgCenter = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        if HudMsgCenter then -- 处决时关闭Nagging
            HudMsgCenter:HideNagging(true, true)
        end
        local Player = G.GetPlayerCharacter(self, 0)
        if Player and Player.SkillComponent then
            Player.SkillComponent:TryJudge(self.TargetActor)
            local controller = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
            controller:SendMessage("DoJudge")
        end
    end
end

function UIHudJudge:OnDurationTimeOut()
    self:DestoryWidget()
end

function UIHudJudge:OnCloseJudgeWidget()
    self:OnCloseAnimationCompleted()
end

return UIHudJudge
