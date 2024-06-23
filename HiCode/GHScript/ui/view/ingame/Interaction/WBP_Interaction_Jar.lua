--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR CuiZhiyuan
-- @DATE ${date} ${time}
--
local G = require('G')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')

---@type WBP_Interaction_Jar_C
local WBP_Interaction_Jar = Class(UIWindowBase)

--function WBP_Interaction_Jar:Initialize(Initializer)
--end

--function WBP_Interaction_Jar:PreConstruct(IsDesignTime)
--end

 function WBP_Interaction_Jar:OnConstruct()
    self.Button_Click.OnClicked:Add(self, self.ButtonOnClick)
    self.WBP_Interaction_Secondary.WBP_Common_Topcontent.Commonbutton_Close.OnClicked:Add(self,self.OnclickCloseButton)
    self.Cvs_TopTitle:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Button_Click:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_Common_Tips_Obtain:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_Interaction_Secondary:SetVisibility(UE.ESlateVisibility.Hidden)
 end

 function WBP_Interaction_Jar:UpdateParams(ObjectInfo,TextID,Actor)
    self.WBP_Common_Tips_Obtain:SetText(ObjectInfo)
    self.IntextID=TextID
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DelayShowMonoLogue}, 0.3, false)
    if not Actor then
     G.log:debug("czy", "WBP_Interaction_Jar:ButtonOnClickTest Find No Actor")
   else
      self.JarActor = Actor
  end
 end

 function WBP_Interaction_Jar:DelayShowMonoLogue()
   self.WBP_Interaction_Secondary:SetVisibility(UE.ESlateVisibility.Visible)
   self.WBP_Interaction_Secondary:SetBottomMonoLogue(self.IntextID)
   self.WBP_Interaction_Secondary:PlayTitleInAnim()
 end


 function WBP_Interaction_Jar:OnclickCloseButton()
   self.JarActor:SetShakeFalse()
   local OnAnimFinish = function()
      UIManager:CloseUI(self, true)
  end
  self.WBP_Interaction_Secondary:PlayTitleOutAnim(OnAnimFinish)
  local Ctr = UE.UGameplayStatics.GetPlayerController(self, 0)
  UE.AActor.EnableInput(Ctr)
 end

 function WBP_Interaction_Jar:ButtonOnClickTest()
   self.WBP_Common_Tips_Obtain:SetVisibility(UE.ESlateVisibility.Visible)
   self.Button_Click:SetVisibility(UE.ESlateVisibility.Visible)
   self.WBP_Interaction_Secondary:SetVisibility(UE.ESlateVisibility.Hidden)
   self:PlayAnimation(self.DXin, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
 end

 function WBP_Interaction_Jar:ButtonOnClick()
   self:PlayAnimation(self.DXout, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
   self.Button_Click:SetVisibility(UE.ESlateVisibility.Hidden)

end

 function WBP_Interaction_Jar:EndAnimationFinish()
  local Ctr = UE.UGameplayStatics.GetPlayerController(self, 0)
   if self.JarActor then
        local Component = UE.AActor.GetComponentByClass(Ctr,self.CompClass)
         if Component.Client_BottleInteractFinish then
          Component:Client_BottleInteractFinish(self.JarActor)
        end
   else
      G.log:debug("czy", "WBP_Interaction_Jar:EndAnimationFinish Find No Actor Or No Actor.RunOnSvr")
   end

    self:CloseMyself(true)
    UE.AActor.EnableInput(Ctr)
 end



return WBP_Interaction_Jar
