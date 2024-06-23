-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief 叙事物件表.xlsx/叙事物件表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

--- Type
M.Note = 1
M.Comment = 2
M.RandomEvent = 3

M.data = {
    [100] = {
        Type = M.Note,
        Content = {"NOTE_TITLE_1", "NOTE_CONTENT_1"},
    },
    [1001] = {
        Type = M.Comment,
        Content = {"30000", "Comment_example_01"},
    },
    [1002] = {
        Type = M.Comment,
        Content = {"30000", "Comment_example_02"},
    },
    [1003] = {
        Type = M.Comment,
        Content = {"30000", "Comment_example_03"},
    },
    [1004] = {
        Type = M.Comment,
        Content = {"30000", "Comment_example_04"},
    },
    [2011] = {
        Type = M.RandomEvent,
        Content = {"Mission_RandomEvent_1", "RT_Title_1", "RT_Content_1"},
    },
    [2012] = {
        Type = M.RandomEvent,
        Content = {"Mission_RandomEvent_2", "RT_Title_2", "RT_Content_2"},
    },
    [2013] = {
        Type = M.RandomEvent,
        Content = {"Mission_RandomEvent_3", "RT_Title_3", "RT_Content_3"},
    },
    [2014] = {
        Type = M.RandomEvent,
        Content = {"Mission_RandomEvent_4", "RT_Title_4", "RT_Content_4"},
    },
}

M.extra_data = {}

return M
