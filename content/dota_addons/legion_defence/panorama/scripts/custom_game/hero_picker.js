
var HEROES_NETTABLE = "HeroesList";
var HEROES_KEY = "heroes";

var m_HeroPanels = [];
var m_SelectedHeroIndex;

var m_CountdownStart = 0;
var m_CountdownDuration = 60;
var m_WarningTime = 20;

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

function UpdateCountdown()
{
	if( m_CountdownDuration >= 0 )
	{
		var time = Game.GetDOTATime(false, false);
		var remaining_time = Math.floor((m_CountdownStart + m_CountdownDuration) - time);

		var remaining_minutes = Math.floor(remaining_time / 60);
		var remaining_seconds = Math.floor(remaining_time % 60);
		if(remaining_minutes < 0) { remaining_minutes = -remaining_minutes; }
		if(remaining_seconds < 0) { remaining_seconds = -remaining_seconds; }
		if(remaining_seconds < 10) { remaining_seconds = "0" + remaining_seconds; }

		$("#CountdownLabel").visible = true;
		$("#CountdownLabel").text = String.format("{2}{0}:{1}", remaining_minutes, remaining_seconds, remaining_time < 0 ? "-" : "");

		if(remaining_time < m_WarningTime)
		{
			$("#CountdownWarningLabel").visible = true;
			$("#CountdownWarningLabel").SetHasClass( "CountdownWarningRed", !$("#CountdownWarningLabel").BHasClass("CountdownWarningRed") );
		}
		else
		{
			$("#CountdownWarningLabel").visible = false;
		}
	}

	$.Schedule( 0.5, UpdateCountdown );
}

(function()
{
	$.GetContextPanel().visible = false;
	$("#CountdownLabel").visible = false;
	$("#CountdownWarningLabel").visible = false;

	// CreateFullHeroList();
	GameEvents.Subscribe( "legion_cl_select_hero", OnSelectHero );

})();

Objects.Define({

	Show : function()
	{
		CreateFullHeroList();
		$.GetContextPanel().visible = true;
		m_CountdownStart = -1;
		m_CountdownDuration = -1;
	},

	ShowLimited : function( heroesList )
	{
		CreateHeroesList( heroesList );
		$.GetContextPanel().visible = true;
	},

	SetCountdown : function( start, duration )
	{
		m_CountdownStart = start;
		m_CountdownDuration = duration;
		UpdateCountdown();
	}

});

