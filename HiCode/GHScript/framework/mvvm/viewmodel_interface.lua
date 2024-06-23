--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

---@class ViewModelInterface
local ViewModelInterface = Class()
ViewModelInterface.__IsViewModelInterface__ = true

function ViewModelInterface:ctor()
end

function ViewModelInterface:IsViewModelField()
end

function ViewModelInterface:IsViewModelFieldArray()
end

function ViewModelInterface:IsViewModel()
end

function ViewModelInterface:ReleaseVMObj()
end

return ViewModelInterface
