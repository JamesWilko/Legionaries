
var m_TextboxLines = [];
var m_TextboxMaxLines = 10;
var m_TextboxCurrent = 0;

var m_TimestampColor = "goldenrod";

function GetTextboxIndex( m_TextboxCurrent )
{
	return m_TextboxCurrent % m_TextboxMaxLines;
}

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
			message = String.format(message, data["argNumber"], $.Localize(data["argString"]), Players.GetPlayerName(messagePlayer));
			message = "<span class=\"" + m_TimestampColor + "\">[" + GetTimestamp() + "]</span> " + message;

			m_TextboxLines[GetTextboxIndex(m_TextboxCurrent)] = message;
			m_TextboxCurrent++;

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
	for(var i = m_TextboxCurrent; i < m_TextboxCurrent + m_TextboxMaxLines; ++i)
	{
		if(i > m_TextboxCurrent)
		{
			text += "\n<br/>";
		}
		text += m_TextboxLines[GetTextboxIndex(i)];
	}
	$("#TextboxText").text = text;
	$("#TextboxParent").ScrollToBottom();
}

function Scroll()
{
	$("#TextboxParent").ScrollToBottom();
	$.Schedule(0.016, Scroll);
}

(function()
{
	for(var i = 0; i < m_TextboxMaxLines; ++i)
	{
		m_TextboxLines.push("");
	}

	GameEvents.Subscribe( "legion_custom_chat", OnReceivedCustomChat );
	Scroll();
})();
