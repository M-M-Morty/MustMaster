-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief 事务所换肤表.xlsx/楼层房间表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

M.data = {
    [1] = {
        Front = {
            Room_Name = "前台",
            Index = "Front",
            Area = {"Front_Reception", "Front_Waiting"},
            Area_Name = {"接待区", "等候区"},
        },
        Business = {
            Room_Name = "办公室",
            Index = "Business",
            Area = {"Business_Visitor", "Business_Analyse", "Business_Reading", "Business_Other"},
            Area_Name = {"会客区", "分析区", "阅读区", "其他"},
        },
    },
}

M.extra_data = {}

return M
