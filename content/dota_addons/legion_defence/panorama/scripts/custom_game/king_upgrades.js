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
		for(var key in m_UpgradePanels)
		{
			m_UpgradePanels[key].RemoveAndDeleteChildren()
		}
		m_UpgradePanels = [];
	}

	// Add new panels
	for(var key in m_KingUpgrades)
	{
		var upgrade = m_KingUpgrades[key];
		var panel = $.CreatePanel( "Panel", $("#UpgradesList"), upgrade );
		panel.BLoadLayout( "file://{resources}/layout/custom_game/king_upgrade_item.xml", true, false );
		m_UpgradePanels[upgrade] = panel.GetParent();
	}
}

(function()
{
	// Net Table for King Upgrades, listen to when it updates and update our UI too
	CustomNetTables.SubscribeNetTableListener( "KingUpgradeData", OnKingUpgradeDataChanged );
	OnKingUpgradeDataChanged();
})();
