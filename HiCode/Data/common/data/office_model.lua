-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief 事务所换肤表.xlsx/模型换肤表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

M.data = {
    Table_01_Basic = {
        Table_01_Basic = {
            IsBasicMesh = true,
            Index = "Table_01_Basic",
            UnlockItemID = 990010,
            UnlockItemNum = 0,
            ColorUnlockItemID = 990010,
            ColorUnlockItemNum = 10,
            CompName = {"房顶", "屋檐"},
        },
        Table_01_Skin_01 = {
            IsBasicMesh = false,
            Index = "Table_01_Skin_01",
            UnlockItemID = 990010,
            UnlockItemNum = 2000,
            ColorUnlockItemID = 990010,
            ColorUnlockItemNum = 10,
            CompName = {"房顶", "屋檐", "软包"},
        },
        Table_01_Skin_02 = {
            IsBasicMesh = false,
            Index = "Table_01_Skin_02",
            UnlockItemID = 990010,
            UnlockItemNum = 2000,
            ColorUnlockItemID = 990010,
            ColorUnlockItemNum = 10,
            CompName = {"软包", "木料"},
        },
    },
    Office_Test_Group = {
        Office_Test_Group = {
            IsBasicMesh = true,
            Index = "Office_Test_Group",
            UnlockItemID = 990010,
            UnlockItemNum = 0,
            ColorUnlockItemID = 990010,
            ColorUnlockItemNum = 10,
            CompName = {"部件1", "部件2", "部件3"},
        },
        Office_Test_Group_2 = {
            IsBasicMesh = false,
            Index = "Office_Test_Group_2",
            UnlockItemID = 990010,
            UnlockItemNum = 1000,
            ColorUnlockItemID = 990010,
            ColorUnlockItemNum = 10,
            CompName = {"部件1", "部件2", "部件3"},
        },
    },
}

M.extra_data = {}

return M
