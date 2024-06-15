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
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
---@type WBP_PreBarrage_Item_C
local WBP_PreBarrage_Item = Class(UIWidgetBase)

--function WBP_PreBarrage_Item:Initialize(Initializer)
--end

--function WBP_PreBarrage_Item:PreConstruct(IsDesignTime)
--end

--function WBP_PreBarrage_Item:Tick(MyGeometry, InDeltaTime)
--end

 function WBP_PreBarrage_Item:OnConstruct()
   self.Info = UE.FSlateFontInfo()
   self.Info.FontObject= self.FontFamily
   self.Info.OutlineSettings=self.OutlineSettingsAB
   self.PauseTime=1.1
   self.Moveingtime=0.2
   self.LoopTime=0
   self.RunX=true
   self.RunY=true
   self.CurentX=1
   self.CurentY=1
   self.Txt_Barrage01:SetVisibility(UE.ESlateVisibility.Hidden)
   self.Txt_Barrage02:SetVisibility(UE.ESlateVisibility.Hidden)
   self.Txt_Barrage03:SetVisibility(UE.ESlateVisibility.Hidden)
   self.Txt_Barrage04:SetVisibility(UE.ESlateVisibility.Hidden)
   self.DX_MaterialInstanceBlur=UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(self,self.Parent)
   self.RetainerBoxBarrage:SetEffectMaterial(self.DX_MaterialInstanceBlur)
 end

 function WBP_PreBarrage_Item:PlayFirstAnimation(InText)
   self.Info.Size = math.random(26,36)
   self.Txt_Barrage01:SetText(InText)
   self.Txt_Barrage01:SetFont(self.Info)
   self.Txt_Barrage01:SetVisibility(UE.ESlateVisibility.Visible)
   self:PlayAnimation(self.DXinFirstBarrage,0,1,UE.EUMGSequencePlayMode.Forward,1.0,false)
 end

 function WBP_PreBarrage_Item:PlaySecondAnimation(InText)
   self.Info.Size = math.random(26,36)
   self.Txt_Barrage02:SetText(InText)
   self.Txt_Barrage02:SetFont(self.Info)
   self.Txt_Barrage02:SetVisibility(UE.ESlateVisibility.Visible)
   self:PlayAnimation(self.DXinSecondBarrage,0,1,UE.EUMGSequencePlayMode.Forward,1.0,false)
 end

 function WBP_PreBarrage_Item:PlayThirdAnimation(InText)
   self.Info.Size = math.random(26,36)
   self.Txt_Barrage03:SetText(InText)
   self.Txt_Barrage03:SetFont(self.Info)
   self.Txt_Barrage03:SetVisibility(UE.ESlateVisibility.Visible)
   self:PlayAnimation(self.DXinThirdBarrage,0,1,UE.EUMGSequencePlayMode.Forward,1.0,false)
 end

 function WBP_PreBarrage_Item:PlayForthAnimation(InText)
   self.Info.Size = math.random(26,46)
   self.Txt_Barrage04:SetText(InText)
   self.Txt_Barrage04:SetFont(self.Info)
   self.Txt_Barrage04:SetVisibility(UE.ESlateVisibility.Visible)
   self:PlayAnimation(self.DXinFouthBarrage,0,1,UE.EUMGSequencePlayMode.Forward,1.0,false)
 end

 function WBP_PreBarrage_Item:DXEvent_TextBlur1()
  self:SetDynamicEffect(self.DXinFirstBarrage)
 end

 function WBP_PreBarrage_Item:DXEvent_TextBlur2()
  self:SetDynamicEffect(self.DXinSecondBarrage)
end

function WBP_PreBarrage_Item:DXEvent_TextBlur3()
  self:SetDynamicEffect(self.DXinThirdBarrage)
end

function WBP_PreBarrage_Item:DXEvent_TextBlur4()
  self:SetDynamicEffect(self.DXinFouthBarrage)
end

function WBP_PreBarrage_Item:SetDynamicEffect(Animation)
  local AnimationCurrentTime=self:GetAnimationCurrentTime(Animation)
  local FloatInTime=self.DX_BlurCurve:GetFloatValue((AnimationCurrentTime-1)*1.2)
  self.DX_MaterialInstanceBlur:SetScalarParameterValue("Distance",FloatInTime*0.06)
end

 function WBP_PreBarrage_Item:AnimForthPause()
  self.PauseTime=self:PauseAnimation(self.DXinFouthBarrage) 
 end

 function WBP_PreBarrage_Item:Keeprun(LocX,LocY)
  UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.PlayBlowAnim},0.15,false)
  if LocX<300 and LocX>-300 and LocY<100 and LocY>-100 then
  else
  self:MoveBarrage(LocX,LocY)
  end
 end

 function WBP_PreBarrage_Item:PlayBlowAnim()
  self:PlayAnimation(self.DXinFouthBarrage,self.PauseTime,1,UE.EUMGSequencePlayMode.Forward,1,false)
 end


 function WBP_PreBarrage_Item:MoveBarrage(LocX,LocY)
  self.PosX=LocX
  self.PosY=LocY
  self.MoveTimer=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.BarragePositionByTimer},0.1,true)
 end

 function WBP_PreBarrage_Item:BarragePositionByTimer()
  self.Moveingtime=self.Moveingtime+0.2
  local MovePanel=UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.RetainerBoxBarrage)
  if self.RunX==true then
    self.CurentX=self.PosX*self.Moveingtime
  end
  if self.RunY==true then
    self.CurentY=self.PosY*self.Moveingtime
  end
  if math.abs( self.CurentX )>900-math.abs( self.PosX )  and self.CurentX>0 then
    self.CurentX=850-self.PosX
    self.RunY=false
  end
  if math.abs( self.CurentX )>900-math.abs( self.PosX )  and self.CurentX<0 then
    self.CurentX=-850-self.PosX
    self.RunY=false
  end
  if math.abs( self.CurentY )>500-math.abs( self.PosY )  and self.CurentY>0 then
    self.CurentY=500-self.PosY
    self.RunX=false
  end
  if math.abs( self.CurentY )>500-math.abs( self.PosY )  and self.CurentY<0 then
    self.CurentY=-500-self.PosY
    self.RunX=false
  end
  MovePanel:SetPosition(UE.FVector2D(self.CurentX,self.CurentY))
  self.LoopTime=self.LoopTime+1
  if self.LoopTime==5 then
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.MoveTimer)
  end
 end

 function WBP_PreBarrage_Item:AnFinish()

   self:RemoveFromParent()
 end


return WBP_PreBarrage_Item
