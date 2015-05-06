local Stats = {}

local function update(self)
	if self.sortn ~= #self.vals then
		table.sort(self.vals)
		self.sortn = #self.vals
		self._mean = nil
		self._median = nil
		self._stdev = nil
		return true
	end
	return false
end

function Stats:add(val)
	table.insert(self.vals, val)
end

function Stats:clear()
	self.vals = {}
	self.sortn = nil
end

function Stats:sum()
	if #self.vals == 0 then return 0.0 end
	if update(self) or not self._mean then
		local sum = 0.0
		local vals = self.vals
		for i=1,#vals do
			sum = sum + vals[i]
		end
		self._sub = sum
	end
	return self._sub
end

function Stats:mean()
	if #self.vals == 0 then return 0.0 end
	if update(self) or not self._mean then
		self._mean = self:sum() / #self.vals
	end
	return self._mean
end

function Stats:median()
	if #self.vals == 0 then return 0.0 end
	if update(self) or not self._median then
		if math.fmod(#self.vals, 2) == 0 then
			self._median = (self.vals[#self.vals/2] + self.vals[(#self.vals/2)+1]) / 2
		else
			self._median = self.vals[math.ceil(#self.vals/2)]
		end
	end
	return self._median
end

function Stats:stdev()
	if #self.vals == 0 then return 0.0 end
	if update(self) or not self._stdev then
		local mean = self:mean()
		local sum = 0
		local vals = self.vals
		local pow = math.pow
		for i=1,#vals do
			sum = sum + pow(vals[i] - mean, 2)
		end
		self._stdev = math.sqrt(sum / (#self.vals-1))
	end
	return self._stdev
end

function Stats:min()
	if #self.vals == 0 then return 0.0 end
	update(self)
	return self.vals[1]
end

function Stats:max()
	if #self.vals == 0 then return 0.0 end
	update(self)
	return self.vals[#self.vals]
end

Stats.__index = Stats

return function()
	return setmetatable({vals={}}, Stats)
end
