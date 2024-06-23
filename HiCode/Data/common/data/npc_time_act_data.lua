-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief NPC配置表.xlsx/NPC行动表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

--- type
M.idle = 0
M.walk = 1
M.location = 2
--- subtype
M.normal = 0
M.sun = 1
M.rain = 2

M.data = {
    [1001] = {
        [M.sun] = {
            type = M.idle,
            subtype = M.sun,
            normal_anim = "DT_test_idle_sun",
            sp_anim = "DT_test_idlesp_sun",
        },
        [M.rain] = {
            type = M.idle,
            subtype = M.rain,
            normal_anim = "DT_test_idle_rain",
            sp_anim = "DT_test_idlesp_rain",
        },
    },
    [1002] = {
        [M.normal] = {
            type = M.walk,
            subtype = M.normal,
            spline_id = {10001021},
        },
    },
    [1003] = {
        [M.normal] = {
            type = M.location,
            subtype = M.normal,
            location = {1520.0, 800.0, 0.0},
        },
    },
    [1004] = {
        [M.normal] = {
            type = M.location,
            subtype = M.normal,
            location = {1000.0, 1000.0, 0.0},
        },
    },
    [1005] = {
        [M.sun] = {
            type = M.idle,
            subtype = M.sun,
            normal_anim = "DT_id",
            sp_anim = "DT_id3",
        },
    },
    [1006] = {
        [M.rain] = {
            type = M.idle,
            subtype = M.rain,
            normal_anim = "DT_id",
            sp_anim = "DT_id3",
        },
    },
}

M.extra_data = {}

return M
