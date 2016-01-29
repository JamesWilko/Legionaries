
var m_CurrencyLocals = [];
m_CurrencyLocals["CurrencyGold"] = "legion_currency_gold";
m_CurrencyLocals["CurrencyGems"] = "legion_currency_gems";
m_CurrencyLocals["CurrencyFood"] = "legion_currency_food";

var m_CurrencyColours = [];
m_CurrencyColours["CurrencyGold"] = "yellow";
m_CurrencyColours["CurrencyGems"] = "cyan";
m_CurrencyColours["CurrencyFood"] = "orange";

function GetUpgradeData( sUpgradeId )
{
	var upgradesData = CustomNetTables.GetTableValue( "Upgrades", "upgrades" );
	for(var key in upgradesData)
	{
		var upgrade = upgradesData[key];
		if(sUpgradeId == upgrade["id"])
		{
			return upgrade;
		}
	}
	return undefined;
}

function ShowTooltip( panel )
{
	var upgradeData = GetUpgradeData(panel.id.toString());
	var upgradeLevelData = CustomNetTables.GetTableValue( "Upgrades", panel.id.toString() );

	var max_level = false;
	if(upgradeLevelData &&
		upgradeLevelData[Players.GetLocalPlayer()] &&
		upgradeLevelData[Players.GetLocalPlayer()] == upgradeData["max_level"])
	{
		max_level = true;
	}

	var title = $.Localize(panel.id);
	var desc = $.Localize(panel.id + "_Description");
	var value_name = $.Localize(panel.id + "_Value");
	var value = upgradeData["value"];

	// Build tooltip data
	var data = {
		"panelId" : panel.id,
		"title" : title.toUpperCase(),
		"desc" : desc,
		"cooldown" : upgradeData["time"]
	};

	var altDescKey = panel.id + "_Note0";
	var altDesc = $.Localize(altDescKey);
	if(altDesc != altDescKey)
	{
		data["alt-desc"] = altDesc;
	}

	if(!max_level)
	{
		// Add value info
		data["value-1-name"] = value_name;
		data["value-1-value"] = value;
		data["value-1-value-color"] = "yellow";

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
	}
	else
	{
		// Show max level info
		data["value-1-name"] = "";
		data["value-1-value"] = $.Localize("legion_upgrade_max_level");
		data["value-1-value-color"] = "red";
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

function CancelUpgrade( panel )
{
	GameEvents.SendCustomGameEventToServer( "legion_cancel_upgrade", { "sUpgradeId" : panel.id } );
}

function OnUpgradesUpdated()
{
	var key = $.GetContextPanel().id.toString();
	var upgrade = GetUpgradeData(key);
	if(upgrade)
	{
		var upgradeLevel = upgrade["default"];
		var upgradeLevelMax = upgrade["max_level"];
		var upgradeLevelFriendly = upgradeLevel;
		var upgradeLevelData = CustomNetTables.GetTableValue( "Upgrades", key );

		if(upgradeLevelData && upgradeLevelData[Players.GetLocalPlayer()])
		{
			upgradeLevel = upgradeLevelData[Players.GetLocalPlayer()];
			upgradeLevelFriendly = upgradeLevel;
		}
		if(upgrade["count_method"] == "backwards")
		{
			upgradeLevelFriendly = upgradeLevelMax - upgradeLevel;
		}
		if(upgradeLevel == upgradeLevelMax)
		{
			upgradeLevelFriendly = $.Localize("legion_upgrade_max_level_short");
		}

		$("#Text").text = $.Localize(key + "_Short");
		$("#Value").text = upgradeLevelFriendly;
		$("#Image").itemname = upgrade["display_image"];
	}
}

function AutoUpdateUpgrade()
{
	UpdateUpgrade();
	$.Schedule( 0.033, AutoUpdateUpgrade );
}

function UpdateUpgrade()
{
	var upgradeInProgress = false;
	var upgradesData = CustomNetTables.GetTableValue( "Upgrades", "upgrades" );

	if(upgradesData)
	{
		var key = "pending_" + $.GetContextPanel().id.toString();
		var upgrade = CustomNetTables.GetTableValue( "Upgrades", key );
		if(upgrade)
		{
			upgrade = upgrade[Players.GetLocalPlayer()];
			if(upgrade["is_upgrading"])
			{
				var start = upgrade["start_time"];
				var finish = upgrade["finish_time"];
				var duration = finish - start;
				var percent = (Game.GetDOTATime(false, false) - start) / duration;
				percent = Math.max(0.0, Math.min(percent, 1.0)) * 100.0;

				upgradeInProgress = true;
				$("#CooldownOverlay").style.width = percent + "%";
				$("#CooldownQueue").text = "x" + upgrade["queued"];
			}
		}
	}

	$("#CooldownPanel").visible = upgradeInProgress;
}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "Upgrades", OnUpgradesUpdated );
	OnUpgradesUpdated();
	AutoUpdateUpgrade();
})();

