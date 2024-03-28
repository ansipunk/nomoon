local models = require("models")
local test = require("test")

local t = test("models")

t:run("create thread", function(ctx)
	local content = "content"
	local token = "token"
	local created = models.createThread(ctx.db, content, token)

	t:assertEqual(created.id, 3)
	t:assertEqual(created.content, content)
	t:assertEqual(created.token, token)
	t:assertNotNil(created.created_at, "created.created_at")
	t:assertNotNil(created.bumped_at, "created.bumped_at")
end)

t:run("create post", function(ctx)
	local threadId = 1
	local content = "content"
	local token = "token"
	local created = models.createPost(ctx.db, threadId, content, token)

	t:assertEqual(created.id, 6)
	t:assertEqual(created.thread_id, threadId)
	t:assertEqual(created.content, content)
	t:assertEqual(created.token, token)
	t:assertNotNil(created.created_at, "created.created_at")
end)

t:stats()
