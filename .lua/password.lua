local argon2 = require("argon2")

local function hash(password)
	local hashed, err = argon2.hash_encoded(password, GetRandomBytes(64), {
       variant = argon2.variants.argon2_i,
       m_cost = 65536,
       hash_len = 24,
       parallelism = 4,
       t_cost = 2,
    })
	if hashed == nil then error(err) end
	return hashed
end

local function verify(hashed, password)
	return hashed ~= nil and argon2.verify(hashed, password)
end

return {
	hash = hash,
	verify = verify,
}
