
var m_Heroes = [];
m_Heroes.push("npc_dota_hero_ember_spirit");
m_Heroes.push("npc_dota_hero_lina");
m_Heroes.push("npc_dota_hero_zuus");

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

(function()
{

	$.GetContextPanel().visible = false;

	for (var i = 0; i < m_Heroes.length; i++)
	{
		var m_Hero = $.CreatePanel( "Panel", $("#HeroesScroll"), m_Heroes[i] );
		m_Hero.BLoadLayout( "file://{resources}/layout/custom_game/hero_picker_panel.xml", true, false );
		m_Hero.AddClass("NotHighlighted");
		m_HeroPanels[m_Heroes[i]] = m_Hero;
	};	

	GameEvents.Subscribe( "legion_show_hero_picker", OnShowHeroPicker );
	GameEvents.Subscribe( "legion_close_hero_picker", OnCloseHeroPicker );
	GameEvents.Subscribe( "legion_cl_select_hero", OnSelectHero );

})();
