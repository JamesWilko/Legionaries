
--
-- James Wilkinson, 2016
-- http://jameswilko.com/, http://github.com/JamesWilko
--

base64 = {}

if not base64 then
	error("Could not create the base64 global table!")
	return false
end

base64._CharacterIndices = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
base64._Padding = { '', '==', '=' }
local chars = base64._CharacterIndices
local padding = base64._Padding

function base64:Encode( data )

	local d = data:gsub('.', function(x) 
		local r = ''
		local b = x:byte()
		for i = 8, 1, -1 do
			r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
		end
		return r
	end)
	d = d .. '0000'
	d = d:gsub('%d%d%d?%d?%d?%d?', function(x)
		if #x < 6 then
			return ''
		end
		local c = 0
		for i = 1, 6 do
			c = c + (x:sub(i,i) == '1' and 2 ^ (6 - i) or 0)
		end
		return chars:sub(c + 1, c + 1)
	end)
	d = d .. padding[#data % 3 + 1]
	
	return d

end

function base64:Decode( data )

	local d = string.gsub(data, '[^' .. chars .. '=]', '')
	d = d:gsub('.', function(x)
		if x == '=' then
			return ''
		end
		local r = ''
		local f = chars:find(x) - 1
		for i = 6, 1, -1 do
			r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
		end
		return r
	end)
	d = d:gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if #x ~= 8 then
			return ''
		end
		local c = 0
		for i = 1, 8 do
			c = c + (x:sub(i,i) == '1' and 2 ^ (8 - i) or 0)
		end
		return string.char(c)
	end)

end

return base64
