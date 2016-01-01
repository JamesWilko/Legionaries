
var m_CurrencyLocals = [];
m_CurrencyLocals["CurrencyGold"] = "legion_currency_gold";
m_CurrencyLocals["CurrencyGems"] = "legion_currency_gems";
m_CurrencyLocals["CurrencyFood"] = "legion_currency_food";

var m_CurrencyColours = [];
m_CurrencyColours["CurrencyGold"] = "yellow";
m_CurrencyColours["CurrencyGems"] = "cyan";
m_CurrencyColours["CurrencyFood"] = "orange";

function ShowTooltip( panel )
{
	var upgradesData = CustomNetTables.GetTableValue( "Upgrades", "upgrades" );
	var upgradeData = upgradesData[panel.id.toString()];

	var title = $.Localize(panel.id);
	var desc = $.Localize(panel.id + "_Description");
	var value_name = $.Localize(panel.id + "_Value");
	var value = upgradeData["value"];

	// Build tooltip data
	var data = {
		"panelId" : panel.id,
		"title" : title.toUpperCase(),
		"desc" : desc,
		"value-1-name" : value_name,
		"value-1-value" : value,
		"value-1-value-color" : "yellow",
	};

	// Add cost information
	var i = 2;
	for(var key in upgradeData["cost"])
	{
		var costData = upgradeData["cost"][key];
		var currency = costData["currency"];
		var amount = costData["amount"];

		data["value-" + i + "-name"] = $.Localize(m_CurrencyLocals[currency] + "_cost");
		data["value-" + i + "-value"] = costData["amount"];
		data["value-" + i + "-value-color"] = m_CurrencyColours[currency];

		i++;
	}

	// Send event
	GameEvents.SendEventClientSide("show_legion_tooltip", data );
}

function HideTooltip( panel )
{
	GameEvents.SendEventClientSide("hide_legion_tooltip", {} );
}

function PurchaseUpgrade( panel )
{
	GameEvents.SendCustomGameEventToServer( "legion_purchase_upgrade", { "sUpgradeId" : panel.id } );
}
