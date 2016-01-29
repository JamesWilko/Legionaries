
var m_Upgrades = [];

function CreateUpgrades()
{
	var upgradesData = CustomNetTables.GetTableValue( "Upgrades", "upgrades" );
	if(upgradesData)
	{
		// Run through all upgrades
		for(var key in upgradesData)
		{
			var upgrade = upgradesData[key];
			var upgradeId = upgrade["id"];

			// Add or update upgrade
			var panel = $("#" + upgradeId);
			if(!panel)
			{
				panel = $.CreatePanel( "Panel", $("#ChildList"), upgradeId );
			}
			panel.BLoadLayout( "file://{resources}/layout/custom_game/general_upgrade_item.xml", true, false );
			m_Upgrades[upgradeId] = panel.GetParent();

			var upgradeLevel = upgrade["default"];
			var upgradeLevelData = CustomNetTables.GetTableValue( "Upgrades", upgradeId );
			if(upgradeLevelData && upgradeLevelData[Players.GetLocalPlayer()])
			{
				upgradeLevel = upgradeLevelData[Players.GetLocalPlayer()];
				if(upgradeLevel == upgrade["max_level"])
				{
					upgradeLevel = $.Localize("legion_upgrade_max_level_short");
				}
			}

			panel.FindChild("Text").text = $.Localize(upgradeId + "_Short");
			panel.FindChild("Value").text = upgradeLevel;
			panel.FindChild("UpgradeButton").FindChild("Image").itemname = upgrade["display_image"];
		}
	}

}

(function()
{
	//CustomNetTables.SubscribeNetTableListener( "Upgrades", OnUpgradesUpdated );
	CreateUpgrades();
})();
