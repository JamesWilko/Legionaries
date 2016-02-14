
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

GameAnalytics._THINK = 1
GameAnalytics._QUEUE_TIME = 5

GameAnalytics._CODES = {
	["200"] = {true, ""},
	["401"] = {false, "unauthorized"},
	["413"] = {false, "too_large"},
	["400"] = {false, "bad_request"},
}

GameAnalytics._EVENTS_QUEUE = {}
GameAnalytics._MAX_EVENTS_IN_PAYLOAD = 3

GameAnalytics._GAME_KEY = {
	["live"] = "",
	["sandbox"] = "",
}
GameAnalytics._SECRET_KEY = {
	["live"] = "",
	["sandbox"] = "",
}

GameAnalytics._SANDBOX = true
GameAnalytics._LOGGING = true
GameAnalytics._ENABLED = true

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
	if string.sub(data, 1, 1) ~= "[" then
		data = '[' .. data .. ']'
	end
	return data
end

function GameAnalytics:Initialize()

	-- NOTE:
	-- Dota Specific Think,
	-- Since we don't have access to os.time to get the epoch time, we retrieve the server timestamp during initalization
	-- and then continously increase it during the game. Then we send that timestamp as the client timestamp to the server.
	self._think_ent = IsValidEntity(self._think_ent) and self._think_ent or Entities:CreateByClassname("info_target")
	self._think_ent:SetThink("OnThink", self, "GameAnalyticsThink", GameAnalytics._THINK)

	-- Send initialization event
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

function GameAnalytics:OnThink()

	-- Dota Specific Think
	self._client_time = (self._client_time or 0) + GameAnalytics._THINK

	if (self._client_time % GameAnalytics._QUEUE_TIME) == 0 then
		GameAnalytics:SendEvents()
	end

	return GameAnalytics._THINK

end

function GameAnalytics:GetTimestamp()
	return (self._server_time or 1418274202) + (self._client_time or 0)
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

-- http://apidocs.gameanalytics.com/REST.html?json#progression
function GameAnalytics:SendProgressionEvent( id, dataTable )

	if not GameAnalytics._ENABLED then
		return false
	end

	dataTable = dataTable or {}
	dataTable["event_id"] = id
	self:BuildEventTable( "progression", dataTable )

	self:RecordEvent( dataTable )
	return true

end

-- http://apidocs.gameanalytics.com/REST.html?json#design
function GameAnalytics:SendDesignEvent( id, dataTable )

	if not GameAnalytics._ENABLED then
		return false
	end

	dataTable = dataTable or {}
	dataTable["event_id"] = id
	self:BuildEventTable( "design", dataTable )

	self:RecordEvent( dataTable )
	return true

end

function GameAnalytics:RecordEvent( payload )
	table.insert(GameAnalytics._EVENTS_QUEUE, payload)
end

function GameAnalytics:SendEvents()

	local num_queued_events = #GameAnalytics._EVENTS_QUEUE
	if num_queued_events < 1 then
		return false
	end

	-- TODO: Check if the event failed to record and re-add the events back to the queue
	local payload = {}
	local events_num = math.min(GameAnalytics._MAX_EVENTS_IN_PAYLOAD, num_queued_events)
	for i = 0, events_num, 1 do
		table.insert( payload, GameAnalytics._EVENTS_QUEUE[1] )
		table.remove( GameAnalytics._EVENTS_QUEUE, 1 )
	end

	self:SendEvent( "events", payload )

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

	self:Log("Sending GameAnalytics events...")
	req:Send(function(result)

		local success, error_code = self:GetErrorCode(result)
		if success then
			self:Log("Successfully recorded events... ")
		else
			self:Log("Failed to record events, " .. tostring(error_code))
		end

	end)

	return true

end
