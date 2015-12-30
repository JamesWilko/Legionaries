
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
				WavePanel = $.CreatePanel( "Panel", $("#WavesContainer"), "WavePanel" + i );
				WavePanel.BLoadLayout( "file://{resources}/layout/custom_game/upcoming_wave_icon.xml", false, false );
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

	// Create tooltip
	if(!m_Tooltip)
	{
		m_Tooltip = $.CreatePanel( "Panel", $.GetContextPanel(), "Tooltip" );
		m_Tooltip.BLoadLayout( "file://{resources}/layout/custom_game/upcoming_wave_tooltip.xml", true, false );
		HideTooltip();
	}

}

function ShowTooltip( args )
{
	// Get wave number
	var panel = $("#" + args["panelId"]);
	var id = panel.id;
	id = id.replace("WavePanel", "");

	// Get wave data
	var nettable = CustomNetTables.GetTableValue( "UpcomingWaveData", "waves" );
	if(nettable && nettable[id.toString()] && nettable[id.toString()]["wave"])
	{
		// Set tooltip info
		var waveData = nettable[id.toString()]["wave"];
		for (var key in waveData)
		{
			if(key.indexOf("npc_") == 0)
			{
				var title = $.Localize(key) + " (x" + waveData[key] + ")";
				var desc = $.Localize(key + "_Description");
				m_Tooltip.FindChild("TooltipTitle").text = title;
				m_Tooltip.FindChild("TooltipDesc").text = desc;
				break;
			}
		}

		// Show tooltip boss wave tag
		var boss = waveData["boss"];
		var isBoss = boss != undefined && boss == "true";
		m_Tooltip.FindChild("TooltipBossMarker").visible = isBoss;
	}

	// Set tooltip position
	m_Tooltip.style.x = ($("#WavesContainer").actualxoffset + panel.actualxoffset) + "px";
	m_Tooltip.style.y = "64px";

	// Show tooltip
	m_Tooltip.visible = true;
}

function HideTooltip()
{
	// Hide tooltip
	m_Tooltip.visible = false;
}

(function()
{
	
	CustomNetTables.SubscribeNetTableListener( "UpcomingWaveData", RebuildWavesList );
	RebuildWavesList();

	GameEvents.Subscribe("show_upcoming_wave_tooltip", ShowTooltip);
	GameEvents.Subscribe("hide_upcoming_wave_tooltip", HideTooltip);

})();
