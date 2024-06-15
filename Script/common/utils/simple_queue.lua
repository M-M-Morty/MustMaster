
local Queue = {}

function Queue.new()
    return setmetatable({first = 1, last = 1}, {__index = Queue})
end

function Queue:Push(v)
    self[self.last] = v
    self.last = self.last + 1
end

function Queue:Pop()
    self[self.first] = nil
    self.first = self.first + 1
end

function Queue:Clear()
	while self:Size() > 0 do
		self:Pop()
	end
end

function Queue:Size()
	return self.last - self.first
end

function Queue:First()
	return self[self.first]
end

function Queue:Last()
	return self[self.last - 1]
end

return Queue
