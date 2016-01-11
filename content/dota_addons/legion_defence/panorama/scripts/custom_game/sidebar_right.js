
var m_Mercs;

(function()
{

	m_Mercs = $.CreatePanel( "Panel", $("#ChildList"), "MercenariesPanel" );
	m_Mercs.BLoadLayout( "file://{resources}/layout/custom_game/mercenaries_panel.xml", true, false );

})();
