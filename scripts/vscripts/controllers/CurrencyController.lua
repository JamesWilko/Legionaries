
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

CCurrencyController.CURRENCY_DEFAULT_AMOUNT = 0
CCurrencyController.CURRENCY_DEFAULT_LIMIT = -1

function CCurrencyController:Setup()

	-- Table for containing currencies for players
	self._currency_types = {}
	self._currencies = {}

	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CCurrencyController, "HandleOnWaveComplete"), self)

end

function CCurrencyController:RegisterCurrency( sCurrency, iDefaultAmount, enumLimitType, iDefaultLimit )

	assert( type(sCurrency) == "string", "Currencies must be registered with a string as their id." )
	assert( enumLimitType == CURRENCY_LIMIT_NONE or enumLimitType == CURRENCY_LIMIT_NONE or enumLimitType == CURRENCY_LIMIT_SOFT,
	"Unrecognized currency limit type! Please specify a currency limit type specified in CurrencyController." )

	self._currency_types[sCurrency] = {
		default_amount = iDefaultAmount or CCurrencyController.CURRENCY_DEFAULT_AMOUNT,
		limit_type = enumLimitType,
		limit_amount = iDefaultLimit or CCurrencyController.CURRENCY_DEFAULT_LIMIT,
	}

end

---------------------------------------
-- Helper Functions
---------------------------------------
function CCurrencyController:_CreateCurrencyPlayerTable( sCurrency, iPlayerId )

	if self._currencies[sCurrency] == nil then
		self._currencies[sCurrency] = {}
	end

	if self._currencies[sCurrency][iPlayerId] == nil then

		local currency_data = self._currency_types[sCurrency]
		self._currencies[sCurrency][iPlayerId] = {
			amount = currency_data.default_amount or CCurrencyController.CURRENCY_DEFAULT_AMOUNT,
			limit = currency_data.limit_amount or CCurrencyController.CURRENCY_DEFAULT_LIMIT
		}

	end

end

function CCurrencyController:_GetPlayerId( hPlayer )
	return type(hPlayer) == "number" and hPlayer or hPlayer:GetPlayerID()
end

---------------------------------------
-- Currency Amounts
---------------------------------------
function CCurrencyController:AddCurrency( sCurrency, hPlayer, iAmount )

	assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )
	assert( iAmount >= 0, "AddCurrency must add a positive amount to the player currency, use TakeCurrency to remove currency!" )

	local id = self:_GetPlayerId( hPlayer )
	self:_CreateCurrencyPlayerTable( sCurrency, id )

	-- Add currency to player
	self._currencies[sCurrency][id].amount = self._currencies[sCurrency][id].amount + iAmount

	-- Hard limit currency
	if self._currency_types[sCurrency].limit_type == CURRENCY_LIMIT_HARD then
		if self._currencies[sCurrency][id].amount > self._currencies[sCurrency][id].limit then
			self._currencies[sCurrency][id].amount = self._currencies[sCurrency][id].limit
		end
	end

	return self._currencies[sCurrency][id].amount

end

function CCurrencyController:TakeCurrency( sCurrency, hPlayer, iAmount )

	assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be used!" )
	assert( iAmount <= 0, "TakeCurrency must remove a negative amount to the player currency, use AddCurrency to add currency!" )

	local id = self:_GetPlayerId( hPlayer )
	self:_CreateCurrencyPlayerTable( sCurrency, id )

	-- Take currency
	self._currencies[sCurrency][id].amount = self._currencies[sCurrency][id].amount - iAmount

	-- Prevent currency from going negative
	if self._currencies[sCurrency][id].amount < 0 then
		self._currencies[sCurrency][id].amount = 0
	end

	return self._currencies[sCurrency][id].amount

end

function CCurrencyController:GetCurrency( sCurrency, hPlayer )

	assert( self._currency_types[sCurrency] ~= nil, "Currencies must be registered before they can be retrieved!" )

	local id = self:_GetPlayerId( hPlayer )
	self:_CreateCurrencyPlayerTable( sCurrency, id )
	return self._currencies[sCurrency][id].amount

end

---------------------------------------
-- Currency Limits
---------------------------------------
function CCurrencyController:SetCurrencyLimit( sCurrency, hPlayer, iLimit )
	local id = self:_GetPlayerId( hPlayer )
	self:_CreateCurrencyPlayerTable( sCurrency, id )
	return self._currencies[sCurrency][id].limit
end

function CCurrencyController:GetCurrencyLimit( sCurrency, hPlayer )
	local id = self:_GetPlayerId( hPlayer )
	self:_CreateCurrencyPlayerTable( sCurrency, id )
	return self._currencies[sCurrency][id].limit
end

function CCurrencyController:GetCurrencyLimitType( sCurrency )
	return self._currency_types[sCurrency].limit_type
end

---------------------------------------
-- Handlers
---------------------------------------
function CCurrencyController:HandleOnWaveComplete( event )

	-- Process end of wave soft limits
	for currency_name, data in pairs( self._currencies ) do
		if self:GetCurrencyLimitType( currency_name ) == CURRENCY_LIMIT_SOFT then

			for player_id, player in pairs( data ) do

				if data.amount > data.limit then
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

end
