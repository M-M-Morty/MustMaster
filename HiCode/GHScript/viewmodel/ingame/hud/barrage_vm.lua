

local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local DialogueObjectModule = require("mission.dialogue_object")

local cast_and_crew_data = nil
local cast_crew_group_data = nil
pcall(function()
    cast_and_crew_data = require("common.data.cast_and_crew_data").data
    cast_crew_group_data = require("common.data.cast_crew_group_data").data
end)

---@class BarrageVM : ViewModelBase
local BarrageVM = Class(ViewModelBaseClass)

---@enum EBrgMotion
---@field Roll 滚动
---@field Vertical 竖屏
---@field Boom 爆炸
BarrageVM.EBrgMotion = {
    Roll = 1,
    Vertical = 2,
    Boom = 3,
}

---@enum EBrgStyle
---@field First 第一幕
---@field Second 第二幕
---@field Third 第三幕
---@field Forth 第四幕
BarrageVM.EBrgStyle = {
    First = 1,
    Second = 2,
    Third = 3,
    Fourth = 4,
}

function BarrageVM:ctor()
end

---@class BarrageStage 一个弹幕任务
---@field Content table<string> 弹幕的文本内容为字符串数组
---@field Delay number @[opt] 执行延迟
---@field Interval number @[opt] 出现间隔
---@field Frequency number @[opt] 重复次数
---@field LifeTime number @[opt] 单个弹幕的存活时间
---@field Speed number @[opt] 滚动速度(仅滚动弹幕有效)
---@field EndTime number @[opt] 这匹弹幕的结束时间(以执行延迟结束后开始算起)
local BarrageStage = {}

---`brief` 打开弹幕界面
---`notice` 一期弹幕功能参数四个阶段固定运动方式为白色滚动,红色滚动,竖屏,炸屏
---@param Stag1 BarrageStage
---@param Stag2 BarrageStage
---@param Stag3 BarrageStage
---@param Stag4 BarrageStage
function BarrageVM:OpenBrgSeq4(Stag1, Stag2, Stag3, Stag4)
    G.log:debug("zys", "BarrageVM:OpenBrgWnd()")
    local UI = UIManager:OpenUI(UIDef.UIInfo.UI_Barrage)
    if UI then
        UI:CreateBossBrgSequence(Stag1, Stag2, Stag3, Stag4)
    end
end

---`brief`关闭弹幕界面
function BarrageVM:CloseBrgWnd()
    G.log:debug("zys", "BarrageVM:CloseBrgWnd()")
    UIManager:CloseUIByName(UIDef.UIInfo.UI_Barrage.UIName, true)
end

---`brief`打开演职员表
---@param Content table
function BarrageVM:OpenScreenCreditList()
    G.log:debug("zys", "BarrageVM:OpenScreenCreditList()")
    if not cast_and_crew_data or not  cast_crew_group_data then
        G.log:debug('zys][credit list', "error: failed to read config list !!!")
        return
    end
    local UI = UIManager:OpenUI(UIDef.UIInfo.UI_ScreenCreditList)
    if UI then
        local Content = {}
        local CurGroupIndex = nil
        local CurGroup = nil
        for k,v in pairs(cast_and_crew_data) do
            if (not CurGroupIndex) or (v.cast_crew_group ~= CurGroupIndex) then
                CurGroup = {Content = {}}
                CurGroupIndex = v.cast_crew_group
                CurGroup.GroupName = cast_crew_group_data[CurGroupIndex].group_name
                table.insert(Content, CurGroup)
            else
                table.insert(CurGroup.Content, {Name = v.cast_crew_name, Entry = ''})
            end
        end
        UI:ShowScreenCreditList(Content)
    end
end

---`brief`关闭演职员表
function BarrageVM:CloseScreenCreditList()
    G.log:debug("zys", "BarrageVM:CloseScreenCreditList()")
    UIManager:CloseUIByName(UIDef.UIInfo.UI_ScreenCreditList.UIName, true)
end

return BarrageVM