
var m_Upgrades = [];

function OnUpgradesUpdated()
{
	var upgradesData = CustomNetTables.GetTableValue( "Upgrades", "upgrades" );
	if(upgradesData)
	{
		// Run through all upgrades
		for(var key in upgradesData)
		{
			var upgrade = upgradesData[key];

			// Add or update upgrade
			var panel = $("#" + key);
			if(!panel)
			{
				panel = $.CreatePanel( "Panel", $("#ChildList"), key );
			}
			panel.BLoadLayout( "file://{resources}/layout/custom_game/general_upgrade_item.xml", true, false );
			m_Upgrades[key] = panel.GetParent();

			var upgradeLevel = upgrade["default"];
			var upgradeLevelData = CustomNetTables.GetTableValue( "Upgrades", key );
			if(upgradeLevelData && upgradeLevelData[Players.GetLocalPlayer()])
			{
				upgradeLevel = upgradeLevelData[Players.GetLocalPlayer()];
				if(upgradeLevel == upgrade["max_level"])
				{
					upgradeLevel = $.Localize("legion_upgrade_max_level_short");
				}
			}

			panel.FindChild("Text").text = $.Localize(key + "_Short");
			panel.FindChild("Value").text = upgradeLevel;
			panel.FindChild("UpgradeButton").FindChild("Image").itemname = upgrade["display_image"];
		}
	}

}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "Upgrades", OnUpgradesUpdated );
	OnUpgradesUpdated();
})();
