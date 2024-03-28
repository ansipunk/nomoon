local sqlite3 = require("lsqlite3")

local Database = {}
Database.__index = Database

local function finalize(stmt)
	local status = stmt:finalize()
	if status ~= sqlite3.OK then error(status) end
end

function Database.new(url)
	local self = setmetatable({}, Database)
	if url == nil then
		self.db = sqlite3.open_memory()
	else
		self.db = sqlite3.open(url)
	end
	return self
end

function Database:prepare(...)
	local args = {...}
	local query = args[1]
	local stmt = self.db:prepare(query)
	assert(stmt, self.db:errmsg())
	if #args > 1 then stmt:bind_values(table.unpack(args, 2)) end
	return stmt
end

function Database:execute(...)
	local stmt = self:prepare(...)
	while true do
		local step = stmt:step()
		if step == sqlite3.DONE or step == sqlite3.ERROR then break end
	end
	finalize(stmt)
end

function Database:fetchOne(...)
	local stmt = self:prepare(...)
	for row in stmt:nrows() do return row end
	finalize(stmt)
end

function Database:fetchAll(...)
	local rows = {}
	local stmt = self:prepare(...)
	for row in stmt:nrows() do table.insert(rows, row) end
	finalize(stmt)
	return rows
end

return Database.new
