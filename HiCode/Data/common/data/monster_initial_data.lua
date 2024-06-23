-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2023 Tencent Inc. All rights reserved.
--- @brief 怪物表.xlsx/怪物初始数据表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

M.data = {
    [10002] = {
        name = "近战怪",
    },
    [10003] = {
        name = "远程怪",
    },
    [10004] = {
        name = "盾牌怪",
    },
    [10007] = {
        name = "金刚",
        weapon_id = 1001,
    },
    [10008] = {
        name = "空中怪",
    },
    [10009] = {
        name = "蒸汽BOSS",
        weapon_id = 1003,
    },
    [10010] = {
        name = "里卡多",
        hero_path = "/Game/Character/Monster/Boss_Riccardo/Blueprints/BP_Boss_Riccardo.BP_Boss_Riccardo_C",
        weapon_id = 1001001,
    },
    [10011] = {
        name = "pika",
        hero_path = "/Game/Character/Monster/SK_Monster_Pika_BasicBody/Blueprints/BPA_Pika.BPA_Pika_C",
    },
    [10012] = {
        name = "气球pika",
        hero_path = "/Game/Character/Monster/Pika_Balloon/Blueprints/BPA_Pika_Balloon.BPA_Pika_Balloon_C",
    },
}

M.extra_data = {}

return M
