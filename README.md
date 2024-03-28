```
local fm = require("fullmoon")

local function ensureToken(r)
	if r.cookies.token == nil then
		local token = EscapePass(GetRandomBytes(64))
		r.cookies.token = {token, httponly = true, samesite = "Strict", path = "/"}
		return token
	end

	return r.cookies.token
end

local function redirectToThread(threadId)
	return fm.serveRedirect(302, "/t/%s" % {threadId})
end

fm.setTemplate({"/templates/", html="fmt"})

fm.setTemplate("400", function ()
	return fm.render("error", {text="400 - Bad request"})
end)

fm.setTemplate("403", function ()
	return fm.render("error", {text="403 - Forbidden"})
end)

fm.setTemplate("404", function ()
	return fm.render("error", {text="404 - No such thing"})
end)

fm.setTemplate("500", function ()
	return fm.render("error", {text="500 - Internal error"})
end)

fm.setRoute("/favicon.ico", "/static/favicon.ico")
fm.setRoute("/styles.css", "/static/styles.css")
fm.setRoute("/logo.png", "/static/logo.png")

fm.setRoute(fm.POST("/t"), function (r)
	local token = ensureToken(r)
	local thread = createThread(ml(r.params.content), token)
	return redirectToThread(thread.id)
end)

fm.setRoute(fm.GET("/t/:threadId[%d]"), function (r)
	local token = ensureToken(r)
	local status, thread = pcall(getThread, r.params.threadId, token)
	if status == false or thread.id == nil then
		return fm.serve404
	end
	return fm.render("thread", {thread=thread})
end)

fm.setRoute(fm.POST("/t/:threadId[%d]"), function (r)
	local threadId = r.params.threadId

	if r.params.action ~= "delete" then
		return fm.serve400
	end

	local token = ensureToken(r)
	deleteThread(threadId, token)
	return fm.serveRedirect(302, "/")
end)

fm.setRoute(fm.POST("/t/:threadId[%d]/p"), function (r)
	local token = ensureToken(r)
	local threadId = tonumber(r.params.threadId)
	local status, _ = pcall(createPost, threadId, ml(r.params.content), token, r.params.op)
	if status == false then
		return fm.serve400
	end
	return redirectToThread(threadId)
end)

fm.setRoute(fm.POST("/t/:threadId[%d]/p/:postId[%d]"), function (r)
	local threadId = r.params.threadId

	if r.params.action ~= "delete" then
		return fm.serve400
	end

	local token = ensureToken(r)
	deletePost(r.params.postId, token)
	return redirectToThread(threadId)
end)

fm.setRoute(fm.GET("/"), function (r)
	local token = ensureToken(r)
	local threads = getThreads(token, 0)
	return fm.render("home", {threads=threads})
end)

fm.setRoute(fm.GET("/:page[%d]"), function (r)
	local token = ensureToken(r)
	local page = tonumber(r.params.page)
	local threads = getThreads(token, page)
	return fm.render("home", {threads=threads})
end)

fm.setRoute(fm.GET("/faq"), function ()
	return fm.render("faq")
end)

fm.run()
```
