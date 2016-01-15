
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

CURRENCY_INCOME_NONE = 0
CURRENCY_INCOME_PER_ROUND = 1 -- Income is added at the end of every round
CURRENCY_INCOME_PER_MINUTE = 2 -- Income is added continuously of a rate of X per minute

-- Currency ids, use these as the nettable names
CURRENCY_GOLD = "CurrencyGold"
CCurrencyController.GOLD_DEFAULT_AMOUNT = 300
CCurrencyController.GOLD_DEFAULT_INCOME = 0

CURRENCY_GEMS = "CurrencyGems"
CCurrencyController.GEMS_DEFAULT_AMOUNT = 80
CCurrencyController.GEMS_DEFAULT_LIMIT = 200
CCurrencyController.GEMS_DEFAULT_INCOME = 0

CURRENCY_FOOD = "CurrencyFood"
CCurrencyController.FOOD_DEFAULT_AMOUNT = 0
CCurrencyController.FOOD_DEFAULT_LIMIT = 0

CCurrencyController.CURRENCY_DEFAULT_AMOUNT = 0
CCurrencyController.CURRENCY_DEFAULT_LIMIT = -1
CCurrencyController.INCOME_THINK_DELAY = 1
CCurrencyController.SHOW_PARTICLES_FOR_PASSIVE_INCOME = false

function CCurrencyController:Setup()

	-- Table for containing currencies types, and players with currencies
	self._currency_types = {}
	self._players = {}

	-- Create currencies
	local gold = {
		default_amount = CCurrencyController.GOLD_DEFAULT_AMOUNT,
		limit_type = CURRENCY_LIMIT_NONE,
		income_type = CURRENCY_INCOME_PER_ROUND,
		default_income = CCurrencyController.GOLD_DEFAULT_INCOME,
	}
	self:RegisterCurrency( CURRENCY_GOLD, gold )

	local gems = {
		default_amount = CCurrencyController.GEMS_DEFAULT_AMOUNT,
		limit = CCurrencyController.GEMS_DEFAULT_LIMIT,
		limit_type = CURRENCY_LIMIT_SOFT,
		income_type = CURRENCY_INCOME_PER_MINUTE,
		default_income = CCurrencyController.GEMS_DEFAULT_INCOME,
	}
	self:RegisterCurrency( CURRENCY_GEMS, gems )

	local food = {
		default_amount = CCurrencyController.FOOD_DEFAULT_AMOUNT,
		limit = CCurrencyController.FOOD_DEFAULT_LIMIT,
		limit_type = CURRENCY_LIMIT_HARD,
	}
	self:RegisterCurrency( CURRENCY_FOOD, food )

	-- Setup income think
	if IsServer() then
		GameRules:GetGameModeEntity():SetThink( "OnIncomeThink", self, "CurrencyControllerIncomeThink", CCurrencyController.INCOME_THINK_DELAY )
	end

	-- Setup events
	ListenToGameEvent("legion_player_assigned_lane", Dynamic_Wrap(CCurrencyController, "OnPlayerAssignedLane"), self)
	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CCurrencyController, "HandleOnWaveComplete"), self)

end

---------------------------------------
-- Currencies
---------------------------------------
function CCurrencyController:RegisterCurrency( sCurrency, tData )

	assert( type(sCurrency) == "string", "Currencies must be registered with a string as their id." )

	-- Create data table
	self._currency_types[sCurrency] = {
		net_table = sCurrency,
		default_amount = tData.default_amount or CCurrencyController.CURRENCY_DEFAULT_AMOUNT,
		limit_type = tData.limit_type or CURRENCY_LIMIT_NONE,
		limit_amount = tData.limit or CCurrencyController.CURRENCY_DEFAULT_LIMIT,
		income_type = tData.income_type or CURRENCY_INCOME_NONE,
		default_income = tData.default_income or 0,
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

function CCurrencyController:GetCurrencyDefaultIncome( sCurrency )
	assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )
	return self._currency_types[sCurrency].default_income
end

---------------------------------------
-- Helper Functions
---------------------------------------
function CCurrencyController:SetupNetTableDataForPlayer( sCurrency, iPlayerId )

	assert( type(iPlayerId) == "number", "Player ID must be a number to create a player data table!" )

	-- Add player to the registered players table
	local add_player = true
	for k, v in ipairs(self._players) do
		if v == iPlayerId then
			add_player = false
			break
		end
	end
	if add_player then
		print(string.format("Adding player '%i' to players currency table", iPlayerId))
		table.insert( self._players, iPlayerId )
	end

	-- Create default player data
	local data = {
		amount = self:GetCurrencyDefaultAmount(sCurrency),
		limit = self:GetCurrencyDefaultLimit(sCurrency),
		income = self:GetCurrencyDefaultIncome(sCurrency),
		income_accrued = 0.0,
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

function CCurrencyController:ModifyCurrency( sCurrency, hPlayer, iAmount, bSupressParticles )

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

		-- Play particles
		if not bSupressParticles then

			local player = PlayerResource:GetPlayer( player_id )
			if player then
				local player_hero = player:GetAssignedHero()
				if iAmount < 0 then
					PlayCurrencyLostParticles( sCurrency, -iAmount, player_hero )
				elseif iAmount > 0 then
					PlayCurrencyGainedParticles( sCurrency, iAmount, player_hero )
				end
				ShowCurrencyPopup( player_hero, sCurrency, iAmount, 1 )
			end

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

function CCurrencyController:CanAfford( sCurrency, hPlayer, iAmount, bPlaySound )

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

		-- Play sound
		local canAfford = iAmount <= data.amount
		if not canAfford and bPlaySound then
			EmitSoundOnClient("General.InvalidTarget_Invulnerable", PlayerResource:GetPlayer(player_id))	
		end

		return canAfford

	end

end

---------------------------------------
-- Currency Limits
---------------------------------------
function CCurrencyController:SetCurrencyLimit( sCurrency, hPlayer, iNewLimit )

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

function CCurrencyController:GetCurrencyLimit( sCurrency, hPlayer )

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

		return data.limit

	end

end

function CCurrencyController:ProcessEndOfWaveLimits()

	-- Process end of wave soft limits
	for currency, cur_data in pairs( self._currency_types ) do
		if self:GetCurrencyLimitType( currency ) == CURRENCY_LIMIT_SOFT then

			for i, player_id in pairs( self._players ) do

				local amount = self:GetCurrencyAmount( currency, player_id )
				local limit = self:GetCurrencyLimit( currency, player_id )
				if limit < amount then

					-- Process overflow amount
					local overflow = amount - limit
					local data = {
						["lPlayer"] = player_id,
						["sCurrency"] = currency,
						["lAmount"] = overflow,
					}
					FireGameEventLocal( "currency_soft_limit", data )

					-- Set currency to limit
					self:SetCurrency( currency, player_id, limit )

				end

			end

		end
	end

end

---------------------------------------
-- Incomes
---------------------------------------
function CCurrencyController:SetCurrencyIncome( sCurrency, hPlayer, iNewIncome, bRelative )

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

		-- Set currency income
		if not bRelative then
			data.income = iNewIncome
		else
			data.income = data.income + iNewIncome
		end
		
		-- Set net table
		CustomNetTables:SetTableValue( nettable, tostring(player_id), data )

		return data.income

	end

end

function CCurrencyController:OnIncomeThink()

	if IsServer() then

		-- Run through all currencies for all players
		for currency, currencyData in pairs(self._currency_types) do
			if currencyData.income_type == CURRENCY_INCOME_PER_MINUTE then
				for i, player_id in pairs( self._players ) do

					-- Get currency table for player
					local nettable = self:GetCurrencyNetTable( currency )
					local playerData = CustomNetTables:GetTableValue( nettable, tostring(player_id) )
					if playerData then

						-- Increment income earned during think delay
						local income_amount = playerData.income * (CCurrencyController.INCOME_THINK_DELAY / 60)
						playerData.income_accrued = playerData.income_accrued + income_amount

						-- When income is able to be added
						if playerData.income_accrued >= 1 then

							-- Add income to currency amounts
							local immediate_income = math.floor(playerData.income_accrued)
							playerData.income_accrued = playerData.income_accrued - immediate_income
							self:ModifyCurrency( currency, player_id, immediate_income, not CCurrencyController.SHOW_PARTICLES_FOR_PASSIVE_INCOME )

							-- Get updated datatable before saving income
							local updatedData = CustomNetTables:GetTableValue( nettable, tostring(player_id) )
							updatedData.income_accrued = playerData.income_accrued
							playerData = updatedData

						end

						-- Set new accrued income in net table
						CustomNetTables:SetTableValue( nettable, tostring(player_id), playerData )

					end

				end
			end
		end

		-- Think again
		return CCurrencyController.INCOME_THINK_DELAY

	end

end

function CCurrencyController:ProcessEndOfWaveIncome()

	if IsServer() then

		-- Run through all currencies for all players
		for currency, currencyData in pairs(self._currency_types) do
			if currencyData.income_type == CURRENCY_INCOME_PER_ROUND then
				for i, player_id in pairs( self._players ) do

					-- Get currency table for player
					local nettable = self:GetCurrencyNetTable( currency )
					local playerData = CustomNetTables:GetTableValue( nettable, tostring(player_id) )
					if playerData then

						-- Add income to currency amounts
						self:ModifyCurrency( currency, player_id, playerData.income )

					end

				end
			end
		end

		-- Think again
		return CCurrencyController.INCOME_THINK_DELAY

	end

end

---------------------------------------
-- Handlers
---------------------------------------
function CCurrencyController:HandleOnWaveComplete( event )
	self:ProcessEndOfWaveLimits()
	self:ProcessEndOfWaveIncome()
end

function CCurrencyController:OnPlayerAssignedLane( data )

	local playerId = data["lPlayer"]
	for currency, currencyData in pairs(self._currency_types) do
		local nettable = self:GetCurrencyNetTable( currency )
		local data = self:SetupNetTableDataForPlayer( currency, playerId )
		CustomNetTables:SetTableValue( nettable, tostring(playerId), data )
	end

end
