
var m_Currencies;
var m_Spacers = [];
var m_KingUpgrades;

var m_Tooltip;

(function()
{

	m_Currencies = $.CreatePanel( "Panel", $("#ChildList"), "CurrenciesList" );
	m_Currencies.BLoadLayout( "file://{resources}/layout/custom_game/currencies.xml", true, false );

	var m_Spacer = $.CreatePanel( "Panel", $("#ChildList"), "Spacer1" );
	m_Spacer.AddClass( "VerticalSpacer", true );
	m_Spacers.push(m_Spacer);

	m_KingUpgrades = $.CreatePanel( "Panel", $("#ChildList"), "KingUpgradesPanel" );
	m_KingUpgrades.BLoadLayout( "file://{resources}/layout/custom_game/king_upgrades.xml", true, false );

})();
