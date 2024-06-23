
-- @class OfficeEnums
local OfficeEnums = {
    ---@class  OfficeModelSkinState
    OfficeModelSkinState = {
        Invalid = 0,
        AlreadyPurchasedOne = 1,               --- 已付费
        UnPurchasedAny = 2,            --- 需付费
        LockedByPrecondition = 3, --- 前置条件不满足无法购买
        Hide = 4,                 --- 对此玩家隐藏
    },
    
    DecorationErrorCode = {
        OK = 0,
        Busy = -1,
        UnknownServerError = -2,

        SameSkin = -3,
        SameColor = -4,
        InvalidCompIndex = -5,
        InvalidModelOrSkinID = -6,
        
        CostItemNotEnough = -7,
        
        AlreadyInDecorationMode = -8;
        NotInDecorationMode = -9,
    },
    
    DesignSchemeAuthorType = {
        PlayerSelf = 1,
        OtherPlayer = 2,
    }
}


return OfficeEnums
