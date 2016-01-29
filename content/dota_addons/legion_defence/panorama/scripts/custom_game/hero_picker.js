
var HEROES_NETTABLE = "HeroesList";
var HEROES_KEY = "heroes";

var m_HeroPanels = [];
var m_SelectedHeroIndex;

var m_LastFinalize = -1;
var FINALIZE_COOLDOWN = 2;

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
		if(m_LastFinalize < 0 || Game.Time() < m_LastFinalize + FINALIZE_COOLDOWN)
		{
			GameEvents.SendCustomGameEventToServer( "legion_hero_selected", { "sHeroId" : m_SelectedHeroIndex } );
			m_LastFinalize = Game.Time();
		}
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

function CreateFullHeroList()
{
	var heroes = CustomNetTables.GetTableValue( HEROES_NETTABLE, HEROES_KEY );
	var list = [];
	for( var id in heroes )
	{
		list.push(id);
	}
	CreateHeroesList( list );
}

function CreateHeroesList( heroesList )
{
	// Remove previous heroes
	if(m_HeroPanels)
	{
		for(var id in m_HeroPanels)
		{
			m_HeroPanels[id].visible = false;
			m_HeroPanels[id].DeleteAsync( 0.0 );
		}
		m_HeroPanels = [];
	}

	// Create new heroes list
	for(var i = 0; i < heroesList.length; ++i)
	{
		var heroId = heroesList[i];
		var m_Hero = Objects.Instantiate("hero_picker_character", heroId, $("#HeroesScroll"));
		m_HeroPanels[heroId] = m_Hero;
		m_Hero.AddClass("NotHighlighted");
		m_Hero.SetHero(heroId);
	}
}

(function()
{
	// $.GetContextPanel().visible = false;
	CreateFullHeroList();
	GameEvents.Subscribe( "legion_cl_select_hero", OnSelectHero );
})();

Objects.Define({

	Show : function()
	{
		CreateFullHeroList();
		$.GetContextPanel().visible = true;
	},

	ShowLimited : function( heroesList )
	{
		CreateHeroesList( heroesList );
		$.GetContextPanel().visible = true;
	}

});

