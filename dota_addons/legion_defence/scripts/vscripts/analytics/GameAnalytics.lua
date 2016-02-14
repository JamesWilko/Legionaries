
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

GameAnalytics._CODES = {
	["200"] = {true, ""},
	["401"] = {false, "unauthorized"},
	["413"] = {false, "too_large"},
	["400"] = {false, "bad_request"},
}

GameAnalytics._GAME_KEY = {
	["live"] = "",
	["sandbox"] = "",
}
GameAnalytics._SECRET_KEY = {
	["live"] = "",
	["sandbox"] = "",
}
GameAnalytics._SANDBOX = true

GameAnalytics._ENABLED = true
GameAnalytics._LOGGING = true

function GameAnalytics:Log( str )
	if GameAnalytics._LOGGING then
		print("[GameAnalytics] " .. tostring(str))
	end
end

function GameAnalytics:GameKey()
	local key = GameAnalytics._SANDBOX and GameAnalytics._GAME_KEY["sandbox"] or GameAnalytics._GAME_KEY["live"]
	return key
end

function GameAnalytics:SecretKey()
	local key = GameAnalytics._SANDBOX and GameAnalytics._SECRET_KEY["sandbox"] or GameAnalytics._SECRET_KEY["live"]
	return key
end

function GameAnalytics:URL()
	local url = GameAnalytics._SANDBOX and GameAnalytics._SANDBOX_URL or GameAnalytics._URL
	return string.format(url, self:GameKey())
end

function GameAnalytics:GetURL( eventType )
	return string.format("%s%s", self:URL(), eventType)
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

function GameAnalytics:GetErrorCode( httpResult )
	local code = tostring(httpResult["StatusCode"])
	return unpack( GameAnalytics._CODES[code] )
end

function GameAnalytics:GetData( httpResult )
	if httpResult and httpResult["Body"] then
		local data = JSON:decode(httpResult["Body"])
		return data
	end
	return nil
end

function GameAnalytics:EncodePayload( payload )
	local data = JSON:encode( payload )
	data = '[' .. data .. ']'
	return data
end

function GameAnalytics:Initialize()

	local url = self:GetURL("init")

	local payload = {
		["platform"] = "dota",
		["os_version"] = "",
		["sdk_version"] = "rest api v2"
	}
	
	local data = self:EncodePayload( payload )
	local auth = self:GetAuthenticationString( data )

	local req = CreateHTTPRequest( self:HTTPMethod(), url )
	req:SetHTTPRequestHeaderValue("Content-Type", "application/json")
	req:SetHTTPRequestHeaderValue("Authorization", auth)
	req:SetHTTPRequestRawPostBody("application/json", data)
	req:SetHTTPRequestAbsoluteTimeoutMS( self._TIMEOUT_MS )

	self:Log("Sending GameAnalytics initialization request...")
	req:Send(function(result)

		self:Log("Received initialization callback...")

		local success, error_id = self:GetErrorCode(result)
		local enable = false

		if success then
			local data = self:GetData(result)
			if data["enabled"] == true then
				enable = true
			else
				enable = false
			end
			self._server_time = data["server_ts"]
		end

		if enable then
			self:Log("Initialization successful, sending analytics to server.")
			self:SendSessionStartEvent()
		else
			self:Log("Error " .. error_id .. ", disabling analytics for this game session.")
			GameAnalytics._ENABLED = false
		end

	end)

end

function GameAnalytics:GetTimestamp()
	local t = (self._server_time or 1418274202) + 1
	self._server_time = t
	return t
end

function GameAnalytics:GetSessionID()
	-- TODO: Generate this
	return "de305d54-75b4-431b-adb2-eb6b9e546014"
end

function GameAnalytics:BuildEventTable( category, dataTable )

	if not self._event_data then

		self._event_data = {
			["v"] = 2,
			["device"] = "dota2server",
			["user_id"] = "00000000-0000-0000-0000-000000000000", -- TODO: Generate this
			["sdk_version"] = "rest api v2",
			["os_version"] = "windows 10.0",
			["manufacturer"] = "valve",
			["platform"] = "windows",
		}

	end

	for k, v in pairs( self._event_data ) do
		dataTable[k] = v
	end

	dataTable["category"] = category
	dataTable["client_ts"] = self:GetTimestamp()
	dataTable["session_id"] = self:GetSessionID()
	dataTable["session_num"] = 1

	return dataTable

end

function GameAnalytics:SendSessionStartEvent()

	if not GameAnalytics._ENABLED then
		return false
	end

	local dataTable = {}
	self:BuildEventTable( "user", dataTable )

	self:SendEvent( "events", dataTable )

	return true

end

function GameAnalytics:SendProgressionEvent( id, dataTable )

	if not GameAnalytics._ENABLED then
		return false
	end

	dataTable["event_id"] = id
	self:BuildEventTable( "progression", dataTable )

	self:SendEvent( "events", dataTable )

	return true

end

function GameAnalytics:SendEvent( eventType, payload )

	local url = self:GetURL( eventType )
	local data = self:EncodePayload( payload )
	local auth = self:GetAuthenticationString( data )

	local req = CreateHTTPRequest( self:HTTPMethod(), url )
	req:SetHTTPRequestHeaderValue( "Content-Type", "application/json" )
	req:SetHTTPRequestHeaderValue( "Authorization", auth )
	req:SetHTTPRequestRawPostBody( "application/json", data )
	req:SetHTTPRequestAbsoluteTimeoutMS( self._TIMEOUT_MS )

	self:Log("Sending GameAnalytics event...")
	req:Send(function(result)

		self:Log("Received event response")
		table.print(result, "\t")

	end)

end
