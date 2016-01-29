
var HEROES_NETTABLE = "HeroesList";
var ABILITIES_KEY = "abilities";
var MAX_ABILITIES = 6;

var HeroID;

function SetHero( HeroId )
{
	HeroID = HeroId;

	$("#HeroImage").style.backgroundImage = "url( \"file://{images}/../videos/heroes/" + HeroId + ".webm\" )";
	$("#HeroName").text = $.Localize(HeroId);

	var abilities = CustomNetTables.GetTableValue( HEROES_NETTABLE, ABILITIES_KEY );
	if(abilities)
	{
		for(var i = 1; i <= MAX_ABILITIES; ++i)
		{
			var ability = abilities[HeroID][i];
			$("#Ability" + i).abilityname = ability;
		}
	}
}

function OnSelected()
{
	GameEvents.SendEventClientSide( "legion_cl_select_hero", { "id" : $.GetContextPanel().id } );
}

function ShowAbilityTooltip( AbilityId )
{
	var abilities = CustomNetTables.GetTableValue( HEROES_NETTABLE, ABILITIES_KEY );
	if(abilities)
	{
		var ability = abilities[HeroID][AbilityId];
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

Objects.Define({
	SetHero : function( HeroId ) { SetHero(HeroId); }
});
