--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR CuiZhiyuan
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
local NpcBubbleTable = require("common.data.barrage_content_data").data
---@type WBP_PreBarrage_C
local  WBP_PreBarrage = Class(UIWindowBase)


--function WBP_PreBarrage:Initialize(Initializer)
--end

--function WBP_PreBarrage:PreConstruct(IsDesignTime)
--end

--function WBP_PreBarrage:Tick(MyGeometry, InDeltaTime)
--end

 function WBP_PreBarrage:OnConstruct()
  self.RandomTime=0
  self.RDList={}
  self.SecondTypeIndex=self:GetindexofType(2)
  self.ThirdTypeIndex=self:GetindexofType(3)
  self.ForthBarrageTimes=self:GetindexofType(4)
  self.TextID1=1
  self.TextID2=self.SecondTypeIndex
  self.TextID3=self.ThirdTypeIndex
  self.TextID4=self.ForthBarrageTimes
 end

 function WBP_PreBarrage:UpdateParams(FirstFinishTime,SecondStartTime,SecondFinishTime,ThirdStartTime,ThirdFinishTime,ForthStartTime,ForthFinishTime,FirstInterval,SecondInterval,ThirdInterval,ForthInterval)
  self.SecondInterval=SecondInterval
  self.ThirdInterval=ThirdInterval
  self.ForthInterval=ForthInterval
  self.FirstStarthandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ADDFirstStageBarrage},FirstInterval,true)
  self.FirstFinishthandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.FirstStageFinish},FirstFinishTime,false)
  self.SecondStarthandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.SecondStageStart},SecondStartTime,false)
  self.SecondFinishthandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.SecondStageFinish},SecondFinishTime,false)
  self.ThirdStarthandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ThirdStageStart},ThirdStartTime,false)
  self.ThirdFinishthandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ThirdStageFinish},ThirdFinishTime,false)
  self.ForthStarthandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ForthStageStart},ForthStartTime,false)
  self.ForthFinishthandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ForthStageFinish},ForthFinishTime-1,false)
 end

--第一阶段弹幕
function WBP_PreBarrage:ADDFirstStageBarrage()
  local widget ,ChildPanel=self:CreatUI()
  self:SetUIPosition(ChildPanel,8)
  if self.TextID1 == self.SecondTypeIndex then
     self.TextID1=1
  end
  local InText=NpcBubbleTable[self.TextID1].barrage_content
  widget:PlayFirstAnimation(InText)
  self.TextID1=self.TextID1+1
end

--第一阶段结束
function WBP_PreBarrage:FirstStageFinish()
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.FirstStarthandle)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.FirstFinishthandle)
end

--第二阶段开始
function WBP_PreBarrage:SecondStageStart()
  self.Secondhandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ADDSecondStageBarrage},self.SecondInterval,true)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.SecondStarthandle)
end

--第二阶段弹幕
function WBP_PreBarrage:ADDSecondStageBarrage()
  local widget ,ChildPanel=self:CreatUI()
  self:SetUIPosition(ChildPanel,8)
  if self.TextID2 == self.ThirdTypeIndex then
    self.TextID2=self.SecondTypeIndex
  end
  local InText=NpcBubbleTable[self.TextID2].barrage_content
  widget:PlaySecondAnimation(InText)
  self.TextID2=self.TextID2+1
end

--第二阶段结束
function WBP_PreBarrage:SecondStageFinish()
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.Secondhandle)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.SecondFinishthandle)
end

--第三阶段开始
function WBP_PreBarrage:ThirdStageStart()
  self.Thirdhandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ADDThirdStageBarrage},self.ThirdInterval,true)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ThirdStarthandle)
end

--第三阶段弹幕
function WBP_PreBarrage:ADDThirdStageBarrage()
  local widget ,ChildPanel=self:CreatUI()
  self:SetUIPosition(ChildPanel,8)
  if self.TextID2 == self.ThirdTypeIndex then
    self.TextID2=self.SecondTypeIndex
  end
  local InText=NpcBubbleTable[self.TextID2].barrage_content
  widget:PlaySecondAnimation(InText)
  self.TextID2=self.TextID2+1
end

--第三阶段结束
function WBP_PreBarrage:ThirdStageFinish()
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.Thirdhandle)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ThirdFinishthandle)
end

--第四阶段开始a
function WBP_PreBarrage:ForthStageStart()
  self.Forthhandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ADDForthStageBarrage},self.ForthInterval,true)
  self.Forthhandlea=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ForthStageStarta},1.5,false)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ForthStarthandle)
end

--第四阶段开始b
function WBP_PreBarrage:ForthStageStarta()
  self.ForthhandleA=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ADDForthStageBarrage},0.02,true)
  self.Forthhandleb=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ForthStageStartb},1.5,false)
  self.ForthhandlebStop=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ForthStageStopb},1.2,false)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.Forthhandle)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.Forthhandlea)
end

function WBP_PreBarrage:ForthStageStopb()
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ForthhandlebStop)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ForthhandleA)
end

--第四阶段开始c
function WBP_PreBarrage:ForthStageStartb()
  self.Cvs_Barrage_01:SetVisibility(UE.ESlateVisibility.Visible)
  self:PlayAnimation(self.BarrageIn01,0,1,UE.EUMGSequencePlayMode.Forward,2,false)
  self.Cvs_Barrage_02:SetVisibility(UE.ESlateVisibility.Visible)
  self:PlayAnimation(self.BarrageIn02,0,1,UE.EUMGSequencePlayMode.Forward,2,false)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.Forthhandleb)
end

--第四阶段弹幕
function WBP_PreBarrage:ADDForthStageBarrage()

  local widget ,ChildPanel=self:CreatUI()
  ChildPanel:SetAlignment(UE.FVector2D(0.5, 0.5))
  ChildPanel:SetPosition(UE.FVector2D(math.random(-920,920), math.random(-500,500)))
  if self.TextID4 == #NpcBubbleTable+1 then
    self.TextID4=self.ForthBarrageTimes
  end
  local InText=NpcBubbleTable[self.TextID4].barrage_content
  widget:PlayForthAnimation(InText)
  self.TextID4=self.TextID4+1
end

--第四阶段结束
function WBP_PreBarrage:ForthStageFinish()
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ForthFinishthandle)
  self.BeginVanish=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.Vanish},0.02,false)
  self.CloseUI=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.ClosePreBarrage},1,false)
end

--执行群体消失逻辑
function WBP_PreBarrage:Vanish()
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.BeginVanish)
  for i = 1, self.CanvasPanel_Main:GetChildrenCount() do
    local Child=self.CanvasPanel_Main:GetChildAt(i-1)
    local ChildPanel=UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(Child)
    local Position1=ChildPanel:GetPosition()
    if Child.Keeprun then
      Child:Keeprun(Position1.X,Position1.Y)
    end
  end
  self.BarrageInhandle=UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.PlayBarrageOut},0.15,false)
end

function WBP_PreBarrage:PlayBarrageOut()
  self:PlayAnimation(self.BarrageOut01,0,1,UE.EUMGSequencePlayMode.Forward,1,false)
  self:PlayAnimation(self.BarrageOut02,0,1,UE.EUMGSequencePlayMode.Forward,1,false)
  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.BarrageInhandle)
end

function WBP_PreBarrage:AnimOutFinish()
  self.Cvs_Barrage_01:SetVisibility(UE.ESlateVisibility.Hidden)
  self.Cvs_Barrage_02:SetVisibility(UE.ESlateVisibility.Hidden)
end

--关闭UI
function WBP_PreBarrage:ClosePreBarrage()

  UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.CloseUI)
    UIManager:CloseUI(self,true)
end

--创建并初始化弹幕UI
function WBP_PreBarrage:CreatUI()
  local widget = UE.UWidgetBlueprintLibrary.Create(self, self.ItemClass)
  local ChildWidget=self.CanvasPanel_Main:AddChildToCanvas(widget)
  local ChildPanel=ChildWidget:Cast(UE.UCanvasPanelSlot)
  local Anchors = UE.FAnchors()
  Anchors.Minimum = UE.FVector2D(0.5, 0.5)
  Anchors.Maximum = UE.FVector2D(0.5, 0.5)
  ChildPanel:SetAnchors(Anchors)
  return widget,ChildPanel
end


--划分八个不重复随机的区域
function WBP_PreBarrage:SetUIPosition(ChildPanel,locationNumber)
  local PositionX=0 local PositionY=0 local AlignmentX=0 local AlignmentY=0
  local switch = {
    [1] = function() -- 左上
      PositionX=-960+math.random(480) PositionY=-540+math.random(360) AlignmentX=-0.5 AlignmentY=0
    end,
    [7] = function() -- 上
      PositionX=-480+math.random(960) PositionY=-540+math.random(360) AlignmentX=0.5 AlignmentY=0
    end,
    [2] = function() -- 右上
      PositionX=480+math.random(480) PositionY=-540+math.random(360) AlignmentX=1.5 AlignmentY=0
    end,
    [3] = function() -- 左
      PositionX=-960+math.random(480) PositionY=-180+math.random(360) AlignmentX=-0.5 AlignmentY=0.5
    end,
    [4] = function() -- 右
      PositionX=480+math.random(480) PositionY=-180+math.random(360) AlignmentX=1.5 AlignmentY=0.5
    end,
    [5] = function() -- 左下
      PositionX=-960+math.random(480) PositionY=180+math.random(360) AlignmentX=-0.5 AlignmentY=1
    end,
    [8] = function() -- 下
      PositionX=-480+math.random(960) PositionY=180+math.random(360) AlignmentX=0.5 AlignmentY=1
    end,
    [6] = function() -- 右下
      PositionX=480+math.random(480) PositionY=180+math.random(360) AlignmentX=1.5 AlignmentY=1
    end
    }
  local randomPosition=self:GetOneRandomNum(locationNumber)
  local f = switch[randomPosition]
  if(f) then
  f()
  end
  ChildPanel:SetAlignment(UE.FVector2D(AlignmentX, AlignmentY))
  ChildPanel:SetPosition(UE.FVector2D(PositionX, PositionY))
end


--获得一个一到任意之间的不重复随机数
function WBP_PreBarrage:GetOneRandomNum(RanNumber)
  if self.RandomTime==0 then
    self.RDList=self:GetRandomNumList(RanNumber)
  end
  self.RandomTime=self.RandomTime+1
  if self.RandomTime>=RanNumber then
    self.RandomTime=0
  end
  if self.RandomTime==0 then
    return self.RDList[RanNumber]
  else
    return self.RDList[self.RandomTime]
  end
end


--获取不重复随机数表
function WBP_PreBarrage:GetRandomNumList(len)
  local rsList = {}
  for i = 1,len do
      table.insert(rsList,i)
  end
  local num,tmp
  for i = 1,len do
      num = math.random(1,len)
      tmp = rsList[i]
      rsList[i] = rsList[num]
      rsList[num] = tmp   
  end
  return rsList
end

--按类型返回第一句文本的索引
function WBP_PreBarrage:GetindexofType(Type)
  for i = 1, #NpcBubbleTable do
    if NpcBubbleTable[i].type==Type then
    return i
    end
  end
end

return WBP_PreBarrage
