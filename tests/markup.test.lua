local markup = require("markup")
local test = require("test")

local t = test("markup")

t:run("escape html", function()
	local input = '</html>&<script>'
	local want = '<p>&lt;/html>&amp;&lt;script></p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("single paragraph", function()
	local input = 'Hello world!'
	local want = '<p>Hello world!</p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("multiple paragraphs", function()
	local input = 'Hello world!\nhello.'
	local want = '<p>Hello world!</p>\n<p>hello.</p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("trim whitespace", function()
	local input = '  Hello world !\nhello.     '
	local want = '<p>Hello world !</p>\n<p>hello.</p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("inline bold", function()
	local input = 'this is **bold** and this is ** not\nalso not **'
	local want = '<p>this is <strong>bold</strong> and this is ** not</p>\n<p>also not **</p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("inline italic", function()
	local input = 'this is __italic__ and this is __ not\nalso not __'
	local want = '<p>this is <em>italic</em> and this is __ not</p>\n<p>also not __</p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("inline monospaced", function()
	local input = 'this is ``monospaced`` and this is `` not\nalso not ``'
	local want = '<p>this is <code>monospaced</code> and this is `` not</p>\n<p>also not ``</p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("inline spoiler", function()
	local input = 'this is %%spoilered%% and this is %% not\nalso not %%'
	local want = '<p>this is <span class="spoiler">spoilered</span> and this is %% not</p>\n<p>also not %%</p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("inline strikethrough", function()
	local input = 'this is ~~striked~~ and this is ~~ not\nalso not ~~'
	local want = '<p>this is <s>striked</s> and this is ~~ not</p>\n<p>also not ~~</p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("inline mixed", function()
	local input = 'hello **this__is**an__example__'
	local want = '<p>hello <strong>this__is</strong>an<em>example</em></p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:run("blockquote", function()
	local input = '>quote\ntext\n>  quote\n>\tquote'
	local want = '<p class="quote">quote</p>\n<p>text</p>\n<p class="quote">quote</p>\n<p class="quote">quote</p>'
	local got = markup(input)
	t:assertEqual(got, want)
end)

t:stats()
