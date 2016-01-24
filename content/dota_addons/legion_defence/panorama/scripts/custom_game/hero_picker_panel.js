
function SetHero( HeroId )
{
	$("#HeroImage").style.backgroundImage = "url( \"file://{images}/../videos/heroes/" + HeroId + ".webm\" )";
	$("#HeroName").text = $.Localize(HeroId);
}

function OnSelected()
{
	GameEvents.SendEventClientSide( "legion_cl_select_hero", { "id" : $.GetContextPanel().id } );
}

function ShowAbilityTooltip( AbilityId )
{
	var data = {
		"title" : "Ability " + AbilityId,
		"desc" : "Desc for ability " + AbilityId,
	};
	GameEvents.SendEventClientSide("show_legion_tooltip", data );
}

function HideAbilityTooltip()
{
	GameEvents.SendEventClientSide("hide_legion_tooltip", {} );	
}

(function()
{

	SetHero( $.GetContextPanel().id );

})();
