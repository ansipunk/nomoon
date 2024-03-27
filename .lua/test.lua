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

function TestRunner:assertNotNil(got)
	if got == nil then
		error(
			"-- expected --\n%s\n" % {got} ..
			"-- to be not nil --"
		)
	end
end

function TestRunner:ctx()
	return {db=sqlite()}
end

function TestRunner:run(name, func)
	local status, err = pcall(func, self:ctx())

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
