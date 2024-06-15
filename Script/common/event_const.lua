

local _M = {}

local ComboEventEnum = {}
ComboEventEnum.KEY_DOWN = 1
ComboEventEnum.KEY_UP = 2
-- ComboPeriod, in this window when pressed, it will have a next combo skill, and will activate in ComboCheck.
ComboEventEnum.PERIOD_START = 3
ComboEventEnum.PERIOD_END = 4

-- ComboCheck, this was the window do things one of below:
-- 1. Check whether activate next combo skill (if have one).
-- 2. do nothing.
ComboEventEnum.CHECK_START = 5
ComboEventEnum.CHECK_END = 6

-- 后摇开始帧，此帧开始后续动画可被打断
ComboEventEnum.COMBO_TAIL = 7

local SkillField = {}
SkillField.ComboSkillID = "combo_skill_id"

-- 技能按键输入类型，对应的按键会读取导表 weapon_data 中相应的技能 id.
-- 和 SkillType 不同.
local SkillInputTypes = {}
SkillInputTypes.NormalSkill = "normal_attack_id"
SkillInputTypes.InAirNormalSkill = "jump_normal_attack_id"
SkillInputTypes.SecondarySkill = "secondary_id"
SkillInputTypes.SuperSkill = "super_skill_id"
SkillInputTypes.BlockSkill = "block_id"
SkillInputTypes.StrikeBackSkill = "strike_back_id"
SkillInputTypes.ChargeSkill = "charge_id"
SkillInputTypes.InAirChargeSkill = "inair_charge_id"

local MoveDir = {}
MoveDir.Forward = 1
MoveDir.Backward = 2
MoveDir.Left = 3
MoveDir.Right = 4

-- Custom movement mode
local CustomMovementModes = {}
CustomMovementModes.Rush = 1
CustomMovementModes.Dodge = 2
CustomMovementModes.Climb = 3
CustomMovementModes.FixedPointJump = 4
CustomMovementModes.Mantle = 5
CustomMovementModes.Skill = 6
CustomMovementModes.Spline = 7
CustomMovementModes.Glide = 8

local InputModes = {}
InputModes.Normal = 1
InputModes.Dodge = 2
InputModes.Climb = 3
InputModes.Skill = 4
InputModes.NormalBuilder = 5
InputModes.SplineBuilder = 6
InputModes.Maduke = 7
InputModes.AreaAbility = 8
InputModes.AreaAbilityUse = 9
InputModes.Ride = 10

local SprintClimbEndReason = {}
SprintClimbEndReason.MantleStart = 1
SprintClimbEndReason.Cancel = 2
SprintClimbEndReason.Reject = 3
SprintClimbEndReason.Break = 4 -- 打断攀爬(来自放技能、受击等，不需要攀爬结束动画)

local InKnockTypes = {}
InKnockTypes.Default = "Default"
InKnockTypes.KnockBack = "KnockBacK"
InKnockTypes.KnockFly = "KnockFly"

local InKnockStackTypes = {}
InKnockStackTypes.Stack = 0
InKnockStackTypes.Reset = 1

---Export
_M.ComboEventEnum = ComboEventEnum
_M.SkillField = SkillField
_M.MinComboSkillCount = 2
_M.MoveDir = MoveDir
_M.CustomMovementModes = CustomMovementModes
_M.InputModes = InputModes
_M.SprintClimbEndReason = SprintClimbEndReason
_M.InKnockTypes = InKnockTypes
_M.InKnockStackTypes = InKnockStackTypes
_M.SkillInputTypes = SkillInputTypes

return _M
