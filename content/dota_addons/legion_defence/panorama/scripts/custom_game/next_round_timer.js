
function UpdateTimer()
{
	var nettable = CustomNetTables.GetTableValue( "UpcomingWaveData", "next_wave_time" );
	if(nettable)
	{
		var next_round_time = nettable["time"];
		if(next_round_time > 0)
		{
			var dota_time = Game.GetDOTATime(false, false);
			$("#time").text = Math.ceil(next_round_time - dota_time);
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
