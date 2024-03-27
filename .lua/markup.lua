local re = require("re")
local quotePattern = re.compile("^>\\s*\\S")

local function normalizeNewlines(input)
	input = input:gsub("\r\n", "\n")
	input = input:gsub("\r", "\n")
	return input
end

local function trim(line)
	line = line:gsub("^[ \t]+", "")
	line = line:gsub("[ \t]+$", "")
	return line
end

local function escape(line)
	return EscapeHtml(line)
end

local function markup(input)
	local lines = {}
	input = normalizeNewlines(input)

	for line in string.gmatch(input, "([^\n]+)") do
		if quotePattern:search(line) then
			line = string.sub(line, 2, #line)
			line = trim(line)
			line = escape(line)
			table.insert(lines, '<p class="quote">%s</p>' % {line})
		else
			line = trim(line)
			line = escape(line)

			local options = {
				{"%`%`", "<code>%1</code>"},
				{"%*%*", "<strong>%1</strong>"},
				{"%_%_", "<em>%1</em>"},
				{"%%%%", '<span class="spoiler">%1</span>'},
				{"%~%~", '<span class="strikethrough">%1</span>'},
			}

			for _, o in ipairs(options) do
				line = line:gsub(o[1].."([^%s][%*%_]?)"..o[1], o[2])
				line = line:gsub(o[1].."([^%s][^<>]-[^%s][%*%_]?)"..o[1], o[2])
			end

			table.insert(lines, "<p>%s</p>" % {line})
		end
	end

	return table.concat(lines, "\n")
end

return markup
