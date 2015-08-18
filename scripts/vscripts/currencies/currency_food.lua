
---------------------------------------
-- Food Currency
-- 	Used for purchasing and keeping units on the field
---------------------------------------

if CCurrencyFood == nil then
	CCurrencyFood = class({})
end

CURRENCY_FOOD = "CurrencyFood"

function CCurrencyFood:Register( controller )

	CCurrencyFood.DEFAULT_AMOUNT = 20
	CCurrencyFood.LIMIT_TYPE = CURRENCY_LIMIT_HARD
	CCurrencyFood.DEFUALT_LIMIT = 20

	controller:RegisterCurrency(
		CURRENCY_FOOD,
		CCurrencyFood.DEFAULT_AMOUNT,
		CCurrencyFood.LIMIT_TYPE,
		CCurrencyFood.DEFUALT_LIMIT
	)

end
