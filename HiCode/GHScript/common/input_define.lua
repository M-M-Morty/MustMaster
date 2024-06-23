--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local tb = {}

-- 绑定的按键名称，参考EKeys下的命名
tb.Keys =
{
    LeftAlt = 'LeftAlt',
    MouseScrollUp = 'MouseScrollUp',
    MouseScrollDown = 'MouseScrollDown',
    RightMouseButton = 'RightMouseButton',


    F = 'F',
    E = 'E',
    J = 'J',
    V = 'V',
    X = 'X',
    G = 'G',
    Z = 'Z',
    L = 'L',
    Q = 'Q',
    M = 'M',
    SpaceBar = 'SpaceBar',
    One = "One",
    Three = "Three",
    Five = "Five",
}

tb.Actions =
{
    InteractAction = 'InteractAction',                   -- 交互Action，默认F键
    UIScrollAction = 'UIScrollAction',                   -- UI滚动Action，默认鼠标滚轮
    OpenMissionMainUIAction = 'OpenMissionMainUIAction', -- 打开任务面板Action，默认J键
    ReleaseMouseAction = "ReleaseMouseAction",           -- 释放鼠标Action，默认左Alt键
    TrackMissionAction = "TrackMissionAction",           -- 追踪任务Action，默认V键，额外加X键方便光恒测试
    HUDTestAction = "HUDTestAction",                     -- 光恒HUD测试快捷键，默认E键
    SuperSkillAction = "SuperSkillAction",               -- 大招
    SecondarySkillAction = "SecondarySkillAction",       -- 二技能
    AimAction = "AimAction",                             -- 右击
    CloseAreaAbilityAction = "CloseAreaAbilityAction",   -- 区域能力、复制器、马杜克灯界面关闭按钮
    OpenAreaAbilityAction = "OpenAreaAbilityAction",     -- 区域能力打开按钮
    OpenCopyAbilityAction = "OpenCopyAbilityAction",      -- 复制器界面打开按钮
    OpenMapUIAction = 'OpenMapUIAction'                  -- 打开地图面板Action，默认M键
}

local KeyNameActionMapping =
{
    [tb.Keys.LeftAlt] = tb.Actions.ReleaseMouseAction,
    [tb.Keys.F] = tb.Actions.InteractAction,
    [tb.Keys.E] = tb.Actions.HUDTestAction,
    [tb.Keys.J] = tb.Actions.OpenMissionMainUIAction,
    [tb.Keys.X] = tb.Actions.CloseAreaAbilityAction,
    [tb.Keys.G] = tb.Actions.OpenAreaAbilityAction,
    [tb.Keys.Z] = tb.Actions.OpenCopyAbilityAction,
    [tb.Keys.V] = tb.Actions.TrackMissionAction,
    [tb.Keys.Q] = tb.Actions.SuperSkillAction,
    [tb.Keys.M] = tb.Actions.OpenMapUIAction,
    [tb.Keys.RightMouseButton] = tb.Actions.AimAction,
}

function tb:IsAction(InputName, ActionName)
    if InputName == ActionName then
        return true
    end

    -- 不是一个ActionName，那么则为从UI来的KeyName
    if KeyNameActionMapping[InputName] == ActionName then
        return true
    end
end

function tb:ActionNameToKeyName(InActionName)
    for KeyName, ActionName in pairs(KeyNameActionMapping) do
        if ActionName == InActionName then
            return KeyName
        end
    end
    return ''
end

return tb
