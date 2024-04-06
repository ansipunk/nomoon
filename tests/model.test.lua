local model = require("model")
local test = require("test")

local t = test("model")

t:run("create thread", function(ctx)
	local content = "content"
	local token = "token"
	local created = model.createThread(ctx.db, content, token)

	t:assertEqual(created.content, content)
	t:assertEqual(created.token, token)
	t:assertNotNil(created.created_at, "created.created_at")
	t:assertNotNil(created.bumped_at, "created.bumped_at")
	t:assertNotNil(created.id, "created.id")
end)

t:run("get thread", function(ctx)
	local thread = ctx.items.threads[1]
	local fetched = assert(model.getThread(ctx.db, thread.id, "token"))

	t:assertEqual(fetched.you, 0)
	t:assertEqual(fetched.content, thread.content)
	t:assertEqual(fetched.delete_link, thread.delete_link)

	for n, got in ipairs(fetched.posts) do
		local want = thread.posts[n]

		t:assertEqual(got.id, want.id)
		t:assertEqual(got.thread_id, want.thread_id)
		t:assertEqual(got.content, want.content)
		t:assertEqual(got.op, want.op)
		t:assertEqual(got.delete_link, want.delete_link)
		t:assertEqual(got.you, 0)
	end
end)

t:run("get thread you", function(ctx)
	local thread = ctx.items.threads[1]
	local token = thread.token
	local fetched = assert(model.getThread(ctx.db, thread.id, token))

	t:assertEqual(fetched.you, 1)
	t:assertEqual(fetched.content, thread.content)
	t:assertEqual(fetched.post_count, #thread.posts)
	t:assertEqual(fetched.delete_link, thread.delete_link)

	for n, got in ipairs(fetched.posts) do
		local want = thread.posts[n]

		if want.token == token then
			t:assertEqual(got.you, 1)
		else
			t:assertEqual(got.you, 0)
		end
	end
end)

t:run("get thread nonexistent", function(ctx)
	local fetched = model.getThread(ctx.db, 0, "token")
	t:assertNil(fetched, "thread exists")
end)

t:run("get threads", function(ctx)
	local threads = ctx.items.threads
	local fetchedAll = model.getThreads(ctx.db, "token").threads

	for _, fetched in ipairs(fetchedAll) do
		local thread = threads[fetched.id]

		t:assertEqual(fetched.you, 0)
		t:assertEqual(fetched.content, thread.content)
		t:assertEqual(fetched.delete_link, thread.delete_link)
		t:assertEqual(fetched.post_count, #thread.posts)
		t:assertLowerOrEqual(#fetched.posts, 3)

		local fetched_posts = fetched.posts
		if #fetched_posts > 3 then
			fetched_posts = table.unpack(fetched_posts, #fetched_posts - 2, #fetched_posts)
		end

		for _, got in ipairs(fetched_posts) do
			local want

			for _, post in ipairs(thread.posts) do
				if post.id == got.id then
					want = post
					break
				end
			end

			t:assertEqual(got.thread_id, want.thread_id)
			t:assertEqual(got.content, want.content)
			t:assertEqual(got.op, want.op)
			t:assertEqual(got.delete_link, want.delete_link)
			t:assertEqual(got.you, 0)
		end
	end
end)

t:run("get threads pagination", function(ctx)
	local firstPageWant = {ctx.items.threads[2]}
	local lastPageWant = {ctx.items.threads[1]}

	local function equal(a, b)
		if #a.threads ~= #b then return false end

		for n, thread in ipairs(a.threads) do
			if thread.id ~= b[n].id then return false end
		end

		return true
	end

	local firstPage = model.getThreads(ctx.db, "token", 0, 1)
	local lastPage = model.getThreads(ctx.db, "token", firstPage.next, 1)
	t:assert(equal(firstPage, firstPageWant), "firstPage != firstPageWant")
	t:assert(equal(lastPage, lastPageWant), "lastPage != lastPageWant")

	local newFirstPage = model.getThreads(ctx.db, "token", lastPage.prev, 1)
	t:assert(equal(newFirstPage, firstPageWant), "newFirstPage != firstPageWant")
end)

t:run("get threads you", function(ctx)
	local threads = ctx.items.threads
	local token = threads[1].token
	local fetchedAll = model.getThreads(ctx.db, token)

	for i, fetched in ipairs(fetchedAll) do
		local thread = threads[i]

		if thread.token == token then
			t:assertEqual(fetched.you, 1)
		else
			t:assertEqual(fetched.you, 0)
		end

		t:assertEqual(fetched.content, thread.content)
		t:assertEqual(fetched.delete_link, thread.delete_link)
		t:assertLowerOrEqual(fetched.post_count, 3)

		local fetched_posts = fetched.posts
		if #fetched_posts > 3 then
			fetched_posts = table.unpack(fetched_posts, #fetched_posts - 2, #fetched_posts)
		end

		for j, got in ipairs(fetched_posts) do
			local want = thread.posts[j]

			t:assertEqual(got.id, want.id)
			t:assertEqual(got.thread_id, want.thread_id)
			t:assertEqual(got.content, want.content)
			t:assertEqual(got.op, want.op)
			t:assertEqual(got.delete_link, want.delete_link)

			if want.token == token then
				t:assertEqual(got.you, 1)
			else
				t:assertEqual(got.you, 0)
			end
		end
	end
end)

t:run("get threads bump order", function(ctx)
	local token = "token"
	local threads = model.getThreads(ctx.db, token)
	t:assertEqual(threads.threads[1].id, 2)
	t:assertEqual(threads.threads[2].id, 1)
	model.createPost(ctx.db, 1, "content", token)
	threads = model.getThreads(ctx.db, token)
	t:assertEqual(threads.threads[1].id, 1)
	t:assertEqual(threads.threads[2].id, 2)
end)

t:run("delete thread", function(ctx)
	local thread = ctx.items.threads[1]
	model.deleteThread(ctx.db, thread.id, thread.token)
	local fetched = model.getThread(ctx.db, thread.id, thread.token)
	t:assertNil(fetched, "thread %s was not deleted" % {thread.id})
end)

t:run("delete thread with wrong token", function(ctx)
	local token = "token"
	local thread = ctx.items.threads[1]
	model.deleteThread(ctx.db, thread.id, token)
	local fetched = model.getThread(ctx.db, thread.id, token)
	t:assertNotNil(fetched, "thread %s was not deleted" % {thread.id})
end)

t:run("delete thread admin", function(ctx)
	local thread = ctx.items.threads[1]
	model.deleteThreadAdmin(ctx.db, thread.id)
	local fetched = model.getThread(ctx.db, thread.id, thread.token)
	t:assertNil(fetched, "thread %s was not deleted" % {thread.id})
end)

t:run("create post", function(ctx)
	local threadId = 1
	local content = "content"
	local token = "token"
	local created = model.createPost(ctx.db, threadId, content, token)

	t:assertEqual(created.thread_id, threadId)
	t:assertEqual(created.content, content)
	t:assertEqual(created.token, token)
	t:assertNotNil(created.created_at, "created.created_at")
	t:assertNotNil(created.id, "created.id")
end)

t:run("create post op", function(ctx)
	local token = ctx.items.tokens.john
	local created = model.createPost(ctx.db, 1, "content", token, "true")
	t:assertEqual(created.op, 1)
end)

t:run("create post op with wrong token", function(ctx)
	local token = ctx.items.tokens.jane
	local created = model.createPost(ctx.db, 1, "content", token, "true")
	t:assertEqual(created.op, 0)
end)

t:run("delete post", function(ctx)
	local thread = ctx.items.threads[1]
	model.deletePost(ctx.db, thread.posts[1].id, thread.posts[1].token)
	local fetched = assert(model.getThread(ctx.db, thread.id, "token"))
	t:assertEqual(fetched.post_count, #thread.posts - 1)
end)

t:run("delete post with wrong token", function(ctx)
	local thread = ctx.items.threads[1]
	model.deletePost(ctx.db, thread.posts[1].id, "token")
	local fetched = assert(model.getThread(ctx.db, thread.id, "token"))
	t:assertEqual(fetched.post_count, #thread.posts)
end)

t:run("delete post admin", function(ctx)
	local thread = ctx.items.threads[1]
	model.deletePostAdmin(ctx.db, thread.posts[1].id)
	local fetched = assert(model.getThread(ctx.db, thread.id, "token"))
	t:assertEqual(fetched.post_count, #thread.posts - 1)
end)

t:stats()
