local test = require("test")

local t = test("sqlite")

t:run("fetch one", function(ctx)
	ctx.db:execute([[
		CREATE TABLE
			test_table (key, alpha, beta);
		INSERT INTO
			test_table (key, alpha, beta)
			VALUES (?, ?, ?);
	]], 0, 1, 2)

	local want = {alpha=1, beta=2}
	local got = ctx.db:fetchOne([[
		SELECT alpha, beta
			FROM test_table
			WHERE key = ?;
	]], 0)

	for _, field in ipairs({"alpha", "beta"}) do
		t:assertEqual(got[field], want[field])
	end
end)

t:run("fetch nonexistent", function(ctx)
	ctx.db:execute([[
		CREATE TABLE test_table
			(key, alpha, beta);
	]])
	local got = ctx.db:fetchOne([[
		SELECT alpha, beta
			FROM test_table;
	]])
	t:assertNil(got)
end)

t:run("fetch all", function(ctx)
	ctx.db:execute([[
		CREATE TABLE
			test_table (key, alpha, beta);
		INSERT INTO
			test_table (key, alpha, beta)
			VALUES (?, ?, ?), (?, ?, ?);
	]], 0, 1, 2, 3, 4, 5)

	local want = {{alpha=1, beta=2}, {alpha=4, beta=5}}
	local got = ctx.db:fetchAll([[
		SELECT alpha, beta
			FROM test_table;
	]])

	for n, row in ipairs(got) do
		for _, field in ipairs({"alpha", "beta"}) do
			t:assertEqual(row[field], want[n][field])
		end
	end
end)

t:run("fetch empty", function(ctx)
	ctx.db:execute([[
		CREATE TABLE test_table
			(key, alpha, beta);
	]])
	local want = 0
	local got = #ctx.db:fetchAll([[
		SELECT alpha, beta
			FROM test_table;
	]])
	t:assertEqual(got, want)
end)

t:stats()
