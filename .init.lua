-- [[ nomoon ]]

local template = require("template")
local password = require("password")
local markup = require("markup")
local router = require("router")
local sqlite = require("sqlite")
local model = require("model")

local db = sqlite(arg[1])

local function getToken()
	local token = GetCookie("token")
	if token == nil or token == "" then
		token = EscapePass(GetRandomBytes(64))
		SetCookie("token", token, {Path="/", HttpOnly=true, SameSite="Strict"})
	end
	return token
end

local function isAdmin()
	local token = GetCookie("admin")
	return token ~= nil and password.verify(arg[2], token)
end

local function getFormContent()
	local content = GetParam("content")
	if content == nil then return nil end
	if #content > 4096 then content = string.sub(content, 1, 4096) end
	content = markup(content)
	if content == "" then return nil end
	return content
end

local function serveHtml(content)
	SetHeader("Content-Type", "text/html; charset=utf-8")
	Write(content)
end

local function serveError(code, err)
	if err == nil then
		err = tostring(code)
	else
		err = code .. " - " .. err
	end

	SetStatus(code)
	serveHtml(template.renderErrorPage(err))
end

local function serveRedirect(target)
	SetStatus(302)
	SetHeader("Location", target)
end

local function serveRequest()
	local route = router(GetPath())
	local token = getToken()
	local method = GetMethod()
	local admin = isAdmin()

	if route ~= nil then
		if method == "GET" then
			if route.entity == "favicon" then return ServeAsset("/static/favicon.ico") end
			if route.entity == "styles" then return ServeAsset("/static/styles.css") end
			if route.entity == "logo" then return ServeAsset("/static/logo.png") end
			if route.entity == "faq" then return serveHtml(template.renderFaqPage()) end

			if route.entity == "root" then
				local threads = model.getThreads(db, token, route.page)
				return serveHtml(template.renderHomePage(threads, admin))
			elseif route.entity == "thread" and route.threadId ~= 0 then
				local thread = model.getThread(db, route.threadId, token)
				if thread == nil then return serveError(404, "No such thing") end
				return serveHtml(template.renderThreadPage(thread, admin))
			end
		elseif method == "POST" then
			if route.entity == "thread" then
				if route.threadId == 0 then
					local content = getFormContent()
					if content == nil then serveError(400, "Bad request") end
					local thread = model.createThread(db, content, token)
					return serveRedirect("/t/" .. tostring(thread.id))
				elseif GetParam("action") == "delete" then
					if admin then
						model.deleteThreadAdmin(db, route.threadId)
					else
						model.deleteThread(db, route.threadId, token)
					end
					return serveRedirect("/")
				end
			elseif route.entity == "post" and route.threadId ~= 0 then
				if route.postId == 0 then
					local content = getFormContent()
					if content == nil then serveError(400, "Bad request") end
					local op = GetParam("op")
					model.createPost(db, route.threadId, content, token, op)
					return serveRedirect("/t/" .. tostring(route.threadId))
				elseif GetParam("action") == "delete" then
					if admin then
						model.deletePostAdmin(db, route.postId)
					else
						model.deletePost(db, route.postId, token)
					end
					return serveRedirect("/t/" .. tostring(route.threadId))
				end
			end
		end
	end

	return serveError(404, "No such thing")
end

ProgramCache(24 * 60 * 60)

function OnServerStart()
	model.migrate(db)
end

function OnHttpRequest()
	local status, err = pcall(serveRequest)

	if not status then
		serveError(500, "Internal error")
		error(err)
	end
end
