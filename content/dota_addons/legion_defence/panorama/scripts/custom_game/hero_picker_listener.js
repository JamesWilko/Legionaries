
var m_HeroPicker;

var NET_TABLE = "HeroPickingData";
var TABLE_KEY = "data";

function OnShowHeroPicker( data )
{
	$.GetContextPanel().visible = true;

	if(m_HeroPicker)
	{
		RemoveHeroPicker();
	}

	m_HeroPicker = Objects.Instantiate("hero_picker", "HeroPickerScreen", $.GetContextPanel());
	if(!data["bLimitedSelection"])
	{
		m_HeroPicker.Show();
	}
	else
	{
		var playerPickData = CustomNetTables.GetTableValue( NET_TABLE, Players.GetLocalPlayer().toString() );
		var heroesList = [];
		for(var key in playerPickData)
		{
			heroesList.push(playerPickData[key]);
		}
		m_HeroPicker.ShowLimited( heroesList );
	}
	m_HeroPicker.SetCountdown( data["lStartTime"], data["lDuration"] );
}

function OnCloseHeroPicker()
{
	$.GetContextPanel().visible = false;
	RemoveHeroPicker();
}

function RemoveHeroPicker()
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
			OnShowHeroPicker(pickingData);
		}
	}

})();
