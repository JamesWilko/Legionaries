
if CLegionDefence == nil then
	_G.CLegionDefence = class({})
end

require("Utils")
require("MapController")
require("WaveController")
require("UnitController")
require("BuildGrid")

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]

	-- PrecacheResource( "particle_folder", "particles/units/heroes/hero_lina/", context )

	PrecacheResource( "model", "models/items/dragon_knight/sword_davion.vmdl", context )
	PrecacheResource( "model", "models/items/dragon_knight/shield_davion.vmdl", context )

	PrecacheUnitByNameSync( "npc_dota_hero_clinkz", context )
	PrecacheUnitByNameSync( "npc_dota_hero_dragon_knight", context )
	PrecacheUnitByNameSync( "npc_dota_hero_ember_spirit", context )
	PrecacheUnitByNameSync( "npc_dota_hero_lina", context )
	PrecacheUnitByNameSync( "npc_dota_hero_zuus", context )

	PrecacheUnitByNameSync( "npc_dota_furion_treant", context )

end

-- Create the game mode when we activate
function Activate()

	GameRules.LegionDefence = CLegionDefence()
	GameRules.LegionDefence:InitGameMode()

end

function CLegionDefence:InitGameMode()

	print("CLegionDefence:InitGameMode()")
	self._GameMode = GameRules:GetGameModeEntity()

	self._GameMode:SetThink( "OnThink", self, "GlobalThink", 2 )

	self._GameMode:SetAnnouncerDisabled( true )
	self._GameMode:SetFixedRespawnTime( 3 )
	
	GameRules:SetGoldPerTick( 0 )
	GameRules:SetPreGameTime( 3 )
	GameRules:SetCustomGameSetupTimeout( 3 )

	self:SetupMapController()
	self:SetupWaveController()
	self:SetupUnitController()

	ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap(CLegionDefence, "OnPlayerPickedHero"), self)

end

-- Evaluate the state of the game
function CLegionDefence:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "Template addon script is running." )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end

-- Debug, give player all levels
function CLegionDefence:OnPlayerPickedHero( event )
	local hero = EntIndexToHScript( event.heroindex )
	if hero then
		hero:SetAbilityPoints(25)
		-- hero:AddItemByName("item_necronomicon")
	end
end
