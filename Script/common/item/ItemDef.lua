local ItemDef = {}

ItemDef.NEW_DISAPPEAR_RULE = {
    LEAVE_TAB = 1, ---查看本页签后消失
    CLICK_ITEM = 2, ---点击道具后消失
    CLICK_DETAIL_BUTTON = 3, ---点击使用/查看按键后消失
    PERMANENT = 4, ---不消失
}

ItemDef.TASK_ITEM_DISPLAY_TYPE = {
    TEXT = 1,
    PICTURE = 2,
    PHONE_CARD = 3,
}

ItemDef.CATEGORY = {
    CURRENCY = 10, -- 货币
    WEAPON = 11, -- 武器
    WEAPON_MATERIAL = 12, -- 武器强化材料
    EQUIPMENT = 13, -- 装备
    EQUIPMENT_MATERIAL = 14, --装备材料
    COLLECTION = 15, --采集物
    FOOD = 16, -- 食物
    CONSUMABLE = 17, -- 消耗品
    TASK_ITEM = 18, -- 任务物品
    FURNITURE = 19, -- 家具
}

ItemDef.Quality = {
    WHITE = 1,
    GREEN = 2,
    BLUE = 3,
    PURPLE = 4,
    ORANGE = 5,
}

ItemDef.HideTabIndex = 99999

return ItemDef