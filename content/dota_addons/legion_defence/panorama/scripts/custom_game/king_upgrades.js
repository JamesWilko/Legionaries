"use strict";

var m_ToolTip;
var m_KingUpgrades = [
	"health",
	"regen",
	"armour",
	"attack",
	"heal"
];
var m_CurrencyIcons = new Array();
m_CurrencyIcons["CurrencyGems"] = "file://{images}/custom_game/icons/icon_gems_small.png";
m_CurrencyIcons["CurrencyGold"] = "file://{images}/custom_game/icons/icon_gold_small.png";
m_CurrencyIcons["CurrencyFood"] = "file://{images}/custom_game/icons/icon_food_small.png";

function OnKingUpgradeDataChanged()
{
	for(var i = 0; i < m_KingUpgrades.length; ++i)
	{
		var sUpgrade = m_KingUpgrades[i];
		var realCostPerLevel = GetKingUpgradesData()[sUpgrade]["cost"];
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
		if(GetKingUpgradesData()[sUpgrade]["display_cost"])
		{
			costPerLevel = GetKingUpgradesData()[sUpgrade]["display_cost"];
		}
		var upgradeCurrency = GetKingUpgradesData()[sUpgrade]["currency"];

		var upgradePanel = $("#UpgradeCost-" + sUpgrade);
		if(upgradePanel)
		{
			upgradePanel.SetHasClass( "hidden", realCostPerLevel < 0 );
		}

		var upgradeText = $("#UpgradeCostText-" + sUpgrade);
		if(upgradeText)
		{
			upgradeText.text = costPerLevel;
		}

		var upgradeImage = $("#UpgradeImage-" + sUpgrade);
		if(upgradeImage)
		{
			upgradeImage.SetHasClass( "SoldOut", realCostPerLevel < 0 );
		}

		var upgradeCurrency = $("#UpgradeCostIcon-" + sUpgrade);
		if(upgradeCurrency)
		{
			upgradeCurrency.src = m_CurrencyIcons[upgradeCurrency];
		}
	}
}

function GetKingUpgradesData()
{
	return CustomNetTables.GetTableValue( "KingUpgradeData", "data" );
}

function UpgradeShowTooltip( sUpgradeId )
{
	var incrPerLevel = GetKingUpgradesData()[sUpgradeId]["per_level"];

	// Update tooltip prices and description
	if(m_ToolTip)
	{
		m_ToolTip.SetHasClass( "hidden", false );

		m_ToolTip.FindChild("UpgradeTitle").text = $.Localize("#king_upgrade_" + sUpgradeId).toUpperCase();
		m_ToolTip.FindChild("UpgradeDescription").text = $.Localize("#king_upgrade_" + sUpgradeId + "_Description");
		m_ToolTip.FindChild("UpgradeStatInfo").FindChild("UpgradeStatText").text = $.Localize("#king_upgrade_" + sUpgradeId + "_Value").toUpperCase();
		m_ToolTip.FindChild("UpgradeStatInfo").FindChild("UpgradeStatValue").text = incrPerLevel;

		var posX = 120;
		var posY = GameUI.GetCursorPosition()[1] + 30;
		$("#tooltip").style.marginLeft = posX + "px";
		$("#tooltip").style.marginTop = posY + "px";
	}
}

function UpgradeHideTooltip( sUpgradeId )
{
	if(m_ToolTip)
	{
		m_ToolTip.SetHasClass( "hidden", true );
	}
}

function UpgradeAbility( sUpgradeId )
{
	GameEvents.SendCustomGameEventToServer( "legion_purchase_king_upgrade", { "sUpgradeId" : sUpgradeId } );
}

(function()
{
	// Net Table for King Upgrades, listen to when it updates and update our UI too
	CustomNetTables.SubscribeNetTableListener( "KingUpgradeData", OnKingUpgradeDataChanged );
	OnKingUpgradeDataChanged();

	// Create tooltip
	if(!m_ToolTip)
	{
		m_ToolTip = $.CreatePanel( "Panel", $("#tooltip"), "" );
		m_ToolTip.BLoadLayout( "file://{resources}/layout/custom_game/king_upgrade_tooltip.xml", false, false );
		m_ToolTip.SetHasClass( "hidden", true );
	}

})();
