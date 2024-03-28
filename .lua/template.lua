local templates = {
	faq = '<h4>What is this?</h4><p>This is a textboard where you can anonymous' ..
		'ly view and write posts and chat with other users, inspired by old for' ..
		'ums and imageboards.</p><h4>How to format text?</h4><table><thead><tr>' ..
		'<th>Effect</th><th>Example</th><th>Result</th></tr></thead><tbody><tr>' ..
		'<td>Bold</td><td>**text**</td><td><strong>text</strong></td></tr><tr><' ..
		'td>Italic</td><td>__text__</td><td><em>text</em></td></tr><tr><td>Mono' ..
		'spaced</td><td>`text`</td><td><code>text</code></td></tr><tr><td>Strik' ..
		'ethrough</td><td>~~text~~</td><td><s>text</s></td></tr><tr><td>Spoiler' ..
		'</td><td>%%text%%</td><td><span class="spoiler">text</span></td></tr><' ..
		'tr><td>Quote</td><td>&gt;text</td><td><span class="quote">text</span><' ..
		'/td></tr></tbody></table><h4>Why no code blocks?</h4><p>Use pastebin.<' ..
		'/p><h4>Why make this?</h4><p>To learn Lua.</p>',
	headerEnd = '</title><meta charset="utf-8" /><meta name="viewport" content=' ..
		'"width=device-width, initial-scale=1" /><link rel="stylesheet" href="/' ..
		'styles.css" /><link rel="icon" type="image/x-icon" href="/favicon.ico"' ..
		'></head><body><header><a href="/"><img src="/logo.png" alt="nomoon log' ..
		'o" height="32px" /></a><nav><a href="/faq">faq</a> <a href="/">home</a' ..
		'></nav></header><main>',
	createPostEnd = '/p" method="post"><textarea name="content"></textarea><div' ..
		' class="controls"><label for="op">OP <input type="checkbox" id="op" na' ..
		'me="op" value="true" /></label><input type="submit" value="Send post" ' ..
		'/></div></form>',
	createThread = '<form action="/t" method="post"><textarea name="content"></' ..
		'textarea><div class="controls"><input type="submit" value="Create thre' ..
		'ad" /></div></form>',
	footer = '</main><footer><p>source code: <a href="https://git.sr.ht/~ansipu' ..
		'nk/nomoon">sourcehut/~ansipunk/nomoon</a></p></footer></body></html>',
	deleteEnd = '"><button type="submit" name="action" value="delete">delete</b' ..
		'utton></form>',
	deleteStart = '<form class="delete" method="post" action="',
	headerStart = '<!DOCTYPE html><html><head><title>nomoon / ',
	paginatorStart = '<div class="paginator">',
	contentStart = '<div class="content">',
	createPostStart = '<form action="/t/',
	threadStart = '<div class="thread">',
	you = '<span class="you">You</span>',
	metaStart = '<div class="meta"><p>',
	op = '<span class="op">OP</span>',
	errorStart = '<h1 class="error">',
	postStart = '<div class="post">',
	pageOld = 'Older threads</a>',
	pageNew = 'Newer threads</a>',
	replyStart = '<a href="/t/',
	replyEnd = '">reply</a>',
	pageStart = '<a href="',
	replies = ' replies',
	homeTitle = 'home',
	errorEnd = '</h1>',
	divEnd = '</div>',
	metaEnd = '</p>',
	ellipsis = '...',
	faqTitle = 'faq',
	metaMid = ' / ',
	pageMid = '">',
	hr = '<hr />',
	itemId = "#",
}

local function renderPage(title, content)
	return templates.headerStart .. title .. templates.headerEnd .. content .. templates.footer
end

local function renderItem(item)
	local rendered = templates.metaStart .. item.created_at .. templates.metaMid .. templates.itemId .. tostring(item.id)
	if item.post_count ~= nil then rendered = rendered .. templates.metaMid .. tostring(item.post_count) .. templates.replies end
	if item.you == 1 then rendered = rendered .. templates.metaMid .. templates.you end
	if item.op == 1 then rendered = rendered .. templates.metaMid .. templates.op end
	if item.posts ~= nil then rendered = rendered .. templates.metaMid .. templates.replyStart .. tostring(item.id) .. templates.replyEnd end
	rendered = rendered .. templates.metaEnd
	if item.you == 1 then rendered = rendered .. templates.deleteStart .. item.delete_link .. templates.deleteEnd end
	return rendered .. templates.divEnd .. templates.contentStart .. item.content .. templates.divEnd
end

local function renderThread(thread)
	local rendered = templates.threadStart .. renderItem(thread)
	for _, post in ipairs(thread.posts) do rendered = rendered .. templates.postStart .. renderItem(post) .. templates.divEnd end
	return rendered .. templates.divEnd .. templates.hr
end

local function renderHomePage(threads)
	local content = templates.createThread
	for _, thread in ipairs(threads.threads) do content = content .. renderThread(thread) end
	content = content .. templates.paginatorStart
	if threads.next > 0 then content = content .. templates.pageStart .. tostring(threads.next) .. templates.pageOld end
	if threads.prev >= 0 then content = content .. templates.pageStart .. tostring(threads.prev) .. templates.pageNew end
	content = content .. templates.divEnd
	return renderPage(templates.homeTitle, content)
end

local function renderThreadPage(thread)
	local title = templates.itemId .. tostring(thread.id)
	local content = renderThread(thread) .. templates.createPostStart .. tostring(thread.id) .. templates.createPostEnd
	return renderPage(title, content)
end

local function renderErrorPage(err)
	local content = templates.errorStart .. err .. templates.errorEnd
	return renderPage(err, content)
end

local function renderFaqPage()
	return renderPage(templates.faqTitle, templates.faq)
end

return {
	renderErrorPage = renderErrorPage,
	renderFaqPage = renderFaqPage,
	renderHomePage = renderHomePage,
	renderThreadPage = renderThreadPage,
}
