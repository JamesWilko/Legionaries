
---------------------------------------
-- Gem Currency
-- 	Used for purchasing king upgrades, mercenaries, and unit population increases
---------------------------------------

if CCurrencyGems == nil then
	CCurrencyGems = class({})
end

CURRENCY_GEMS = "CurrencyGems"

function CCurrencyGems:Register( controller )

	CCurrencyGems.DEFAULT_AMOUNT = 100
	CCurrencyGems.LIMIT_TYPE = CURRENCY_LIMIT_SOFT
	CCurrencyGems.DEFUALT_LIMIT = 200

	controller:RegisterCurrency(
		CURRENCY_GEMS,
		CCurrencyGems.DEFAULT_AMOUNT,
		CCurrencyGems.LIMIT_TYPE,
		CCurrencyGems.DEFUALT_LIMIT
	)

end
