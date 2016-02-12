
--
-- Lua library for GameAnalytics REST API
-- http://gameanalytics.com/
-- Requires sha2.lua, base64.lua, and json.lua
-- 
-- James Wilkinson, 2016
-- http://jameswilko.com/, http://github.com/JamesWilko
--

local JSON = require 'util/json'
local sha = require 'util/sha2'
local base64 = require 'util/base64'

GameAnalytics = {}

if not GameAnalytics then
	error("Could not create the GameAnalytics global table!")
	return false
end

GameAnalytics._METHOD = "POST"
GameAnalytics._URL = "http://api.gameanalytics.com/v2/%s/"
GameAnalytics._SANDBOX_URL = "http://sandbox-api.gameanalytics.com/v2/%s/"
GameAnalytics._TIMEOUT_MS = 10000 -- 10s

GameAnalytics._GAME_KEY = {
	["live"] = "",
	["sandbox"] = "",
}
GameAnalytics._SECRET_KEY = {
	["live"] = "",
	["sandbox"] = "",
}

GameAnalytics._SANDBOX = true

function GameAnalytics:GameKey()
	local key = GameAnalytics._SANDBOX and GameAnalytics._GAME_KEY["sandbox"] or GameAnalytics._GAME_KEY["live"]
	return key
end

function GameAnalytics:SecretKey()
	local key = GameAnalytics._SANDBOX and GameAnalytics._SECRET_KEY["sandbox"] or GameAnalytics._SECRET_KEY["live"]
	return key
end

function GameAnalytics:GetURL()
	local url = GameAnalytics._SANDBOX and GameAnalytics._SANDBOX_URL or GameAnalytics._URL
	return string.format(url, self:GameKey())
end

function GameAnalytics:HTTPMethod()
	return GameAnalytics._METHOD
end

function GameAnalytics:GetAuthenticationString( data )
	local auth = sha:hmac( self:SecretKey(), data, sha.sha256 )
	local bytes = sha:ToByteArray(auth)
	local str = sha:ByteArrayToString(bytes)
	return base64:Encode(str)
end

function GameAnalytics:InitTest()

	local url = string.format("%s%s", self:GetURL(), "init")

	local payload = {
		["platform"] = "dota",
		["os_version"] = "",
		["sdk_version"] = "rest api v2"
	}
	local data = JSON:encode(payload)
	local auth = self:GetAuthenticationString( data )

	local req = CreateHTTPRequest( self:HTTPMethod(), url )
	req:SetHTTPRequestHeaderValue("Content-Type", "application/json")
	req:SetHTTPRequestHeaderValue("Authorization", auth)
	req:SetHTTPRequestRawPostBody("application/json", data)
	req:SetHTTPRequestAbsoluteTimeoutMS( self._TIMEOUT_MS )

	req:Send(function(result)
		print("Received server callback!")
		table.print(result, "")
	end)

end
