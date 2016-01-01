"use strict";

var m_ToolTip;
var m_UpgradePanels = [];

var m_KingUpgrades = [
	"health",
	"regen",
	"armour",
	"attack",
	"heal"
];

function OnKingUpgradeDataChanged()
{
	// Remove old panels
	if(m_UpgradePanels)
	{
		for(var i = 0; i < m_UpgradePanels.length; ++i)
		{
			m_UpgradePanels[i].GetParent().RemoveAndDeleteChildren()
		}
		m_UpgradePanels = [];
	}

	// Add new panels
	for(var key in m_KingUpgrades)
	{
		var upgrade = m_KingUpgrades[key];
		var panel = $.CreatePanel( "Panel", $("#UpgradesList"), upgrade );
		panel.BLoadLayout( "file://{resources}/layout/custom_game/king_upgrade_item.xml", true, false );
		m_UpgradePanels[upgrade] = panel;
	}
}

(function()
{
	// Net Table for King Upgrades, listen to when it updates and update our UI too
	CustomNetTables.SubscribeNetTableListener( "KingUpgradeData", OnKingUpgradeDataChanged );
	OnKingUpgradeDataChanged();
})();
