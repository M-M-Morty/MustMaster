-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief 任务基础配置表.xlsx/任务配置表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

M.data = {
    [1001] = {
        Name = "任务1",
        ForceTrace = true,
        Descript = "再次被线索领到了奔狼领。这枚钩钩果种子是否真的就是铁证，雷泽和他的狼群是否就是袭击的罪魁祸首？然后，钩钩果其实还有另外的意义…",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
        PreMissionAct = {1002},
        PreMission = {1002},
    },
    [1002] = {
        Name = "任务2",
        ForceTrace = true,
        Descript = "找到巨龙",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
        PreMissionAct = {1001, 1003},
        PreMission = {1001, 1003},
    },
    [1003] = {
        Name = "确认委托",
        ForceTrace = true,
        Descript = "来自法恩的一名气象研究员Juicy意外失踪，你接到委托去寻找她。",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
    },
    [1004] = {
        Name = "前往农庄",
        ForceTrace = true,
        Descript = "前边有个农庄，也许会有研究员的线索，过去打听打听。",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
    },
    [1005] = {
        Name = "前往圣堂遗迹",
        ForceTrace = true,
        Descript = "研究员在地图上标记了山顶的圣堂遗迹，她会出现在那个地方吗？",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
    },
    [1006] = {
        Name = "寻找研究员",
        ForceTrace = true,
        Descript = "来自法恩的一名气象研究员朱茜在奥兹谷意外失踪，你接到她的同伴伍迪的委托去寻找她。",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
    },
    [1007] = {
        Name = "解救研究员",
        ForceTrace = true,
        Descript = "从奥兹谷的电视柱上发现了研究员朱茜，她莫名其妙地被关进了电视中，根据研究员伍迪的线索，想办法找到蓝色的电波幽灵将其解救出来吧。",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
        IsHide = true,
    },
    [1008] = {
        Name = "回到农庄",
        ForceTrace = true,
        Descript = "找到了研究员Juicy，可是她好像很着急要回农庄去做一件事情，会和蓝晶有关吗？",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
    },
    [1009] = {
        Name = "寻找矮坡旁的电波幽灵",
        ForceTrace = true,
        Descript = "电波幽灵四散而逃，似乎有一只跑到了矿车轨道的矮坡旁，能否顺利找到它呢？",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
    },
    [1010] = {
        Name = "寻找高塔下的电波幽灵",
        ForceTrace = true,
        Descript = "电波幽灵四散而逃，似乎有一只钻到了电视塔地下，该怎么下去呢？",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
    },
    [1011] = {
        Name = "寻找矿坑中的电波幽灵",
        ForceTrace = true,
        Descript = "电波幽灵四散而逃，似乎有一只往崩塌的矿洞跑去了，快快追上去吧！",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
            [100002] = 5000,
        },
    },
    [9001] = {
        Name = "任务1-A",
        ForceTrace = true,
        Descript = "该任务为主线剧幕1中的任务A，无前置任务，需要与NPC1对话，再与NPC5对话后产出宝箱",
        Type = 1,
        RewardItems = {
            [110001] = 1,
            [100002] = 10,
            [170003] = 5,
            [170004] = 1,
            [180006] = 1,
            [190002] = 2,
            [990010] = 3000,
        },
    },
    [9002] = {
        Name = "任务2-B",
        ForceTrace = true,
        Descript = "该任务为主线剧幕2中的任务B，前置任务为任务2-A和剧幕1，需要攻击2个pika",
        Type = 1,
        RewardItems = {},
        PreMissionAct = {9001},
        PreMission = {9002},
    },
    [9003] = {
        Name = "任务2-A",
        ForceTrace = true,
        Descript = "该任务为主线剧幕2中的任务A，无前置任务，需要与NPC2对话，且NPC2在对话完成后播放气泡文字，再播放一段自言自语",
        Type = 1,
        RewardItems = {
            [170003] = 5,
            [170004] = 1,
        },
    },
    [9004] = {
        Name = "任务3-A",
        ForceTrace = true,
        Descript = "该任务为主线剧幕3中的任务A，该任务隐藏面板提示，触发到圆形区域就完成",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
        IsHide = true,
    },
    [9005] = {
        Name = "任务3-B",
        ForceTrace = true,
        Descript = "该任务为主线剧幕3中的任务B，前置任务为剧幕2的任务A，与NPC3对话",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
        PreMission = {9003},
    },
    [9006] = {
        Name = "任务3-C",
        ForceTrace = true,
        Descript = "该任务为主线剧幕3中的任务C，无前置任务，与NPC4对话",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9007] = {
        Name = "任务4-A",
        ForceTrace = true,
        Descript = "该任务为主线剧幕4中的任务A，前置为剧幕2和3，需要采摘花",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
        PreMissionAct = {9002, 9003},
    },
    [9008] = {
        Name = "任务5-A",
        ForceTrace = true,
        Descript = "该任务为支线剧幕5中的任务A，同样与NPC1对话，与主线剧幕1使用同一个NPC",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9009] = {
        Name = "引导任务",
        ForceTrace = true,
        Descript = "该任务为单个任务（模拟引导），采摘花",
        Type = 4,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9010] = {
        Name = "日常任务",
        ForceTrace = true,
        Descript = "该任务为单个任务（模拟日常），需要击败2个pika，然后采摘花",
        Type = 3,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9011] = {
        Name = "惊恐时刻02",
        ForceTrace = true,
        Descript = "旅店住客惶恐不安，似乎被什么东西吓到了，快去探查一下",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9012] = {
        Name = "赶鸡测试任务",
        ForceTrace = true,
        Descript = "赶鸡",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9013] = {
        Name = "音游测试任务",
        ForceTrace = true,
        Descript = "音游",
        Type = 3,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9021] = {
        Name = "惊恐时刻03",
        ForceTrace = true,
        Descript = "旅店住客惶恐不安，似乎被什么东西吓到了，快去探查一下",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9031] = {
        Name = "惊恐时刻04",
        ForceTrace = true,
        Descript = "旅店住客惶恐不安，似乎被什么东西吓到了，快去探查一下",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9041] = {
        Name = "惊恐时刻05",
        ForceTrace = true,
        Descript = "旅店住客惶恐不安，似乎被什么东西吓到了，快去探查一下",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [9999] = {
        Name = "测试任务(整包)",
        ForceTrace = true,
        Descript = "整包商测试世界玩法的任务流程专用",
        Type = 1,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400001] = {
        Name = "五重奏农庄",
        ForceTrace = true,
        Descript = "调查局的西雅让你去一个叫五重奏农庄的地方，是有什么新的委托交给你吗？",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400002] = {
        Name = "西雅的委托",
        ForceTrace = true,
        Descript = "布诺克集团的瑟琳娜认识你并叫你编导老师，这和西雅的委托有什么联系吗？",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400003] = {
        Name = "拍摄风景素材",
        ForceTrace = true,
        Descript = "农庄中出现了危险怪谈，为了避免民众的恐慌，调查局的西雅给你伪造了一个宣传片编导的身份，借拍摄宣传片素材的机会调查农庄中的怪谈。",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400004] = {
        Name = "拍摄人物素材其一",
        ForceTrace = true,
        Descript = "寻找愿意配合拍摄素材的农庄人，并隐秘地询问怪谈的消息。",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400005] = {
        Name = "拍摄人物素材其二",
        ForceTrace = true,
        Descript = "寻找愿意配合拍摄素材的农庄人，并隐秘地询问怪谈的消息。",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400006] = {
        Name = "拍摄人物素材其三",
        ForceTrace = true,
        Descript = "寻找愿意配合拍摄素材的农庄人，并隐秘地询问怪谈的消息。",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400007] = {
        Name = "拍摄人物素材其四",
        ForceTrace = true,
        Descript = "寻找愿意配合拍摄素材的农庄人，并隐秘地询问怪谈的消息。",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400008] = {
        Name = "农庄的怪谈",
        ForceTrace = true,
        Descript = "拍摄素材的过程中，你发现了一些怪谈的痕迹，但并没有一些确定的线索，你决定继续调查。",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400009] = {
        Name = "意外的真相",
        ForceTrace = true,
        Descript = "没想到农庄中潜伏的危险怪谈竟然是卡尔庄主的小女儿克莱尔特，那个救小鸟的善良少女？她的身上有着什么秘密呢？",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
    [400010] = {
        Name = "结束农庄之旅",
        ForceTrace = true,
        Descript = "农庄的危险怪谈解除了，你的宣传片子也拍摄完成，农庄中的大家都善良可爱，不妨把这些视频素材交给布诺克集团吧。",
        Type = 2,
        RewardItems = {
            [100001] = 1000,
        },
    },
}

M.extra_data = {}

return M
