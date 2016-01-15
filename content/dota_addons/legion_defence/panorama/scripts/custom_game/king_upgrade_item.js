
var m_CurrencyIcons = new Array();
m_CurrencyIcons["CurrencyGems"] = "file://{images}/custom_game/icons/icon_gems_small.png";
m_CurrencyIcons["CurrencyGold"] = "file://{images}/custom_game/icons/icon_gold_small.png";
m_CurrencyIcons["CurrencyFood"] = "file://{images}/custom_game/icons/icon_food_small.png";

function UpdateButton( upgrade )
{
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
	var upgradeCurrency = GetKingUpgradesData()[upgrade]["currency"];
	if(GetKingUpgradesData()[upgrade]["display_cost"])
	{
		costPerLevel = GetKingUpgradesData()[upgrade]["display_cost"];
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
		upgradeImage.SetHasClass( "SoldOut", realCostPerLevel < 0 || IsUpgradeAtMaxLevel(upgrade) );
	}
}

function ShowTooltip( panel )
{
	var upgrade = panel.id;
	var title = $.Localize("#king_upgrade_" + upgrade);
	var desc = $.Localize("#king_upgrade_" + upgrade + "_Description");
	var value_name = $.Localize("#king_upgrade_" + upgrade + "_Value");
	var value = GetKingUpgradesData()[upgrade]["per_level"];

	var data = {
		"panelId" : panel.id,
		"title" : title.toUpperCase(),
		"desc" : desc,
		"value-1-name" : value_name.toUpperCase(),
		"value-1-value" : value,
		"value-1-value-color" : "yellow",
	};

	if(IsUpgradeAtMaxLevel(upgrade))
	{
		data["value-1-name"] = "";
		data["value-1-value"] = $.Localize("#legion_upgrade_max_level");
		data["value-1-value-color"] = "red";
	}

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

function OnKingUpgradeDataChanged()
{
	UpdateButton( $.GetContextPanel().id );
}

function GetKingUpgradesData()
{
	return CustomNetTables.GetTableValue( "KingUpgradeData", "data" );
}

function GetUpgradeLevel( sUpgradeId )
{
	var upgrades = CustomNetTables.GetTableValue( "KingUpgradeData", "levels" );
	var localPlayerTeam = Entities.GetTeamNumber(Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer()));
	return upgrades[localPlayerTeam][sUpgradeId];
}

function IsUpgradeAtMaxLevel( sUpgradeId )
{
	var maxLevel = GetKingUpgradesData()[sUpgradeId]["max_level"];
	var currentLevel = GetUpgradeLevel(sUpgradeId);
	return currentLevel == maxLevel;
}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "KingUpgradeData", OnKingUpgradeDataChanged );
	UpdateButton( $.GetContextPanel().id );
})();
