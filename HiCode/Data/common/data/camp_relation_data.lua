-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief 阵营关系表.xlsx/阵营关系表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

--- id
M.CampMonster_Common = "CampMonster_Common"
M.CampMonster_Summoned = "CampMonster_Summoned"
M.CampNPC = "CampNPC"
M.CampObjects_Attackable = "CampObjects_Attackable"
M.CampPlayer = "CampPlayer"
--- Rel_Def
M.Enemy = 1
M.Ally = 2
M.Neutral = 3

M.data = {
    [M.CampPlayer] = {
        CampPlayer = M.Ally,
        CampMonster_Common = M.Enemy,
        CampMonster_Summoned = M.Ally,
        CampNPC = M.Neutral,
        CampObjects_Attackable = M.Enemy,
    },
    [M.CampMonster_Common] = {
        CampMonster_Common = M.Ally,
        CampMonster_Summoned = M.Enemy,
        CampNPC = M.Neutral,
        CampObjects_Attackable = M.Neutral,
    },
    [M.CampMonster_Summoned] = {
        CampMonster_Summoned = M.Ally,
        CampNPC = M.Neutral,
        CampObjects_Attackable = M.Neutral,
    },
    [M.CampNPC] = {
        CampNPC = M.Ally,
        CampObjects_Attackable = M.Neutral,
    },
    [M.CampObjects_Attackable] = {
        CampObjects_Attackable = M.Ally,
    },
}

M.extra_data = {}

return M
