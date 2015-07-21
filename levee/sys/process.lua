local ffi = require('ffi')
local C = ffi.C


local string_array_t = ffi.typeof("const char *[?]")


local function to_string_array_t(...)
	local args = {...}
	local ret = string_array_t(#args+1, args)
	return ret
end


local M = {}

M.execv = function(path, argv)
	return C.execv(path, to_string_array_t(path, unpack(argv or {})))
end


M.execl = function(path, ...)
	return M.execv(path, {...})
end


M.execvp = function(name, argv)
	return C.execvp(name, to_string_array_t(name, unpack(argv or {})))
end


M.execlp = function(path, ...)
	return M.execvp(path, {...})
end


M.waitpid = function(pid, options)
  --[[
  pid:

  <-1  meaning wait for any child process whose process group ID is equal to
       the absolute value of pid.

   -1  meaning wait for any child process.

    0  meaning wait for any child process whose process group ID is equal to
       that of the calling process.

	 >0  meaning wait for the child whose process ID is equal to the value of
       pid.  --]]

	local stat_loc = ffi.new("int[1]")

	local pid = C.waitpid(pid, stat_loc, options)

	if pid < 0 then
		return pid, ffi.errno()
	end

	return pid,
		bit.rshift(bit.band(stat_loc[0], 0xff00), 8),
		bit.band(stat_loc[0], 0x7f)
end


return M