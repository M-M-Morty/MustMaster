---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yongzyzhang.
--- DateTime: 2024/4/19 上午11:33
---
---
---纯属为了IDE EmmyLua 自动提示

---@class FOfficeDecorationActorInfo  对应蓝图 BPS_OfficeDecorationInfo
---@alias Struct.BPS_OfficeDecorationInfo FOfficeDecorationActorInfo
---@field ActorID
---@field Transform FTransform
---@field bRemoved
---@field BasicModelKey
---@field SkinKey
---@field Component table<FOfficeModelPartInfo>
local FOfficeDecorationActorInfo = {}


---@class FOfficeModelPartInfo 
---@field Index number
---@field Color FColor
local FOfficeModelPartInfo = {}


---@class FOfficeModelSkinPayItem
---@field SkinKey
---@field Num
local FOfficeModelSkinPayItem = {}

---@class FOfficeModelColorPayItem  
---@field ModelKey
---@field Index
---@field Color
local FOfficeModelColorPayItem = {}

---@class FOfficeClientDecorationShopCar
---@field SkinItems table<string, FOfficeModelSkinPayItem>
---@field ColorItems table<FOfficeModelColorPayItem>
local FOfficeClientDecorationShopCar = {}

---@class FOfficeActorTrialSkinInfo
---@field ActorID
---@field SkinKey
local FOfficeActorTrialColorInfo = {}

---@class FOfficeActorTrialColorInfo
---@field ActorID
---@field Index number 
---@field Color
local FOfficeActorTrialColorInfo = {}


---@class FOfficeActorTrialDecorationItems
---@field SkinTrialItems table<FOfficeActorTrialSkinInfo>
---@field ColorTrialItems table<FOfficeActorTrialColorInfo>
local FOfficeActorTrialDecorationItems = {}
---@alias Struct.BPS_OfficeDecorationTrialItems FOfficeActorTrialDecorationItems


---@class FLeaveOfficeDecorationModeParam
---@alias Struct.BPS_OfficeLeaveDecorationModeParam FLeaveOfficeDecorationModeParam
---@field bPayAll boolean
---@field TrialDecorationItems FOfficeActorTrialDecorationItems Actor试用的数据
---@field ActorDecorationInfos table<FOfficeDecorationActorInfo> 修改后的Actor装修数据
local FLeaveOfficeDecorationModeParam = {}

---@class FOfficeDesignScheme
---@alias Struct.BPS_OfficeDesignScheme FOfficeDesignScheme
---@field DesignActorDecorationInfos TArray<Struct.BPS_OfficeDecorationInfo>
---@field AuthorType number
---@field AuthorInfo table  
local FOfficeDesignScheme = {}

---@class Struct.BPS_OfficeDesignSchemeDesc
---@field Title string
---@field CoverPictureUrl string
---@field DescText string
local BPS_OfficeDesignSchemeDesc = {}

---@class FOfficeDesignSchemeSlot
---@alias Struct.BPS_OfficeDesignSchemeSlot FOfficeDesignSchemeSlot
---@field Slot number
---@field DesignScheme FOfficeDesignScheme
---@field Description Struct.BPS_OfficeDesignSchemeDesc
local FOfficeDesignSchemeSlot = {}