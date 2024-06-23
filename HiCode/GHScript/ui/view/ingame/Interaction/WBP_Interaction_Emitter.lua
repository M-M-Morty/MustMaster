--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR CuiZhiyuan
-- @DATE ${date} ${time}
--
local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')

---@type WBP_Interaction_Emitter_C
local WBP_Interaction_Emitter = Class(UIWindowBase)

--function WBP_Interaction_Emitter:Initialize(Initializer)
--end

--function WBP_Interaction_Emitter:PreConstruct(IsDesignTime)
--end

 function WBP_Interaction_Emitter:OnConstruct()
    self.ImageProxy=WidgetProxys:CreateWidgetProxy(self.ImageActor)
    self.CommonButton_Close.OnClicked:Add(self,self.OnclickCloseButton)
    self.CommonButton_Close:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Text_Content:SetVisibility(UE.ESlateVisibility.Hidden)
   -- self.bShowTip=true
 end

 function WBP_Interaction_Emitter:UpdateParams(ObjectInfo,InText,ImagePath,CallBack,bShowTopTip)
    self.WBP_Common_Tips_Obtain:SetText(ObjectInfo)
    self.Text_Content:SetText(InText)
    self.ImageProxy:SetImageTexturePath(ImagePath)
    if bShowTopTip==nil then
      self.bShowTip=true
    else
    self.bShowTip=bShowTopTip
    end
    if CallBack then
    self.GetItem=CallBack
    end
    self:OnPlay()
  end

 function WBP_Interaction_Emitter:OnPlay()
   if self.bShowTip==true then
    self:PlayAnimation(self.DX_TitleIn,0,1,UE.EUMGSequencePlayMode.Forward,1.0,false)
   else
      self:OnTitleInFinish()
   end
 end

function WBP_Interaction_Emitter:OnTitleInFinish()
    self:PlayAnimation(self.DX_BottomIn,0,1,UE.EUMGSequencePlayMode.Forward,1.0,false)
    self.CommonButton_Close:SetVisibility(UE.ESlateVisibility.Visible)
    self.Text_Content:SetVisibility(UE.ESlateVisibility.Visible)
end

 function WBP_Interaction_Emitter:OnclickCloseButton()
   if self.GetItem then
      self.GetItem()
      end
   
    UIManager:CloseUI(self,true)
 end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return WBP_Interaction_Emitter
