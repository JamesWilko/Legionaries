
function ShowTooltip( panel )
{
	var waveId = panel.id.toString();
	var title = "";
	var desc = "";
	var boss;

	var nettable = CustomNetTables.GetTableValue( "UpcomingWaveData", "waves" );
	if(nettable && nettable[waveId] && nettable[waveId]["wave"])
	{
		// Set tooltip info
		var waveData = nettable[waveId]["wave"];
		for (var key in waveData)
		{
			if(key.indexOf("npc_") == 0)
			{
				title = $.Localize(key) + " (x" + waveData[key] + ")";
				desc = $.Localize(key + "_Description");
				break;
			}
		}

		// Show tooltip boss wave tag
		var boss = waveData["boss"];
		var isBoss = boss != undefined && boss == "true";
		if(isBoss)
		{
			boss = $.Localize("legion_boss_wave");
		}
	}

	var data = {
		"panelId" : panel.id,
		"title" : title,
		"desc" : desc,
		"value-name" : "",
	};
	if(boss)
	{
		data["value-value"] = boss;
		data["value-value-color"] = "red";
	}
	GameEvents.SendEventClientSide("show_legion_tooltip", data );
}

function HideTooltip( panel )
{
	GameEvents.SendEventClientSide("hide_legion_tooltip", {} );
}
