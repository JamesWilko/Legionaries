
var HEROES_NETTABLE = "HeroesList";
var ABILITIES_KEY = "abilities";

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
	var heroId = $.GetContextPanel().id;
	var abilities = CustomNetTables.GetTableValue( HEROES_NETTABLE, ABILITIES_KEY );
	if(abilities)
	{
		var ability = abilities[heroId][AbilityId];
		var data = {
			"title" : $.Localize("DOTA_Tooltip_Ability_" + ability),
			"desc" : $.Localize("DOTA_Tooltip_Ability_" + ability + "_Description"),
		};
		GameEvents.SendEventClientSide("show_legion_tooltip", data );
	}
}

function HideAbilityTooltip()
{
	GameEvents.SendEventClientSide("hide_legion_tooltip", {} );	
}

(function()
{

	SetHero( $.GetContextPanel().id );

})();
