
var m_CurrencyIcons = new Array();
m_CurrencyIcons["CurrencyGems"] = "file://{images}/custom_game/icons/icon_gems_small.png";
m_CurrencyIcons["CurrencyGold"] = "file://{images}/custom_game/icons/icon_gold_small.png";
m_CurrencyIcons["CurrencyFood"] = "file://{images}/custom_game/icons/icon_food_small.png";

function UpdateButton( mercIndex )
{
	/*
	var realCostPerLevel = GetKingUpgradesData()[upgrade]["cost"];
	if(typeof realCostPerLevel === "object")
	{
		var localPlayerId = Game.GetLocalPlayerID();
		if(realCostPerLevel[localPlayerId])
		{
			realCostPerLevel = realCostPerLevel[localPlayerId];
		}
		else
		{
			realCostPerLevel = realCostPerLevel["default"];
		}
	}

	var costPerLevel = realCostPerLevel;
	if(GetKingUpgradesData()[upgrade]["display_cost"])
	{
		costPerLevel = GetKingUpgradesData()[upgrade]["display_cost"];
	}
	var upgradeCurrency = GetKingUpgradesData()[upgrade]["currency"];

	var upgradePanel = $.GetContextPanel();
	if(upgradePanel)
	{
		upgradePanel.SetHasClass( "hidden", realCostPerLevel < 0 );
	}

	var upgradeText = $("#CostText");
	if(upgradeText)
	{
		upgradeText.text = costPerLevel;
	}

	var upgradeCurrency = $("#CostImage");
	if(upgradeCurrency)
	{
		upgradeCurrency.src = m_CurrencyIcons[upgradeCurrency];
	}

	var upgradeImage = $("#UpgradeImage");
	if(upgradeImage)
	{
		upgradeImage.itemname = GetKingUpgradesData()[upgrade]["icon"];
		upgradeImage.SetHasClass( "SoldOut", realCostPerLevel < 0 );
	}
	*/

	var upgradeText = $("#CostText");
	if(upgradeText)
	{
		upgradeText.text = GetMercenariesData()[mercIndex]["cost"];
	}

	var upgradeCurrency = $("#CostImage");
	if(upgradeCurrency)
	{
		upgradeCurrency.src = m_CurrencyIcons["CurrencyGems"];
	}
}

function ShowTooltip( panel )
{
	var mercIndex = panel.id;
	var mercId = GetMercenariesData()[mercIndex]["id"];
	var title = $.Localize("#" + mercId);
	var desc = $.Localize("#" + mercId + "_Description");

	var data = {
		"panelId" : panel.id,
		"title" : title.toUpperCase(),
		"desc" : desc,
	};

	GameEvents.SendEventClientSide("show_legion_tooltip", data );
}

function HideTooltip( panel )
{
	GameEvents.SendEventClientSide("hide_legion_tooltip", {} );
}

function PurchaseUpgrade( panel )
{
	GameEvents.SendCustomGameEventToServer( "legion_purchase_king_upgrade", { "sUpgradeId" : panel.id } );
}

function OnMercenariesDataChanges()
{
	UpdateButton( $.GetContextPanel().id );
}

function GetMercenariesData()
{
	return CustomNetTables.GetTableValue( "MercenariesData", "units" );
}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "MercenariesData", OnMercenariesDataChanges );
	UpdateButton( $.GetContextPanel().id );
})();
