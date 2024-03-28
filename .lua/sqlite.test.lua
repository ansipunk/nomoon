local sqlite = require("sqlite")
local test = require("test")

local t = test("sqlite")

local items = {
	{alpha="a0", beta="b0"},
	{alpha="a1", beta="b1"},
}

local function prepareDb(db)
	db:execute("CREATE TABLE test_table (id INTEGER PRIMARY KEY, alpha TEXT, beta TEXT);")

	for _, item in ipairs(items) do
		db:execute(
			"INSERT INTO test_table (alpha, beta) VALUES (?, ?);",
			item.alpha, item.beta
		)
	end

	return items
end

t:run("fetch one", function()
	local db = sqlite()
	prepareDb(db)

	local id = 1
	local want = items[id]
	local got = db:fetchOne([[
		SELECT alpha, beta
			FROM test_table
			WHERE id = ?;
	]], id)

	for _, field in ipairs({"alpha", "beta"}) do
		t:assertEqual(got[field], want[field])
	end
end)

t:run("fetch nonexistent", function()
	local db = sqlite()
	prepareDb(db)

	t:assertNil(db:fetchOne([[
		SELECT alpha, beta
			FROM test_table
			WHERE id = ?;
	]], "nonexistent"))
end)

t:run("fetch all", function()
	local db = sqlite()
	prepareDb(db)

	local got = db:fetchAll([[
		SELECT alpha, beta
			FROM test_table;
	]])

	for n, row in ipairs(got) do
		for _, field in ipairs({"alpha", "beta"}) do
			t:assertEqual(row[field], items[n][field])
		end
	end
end)

t:run("fetch empty", function()
	local db = sqlite()
	prepareDb(db)

	local got = db:fetchAll([[
		SELECT alpha, beta
			FROM test_table
			WHERE id = ?;
	]], 0)

	t:assertEqual(#got, 0)
end)

t:stats()
