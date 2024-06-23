-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief 物品配置表.xlsx/背包页签表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

M.data = {
    [1] = {
        tab_name = "BAG_TAB_NAME_1",
        tab_switch = true,
        tab_icon = "BAG_TAB_ICON_1",
        capacity = 1000,
        item_categories = {11, 12},
    },
    [2] = {
        tab_name = "BAG_TAB_NAME_2",
        tab_switch = true,
        tab_icon = "BAG_TAB_ICON_2",
        capacity = 1000,
        item_categories = {13, 14},
    },
    [3] = {
        tab_name = "BAG_TAB_NAME_3",
        tab_switch = true,
        tab_icon = "BAG_TAB_ICON_3",
        capacity = 1000,
        item_categories = {16, 17},
    },
    [4] = {
        tab_name = "BAG_TAB_NAME_4",
        tab_switch = true,
        tab_icon = "BAG_TAB_ICON_4",
        capacity = 1000,
        item_categories = {15},
    },
    [5] = {
        tab_name = "BAG_TAB_NAME_5",
        tab_switch = true,
        tab_icon = "BAG_TAB_ICON_5",
        capacity = 1000,
        item_categories = {18},
    },
    [6] = {
        tab_name = "BAG_TAB_NAME_6",
        tab_switch = true,
        tab_icon = "BAG_TAB_ICON_6",
        capacity = 1000,
        item_categories = {19},
    },
    [99999] = {
        tab_switch = false,
        capacity = 99999,
        item_categories = {10, 21, 22, 23},
    },
}

M.extra_data = {}

return M
