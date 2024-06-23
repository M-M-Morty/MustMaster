
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')


-- 任务追踪------------------------------------------------------------------------------------------------------------------------------
-- 任务追踪 Widget接口定义
local MissionTrackWidgetSample = Class()
--- 绑定一个任务对象，根据任务对象的当前状态初始化Widget
---@param Mission mission_system_sample.MissionObject 任务对象
---@param bIsNew bool 是否新增任务
function MissionTrackWidgetSample:BindMission(Mission, bIsNew)
    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    self.HudTrackingMission = TaskMainVM.HudTrackingMission
    self.HudTrackingMission:BindMission(Mission, bIsNew)
end
--- 开始追踪任务
function MissionTrackWidgetSample:OnMissionTracked()
    if self.HudTrackingMission then
        self.HudTrackingMission:OnMissionTracked()
    end
end
--- 任务进度发生变化
function MissionTrackWidgetSample:OnMissionProgressUpdate()
    if self.HudTrackingMission then
        self.HudTrackingMission:OnMissionProgressUpdate()
    end
end
--- 任务距离发生变化
function MissionTrackWidgetSample:OnMissionDistanceUpdate()
    if self.HudTrackingMission then
        self.HudTrackingMission:OnMissionDistanceUpdate()
    end
end
--- 任务结束
function MissionTrackWidgetSample:OnMissionFinish()
    if self.HudTrackingMission then
        self.HudTrackingMission:OnMissionFinish()
    end
end
--- 解绑当前的任务对象
function MissionTrackWidgetSample:UnbindMission()
    if self.HudTrackingMission then
        self.HudTrackingMission:UnbindMission()
    end
end
--- 注册回调：当任务设置为auto track时，Bind之后2秒不操作回调。Widget内部不需要自行切换状态，外部逻辑将在回调中调用Widget.TrackMission进行状态切换
---@param Callback function()
function MissionTrackWidgetSample:RegisterAutoTrackCallback(Callback)
end
--- 注册回调：当任务设置为not auto track时，Bind之后2秒不操作回调。Widget内部不需要自行切换状态，外部逻辑将在回调中调用UnbindMission进行状态切换
---@param Callback function()
function MissionTrackWidgetSample:RegisterUntrackCallback(Callback)
end
--- 注册回调：当任务完成动效播放完时调用。Widget内部不需要自行切换状态，外部逻辑将在回调中使用BindMission切换到其他任务
---@param Callback function()
function MissionTrackWidgetSample:RegisterMissionFinishCallback(Callback)
end


-- 任务指针------------------------------------------------------------------------------------------------------------------------------
-- 任务指针 Widget接口定义
local MissionArrowWidgetSample = Class()
--- 设置任务指针在屏幕中的位置
---@param Position UE.FVector2D()
function MissionArrowWidgetSample:SetPositionInScreen(Position)
end
--- 显示方向箭头，并设置朝向
---@param Angle float 单位为弧度
function MissionArrowWidgetSample:ShowArrow(Angle)
end
--- 隐藏方向箭头
function MissionArrowWidgetSample:HideArrow()
end
--- 设置任务指针的距离数值，为0时不显示
---@param Distance integer
function MissionArrowWidgetSample:SetDistance(Distance)
end

-- Npc头顶标识 Widget接口定义
local NpcTopWidgetSample = Class()
--- 播放碎碎念内容
---@param Content string
function NpcTopWidgetSample:DisplaySelfTalking(Content)
end
--- 显示/隐藏任务指针
---@param bShow bool
function NpcTopWidgetSample:ShowArrow(bShow)
end
--- 注册回调：当碎碎念播放完成消失时调用
---@param Callback function()
function NpcTopWidgetSample:RegisterSelfTalkingEndCallback(Callback)
end



--- deprecated
-- local MissionArrowWidgetInVisionSample = Class()
-- --- 设置任务指针在屏幕中的位置
-- ---@param Position UE.FVector2D()
-- function MissionArrowWidgetInVisionSample:SetPositionInScreen(Position)
-- end
-- --- 设置任务指针的距离数值，为0时不显示
-- ---@param Distance integer
-- function MissionArrowWidgetInVisionSample:SetDistance(Distance)
-- end
-- --- 播放碎碎念内容
-- ---@param Content string
-- function MissionArrowWidgetInVisionSample:DisplaySelfTalking(Content)
-- end
-- --- 注册回调：当碎碎念播放完成消失时调用
-- ---@param Callback function()
-- function MissionArrowWidgetInVisionSample:RegisterSelfTalkingEndCallback(Callback)
-- end

--- deprecated
-- local MissionArrowWidgetOutVisionSample = Class()
-- --- 设置任务指针在屏幕中的位置和箭头朝向
-- ---@param Position UE.FVector2D()
-- ---@param Angle float 单位为弧度
-- function MissionArrowWidgetOutVisionSample:SetPositionAndRotationInScreen(Position, Angle)
-- end


-- 互动区------------------------------------------------------------------------------------------------------------------------------
-- 互动区 Widget接口定义
local MissionInteractAreaWidgetSample = Class()
--- 设置互动区Item列表
---@param Items array{mission_system_sample.MissionInteractItem}
function MissionInteractAreaWidgetSample:SetInteractItems(Items)
end
--- 注册回调：当其中一个按钮被按下时调用，对于需要长按的选项，则在长按结束后调用。外部逻辑将在回调中决定是否关闭widget
---@param Callback function(mission_system_sample.MissionInteractItem)  回调参数为被按下的按钮对应的Item
function MissionInteractAreaWidgetSample:RegisterInteractItemPressedCallback(Callback)
end


-- 物品展示------------------------------------------------------------------------------------------------------------------------------
-- 单个物品展示 Widget接口定义
local ItemDisplayWidgetSample = Class()
--- 设置物品数据
---@param Item: mission_system_sample.Item
function ItemDisplayWidgetSample:SetItem(Item)
end

-- 获得物品提示区
local ItemDisplayListWidgetSample = Class()
--- 设置物品数据
---@param ItemList: array{mission_system_sample.Item}
function ItemDisplayListWidgetSample:PushItemList(ItemList)
end

-- 任务章节解锁完成提示 -------------------------------------------------------------------------------------------------------------------
--- 任务章节解锁完成提示 Widget接口定义
local MissionFinishWidgetSample = Class()
--- 设置解锁完成信息
---@param FinishData mission_system_sample.MissionFinishInfo
function MissionFinishWidgetSample:SetFinishData(FinishData)
end

-- 通用提示 ------------------------------------------------------------------------------------------------------------------------------
-- 各种通用提示Widget统一接口：需要支持富文本
local TipsWidgetSample = Class()
--- 通用提示
---@param Content string
function TipsWidgetSample:DisplayTips(Content)
end

-- 对话内容 ------------------------------------------------------------------------------------------------------------------------------
-- 对话Widget接口定义
local DialogueWidgetSample = Class()
--- 开始一段对话
---@param Dialogue mission_system_sample.Dialogues
function DialogueWidgetSample:StartDialogue(Dialogues)
end

--- 注册回调：对话结束
---@param Callback function()
function DialogueWidgetSample:RegisterFinishCallback(Callback)
end

-- 任务界面 ------------------------------------------------------------------------------------------------------------------------------
local MissionListWidgetSample = Class()
--- 任务列表展示：左侧任务列表按照(MissionGroupID,MissionActID)进行分组
---@param MissionList array{mission_system_sample.MissionObject}
function MissionListWidgetSample:SetMissionList(MissionList)
end

--- 注册回调：追踪
---@param Callback function(mission_system_sample.MissionObject)  回调参数为追踪的任务Object
function MissionListWidgetSample:RegisterTrackCallback(Callback)
end

--- 注册回调：取消追踪
---@param Callback function(mission_system_sample.MissionObject)  回调参数为取消追踪的任务Object
function MissionListWidgetSample:RegisterUntrackCallback(Callback)
end


local M = {}
M.MissionTrackWidget = MissionTrackWidgetSample
-- M.MissionArrowWidgetInVision = MissionArrowWidgetInVisionSample
-- M.MissionArrowWidgetOutVision = MissionArrowWidgetOutVisionSample
M.MissionArrowWidget = MissionArrowWidgetSample
M.NpcTopWidget = NpcTopWidgetSample
M.MissionInteractAreaWidget = MissionInteractAreaWidgetSample
M.ItemDisplayWidget = ItemDisplayWidgetSample
M.ItemListDisplayWidget = ItemDisplayListWidgetSample
M.MissionFinishWidget = MissionFinishWidgetSample
M.DialogueWidget = DialogueWidgetSample
M.MissionListWidget = MissionListWidgetSample
return M
