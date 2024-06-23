-------------------------------------------------------------------------------
--- @copyright Copyright (c) 2024 Tencent Inc. All rights reserved.
--- @brief 小游戏_小美评审团.xlsx/教程文本
--- 注意：本文件由导表程序自动生成，严禁手动修改！所有修改内容均会在下次导表时被覆盖！
-------------------------------------------------------------------------------
local M = {}

M.data = {
    [1] = {
        GuideTitle = "审判案件资讯",
        GuideTips = "【买家评价】：显示买家投诉内容，投诉图与商品图皆可点击放大检视。\n【商家回复】：显示商家回复与申诉内容，申诉图可点击放大检视。",
        GuideImgRef = "T_CityJudge_Img_Guide_01",
    },
    [2] = {
        GuideTitle = "审判支持对象",
        GuideTips = "请根据案件提供资讯判断，并选择「支持用户」，或是「支持商家」。",
        GuideImgRef = "T_CityJudge_Img_Guide_02",
    },
    [3] = {
        GuideTitle = "审判结果",
        GuideTips = "选择支持对象后，画面将显示判官们支持用户与商家的比例。若结果一致则可累积答对次数以及连续一致次数。",
        GuideImgRef = "T_CityJudge_Img_Guide_03",
    },
}

M.extra_data = {}

return M
