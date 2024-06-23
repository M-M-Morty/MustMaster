---------------------------------------------------------------------
--- @copyright Copyright (c) 2022 Tencent Inc. All rights reserved.
--- @author shiboshen
--- @brief 脚本销毁(Unlua框架销毁时会require此文件)
---------------------------------------------------------------------
require "UnLua"
local G = require("G")

function ReleaseGlobal()
    G.log:info("shibo", "ReleaseGlobal here")
end

ReleaseGlobal()
