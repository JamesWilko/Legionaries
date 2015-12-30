
function UpdateTimer()
{
	var nettable = CustomNetTables.GetTableValue( "UpcomingWaveData", "next_wave_time" );
	if(nettable)
	{
		var next_round_time = nettable["time"];
		if(next_round_time > 0)
		{
			var dota_time = Game.GetDOTATime(false, false);
			var time = next_round_time - dota_time;
			if(time <= 0)
			{
				$("#time").text = $.Localize("legion_round_in_progress");
			}
			else
			{
				$("#time").text = Math.ceil(time);
			}
			$("#time").SetHasClass( "TimerSmall", time <= 0 );
		}
		else
		{
			$("#time").text = "?";
		}
	}

	$.Schedule(1, function(){
		UpdateTimer();
	});
}

(function()
{
	UpdateTimer();
	$.Schedule(1, function(){
		UpdateTimer();
	});
})();
