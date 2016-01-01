
var m_Upgrades = [];

function OnUpgradesUpdated()
{
	// Remove old upgrades
	if(m_Upgrades)
	{
		for(var i = 0; i < m_Upgrades.length; ++i)
		{
			if(m_Upgrades[i])
			{
				m_Upgrades[i].RemoveAndDeleteChildren();
				m_Upgrades[i] = undefined;
			}
		}
		m_Upgrades = [];
	}

	// Add upgrades
	var upgradesData = CustomNetTables.GetTableValue( "Upgrades", "upgrades" );
	if(upgradesData)
	{
		for(var key in upgradesData)
		{
			var upgrade = upgradesData[key];
			var panel = $.CreatePanel( "Panel", $("#ChildList"), key );
			panel.BLoadLayout( "file://{resources}/layout/custom_game/general_upgrade_item.xml", true, false );
			m_Upgrades.push(panel.GetParent());

			var upgradeLevel = upgrade["default"];
			var upgradeLevelData = CustomNetTables.GetTableValue( "Upgrades", key );
			if(upgradeLevelData && upgradeLevelData[Players.GetLocalPlayer()])
			{
				upgradeLevel = upgradeLevelData[Players.GetLocalPlayer()];
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
