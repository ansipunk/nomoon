local sqlite3 = require("lsqlite3")

local Database = {}
Database.__index = Database

function Database.new(url)
	local self = setmetatable({}, Database)
	if url == nil then
		self.db = sqlite3.open_memory()
	else
		self.db = sqlite3.open(url)
	end
	return self
end

function Database.finalize(stmt)
	local status = stmt:finalize()
	if status ~= sqlite3.OK then error(status) end
end

function Database:prepare(query, ...)
	local stmt, args = self.db:prepare(query), {...}
	assert(stmt, self.db:errmsg())
	if #args > 0 then stmt:bind_values(...) end
	return stmt
end

function Database:execute(query, ...)
	local stmt = self:prepare(query, ...)
	while true do
		local step = stmt:step()
		if step == sqlite3.DONE or step == sqlite3.ERROR then break end
	end
	self.finalize(stmt)
end

function Database:fetchOne(query, ...)
	local stmt = self:prepare(query, ...)
	local result = nil
	for row in stmt:nrows() do result = row end
	self.finalize(stmt)
	return result
end

function Database:fetchAll(query, ...)
	local rows = {}
	local stmt = self:prepare(query, ...)
	for row in stmt:nrows() do table.insert(rows, row) end
	self.finalize(stmt)
	return rows
end

return Database.new
