
var m_HeroPicker;

var NET_TABLE = "HeroPickingData";
var TABLE_KEY = "data";

function OnShowHeroPicker()
{
	m_HeroPicker = $.CreatePanel( "Panel", $.GetContextPanel(), "HeroPickerScreen" );
	m_HeroPicker.BLoadLayout( "file://{resources}/layout/custom_game/hero_picker.xml", true, false );
}

function OnCloseHeroPicker()
{
	if(m_HeroPicker)
	{
		m_HeroPicker.DeleteAsync( 0.0 );
		m_HeroPicker = undefined;
	}
}

(function()
{

	GameEvents.Subscribe( "legion_show_hero_picker", OnShowHeroPicker );
	GameEvents.Subscribe( "legion_close_hero_picker", OnCloseHeroPicker );

	// Show picker if the picking time has already started and we've missed the event
	var pickingData = CustomNetTables.GetTableValue( NET_TABLE, TABLE_KEY );
	if(pickingData)
	{
		var start = pickingData["lStartTime"];
		var duration = pickingData["lDuration"];
		var time = Game.GetDOTATime(false, false);
		if(time <= start + duration)
		{
			OnShowHeroPicker();
		}
	}

})();
