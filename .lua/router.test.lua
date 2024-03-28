local router = require("router")
local test = require("test")

local t = test("router")

t:run("resolve /", function()
	local route = "/"
	local want = {entity = "root", threadId = 0, postId = 0, page = 0}
	local got = router.resolveRoute(route)
	t:assertNotNil(got, "expected to resolve route %s" % {route})
	t:assertEqual(got.entity, want.entity)
	t:assertEqual(got.threadId, want.threadId)
	t:assertEqual(got.postId, want.postId)
	t:assertEqual(got.page, want.page)
end)

t:run("resolve /666", function()
	local route = "/666"
	local want = {entity = "root", threadId = 0, postId = 0, page = 666}
	local got = router.resolveRoute(route)
	t:assertNotNil(got, "expected to resolve route %s" % {route})
	t:assertEqual(got.entity, want.entity)
	t:assertEqual(got.threadId, want.threadId)
	t:assertEqual(got.postId, want.postId)
	t:assertEqual(got.page, want.page)
end)

t:run("resolve /t", function()
	local route = "/t"
	local want = {entity = "thread", threadId = 0, postId = 0, page = 0}
	local got = router.resolveRoute(route)
	t:assertNotNil(got, "expected to resolve route %s" % {route})
	t:assertEqual(got.entity, want.entity)
	t:assertEqual(got.threadId, want.threadId)
	t:assertEqual(got.postId, want.postId)
	t:assertEqual(got.page, want.page)
end)

t:run("resolve /t/1", function()
	local route = "/t/1"
	local want = {entity = "thread", threadId = 1, postId = 0, page = 0}
	local got = router.resolveRoute(route)
	t:assertNotNil(got, "expected to resolve route %s" % {route})
	t:assertEqual(got.entity, want.entity)
	t:assertEqual(got.threadId, want.threadId)
	t:assertEqual(got.postId, want.postId)
	t:assertEqual(got.page, want.page)
end)

t:run("resolve /t/1/p", function()
	local route = "/t/1/p"
	local want = {entity = "post", threadId = 1, postId = 0, page = 0}
	local got = router.resolveRoute(route)
	t:assertNotNil(got, "expected to resolve route %s" % {route})
	t:assertEqual(got.entity, want.entity)
	t:assertEqual(got.threadId, want.threadId)
	t:assertEqual(got.postId, want.postId)
	t:assertEqual(got.page, want.page)
end)

t:run("resolve /t/1/p/1", function()
	local route = "/t/1/p/1"
	local want = {entity = "post", threadId = 1, postId = 1, page = 0}
	local got = router.resolveRoute(route)
	t:assertNotNil(got, "expected to resolve route %s" % {route})
	t:assertEqual(got.entity, want.entity)
	t:assertEqual(got.threadId, want.threadId)
	t:assertEqual(got.postId, want.postId)
	t:assertEqual(got.page, want.page)
end)

t:run("resolve invalid", function()
	local route = "invalid"
	local got = router.resolveRoute(route)
	t:assertNil(got, "expected to not resolve")
end)

t:stats()
