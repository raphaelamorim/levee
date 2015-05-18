local ffi = require("ffi")

ffi.cdef[[
struct LeveeFD {
	int no;
};
]]

local C = ffi.C

local FD = {}
FD.__index = FD


function FD:__new(no)
	return ffi.new(self, no)
end


function FD:__tostring()
	return string.format("levee.FD: %d", self.no)
end


function FD:__gc()
	C.close(self.no)
end


function FD:nonblock(on)
	local flags = C.fcntl(self.no, C.F_GETFL, 0)
	if flags == -1 then
		return self, ffi.errno()
	end

	if on then
		flags = bit.bor(flags, C.O_NONBLOCK)
	else
		flags = bit.band(flags, bit.xor(C.O_NONBLOCK))
	end

	local rc = C.fcntl(self.no, C.F_SETFL, ffi.new("int", flags))
	if rc == -1 then
		return self, ffi.errno()
	end
	return self, 0
end


function FD:read(buf, len)
	if not len then len = ffi.sizeof(buf) end
	local len = C.read(self.no, buf, len)
	if len > 0 then
		return len, 0
	else
		return len, ffi.errno()
	end
end


function FD:reads(len)
	len = len or 4096
	local buf = ffi.new("char[?]", len)
	local len = self:read(buf, len)
	if len >= 0 then
		return ffi.string(buf)
	end
end


function FD:write(buf, len)
	if not len then
		if type(buf) == "cdata" then
			len = ffi.sizeof(buf)
		else
			len = #buf
		end
	end
	local len = C.write(self.no, buf, len)
	if len > 0 then
		return len, 0
	else
		return len, ffi.errno()
	end
end


local allocate = ffi.metatype("struct LeveeFD", FD)

return {
	FD = allocate,
	pipe = function()
		local fds = ffi.new("int[2]")
		assert(C.pipe(fds) == 0)
		return allocate(fds[0]), allocate(fds[1])
	end,
}