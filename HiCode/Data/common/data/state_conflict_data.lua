-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief 状态指令冲突表.xlsx/状态指令冲突表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

--- id
M.Action_Idle = 1
M.Action_Move = 2
M.Action_Jump = 3
M.Action_Skill = 4
M.Action_Dodge = 5
M.Action_JumpInAir = 6
M.Action_InKnock = 7
M.Action_Climb = 8
M.Action_SkillNormal = 9
M.Action_Judge = 10
M.Action_FixedPointJump = 11
M.Action_FixedPointJumpLand = 12
M.Action_SwitchPlayer = 13
M.Action_Sprint = 14
M.Action_Hit = 15
M.Action_Dodge_Immunity = 16
M.Action_Aiming_Mode = 17
M.Action_Lock_Mode = 18
M.Action_Mantle = 19
M.Action_Glide = 20
M.Action_SuperSkill = 21
M.Action_Die = 22
M.Action_SwitchPlayerOut = 23
--- State_Def
M.State_Idle = 1
M.State_Move = 2
M.State_Jump = 3
M.State_ForbidMove = 4
M.State_Skill = 5
M.State_SkillTail = 6
M.State_InAir = 7
M.State_AttackZeroGravity = 8
M.State_HitZeroGravity = 9
M.State_HitFalling = 10
M.State_Dodge = 11
M.State_JumpInAir = 12
M.State_Rush = 13
M.State_InKnock = 14
M.State_WithStand = 15
M.State_MoveWithStand = 16
M.State_Climb = 17
M.State_SkillMovable = 18
M.State_SkillNormal = 19
M.State_Judge = 20
M.State_FixedPointJump = 21
M.State_FixedPointJumpLand = 22
M.State_Aim = 23
M.State_ChargePre = 24
M.State_SkillTail_NotMovable = 25
M.State_Sprint = 26
M.State_Hit = 27
M.State_HitTail = 28
M.State_ForbidSkill = 29
M.State_OnThrowEnd = 30
M.State_Aiming_Mode = 31
M.State_Lock_Mode = 32
M.State_Mantle = 33
M.State_Glide = 34
M.State_SuperSkill = 35
M.State_Die = 36
M.State_DodgeTail = 37
M.State_HitTail_NotMovable = 38
--- Op_Def
M.BREAK = 0
M.CANCEL = 1

M.data = {
    [M.Action_Idle] = {
        ["break"] = {M.State_Move},
        ["cancel"] = {},
        ["enter"] = {M.State_Idle},
    },
    [M.Action_Move] = {
        ["break"] = {M.State_Idle, M.State_SkillTail, M.State_HitTail, M.State_DodgeTail, M.State_OnThrowEnd},
        ["cancel"] = {M.State_ForbidMove, M.State_Skill, M.State_SkillTail_NotMovable, M.State_HitTail_NotMovable, M.State_InAir, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_HitFalling, M.State_InKnock, M.State_WithStand, M.State_SkillNormal, M.State_Judge, M.State_FixedPointJump, M.State_ChargePre, M.State_Hit, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Move},
    },
    [M.Action_Jump] = {
        ["break"] = {M.State_Idle, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_AttackZeroGravity, M.State_HitFalling, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_SkillNormal, M.State_FixedPointJumpLand, M.State_ChargePre},
        ["cancel"] = {M.State_ForbidMove, M.State_Skill, M.State_Dodge, M.State_Judge, M.State_FixedPointJump, M.State_Hit, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_Glide, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Jump},
    },
    [M.Action_Skill] = {
        ["break"] = {M.State_Idle, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_Climb, M.State_SkillNormal, M.State_FixedPointJump, M.State_Sprint, M.State_OnThrowEnd, M.State_Mantle, M.State_Glide},
        ["cancel"] = {M.State_Skill, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_Rush, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_Judge, M.State_ChargePre, M.State_Hit, M.State_ForbidSkill, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {},
    },
    [M.Action_Dodge] = {
        ["break"] = {M.State_Idle, M.State_Move, M.State_Skill, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_Rush, M.State_InKnock, M.State_SkillNormal, M.State_ChargePre, M.State_Glide},
        ["cancel"] = {M.State_ForbidMove, M.State_HitZeroGravity, M.State_Climb, M.State_Judge, M.State_Hit, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_SuperSkill, M.State_Die},
        ["enter"] = {},
    },
    [M.Action_JumpInAir] = {
        ["break"] = {M.State_Idle, M.State_Move, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_SkillNormal, M.State_ChargePre, M.State_Sprint, M.State_Glide},
        ["cancel"] = {M.State_ForbidMove, M.State_Skill, M.State_Judge, M.State_Hit, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_JumpInAir},
    },
    [M.Action_InKnock] = {
        ["break"] = {M.State_Idle, M.State_Move, M.State_Rush, M.State_Sprint, M.State_Mantle, M.State_Glide},
        ["cancel"] = {M.State_Aiming_Mode, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_InKnock},
    },
    [M.Action_Climb] = {
        ["break"] = {M.State_Idle, M.State_Move, M.State_Jump, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_Dodge, M.State_Glide},
        ["cancel"] = {M.State_Skill, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_SkillNormal, M.State_Judge, M.State_Aim, M.State_ChargePre, M.State_Hit, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Climb},
    },
    [M.Action_SkillNormal] = {
        ["break"] = {M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_Climb, M.State_FixedPointJump, M.State_Sprint, M.State_OnThrowEnd, M.State_Mantle, M.State_Glide},
        ["cancel"] = {M.State_Skill, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_Rush, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_Judge, M.State_Aim, M.State_Hit, M.State_ForbidSkill, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {},
    },
    [M.Action_Judge] = {
        ["break"] = {M.State_Idle, M.State_Move, M.State_Jump, M.State_ForbidMove, M.State_Skill, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_InAir, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_JumpInAir, M.State_Rush, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_Climb, M.State_SkillMovable, M.State_SkillNormal, M.State_FixedPointJump, M.State_FixedPointJumpLand, M.State_Aim, M.State_ChargePre, M.State_Sprint, M.State_Hit, M.State_ForbidSkill, M.State_OnThrowEnd, M.State_Mantle, M.State_Glide},
        ["cancel"] = {M.State_Judge, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Judge},
    },
    [M.Action_FixedPointJump] = {
        ["break"] = {M.State_Move, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_Sprint, M.State_Glide},
        ["cancel"] = {M.State_Judge, M.State_FixedPointJump, M.State_ChargePre, M.State_Hit, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_FixedPointJump},
    },
    [M.Action_FixedPointJumpLand] = {
        ["break"] = {M.State_Move, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_DodgeTail, M.State_Sprint, M.State_Glide},
        ["cancel"] = {M.State_Judge, M.State_ChargePre, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_FixedPointJumpLand},
    },
    [M.Action_SwitchPlayer] = {
        ["break"] = {M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_WithStand, M.State_MoveWithStand, M.State_SkillMovable, M.State_Aim, M.State_ChargePre, M.State_Sprint},
        ["cancel"] = {M.State_ForbidMove, M.State_Dodge, M.State_Rush, M.State_Climb, M.State_Judge, M.State_OnThrowEnd, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_Glide, M.State_SuperSkill, M.State_Die},
        ["enter"] = {},
    },
    [M.Action_Sprint] = {
        ["break"] = {M.State_Idle, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail},
        ["cancel"] = {M.State_ForbidMove, M.State_Skill, M.State_InAir, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_HitFalling, M.State_InKnock, M.State_WithStand, M.State_SkillNormal, M.State_Judge, M.State_FixedPointJump, M.State_ChargePre, M.State_Hit, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_Glide, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Sprint},
    },
    [M.Action_Hit] = {
        ["break"] = {M.State_Move, M.State_Jump, M.State_ForbidMove, M.State_Skill, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_InAir, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_JumpInAir, M.State_Rush, M.State_WithStand, M.State_MoveWithStand, M.State_Climb, M.State_SkillMovable, M.State_SkillNormal, M.State_FixedPointJumpLand, M.State_ChargePre, M.State_Sprint, M.State_Mantle, M.State_Glide},
        ["cancel"] = {M.State_Judge, M.State_FixedPointJump, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Hit},
    },
    [M.Action_Dodge_Immunity] = {
        ["break"] = {M.State_Idle, M.State_Move, M.State_Skill, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_HitZeroGravity, M.State_InKnock, M.State_SkillNormal, M.State_ChargePre, M.State_Hit, M.State_Mantle, M.State_Glide},
        ["cancel"] = {M.State_Climb, M.State_Judge, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {},
    },
    [M.Action_Aiming_Mode] = {
        ["break"] = {M.State_Idle, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_ForbidSkill},
        ["cancel"] = {M.State_Jump, M.State_Skill, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_JumpInAir, M.State_Rush, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_Climb, M.State_SkillNormal, M.State_Judge, M.State_ChargePre, M.State_Hit, M.State_OnThrowEnd, M.State_Mantle, M.State_Glide, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Aiming_Mode},
    },
    [M.Action_Lock_Mode] = {
        ["break"] = {M.State_Idle, M.State_Move, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_ForbidSkill},
        ["cancel"] = {M.State_Jump, M.State_Skill, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_JumpInAir, M.State_Rush, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_Climb, M.State_SkillNormal, M.State_ChargePre, M.State_Hit, M.State_OnThrowEnd, M.State_Mantle, M.State_Glide, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Lock_Mode},
    },
    [M.Action_Mantle] = {
        ["break"] = {M.State_Idle, M.State_Jump, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_HitZeroGravity, M.State_ForbidSkill, M.State_Glide},
        ["cancel"] = {M.State_Skill, M.State_InKnock, M.State_SkillNormal, M.State_Judge, M.State_ChargePre, M.State_Hit, M.State_OnThrowEnd, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Mantle},
    },
    [M.Action_Glide] = {
        ["break"] = {M.State_Idle, M.State_Jump, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_JumpInAir, M.State_WithStand, M.State_MoveWithStand, M.State_ForbidSkill},
        ["cancel"] = {M.State_Skill, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_InKnock, M.State_Climb, M.State_SkillNormal, M.State_Judge, M.State_FixedPointJump, M.State_FixedPointJumpLand, M.State_Aim, M.State_ChargePre, M.State_Hit, M.State_OnThrowEnd, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_Glide, M.State_SuperSkill, M.State_Die},
        ["enter"] = {M.State_Glide},
    },
    [M.Action_SuperSkill] = {
        ["break"] = {M.State_Idle, M.State_Move, M.State_Jump, M.State_ForbidMove, M.State_Skill, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_InAir, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_JumpInAir, M.State_Rush, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_Climb, M.State_SkillMovable, M.State_SkillNormal, M.State_ChargePre, M.State_Sprint, M.State_Hit, M.State_OnThrowEnd, M.State_Mantle, M.State_Glide},
        ["cancel"] = {M.State_Judge, M.State_FixedPointJump, M.State_FixedPointJumpLand, M.State_ForbidSkill, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_SuperSkill, M.State_Die},
        ["enter"] = {},
    },
    [M.Action_Die] = {
        ["break"] = {M.State_Idle, M.State_Move, M.State_Jump, M.State_ForbidMove, M.State_Skill, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_InAir, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_JumpInAir, M.State_Rush, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_Climb, M.State_SkillMovable, M.State_SkillNormal, M.State_Judge, M.State_FixedPointJump, M.State_FixedPointJumpLand, M.State_Aim, M.State_ChargePre, M.State_Sprint, M.State_Hit, M.State_ForbidSkill, M.State_OnThrowEnd, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_Glide, M.State_SuperSkill, M.State_Die},
        ["cancel"] = {},
        ["enter"] = {M.State_Die},
    },
    [M.Action_SwitchPlayerOut] = {
        ["break"] = {M.State_Move, M.State_Jump, M.State_ForbidMove, M.State_Skill, M.State_SkillTail, M.State_SkillTail_NotMovable, M.State_HitTail, M.State_HitTail_NotMovable, M.State_DodgeTail, M.State_InAir, M.State_AttackZeroGravity, M.State_HitZeroGravity, M.State_HitFalling, M.State_Dodge, M.State_JumpInAir, M.State_Rush, M.State_InKnock, M.State_WithStand, M.State_MoveWithStand, M.State_Climb, M.State_SkillMovable, M.State_SkillNormal, M.State_FixedPointJump, M.State_FixedPointJumpLand, M.State_Aim, M.State_ChargePre, M.State_Sprint, M.State_Hit, M.State_ForbidSkill, M.State_OnThrowEnd, M.State_Aiming_Mode, M.State_Lock_Mode, M.State_Mantle, M.State_Glide, M.State_SuperSkill},
        ["cancel"] = {M.State_Judge, M.State_Die},
        ["enter"] = {M.State_Idle},
    },
}

M.extra_data = {
    states = {
        [1] = "State_Idle",
        [2] = "State_Move",
        [3] = "State_Jump",
        [4] = "State_ForbidMove",
        [5] = "State_Skill",
        [6] = "State_SkillTail",
        [7] = "State_InAir",
        [8] = "State_AttackZeroGravity",
        [9] = "State_HitZeroGravity",
        [10] = "State_HitFalling",
        [11] = "State_Dodge",
        [12] = "State_JumpInAir",
        [13] = "State_Rush",
        [14] = "State_InKnock",
        [15] = "State_WithStand",
        [16] = "State_MoveWithStand",
        [17] = "State_Climb",
        [18] = "State_SkillMovable",
        [19] = "State_SkillNormal",
        [20] = "State_Judge",
        [21] = "State_FixedPointJump",
        [22] = "State_FixedPointJumpLand",
        [23] = "State_Aim",
        [24] = "State_ChargePre",
        [25] = "State_SkillTail_NotMovable",
        [26] = "State_Sprint",
        [27] = "State_Hit",
        [28] = "State_HitTail",
        [29] = "State_ForbidSkill",
        [30] = "State_OnThrowEnd",
        [31] = "State_Aiming_Mode",
        [32] = "State_Lock_Mode",
        [33] = "State_Mantle",
        [34] = "State_Glide",
        [35] = "State_SuperSkill",
        [36] = "State_Die",
        [37] = "State_DodgeTail",
        [38] = "State_HitTail_NotMovable",
    },
    actions = {
        [1] = "Action_Idle",
        [2] = "Action_Move",
        [3] = "Action_Jump",
        [4] = "Action_Skill",
        [5] = "Action_Dodge",
        [6] = "Action_JumpInAir",
        [7] = "Action_InKnock",
        [8] = "Action_Climb",
        [9] = "Action_SkillNormal",
        [10] = "Action_Judge",
        [11] = "Action_FixedPointJump",
        [12] = "Action_FixedPointJumpLand",
        [13] = "Action_SwitchPlayer",
        [14] = "Action_Sprint",
        [15] = "Action_Hit",
        [16] = "Action_Dodge_Immunity",
        [17] = "Action_Aiming_Mode",
        [18] = "Action_Lock_Mode",
        [19] = "Action_Mantle",
        [20] = "Action_Glide",
        [21] = "Action_SuperSkill",
        [22] = "Action_Die",
        [23] = "Action_SwitchPlayerOut",
    },
}

return M
