local model = require("model")
local sqlite = require("sqlite")

local TestRunner = {}
TestRunner.__index = TestRunner

function TestRunner.new(name)
	local self = setmetatable({}, TestRunner)
	self.name = name
	self.total = 0
	self.pass = 0
	self.failed = {}
	return self
end

function TestRunner:assert(got, name)
	if got ~= true then error("-- expected --\n" .. name .. "\n-- to be true --") end
end

function TestRunner:assertNot(got, name)
	if got ~= false then error("-- expected --\n" .. name .. "\n-- to be false --") end
end

function TestRunner:assertEqual(got, want)
	if got ~= want then error("-- expected --\n" .. got .. "\n-- to be equal to --\n" .. want) end
end

function TestRunner:assertLowerOrEqual(got, want)
	if got > want then error("-- expected --\n" .. got .. "\n-- to be lower than or equal to --\n" .. want) end
end

function TestRunner:assertNil(got, name)
	if got ~= nil then error("-- expected --\n" .. name .. "-- to be nil but got --\n" .. got) end
end

function TestRunner:assertNotNil(got, name)
	if got == nil then error("-- expected --\n" .. name .. "-- to be not nil --") end
end

function TestRunner:ctx()
	local db = sqlite()
	model.migrate(db)

	local items = {
		threads = {
			{
				id = 1, content = "1 / john", token = "john", delete_link = "/t/1", bumped_at = "2020-01-01 00:00:00",
				posts = {
					{id = 1, content = "1 / 1 / no / jane", thread_id = 1, op = 0, token = "jane", delete_link = "/t/1/p/1"},
					{id = 2, content = "2 / 1 / no / john", thread_id = 1, op = 0, token = "john", delete_link = "/t/1/p/2"},
					{id = 3, content = "3 / 1 / op / john", thread_id = 1, op = 1, token = "john", delete_link = "/t/1/p/3"},
					{id = 4, content = "4 / 1 / no / jane", thread_id = 1, op = 0, token = "jane", delete_link = "/t/1/p/4"},
				}
			},
			{
				id = 2, content = "2 / jane", token = "jane", delete_link = "/t/2", bumped_at = "2021-01-01 00:00:00",
				posts = {
					{id = 5, content = "5 / 2 / op / jane", thread_id = 2, op = 1, token = "jane", delete_link = "/t/2/p/5"},
				},
			},
		},
		tokens = {john = "john", jane = "jane"},
	}

	for _, thread in ipairs(items.threads) do
		db:execute([[
			INSERT INTO threads
			(content, token, bumped_at)
			VALUES (?, ?, ?);
		]], thread.content, thread.token, thread.bumped_at)

		for _, post in ipairs(thread.posts) do
			db:execute([[
				INSERT INTO posts
				(content, thread_id, op, token)
				VALUES (?, ?, ?, ?);
			]], post.content, post.thread_id, post.op, post.token)
		end
	end

	return {
		db = db,
		items = items,
	}
end

function TestRunner:run(name, func)
	local context = self:ctx()
	local status, err = pcall(func, context)

	if status then
		self.pass = self.pass + 1
	else
		table.insert(self.failed, name .. '\n' .. err)
	end

	self.total = self.total + 1
end

function TestRunner:stats()
	local message = self.name .. ' - ' .. tostring(self.pass) .. '/' .. tostring(self.total) .. ' passed'
	print(message .. '\n' .. '=' * #message)
	for _, err in ipairs(self.failed) do print(err .. '\n' .. '-' * #message) end
	if #self.failed > 0 then os.exit(1) end
end

return TestRunner.new
