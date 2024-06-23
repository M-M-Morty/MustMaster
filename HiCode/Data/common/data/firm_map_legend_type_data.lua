-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief 地图配置表.xlsx/图例类型表
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

--- LegendType
M.BigAreaName = 1
M.SmallAreaName = 2
M.BigArea_Transport = 3
M.SmallArea_Transport = 4
M.Instance = 5
M.Playpoint = 6
M.Task = 7
M.BigArea_NPC = 8
M.SmallArea_NPC = 9
M.Anchor = 10
M.PlayerPosition = 11
--- ExtraActionType
M.Teleport = 1
M.TeleportNearby = 2
M.NoTeleport = 3

M.data = {
    [1001] = {
        LegendType = M.BigArea_Transport,
        Legend_Priority = 1,
        Legend_Scale = {0.5, 3.5},
        Legend_Name = "BIGAREA_TRANSPORT_NAME",
        Legend_Icon = "Map_Icon_Souvenir",
        Legend_Guide = true,
        Legend_Hover_Text = false,
        ExtraActionType = M.Teleport,
    },
    [1002] = {
        LegendType = M.SmallArea_Transport,
        Legend_Priority = 2,
        Legend_Scale = {2.0, 3.5},
        Legend_Name = "SMALLAREA_TRANSPORT_NAME",
        Legend_Icon = "Map_Icon_Alchemy",
        Legend_Guide = true,
        Legend_Hover_Text = false,
        ExtraActionType = M.Teleport,
    },
    [1003] = {
        LegendType = M.Instance,
        Legend_Priority = 3,
        Legend_Scale = {0.5, 3.5},
        Legend_Name = "INSTANCE_NAME",
        Legend_Icon = "Map_Icon_ForgeIron",
        Legend_Guide = true,
        Legend_Hover_Text = true,
        ExtraActionType = M.Teleport,
    },
    [1004] = {
        LegendType = M.Playpoint,
        Legend_Priority = 4,
        Legend_Scale = {0.5, 5.5},
        Legend_Name = "PLAYPOINT_NAME",
        Legend_Icon = "Map_Icon_Music",
        Legend_Guide = true,
        Legend_Hover_Text = true,
        ExtraActionType = M.TeleportNearby,
    },
    [1005] = {
        LegendType = M.BigArea_NPC,
        Legend_Priority = 5,
        Legend_Scale = {0.5, 3.5},
        Legend_Name = "BIGAREA_NPC_NAME",
        Legend_Icon = "Map_Icon_1009",
        Legend_Guide = false,
        Legend_Hover_Text = true,
        ExtraActionType = M.NoTeleport,
    },
    [1006] = {
        LegendType = M.SmallArea_NPC,
        Legend_Priority = 6,
        Legend_Scale = {2.0, 3.5},
        Legend_Name = "SMALLAREA_NPC_NAME",
        Legend_Icon = "Map_Icon_1009",
        Legend_Guide = false,
        Legend_Hover_Text = true,
        ExtraActionType = M.NoTeleport,
    },
    [1007] = {
        LegendType = M.Task,
        Legend_Priority = 7,
        Legend_Scale = {0.5, 5.5},
        Legend_Name = "TASK_NAME",
        Legend_Icon = "Map_Icon_1002",
        Legend_Guide = true,
        Legend_Hover_Text = true,
        ExtraActionType = M.NoTeleport,
    },
    [1008] = {
        LegendType = M.Anchor,
        Legend_Priority = 8,
        Legend_Scale = {0.5, 5.5},
        Legend_Name = "ANCHOR_NAME",
        Legend_Guide = false,
        Legend_Hover_Text = false,
        ExtraActionType = M.NoTeleport,
    },
    [1009] = {
        LegendType = M.BigAreaName,
        Legend_Priority = 9,
        Legend_Scale = {0.5, 2.0},
        Legend_Name = "BIGAREANAME_NAME",
        Legend_Guide = false,
        Legend_Hover_Text = false,
        ExtraActionType = M.NoTeleport,
    },
    [1010] = {
        LegendType = M.SmallAreaName,
        Legend_Priority = 10,
        Legend_Scale = {2.0, 3.5},
        Legend_Name = "SMALLAREA_NAME",
        Legend_Guide = false,
        Legend_Hover_Text = false,
        ExtraActionType = M.NoTeleport,
    },
    [1011] = {
        LegendType = M.PlayerPosition,
        Legend_Priority = 0,
        Legend_Scale = {0.5, 3.5},
        Legend_Name = "PLAYERPOSITION_NAME",
        Legend_Icon = "Map_Icon_1003",
        Legend_Guide = true,
        Legend_Hover_Text = false,
        ExtraActionType = M.NoTeleport,
    },
}

M.extra_data = {}

return M
