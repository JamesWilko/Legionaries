
if CCurrencyController == nil then
	CCurrencyController = class({})
end

function CLegionDefence:SetupCurrencyController()
	self.currency_controller = CCurrencyController()
	self.currency_controller:Setup()
end

function CLegionDefence:GetCurrencyController()
	return self.currency_controller
end

---------------------------------------
-- Currency Controller
---------------------------------------
CURRENCY_LIMIT_NONE = 0
CURRENCY_LIMIT_HARD = 1 -- Hard limit, cap to this value at all times
CURRENCY_LIMIT_SOFT = 2 -- Soft limit, currency can go over this value, but will be lost at end of wave

-- Currency ids, use these as the nettable names
CURRENCY_GOLD = "CurrencyGold"
CCurrencyController.GOLD_DEFAULT_AMOUNT = 300

CURRENCY_GEMS = "CurrencyGems"
CCurrencyController.GEMS_DEFAULT_AMOUNT = 100
CCurrencyController.GEMS_DEFAULT_LIMIT = 200

CURRENCY_FOOD = "CurrencyFood"
CCurrencyController.FOOD_DEFAULT_AMOUNT = 20
CCurrencyController.FOOD_DEFAULT_LIMIT = 20

CCurrencyController.CURRENCY_DEFAULT_AMOUNT = 0
CCurrencyController.CURRENCY_DEFAULT_LIMIT = -1

function CCurrencyController:Setup()

	-- Table for containing currencies types, and players with currencies
	self._currency_types = {}
	self._players = {}

	-- Create currencies
	local gold = {
		default_amount = CCurrencyController.GOLD_DEFAULT_AMOUNT,
		limit_type = CURRENCY_LIMIT_NONE,
	}
	self:RegisterCurrency( CURRENCY_GOLD, CURRENCY_GOLD, gold )

	local gems = {
		default_amount = CCurrencyController.GEMS_DEFAULT_AMOUNT,
		limit = CCurrencyController.GEMS_DEFAULT_LIMIT,
		limit_type = CURRENCY_LIMIT_SOFT,
	}
	self:RegisterCurrency( CURRENCY_GEMS, CURRENCY_GEMS, gems )

	local food = {
		default_amount = CCurrencyController.FOOD_DEFAULT_AMOUNT,
		limit = CCurrencyController.FOOD_DEFAULT_LIMIT,
		limit_type = CURRENCY_LIMIT_HARD,
	}
	self:RegisterCurrency( CURRENCY_FOOD, CURRENCY_FOOD, food )

	-- Setup events
	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CCurrencyController, "HandleOnWaveComplete"), self)

end

---------------------------------------
-- Currencies
---------------------------------------
function CCurrencyController:RegisterCurrency( sCurrency, sNettable, tData )

	assert( type(sCurrency) == "string", "Currencies must be registered with a string as their id." )
	assert( type(sNettable) == "string", "Currencies must be registered with a string as their net table." )

	-- Create data table
	self._currency_types[sCurrency] = {
		net_table = sNettable,
		default_amount = tData.default_amount or CCurrencyController.CURRENCY_DEFAULT_AMOUNT,
		limit_type = tData.limit_type or CURRENCY_LIMIT_NONE,
		limit_amount = tData.limit or CCurrencyController.CURRENCY_DEFAULT_LIMIT,
	}

	print(string.format("Registered currency '%s'", sCurrency))

end

function CCurrencyController:GetCurrencyNetTable( sCurrency )
	assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )
	return self._currency_types[sCurrency].net_table
end

function CCurrencyController:GetCurrencyDefaultAmount( sCurrency )
	assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )
	return self._currency_types[sCurrency].default_amount
end

function CCurrencyController:GetCurrencyDefaultLimit( sCurrency )
	assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )
	return self._currency_types[sCurrency].limit_amount
end

function CCurrencyController:GetCurrencyLimitType( sCurrency )
	assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )
	return self._currency_types[sCurrency].limit_type
end

---------------------------------------
-- Helper Functions
---------------------------------------
function CCurrencyController:SetupNetTableDataForPlayer( sCurrency, iPlayerId )

	-- Add player to the registered players table
	local add_player = true
	for k, v in ipairs(self._players) do
		if v == iPlayerId then
			add_player = false
		end
	end
	if add_player then
		table.insert( self._players, iPlayerId )
	end

	-- Create default player data
	local data = {
		amount = self:GetCurrencyDefaultAmount(sCurrency),
		limit = self:GetCurrencyDefaultLimit(sCurrency)
	}
	return data

end

function CCurrencyController:GetPlayerId( hPlayer )
	return type(hPlayer) == "number" and hPlayer or hPlayer:GetPlayerID()
end

---------------------------------------
-- Currency Amounts
---------------------------------------
function CCurrencyController:SetCurrency( sCurrency, hPlayer, iAmount )

	if IsServer() then

		assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )

		local player_id = self:GetPlayerId( hPlayer )

		-- Get current currency
		local nettable = self:GetCurrencyNetTable( sCurrency )
		local data = CustomNetTables:GetTableValue( nettable, tostring(player_id) )

		-- Handle nil data
		if data == nil then
			data = self:SetupNetTableDataForPlayer( sCurrency, player_id )
		end

		-- Add currency amount
		data.amount = iAmount

		-- Hard limit currency amount
		if self:GetCurrencyLimitType(sCurrency) == CURRENCY_LIMIT_HARD and data.amount > data.limit then
			data.amount = data.limit
		end
		if data.amount < 0 then
			data.amount = 0
		end

		-- Set net table
		CustomNetTables:SetTableValue( nettable, tostring(player_id), data )

		return data.amount

	end

end

function CCurrencyController:ModifyCurrency( sCurrency, hPlayer, iAmount )

	if IsServer() then

		assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )

		local player_id = self:GetPlayerId( hPlayer )

		-- Get current currency
		local nettable = self:GetCurrencyNetTable( sCurrency )
		local data = CustomNetTables:GetTableValue( nettable, tostring(player_id) )

		-- Handle nil data
		if data == nil then
			data = self:SetupNetTableDataForPlayer( sCurrency, player_id )
		end

		-- Add currency amount
		data.amount = data.amount + iAmount

		-- Hard limit currency amount
		if self:GetCurrencyLimitType(sCurrency) == CURRENCY_LIMIT_HARD and data.amount > data.limit then
			data.amount = data.limit
		end
		if data.amount < 0 then
			data.amount = 0
		end

		-- Set net table
		CustomNetTables:SetTableValue( nettable, tostring(player_id), data )

		return data.amount

	end

end

function CCurrencyController:GetCurrencyAmount( sCurrency, hPlayer )

	if IsServer() then

		assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )

		local player_id = self:GetPlayerId( hPlayer )

		-- Get current currency
		local nettable = self:GetCurrencyNetTable( sCurrency )
		local data = CustomNetTables:GetTableValue( nettable, tostring(player_id) )

		-- Handle nil data
		if data == nil then
			data = self:SetupNetTableDataForPlayer( sCurrency, player_id )
		end

		return data.amount

	end

end

function CCurrencyController:CanAfford( sCurrency, hPlayer, iAmount )

	if IsServer() then

		assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )

		local player_id = self:GetPlayerId( hPlayer )

		-- Get current currency
		local nettable = self:GetCurrencyNetTable( sCurrency )
		local data = CustomNetTables:GetTableValue( nettable, tostring(player_id) )

		-- Handle nil data
		if data == nil then
			data = self:SetupNetTableDataForPlayer( sCurrency, player_id )
		end

		return (iAmount <= data.amount)

	end

end

---------------------------------------
-- Currency Limits
---------------------------------------
function CCurrencyController:ModifyCurrencyLimit( sCurrency, hPlayer, iNewLimit )

	if IsServer() then

		assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )

		local player_id = self:GetPlayerId( hPlayer )

		-- Get current currency
		local nettable = self:GetCurrencyNetTable( sCurrency )
		local data = CustomNetTables:GetTableValue( nettable, tostring(player_id) )

		-- Handle nil data
		if data == nil then
			data = self:SetupNetTableDataForPlayer( sCurrency, player_id )
		end

		-- Set currency limit
		data.limit = iNewLimit

		-- Set net table
		CustomNetTables:SetTableValue( nettable, tostring(player_id), data )

		return data.limit

	end

end

---------------------------------------
-- Handlers
---------------------------------------
function CCurrencyController:HandleOnWaveComplete( event )

	-- Process end of wave soft limits
	--[[
	for currency_name, data in pairs( self._currencies ) do
		if self:GetCurrencyLimitType( currency_name ) == CURRENCY_LIMIT_SOFT then

			for player_id, player in pairs( data ) do

				if (data.amount or 0) > (data.limit or 0) then
					-- Fire currency limit event
					local amount = data.amount - data.limit
					local data = {
						["lPlayer"] = player_id,
						["sCurrency"] = currency_name,
						["lAmount"] = nil,
					}
					FireGameEventLocal( "currency_soft_limit", data )

					-- Set currency to limit
					self._currencies[currency_name][player_id].amount = data.limit

				end

			end

		end
	end
	]]

end
