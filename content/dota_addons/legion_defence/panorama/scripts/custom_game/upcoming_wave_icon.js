
function ShowTooltip( panelImage )
{
	var panel = panelImage.GetParent();
	GameEvents.SendEventClientSide("show_upcoming_wave_tooltip", { "panelId" : panel.id } );
}

function HideTooltip( panelImage )
{
	GameEvents.SendEventClientSide("hide_upcoming_wave_tooltip", {} );
}
