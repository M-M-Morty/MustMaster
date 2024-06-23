
local G = require('G')

local StringUtil = {}

local strSplitPattern = '([^%s]*)'
if tonumber(_VERSION:match('[%d%.]+')) < 5.3 then
    strSplitPattern = '([^%s]+)'
end;


--可以分割多级字符串，比如：StringUtil:Split('1,2;3,4', ',', ';')的结果是{{1,2}, {3,4}}
function StringUtil:Split(strContent, ...)
    if type(strContent) ~= 'string' or self:IsEmpty(strContent) then
        return {};
    end;
    local tbSplitor = {...};
    tbSplitor[1] = tbSplitor[1] or ',';
    local Split = nil;
    Split = function(strData, nIdx)
        local tbResult = {};
        local strSplitor = tostring(tbSplitor[nIdx]);
        local strPattern = string.format(strSplitPattern, strSplitor)
        for str in strData:gmatch(strPattern) do
            if nIdx > 1 then
                table.insert(tbResult, Split(str, nIdx - 1));
            else
                table.insert(tbResult, str);
            end;
        end;
        return tbResult;
    end;
    return Split(strContent, #tbSplitor);
end

function StringUtil:StartsWith(strSource, strStart)
    if (type(strSource) ~= 'string') or (type(strStart) ~= 'string') then
        return false
    end
    return string.find(strSource, strStart) == 1
end

function StringUtil:EndsWith(strSource, strEnd)
    if (type(strSource) ~= 'string') or (type(strEnd) ~= 'string') then
        return false
    end
    local nEndLen = string.len(strEnd)
    return strEnd == string.sub( strSource, -nEndLen )
end

--当str为空字符串或为nil时被认为是空。
function StringUtil:IsEmpty(str)
    return str == '' or str == nil
end;

-- 判断utf8字符byte长度
function StringUtil.chsize( char )
    if not char then
        --print("not char")
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end

---计算 UTF8 字符串的长度，每一个中文算一个字符
---@param str string
function StringUtil.utf8len(str)
    local len = 0
    local currentIndex = 1
    while currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + StringUtil.chsize(char)
        len = len +1
    end

    return len
end

---截取字符串，按字符截取，每一个中文算一个字符
---@param str string 要截取的字符串
---@param startChar integer   开始字符下标,从1开始
---@param numChars  integer  要截取的字符长度
function StringUtil.utf8sub( str, startChar, numChars )
    local startIndex = 1
    while startChar > 1 do
        local char = string.byte(str, startIndex)
        startIndex = startIndex + StringUtil.chsize(char)
        startChar = startChar - 1
    end

    local currentIndex = startIndex

    while numChars > 0 and currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + StringUtil.chsize(char)
        numChars = numChars -1
    end
    return str:sub(startIndex, currentIndex - 1), numChars
end

return StringUtil
