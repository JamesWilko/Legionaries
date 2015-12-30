"use strict";

function UpdateGold()
{
	UpdateCurrency( "CurrencyGold" );
}

function UpdateGems()
{
	UpdateCurrency( "CurrencyGems" );
}

function UpdateFood()
{
	UpdateCurrency( "CurrencyFood" );
}

function UpdateCurrency( sCurrency )
{
	var currencyDisplay = $( "#" + sCurrency );
	var currencyIncomeDisplay = $( "#" + sCurrency + "Income" );
	if ( currencyDisplay )
	{
		var data = CustomNetTables.GetTableValue( sCurrency, Players.GetLocalPlayer().toString() );
		if(data)
		{
			if( data["limit"] >= 0 )
			{
				currencyDisplay.text = data["amount"].toString() + " / " + data["limit"].toString();
			}
			else
			{
				currencyDisplay.text = data["amount"].toString();
			}
			if( currencyIncomeDisplay )
			{
				if( data["income"] > 0 )
				{
					currencyIncomeDisplay.text = "+" + data["income"];
				}
				else
				{
					currencyIncomeDisplay.text = "";
				}
			}
		}
		else
		{
			currencyDisplay.text = "-";
			currencyIncomeDisplay.text = "";
		}
	}
}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "CurrencyGold", UpdateGold );
	CustomNetTables.SubscribeNetTableListener( "CurrencyGems", UpdateGems );
	CustomNetTables.SubscribeNetTableListener( "CurrencyFood", UpdateFood );

	UpdateGold();
	UpdateGems();
	UpdateFood();
})();
