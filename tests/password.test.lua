local password = require("password")
local test = require("test")

local t = test("password")

t:run("hash and verify", function()
	local secret = "secret"
	local hash = password.hash(secret)
	t:assert(password.verify(hash, secret))
end)

t:run("hash and verify with invalid password", function()
	local hash = password.hash("secret")
	t:assertNot(password.verify(hash, "invalid"))
end)

t:stats()
