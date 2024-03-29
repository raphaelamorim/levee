local ffi = require('ffi')


local d = require("levee").d


return {
	test_core = function()
		local buf = d.Buffer(4096)
		assert.equal(#buf, 0)
		assert.equal(buf:peek(), "")

		local s = ("."):rep(1024)

		for i = 1, 10 do
			local size = i * 1024

			buf:ensure(size)
			ffi.copy(buf:tail(), s)
			buf:bump(#s)

			assert.equal(#buf, size)
			assert.equal(buf:peek(), ("."):rep(size))
		end

		assert.equal(buf:peek(10), ("."):rep(10))

		buf:trim(5120)
		assert.equal(#buf, 5120)
		assert.equal(buf:peek(), ("."):rep(5120))

		buf:trim()
		assert.equal(#buf, 0)
		assert.equal(buf:peek(), "")
	end,

	test_copy = function()
		local buf = d.Buffer(4096)
		local s = "012345678901234567890123456789"
		buf:push(s)
		local tgt = d.Buffer(4096)
		tgt:bump(buf:copy(tgt:tail()))
		assert.equal(tgt:peek(), s)
	end,

	test_save = function()
		local buf = d.Buffer(8192)
		buf:push("012345678901234567890123456789")

		buf:trim(10)
		local check = buf:available()

		buf:freeze(10)
		-- freezing will reclaim the trimmed offset
		assert.equal(check + 10, buf:available())
		assert.equal(buf:peek(), "0123456789")

		buf:trim(9)
		buf:push("oh hai")
		assert.equal(buf:peek(), "9oh hai")
		local check = buf:available()

		buf:thaw()
		-- thaw will reclaim the trimmed offset
		assert.equal(check + 9, buf:available())
		assert.equal(buf:peek(), "01234567899oh hai")
	end,
}
