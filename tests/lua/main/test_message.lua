return {
	test_value = function()
		local levee = require("levee")
		local h = levee.Hub()

		local v = h:value(1)
		assert.equal(v:recv(), 1)
		assert.equal(v:recv(), 1)

		v:send()
		assert.equal(v:recv(10), levee.TIMEOUT)

		h:spawn_later(10, function() v:send(2) end)
		assert.equal(v:recv(20), 2)

		v:send(3)
		v:send(3)
		assert.equal(v:recv(), 3)
		assert.equal(v:recv(), 3)
	end,

	test_pipe = function()
		local h = require("levee").Hub()
		local p = h:pipe()

		-- recv and then send
		local sent = false
		h:spawn_later(10, function() sent = true; p:send("1") end)
		assert(not sent)
		assert.equal(p:recv(), "1")

		-- send and then recv
		local sent = false
		h:spawn(function() sent = true; p:send("2") end)
		assert(sent)
		assert.equal(p:recv(), "2")
	end,

	test_pipe_timeout = function()
		local levee = require("levee")

		local h = levee.Hub()
		local p = h:pipe()

		assert.equal(p:recv(10), levee.TIMEOUT)
		assert.equal(#h.scheduled, 0)

		h:spawn_later(10, function() p:send("foo") end)
		assert.equal(p:recv(20), "foo")
		assert.equal(#h.scheduled, 0)

		h:spawn(function() p:send("foo") end)
		assert.equal(p:recv(0), "foo")
		assert.equal(#h.scheduled, 0)

		assert.equal(p:recv(0), levee.TIMEOUT)
		assert.equal(#h.scheduled, 0)
	end,

	test_pipe_iter = function()
		local h = require("levee").Hub()
		local p = h:pipe()

		h:spawn(
			function()
				for i = 1, 3 do
					p:send(i)
				end
				p:close()
			end)

		local want = 1
		for i in p do
			assert.equal(want, i)
			want = want + 1
		end
	end,

	test_pipe_close_recver = function()
		local h = require("levee").Hub()
		local p = h:pipe()

		local state
		h:spawn(
			function()
				while true do
					local ok = p:send("foo")
					if not ok then break end
				end
				state = "done"
			end)

		assert.equal(p:recv(), "foo")
		assert.equal(p:recv(), "foo")
		assert.equal(p:recv(), "foo")

		p:close()
		assert.equal(state, "done")
	end,

	test_queue = function()
		local levee = require("levee")
		local h = levee.Hub()
		local q = h:queue()

		-- test send and then recv
		assert.equal(q.empty:recv(), true)
		q:send("1")
		assert.equal(q.empty:recv(10), levee.TIMEOUT)
		q:send("2")
		q:send("3")
		assert.equal(q:recv(), "1")
		assert.equal(q:recv(), "2")
		assert.equal(q.empty:recv(10), levee.TIMEOUT)
		assert.equal(q:recv(), "3")
		assert.equal(q.empty:recv(), true)

		-- test recv and then send
		local state
		h:spawn(function() state = q:recv() end)
		q:send("1")
		h:continue()
		assert.equal(state, "1")

		-- test close
		q:send("1")
		q:send("2")
		q:send("3")
		q:close()
		assert.equal(q:recv(), "1")
		assert.equal(q:recv(), "2")
		assert.equal(q:recv(), "3")
		assert.equal(q:recv(), nil)
	end,

	test_queue_size = function()
		local h = require("levee").Hub()

		local q = h:queue(3)

		h:spawn(function()
			for i = 1, 10 do q:send(i) end
			q:close()
		end)

		local check = 0
		for i in q do
			check = check + 1
			assert.equal(i, check)
		end
		assert.equal(check, 10)
	end,

	test_stalk_send_then_recv = function()
		local levee = require("levee")
		local h = levee.Hub()
		local q = h:stalk(3)

		local sent
		h:spawn(function()
			for i = 1, 10 do
				sent = i
				q:send(i)
			end
			sent = 20
		end)

		assert.equal(sent, 4)
		assert.equal(q:recv(), true)
		h:continue()
		-- recv-ing doesn't remove items from the queue
		assert.equal(sent, 4)

		local check = {}
		for i in q:iter() do table.insert(check, i) end
		assert.same(check, {1, 2, 3})

		q:remove(2)
		h:continue()
		local check = {}
		assert.equal(q:recv(), true)
		for i in q:iter() do table.insert(check, i) end
		assert.same(check, {3, 4, 5})

		q:remove(#q)
		h:continue()
		local check = {}
		for i in q:iter() do table.insert(check, i) end
		assert.same(check, {6, 7, 8})

		q:remove(#q)
		h:continue()
		local check = {}
		for i in q:iter() do table.insert(check, i) end
		assert.same(check, {9, 10})

		assert.equal(q.empty:recv(10), levee.TIMEOUT)
		q:remove(#q)
		assert.equal(q.empty:recv(), true)

		assert.equal(sent, 20)
	end,

	test_stalk_recv_then_send = function()
		local levee = require("levee")
		local h = levee.Hub()
		local q = h:stalk(3)

		local check = {}
		h:spawn(function()
			while true do
				if not q:recv() then break end
				for i in q:iter() do
					table.insert(check, i)
				end
				q:remove(#q)
			end
			table.insert(check, 20)
		end)

		q:send(1)
		h:continue()
		assert.same(check, {1})

		q:send(2)
		q:send(3)
		q:send(4)
		assert.same(check, {1})

		q:send(5)
		assert.same(check, {1, 2, 3, 4})
		q:send(6)
		q:send(7)
		h:continue()
		assert.same(check, {1, 2, 3, 4, 5, 6, 7})

		q:send(8)
		q:send(9)
		q:close()
		h:continue()
		assert.same(check, {1, 2, 3, 4, 5, 6, 7, 8, 9, 20})
	end,

	test_mimo = function()
		local levee = require("levee")
		local h = levee.Hub()
		local q = h:mimo(1)

		-- test send and then recv
		local check = {}
		q:send("1")
		h:spawn(function() q:send("2"); table.insert(check, "2") end)
		h:spawn(function() q:send("3"); table.insert(check, "3") end)

		assert.equal(q:recv(), "1")
		assert.equal(q:recv(), "2")
		assert.equal(q:recv(), "3")

		h:continue()
		assert.same(check, {"2", "3"})

		-- test recv and then send
		local check = {}
		h:spawn(function() table.insert(check, {1, q:recv()}) end)
		h:spawn(function() table.insert(check, {2, q:recv()}) end)
		h:spawn(function() table.insert(check, {3, q:recv()}) end)

		q:send("1")
		q:send("2")
		q:send("3")

		h:continue()
		assert.same(check, {{1, "1"}, {2, "2"}, {3, "3"}})

		-- test close
		q:send("1")
		q:close()
		assert.equal(q:recv(), "1")
		assert.equal(q:recv(), nil)
	end,

	test_selector = function()
		local h = require("levee").Hub()

		local p1 = h:pipe()
		local p2 = h:pipe()

		local s = h:selector()

		-- send before redirect
		h:spawn(function() p1:send("0") end)

		p1:redirect(s)
		p2:redirect(s)

		assert.same(s:recv(), {p1, "0"})

		-- send and then recv
		h:spawn(function() p1:send("1") end)
		assert.same(s:recv(), {p1, "1"})

		-- recv and then send
		local check
		h:spawn(function() check = s:recv() end)
		p2:send("2")
		assert.same(check, {p2, "2"})

		-- 2x pending
		h:spawn(function() p2:send("2") end)
		h:spawn(function() p1:send("1") end)
		assert.same(s:recv(), {p2, "2"})
		assert.same(s:recv(), {p1, "1"})

		-- test sender close
		h:spawn(function() p1:close() end)
		local sender, value = unpack(s:recv())
		assert.same(sender, p1)
		assert.equal(sender.closed, true)
		assert.equal(value, nil)
	end,

	test_selector_timeout = function()
		local levee = require("levee")

		local h = levee.Hub()

		local p1 = h:pipe()
		local p2 = h:pipe()

		local s = h:selector()

		p1:redirect(s)
		p2:redirect(s)

		assert.equal(s:recv(10), levee.TIMEOUT)
		assert.equal(#h.scheduled, 0)

		h:spawn_later(10, function() p1:send("1") end)
		assert.same(s:recv(20), {p1, "1"})
	end,
}
