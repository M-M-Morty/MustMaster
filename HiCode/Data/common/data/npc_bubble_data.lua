-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief NPC配置表.xlsx/NPC冒泡配置表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

M.data = {
    [10001] = {
        [1] = {
            type = 1,
            index = 1,
            trigger_interval = 1.1,
            trigger_distance = 3000.0,
            bubble_interval = 1.1,
            content = "NPC冒泡1",
        },
    },
    [10002] = {
        [1] = {
            type = 2,
            index = 1,
            trigger_interval = 2.2,
            trigger_distance = 4000.0,
            bubble_interval = 2.2,
            content = "NPC冒泡2",
        },
    },
    [10003] = {
        [1] = {
            type = 3,
            index = 1,
            content = "NPC临时冒泡",
        },
    },
    [20001] = {
        [1] = {
            type = 2,
            index = 1,
            trigger_interval = 1.1,
            trigger_distance = 3000.0,
            bubble_interval = 1.1,
            RemainTime = 2.0,
            Next_Bubble_Interval = 1.0,
            content = "NPC冒泡1-1",
        },
        [2] = {
            type = 2,
            index = 2,
            trigger_interval = 1.1,
            trigger_distance = 3000.0,
            bubble_interval = 1.1,
            RemainTime = 2.0,
            Next_Bubble_Interval = 8.0,
            content = "NPC冒泡1-2",
        },
    },
    [20002] = {
        [1] = {
            type = 2,
            index = 1,
            trigger_interval = 2.2,
            trigger_distance = 4000.0,
            bubble_interval = 2.2,
            RemainTime = 2.0,
            Next_Bubble_Interval = -1.0,
            content = "NPC冒泡2",
        },
    },
    [20003] = {
        [1] = {
            type = 2,
            index = 1,
            trigger_interval = 2.2,
            trigger_distance = 4000.0,
            bubble_interval = 2.2,
            RemainTime = 2.0,
            Next_Bubble_Interval = 4.0,
            content = "NPC冒泡3",
            Content_Audio = "NPC_Voice_Test_OnHit",
        },
    },
    [20004] = {
        [1] = {
            type = 2,
            index = 1,
            trigger_interval = 2.2,
            trigger_distance = 4000.0,
            bubble_interval = 2.2,
            RemainTime = 2.0,
            Next_Bubble_Interval = -1.0,
            content = "我我我，我是NPC冒泡4",
            Content_Audio = "NPC_Voice_Test_OnHit",
        },
    },
    [20005] = {
        [1] = {
            type = 2,
            index = 1,
            trigger_interval = 2.2,
            trigger_distance = 4000.0,
            bubble_interval = 2.2,
            RemainTime = 2.0,
            Next_Bubble_Interval = -1.0,
            content = "NPC冒泡5",
        },
    },
    [90001] = {
        [1] = {
            type = 3,
            index = 1,
            trigger_interval = 1.0,
            trigger_distance = 3000.0,
            bubble_interval = 5.0,
            content = "太….太吓人了",
        },
    },
    [90002] = {
        [1] = {
            type = 2,
            index = 1,
            trigger_interval = 1.0,
            trigger_distance = 3000.0,
            bubble_interval = 5.0,
            RemainTime = 3.0,
            Next_Bubble_Interval = 2.0,
            content = "天干物燥，小心火烛",
        },
        [2] = {
            type = 2,
            index = 2,
            trigger_interval = 1.0,
            trigger_distance = 3000.0,
            bubble_interval = 5.0,
            RemainTime = 3.0,
            Next_Bubble_Interval = 2.0,
            content = "附近有幽灵出没，请不要与任何人对话",
        },
        [3] = {
            type = 2,
            index = 3,
            trigger_interval = 1.0,
            trigger_distance = 3000.0,
            bubble_interval = 5.0,
            RemainTime = 3.0,
            Next_Bubble_Interval = 10.0,
            content = "如果发现穿蓝色衣服的人，请立刻离开！",
        },
    },
    [90003] = {
        [1] = {
            type = 2,
            index = 1,
            trigger_interval = 1.0,
            trigger_distance = 3000.0,
            bubble_interval = 5.0,
            RemainTime = 3.0,
            Next_Bubble_Interval = 2.0,
            content = "天干物燥，小心火烛",
        },
        [2] = {
            type = 2,
            index = 2,
            trigger_interval = 1.0,
            trigger_distance = 3000.0,
            bubble_interval = 5.0,
            RemainTime = 3.0,
            Next_Bubble_Interval = 2.0,
            content = "附近有幽灵出没，请不要与任何人对话",
        },
        [3] = {
            type = 2,
            index = 3,
            trigger_interval = 1.0,
            trigger_distance = 3000.0,
            bubble_interval = 5.0,
            RemainTime = 3.0,
            Next_Bubble_Interval = 2.0,
            content = "如果发现穿蓝色衣服的人，请立刻离开！",
        },
    },
    [100001] = {
        [1] = {
            type = 3,
            index = 1,
            content = "小…小心！",
        },
    },
}

M.extra_data = {}

return M
