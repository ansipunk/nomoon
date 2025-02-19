local function resolve(route)
	local elements = {}
	for element in string.gmatch(route, "([^/]+)") do
		table.insert(elements, element)
	end

	if #elements > 4 then return nil end

	if #elements == 0 then
		return {entity = "root", threadId = 0, postId = 0, page = 0}
	end

	if #elements == 1 then
		local page = tonumber(elements[1])
		if page ~= nil then
			return {entity = "root", threadId = 0, postId = 0, page = page}
		end

		if elements[1] == "t" then
			return {entity = "thread", threadId = 0, postId = 0, page = 0}
		elseif elements[1] == "faq" then
			return {entity = "faq", threadId = 0, postId = 0, page = 0}
		elseif elements[1] == "favicon.ico" then
			return {entity = "favicon", threadId = 0, postId = 0, page = 0}
		elseif elements[1] == "styles.css" then
			return {entity = "styles", threadId = 0, postId = 0, page = 0}
		elseif elements[1] == "logo.png" then
			return {entity = "logo", threadId = 0, postId = 0, page = 0}
		end

		return nil
	end

	if elements[1] ~= "t" then return nil end
	local threadId = tonumber(elements[2])
	if threadId == nil then return nil end

	if #elements == 2 then
		return {entity = "thread", threadId = threadId, postId = 0, page = 0}
	end

	if elements[3] ~= "p" then return nil end
	if #elements == 3 then
		return {entity = "post", threadId = threadId, postId = 0, page = 0}
	end

	local postId = tonumber(elements[4])
	if postId == nil then return nil end

	return {entity = "post", threadId = threadId, postId = postId, page = 0}
end

return resolve
