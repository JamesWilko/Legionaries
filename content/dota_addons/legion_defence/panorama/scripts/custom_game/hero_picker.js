
var HEROES_NETTABLE = "HeroesList";
var HEROES_KEY = "heroes";

var m_HeroPanels = [];
var m_SelectedHeroIndex;

function OnShowHeroPicker()
{
	$.GetContextPanel().visible = true;
}

function OnCloseHeroPicker()
{
	$.GetContextPanel().visible = false;
}

function OnSelectHero( data )
{
	SelectHero(data["id"]);
}

function SelectHero( HeroId )
{
	// Unhighlight previous hero
	if(m_SelectedHeroIndex)
	{
		m_HeroPanels[m_SelectedHeroIndex].SetHasClass("Highlighted", false);
		m_HeroPanels[m_SelectedHeroIndex].SetHasClass("NotHighlighted", true);
	}

	// Highlight new hero
	m_SelectedHeroIndex = HeroId;
	var heroPanel = m_HeroPanels[ HeroId ];
	heroPanel.SetHasClass("NotHighlighted", false);
	heroPanel.SetHasClass("Highlighted", true);
}

function FinalizeHero()
{
	if(m_SelectedHeroIndex)
	{
		GameEvents.SendCustomGameEventToServer( "legion_hero_selected", { "sHeroId" : m_SelectedHeroIndex } );
		OnCloseHeroPicker();
	}
}

function RandomizeHero()
{
	var rand = [];
	for(var key in m_HeroPanels)
	{
		rand.push(key);
	}
	var randomIndex = rand[Math.floor(Math.random() * rand.length)];
	SelectHero( randomIndex );
}

function OnHeroListUpdated()
{
	if(m_HeroPanels)
	{
		for(var key in m_HeroPanels)
		{
			m_HeroPanels[key].RemoveAndDeleteChildren()
		}
		m_HeroPanels = [];
	}

	var heroes = CustomNetTables.GetTableValue( HEROES_NETTABLE, HEROES_KEY );
	for( var key in heroes )
	{
		var m_Hero = $.CreatePanel( "Panel", $("#HeroesScroll"), key );
		m_Hero.BLoadLayout( "file://{resources}/layout/custom_game/hero_picker_panel.xml", true, false );
		m_Hero.AddClass("NotHighlighted");
		m_HeroPanels[key] = m_Hero;
	}
}

(function()
{

	$.GetContextPanel().visible = false;

	GameEvents.Subscribe( "legion_show_hero_picker", OnShowHeroPicker );
	GameEvents.Subscribe( "legion_close_hero_picker", OnCloseHeroPicker );
	GameEvents.Subscribe( "legion_cl_select_hero", OnSelectHero );
	CustomNetTables.SubscribeNetTableListener( HEROES_NETTABLE, OnHeroListUpdated );

	OnHeroListUpdated();

})();
