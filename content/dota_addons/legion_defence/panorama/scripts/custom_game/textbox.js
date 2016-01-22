
var m_TextboxLines = [];
var m_TimestampColor = "goldenrod";

String.format = function(format)
{
	var args = Array.prototype.slice.call(arguments, 1);
	return format.replace(/{(\d+)}/g, function(match, number)
	{
		return typeof args[number] != 'undefined' ? args[number] : match;
	});
};

function OnReceivedCustomChat( data )
{
	var team = data["iTeam"];
	var localPlayer = Players.GetLocalPlayer();
	var canShowForTeam = team < 0 || team == Entities.GetTeamNumber(Players.GetPlayerHeroEntityIndex(localPlayer));
	if(canShowForTeam)
	{
		var messagePlayer = data["lPlayer"];
		var shouldOnlyShowToPlayer = data["bPlayerOnly"];
		var canShowForPlayer = true;
		if(shouldOnlyShowToPlayer)
		{
			canShowForPlayer = messagePlayer == localPlayer;
		}
		if(canShowForPlayer)
		{
			var message = $.Localize(data["sMessage"]);
			message = String.format(message, data["argNumber"], data["argString"], Players.GetPlayerName(messagePlayer));
			m_TextboxLines.push("<span class=\"" + m_TimestampColor + "\">[" + GetTimestamp() + "]</span> " + message);
			UpdateTextbox();
		}
	}
}

function GetTimestamp()
{
	var time = Math.floor(Game.GetDOTATime(false, false));
	var mins = 0;
	time = Math.floor(time);
	mins = Math.floor(time / 60);
	time = time - mins * 60;
	if(time < 10)
	{
		time = "0" + time;
	}
	if(mins < 10)
	{
		mins = "0" + mins;
	}
	return mins + ":" + time;
}

function UpdateTextbox()
{
	var text = "";
	for(var i = 0; i < m_TextboxLines.length; ++i)
	{
		if(i > 0)
		{
			text += "\n<br/>";
		}
		text += m_TextboxLines[i];
	}
	$("#TextboxText").text = text;
	$("#TextboxParent").ScrollToBottom();
}

(function()
{

	GameEvents.Subscribe( "legion_custom_chat", OnReceivedCustomChat );

})();
