
--
-- James Wilkinson, 2016
-- http://jameswilko.com/, http://github.com/JamesWilko
--
-- Adapted from wikipedia's psuedocode
-- https://en.wikipedia.org/wiki/SHA-2#Pseudocode
--

sha = {}

if not sha then
	error("Could not create the sha2 global table!")
	return false
end

local bit = require 'util/bit'
local bxor = bit.bit32.bxor
local band = bit.bit32.band
local rrotate = bit.bit32.rrotate
local rshift = bit.bit32.rshift
local bnot = bit.bit32.bnot

sha._temp = {}
sha.PRELOAD_CACHE = true
sha.BLOCK_SIZE = 64 -- 512 bits
sha.Constants = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

function sha:_LoadCache()

	if not self._xor_0x5c or not self._xor_0x36 then

		local char = string.char

		self._xor_0x5c = {}
		self._xor_0x36 = {}
		for i = 0, 0xff do
			self._xor_0x5c[char(i)] = char(bxor(i, 0x5c))
			self._xor_0x36[char(i)] = char(bxor(i, 0x36))
		end

	end

end

function sha:_PreProcess( message )
	local length = #message
	local extra = -(length + 1 + 8) % 64
	length = self:_NumberToString(8 * length, 8)
	message = message .. "\128" .. string.rep("\0", extra) .. length
	assert(#message % 64 == 0)
	return message
end

function sha:_NumberToString( number, bytes )
	local s = ""
	for i = 1, bytes do
		local rem = number % 256
		s = string.char(rem) .. s
		number = (number - rem) / 256
	end
	return s
end

function sha:_NumberSplit( number, bytes )
	local s = ""
	for i = 1, bytes do
		local rem = number % 256
		s = string.char(rem) .. s
		number = (number - rem) / 256
	end
	return s
end

function sha:_StringToNumber( str, index )
	local n = 0
	for i = index, index + 3 do
		n = n * 256 + string.byte(str, i)
	end
	return n
end

function sha:_StringToHex( str )
	return string.gsub(str, ".", function(c)
		return string.format("%02x", string.byte(c))
	end)
end

function sha:_HexToBinary( hex )
	return hex:gsub('..', function(hexval)
		return string.char( tonumber(hexval, 16) )
	end)
end

function sha:_ToBinary( message, hashFunc )
	return self:_HexToBinary( hashFunc(self, message) )
end

function sha:_Init256( tbl )
	tbl[1] = 0x6a09e667
	tbl[2] = 0xbb67ae85
	tbl[3] = 0x3c6ef372
	tbl[4] = 0xa54ff53a
	tbl[5] = 0x510e527f
	tbl[6] = 0x9b05688c
	tbl[7] = 0x1f83d9ab
	tbl[8] = 0x5be0cd19
	return tbl
end

function sha:_DigestBlock( message, chunk, tbl )

	local w = {}
	for i = 1, 16 do
		w[i] = self:_StringToNumber(message, chunk + (i - 1) * 4)
	end

	for i = 17, 64 do
		local v = w[i - 15]
		local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
		v = w[i - 2]
		local s1 = bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
		w[i] = w[i - 16] + s0 + w[i - 7] + s1
	end

	local a = tbl[1]
	local b = tbl[2]
	local c = tbl[3]
	local d = tbl[4]
	local e = tbl[5]
	local f = tbl[6]
	local g = tbl[7]
	local h = tbl[8]

	local k = self.Constants
	for i = 1, 64 do

		local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
		local ch = bxor (band(e, f), band(bnot(e), g))
		local temp1 = h + s1 + ch + k[i] + w[i]
		local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
		local maj = bxor(band(a, b), band(a, c), band(b, c))
		local temp2 = s0 + maj

		h = g
		g = f
		f = e
		e = d + temp1
		d = c
		c = b
		b = a
		a = temp1 + temp2

	end

	tbl[1] = band(tbl[1] + a)
	tbl[2] = band(tbl[2] + b)
	tbl[3] = band(tbl[3] + c)
	tbl[4] = band(tbl[4] + d)
	tbl[5] = band(tbl[5] + e)
	tbl[6] = band(tbl[6] + f)
	tbl[7] = band(tbl[7] + g)
	tbl[8] = band(tbl[8] + h)

end

function sha:_Finalize256( tbl )
	local s = self._NumberToString
	local message = s(self, tbl[1], 4) ..
					s(self, tbl[2], 4) ..
					s(self, tbl[3], 4) ..
					s(self, tbl[4], 4) ..
					s(self, tbl[5], 4) ..
					s(self, tbl[6], 4) ..
					s(self, tbl[7], 4) ..
					s(self, tbl[8], 4)
	return sha:_StringToHex(message)
end

function sha:ToByteArray( data )

	assert( type(data) == "string", "Can only encode strings via ToByteArray" )
	assert( #data % 2 == 0, "Can only convert a string of equal length to a byte array" )

	local bytes = {}
	for i = 1, #data, 2 do
		local val = string.sub(data, i, i + 1)
		local byte = tonumber("0x" .. val)
		table.insert( bytes, byte )
	end

	return bytes

end

function sha:ByteArrayToString( bytes )

	assert( type(bytes) == "table", "Can only convert a table of bytes to a string" )

	local str = ""
	for i = 1, #bytes, 1 do
		str = str .. string.char( bytes[i] )
	end

	return str

end

function sha:sha256( message )

	message = self:_PreProcess( message )
	sha._temp = self:_Init256( sha._temp )

	for i = 1, #message, 64 do
		self:_DigestBlock(message, i, sha._temp)
	end

	return self:_Finalize256(sha._temp)

end

function sha:hmac( key, message, hashFunc )

	sha:_LoadCache()

	local keyLength = #key
	if keyLength > self.BLOCK_SIZE then
		key = self:_ToBinary(key, hashFunc)
	end

	local key_0x36 = key:gsub('.', self._xor_0x36)
	key_0x36 = key_0x36 .. string.rep(string.char(0x36), self.BLOCK_SIZE - keyLength)
	local key_0x5c = key:gsub('.', self._xor_0x5c)
	key_0x5c = key_0x5c .. string.rep(string.char(0x5c), self.BLOCK_SIZE - keyLength)

	local binaryResult = self:_ToBinary( key_0x36 .. message, hashFunc )

	return hashFunc(self, key_0x5c .. binaryResult)

end

if sha.PRELOAD_CACHE then
	sha:_LoadCache()
end

return sha
