
"use strict";

var m_RoundTimer;
var m_Tooltip;
var m_WaveIcons = [];

function RebuildWavesList()
{
	// Add next round timer
	if(!m_RoundTimer)
	{
		m_RoundTimer = $.CreatePanel( "Panel", $("#WavesContainer"), "NextRoundTimer" );
		m_RoundTimer.BLoadLayout( "file://{resources}/layout/custom_game/next_round_timer.xml", false, false );
	}

	// Build wave list
	var nettable = CustomNetTables.GetTableValue( "UpcomingWaveData", "waves" );
	if(nettable)
	{
		var nextWave = nettable["next_wave"];
		var waveSetSize = nettable["set_size"];
		var waveSetStart = nettable["start_of_set"];
		for ( var i = waveSetStart; i < waveSetStart + waveSetSize; ++i )
		{
			var WavePanel = m_WaveIcons[i];
			if(!WavePanel)
			{
				WavePanel = $.CreatePanel( "Panel", $("#WavesContainer"), i );
				WavePanel.BLoadLayout( "file://{resources}/layout/custom_game/upcoming_wave_item.xml", false, false );
				m_WaveIcons.push(WavePanel);
			}
			
			if(nettable[i.toString()] && nettable[i.toString()]["wave"]) 
			{
				var boss = nettable[i.toString()]["wave"]["boss"];
				var isBoss = boss != undefined && boss == "true";
				WavePanel.SetHasClass( "BossWave", isBoss );

				var image = nettable[i.toString()]["wave"]["image"];
				if(image)
				{
					WavePanel.FindChild("HeroImage").SetImage( image );
				}
			}
			else
			{
				WavePanel.SetHasClass( "BossWave", false );
			}

			WavePanel.SetHasClass( "CurrentWave", i == nextWave );
			WavePanel.FindChild("HeroImage").SetHasClass( "Complete", i < nextWave );
			WavePanel.FindChild("CompleteOverlay").SetHasClass( "Hidden", i >= nextWave );
		}
	}
}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "UpcomingWaveData", RebuildWavesList );
	RebuildWavesList();
})();
