local function migrate(db)
	local queries = {
		[[
			PRAGMA foreign_keys = ON;
		]],
		[[
			CREATE TABLE IF NOT EXISTS threads (
				id INTEGER PRIMARY KEY,
				content TEXT NOT NULL,
				token TEXT NOT NULL,
				created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
				bumped_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
			);
		]],
		[[
			CREATE INDEX IF NOT EXISTS threads_bumped_at_idx ON threads (bumped_at);
		]],
		[[
			CREATE TABLE IF NOT EXISTS posts (
				id INTEGER PRIMARY KEY,
				thread_id INTEGER NOT NULL,
				content TEXT NOT NULL,
				token TEXT NOT NULL,
				op INTEGER NOT NULL DEFAULT 0,
				created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
				FOREIGN KEY (thread_id) REFERENCES threads (id) ON DELETE CASCADE
			);
		]],
		[[
			CREATE INDEX IF NOT EXISTS posts_created_at_idx ON posts (created_at);
		]],
	}

	for _, query in ipairs(queries) do
		db:execute(query)
	end
end

local function createThread(db, content, token)
	return assert(db:fetchOne([[
		INSERT INTO threads (content, token)
		VALUES (?, ?) RETURNING *;
	]], content, token), "failed to create thread")
end

local function deleteThread(db, threadId, token)
	db:execute([[
		DELETE FROM threads
		WHERE id = ? AND token = ?;
	]], threadId, token)
end

local function createPost(db, threadId, content, token, op)
	local isOp = 0

	if op == "true" then
		local thread = db:fetchOne([[
			SELECT id FROM threads
			WHERE id = ? AND token = ?;
		]], threadId, token)

		if thread ~= nil then
			isOp = 1
		end
	end

	local post = assert(db:fetchOne([[
		INSERT INTO posts (thread_id, content, token, op)
		VALUES (?, ?, ?, ?) RETURNING *;
	]], threadId, content, token, isOp), "failed to create post")

	local count = assert(db:fetchOne([[
		SELECT count(1) AS count
		FROM posts WHERE thread_id = ?;
	]], threadId))

	if count.count < 100 then
		db:execute([[
			UPDATE threads
			SET bumped_at = CURRENT_TIMESTAMP
			WHERE id = ?;
		]], threadId)
	end

	return post
end

local function deletePost(db, postId, token)
	db:execute([[
		DELETE FROM posts
		WHERE id = ? AND token = ?;
	]], postId, token)
end

local function getThread(db, threadId, token)
	local thread = db:fetchOne([[
		SELECT id, content, created_at, '/t/' || id AS delete_link,
		CASE WHEN (token = ?) THEN 1 ELSE 0 END AS you
		FROM threads WHERE id = ?;
	]], token, threadId)

	if thread == nil then
		return nil
	end

	local posts = db:fetchAll([[
		SELECT id, thread_id, content, created_at, op,
		CASE WHEN (token = ?) THEN 1 ELSE 0 END AS you,
		'/t/' || thread_id || '/p/' || id AS delete_link
		FROM posts WHERE thread_id = ?;
	]], token, threadId)

	thread.posts = posts
	thread.post_count = #posts
	return thread
end

local function getThreads(db, token, page, pageSize)
	if page == nil then
		page = 0
	end

	if pageSize == nil then
		pageSize = 10
	end

	local result = {
		threads = {},
		prev = page - 1,
		next = 0,
	}

	if page < 0 then
		return result
	end

	local threads = assert(db:fetchAll([[
		SELECT id, content, created_at, bumped_at,
		CASE WHEN (token = ?) THEN 1 ELSE 0 END AS you,
		'/t/' || id AS delete_link FROM threads
		ORDER BY bumped_at DESC LIMIT ? OFFSET ?;
	]], token, pageSize + 1, page * pageSize), "failed to get threads")

	if threads[pageSize + 1] ~= nil then
		result.next = page + 1
		threads = {table.unpack(threads, 1, pageSize)}
	end

	local threadIds = ""
	for idx, thread in ipairs(threads) do
		if idx == 1 then
			threadIds = tostring(thread.id)
		else
			threadIds = "%s, %s" % {threadIds, thread.id}
		end
	end

	local posts = assert(db:fetchAll([[
		SELECT id, thread_id, content, created_at, op,
		CASE WHEN (token = ?) THEN 1 ELSE 0 END AS you,
		'/t/' || thread_id || '/p/' || id AS delete_link
		FROM posts WHERE thread_id IN (]]..threadIds..[[);
	]], token), "failed to get thread posts")

	local threadPosts = {}
	for _, post in ipairs(posts) do
		local threadId = post.thread_id

		if threadPosts[threadId] == nil then
			threadPosts[threadId] = {post}
		else
			table.insert(threadPosts[threadId], post)
		end
	end

	local enriched = {}
	for _, thread in ipairs(threads) do
		if threadPosts[thread.id] == nil then
			thread.posts = {}
			thread.post_count = 0
		else
			table.sort(threadPosts[thread.id], function(x, y) return x.created_at < y.created_at end)
			thread.post_count = #threadPosts[thread.id]

			if thread.post_count <= 3 then
				thread.posts = threadPosts[thread.id]
			else
				thread.posts = {table.unpack(threadPosts[thread.id], thread.post_count - 2, thread.post_count)}
			end
		end

		table.insert(enriched, thread)
	end

	result.threads = enriched
	return result
end

return {
	migrate = migrate,
	createThread = createThread,
	getThread = getThread,
	getThreads = getThreads,
	deleteThread = deleteThread,
	createPost = createPost,
	deletePost = deletePost,
}
