--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local InputDef = require('CP0032305_GH.Script.common.input_define')

---@type WBP_HUD_BlackCurtain_C
local WBP_HUD_BlackCurtain =Class(UIWindowBase)

--function WBP_HUD_BlackCurtain:Initialize(Initializer)
--end

--function WBP_HUD_BlackCurtain:PreConstruct(IsDesignTime)
--end

 function WBP_HUD_BlackCurtain:OnConstruct()
    self:InitViewModel()
 end

 function WBP_HUD_BlackCurtain:UpdateParams(InText)
    self.CaptionText=InText
end

    --用于计算传递文本所换行数
 function WBP_HUD_BlackCurtain:CalculateLineBreaks(Str)
    --计算换行符数量，并从文本中去除
    local StrNoWarp,SymbolWarp=string.gsub(Str,"\n","")
    --计算文本中剩余内容的字符串长度并除以每行打字机字符串长度
    local WordWarp=math.floor(string.len(StrNoWarp)/75)
    if  SymbolWarp~=0 then
        return SymbolWarp
    else
        return WordWarp
    end
 end

function WBP_HUD_BlackCurtain:OnShow()
    self:PlayAnimation(self.DX_MissionStart, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    self:PlayAnimation(self.DX_Loop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_BlackCurtain:OnHide()
end

function WBP_HUD_BlackCurtain:InitViewModel()
    ---@type DialogueVM
    self.DialogueVM =ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    ViewModelBinder:BindViewModel(self.Text_ContentField, self.DialogueVM.DialogContentField, ViewModelBinder.BindWayToWidget)
end

function WBP_HUD_BlackCurtain:DXEventMissionStartEnd()
    local LineBreaksNumber=self:CalculateLineBreaks(self.CaptionText)
    --根据所换行数计算Cav相关位置
    UE.UWidget.SetRenderTranslation(self.TypeWriterCanvas,UE.FVector2D(0,-LineBreaksNumber*26))
    self.WBP_TypeWriter:SetText(self.CaptionText)
end

function WBP_HUD_BlackCurtain:SetBlackCurtainText(ChangeText)
    local LineBreaksNumber=self:CalculateLineBreaks(ChangeText)
    UE.UWidget.SetRenderTranslation(self.TypeWriterCanvas,UE.FVector2D(0,-LineBreaksNumber*26))
    self.WBP_TypeWriter:SetText(ChangeText)
    
end

---@param PlaySpeed number @[opt]
function WBP_HUD_BlackCurtain:BlackCurtainClose(PlaySpeed)
    PlaySpeed = PlaySpeed or 1
     self:PlayAnimation(self.DX_MissionFinish, 0, 1, UE.EUMGSequencePlayMode.Forward, PlaySpeed, false)
end

function WBP_HUD_BlackCurtain:DXEventMissionFinishEnd()
    self:CloseMyself(true)
end



--function WBP_HUD_BlackCurtain:Tick(MyGeometry, InDeltaTime)
--end

return WBP_HUD_BlackCurtain
