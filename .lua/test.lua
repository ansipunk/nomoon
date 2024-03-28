local models = require("models")
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

function TestRunner:assertEqual(got, want)
	if got ~= want then
		error(
			"-- expected --\n%s\n" % {got} ..
			"-- to be equal to --\n%s" % {want}
		)
	end
end

function TestRunner:assertNil(got)
	if got ~= nil then
		error(
			"-- expected --\n%s\n" % {got} ..
			"-- to be nil --"
		)
	end
end

function TestRunner:assertNotNil(got, name)
	if got == nil then
		error(
			"-- expected --\n%s\n" % {name} ..
			"-- to be not nil --"
		)
	end
end

function TestRunner:ctx()
	local db = sqlite()
	models.migrate(db)

	local db_items = {
		threads = {
			fields = {"content", "token"},
			items = {
				{id = 1, content = "1 / john", token = "john"},
				{id = 2, content = "2 / jane", token = "jane"},
			},
		},
		posts = {
			fields = {"content", "threadId", "op", "token"},
			items = {
				{id = 1, content = "1 / 1 / no / jane", threadId = 1, op = 0, token = "jane"},
				{id = 2, content = "2 / 1 / no / john", threadId = 1, op = 0, token = "john"},
				{id = 3, content = "3 / 1 / op / john", threadId = 1, op = 1, token = "john"},
				{id = 4, content = "4 / 1 / no / jane", threadId = 1, op = 0, token = "jane"},
				{id = 5, content = "5 / 2 / op / jane", threadId = 2, op = 1, token = "jane"},
			},
		},
		tokens = {
			john = "john",
			jane = "jane",
		}
	}

	for _, thread in ipairs(db_items.threads.items) do
		db:execute([[
			INSERT INTO threads
			(content, token)
			VALUES (?, ?);
		]], thread.content, thread.token)
	end

	for _, post in ipairs(db_items.posts.items) do
		db:execute([[
			INSERT INTO posts
			(content, thread_id, op, token)
			VALUES (?, ?, ?, ?);
		]], post.content, post.threadId, post.op, post.token)
	end

	return {
		db = db,
		db_items = db_items,
	}
end

function TestRunner:run(name, func)
	local context = self:ctx()
	local status, err = pcall(func, context)

	if status then
		self.pass = self.pass + 1
	else
		table.insert(self.failed, "%s\n%s" % {name, err})
	end

	self.total = self.total + 1
end

function TestRunner:stats()
	local message = "%s - %s/%s passed" % {self.name, self.pass, self.total}
	print(message)
	print("=" * #message)
	for _, err in ipairs(self.failed) do
		print(err)
		print("-" * #message)
	end
end

return TestRunner.new
