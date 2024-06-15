--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
---@type WBP_HUD_MadukLamp_C
local WBP_HUD_MadukLamp = Class(UIWindowBase)
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ConstPic = require("CP0032305_GH.Script.common.pic_const")
--function WBP_HUD_MadukLamp:Initialize(Initializer)
--end

--function WBP_HUD_MadukLamp:PreConstruct(IsDesignTime)
--end


function WBP_HUD_MadukLamp:OnConstruct()

end

function WBP_HUD_MadukLamp:OnShow()
    self.AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
end

function WBP_HUD_MadukLamp:Close()
    self:StopAnimationsAndLatentActions()
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self:PlayAnimation(self.DX_TextOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_MadukLamp:UpdateParams(type)
    self.type = type
    self.curState = nil
    self.isCurFocus = nil
    self:StopAnimationsAndLatentActions()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self:PlayAnimation(self.DX_TextIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    if type == 1 then
        self:EnterMadukLampNomalState()
    elseif type == 2 then
        self:EnterReplicatorNomalState()
    end
end

function WBP_HUD_MadukLamp:Tick(MyGeometry, InDeltaTime)
end

function WBP_HUD_MadukLamp:EnterMadukLampAimState()
    if self.curState == "MadukLampAim" then
        return
    end
    self.Widget_CrossHair:SetActiveWidgetIndex(0)
    self.MadukLampState:SetActiveWidgetIndex(1)
    self.curState = "MadukLampAim"
end

function WBP_HUD_MadukLamp:EnterMadukLampNomalState()
    if self.curState == "MadukLampNomal" then
        return
    end
    self.Widget_CrossHair:SetActiveWidgetIndex(0)
    self.MadukLampState:SetActiveWidgetIndex(0)
    self.curState = "MadukLampNomal"
end

function WBP_HUD_MadukLamp:EnterMadukLampFocusState()
    if self.isCurFocus then
        return
    end
    self:PlayAnimation(self.DX_ScaleDown, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.isCurFocus = true
end

function WBP_HUD_MadukLamp:EnterMadukLampUnFocusState()
    if not self.isCurFocus then
        return
    end
    self:PlayAnimation(self.DX_ScaleUp, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.isCurFocus = false
end
function WBP_HUD_MadukLamp:EnterReplicatorNomalState()
    if self.curState == "ReplicatorNomal" then
        return
    end
    self.Widget_CrossHair:SetActiveWidgetIndex(1)
    self.ReplicatorState:SetActiveWidgetIndex(0)
    self.curState = "ReplicatorNomal"
end

function WBP_HUD_MadukLamp:EnterReplicatorAimState()
    if self.curState == "ReplicatorAim" then
        return
    end
    self.Widget_CrossHair:SetActiveWidgetIndex(1)
    self.ReplicatorState:SetActiveWidgetIndex(1)
    self.curState = "ReplicatorAim"
end

function WBP_HUD_MadukLamp:EnterReplicatorFocusState()
    if self.isCurFocus then
        return
    end
    self:PlayAnimation(self.DX_ScaleDown, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.isCurFocus = true
end

function WBP_HUD_MadukLamp:EnterReplicatorUnFocusState()
    if not self.isCurFocus then
        return
    end
    self:PlayAnimation(self.DX_ScaleUp, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self.isCurFocus = false
end

function WBP_HUD_MadukLamp:SetShineInfo(name, PicKey)
    self.Text_Shine:SetText(name)
    self.Cvs_Shine:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if PicKey ~= nil then
        ConstPic.SetImageBrush(self.Img_IconShine, PicKey)
    end
end

function WBP_HUD_MadukLamp:HideShineInfo()
    self.Cvs_Shine:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self:PlayAnimation(self.DX_TextOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

return WBP_HUD_MadukLamp
