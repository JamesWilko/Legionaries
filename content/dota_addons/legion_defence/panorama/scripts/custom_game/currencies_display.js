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
	if ( currencyDisplay )
	{
		var data = CustomNetTables.GetTableValue( sCurrency, Players.GetLocalPlayer().toString() );
		if( data["limit"] >= 0 )
		{
			currencyDisplay.text = data["amount"].toString() + " / " + data["limit"].toString();
		}
		else
		{
			currencyDisplay.text = data["amount"].toString();
		}
	}
}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "CurrencyGold", UpdateGold );
	CustomNetTables.SubscribeNetTableListener( "CurrencyGems", UpdateGems );
	CustomNetTables.SubscribeNetTableListener( "CurrencyFood", UpdateFood );
})();
