
if CLegionDefence == nil then
	_G.CLegionDefence = class({})
end

require("Utils")
require("controllers/HeroSelectionController")
require("controllers/CurrencyController")
require("controllers/MapController")
require("controllers/WaveController")
require("controllers/UnitController")
require("controllers/HeroController")
require("controllers/KingController")
require("controllers/LaneController")
require("controllers/MineController")
require("controllers/FoodController")
require("controllers/UpgradesController")
require("controllers/MercenaryController")
require("controllers/StatsController")
require("BuildGrid")
require("GameUtils")
require("ChatUtils")
require("analytics/Analytics")

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]

	-- PrecacheResource( "particle_folder", "particles/units/heroes/hero_lina/", context )

	PrecacheResource("particle_folder", "particles/currencies/", context)
	PrecacheResource("particle_folder", "particles/spawns/", context)
	PrecacheResource("particle", "particles/units/heroes/hero_rattletrap/rattletrap_cog_attack.vpcf", context)

	-- Miner particles
	PrecacheResource( "particle", "particles/units/heroes/hero_chen/chen_teleport_flash.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/puck/puck_alliance_set/puck_illusory_orb_launch_aproset.vpcf", context )

	-- King
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_omniknight.vsndevts", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_oracle/oracle_false_promise_heal.vpcf", context )

	-- Boss
	PrecacheUnitByNameSync( "npc_dota_hero_nevermore", context )

	-- Currency, armour, crystal particles
	PrecacheResource( "particle_folder", "particles/units/", context )
	PrecacheResource( "particle_folder", "particles/currencies/", context )
	PrecacheResource( "particle_folder", "particles/crystal/", context )

end

-- Create the game mode when we activate
function Activate()

	GameRules.LegionDefence = CLegionDefence()
	GameRules.LegionDefence:InitGameMode()

end

function CLegionDefence:InitGameMode()

	print("CLegionDefence:InitGameMode()")
	self._GameMode = GameRules:GetGameModeEntity()
	self._GameMode._developer = true

	self._GameMode:SetThink( "OnThink", self, "GlobalThink", 2 )

	self._GameMode:SetAnnouncerDisabled( true )
	self._GameMode:SetFixedRespawnTime( 3 )
	self._GameMode:SetFogOfWarDisabled( true )
	
	GameRules:SetSameHeroSelectionEnabled( true )
	GameRules:SetGoldPerTick( 0 )
	GameRules:SetPreGameTime( 0 )
	GameRules:SetCustomGameSetupTimeout( 3 )

	self:SetupHeroSelectionController()
	self:SetupLaneController()
	self:SetupMapController()
	self:SetupCurrencyController()
	self:SetupWaveController()
	self:SetupUnitController()
	self:SetupHeroController()
	self:SetupKingController()
	self:SetupMineController()
	self:SetupFoodController()
	self:SetupUpgradeController()
	self:SetupMercenaryController()
	self:SetupStatsController()

	self:SetupAnalytics()

	GameRules:GetGameModeEntity():SetCustomGameForceHero( "npc_dota_hero_wisp" )

	ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CLegionDefence, "OnGameRulesStateChanged"), self)
	ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap(CLegionDefence, "OnPlayerPickedHero"), self)

end

-- Evaluate the state of the game
function CLegionDefence:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		-- print( "Template addon script is running." )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end

function CLegionDefence:OnGameRulesStateChanged( event )

	if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then

		-- Initialize analytics
		Analytics:Initialize()

		-- Open hero selection on clients
		self:GetHeroSelectionController():OnEnterHeroSelectionState()

	end

end

-- Debug, give player all levels
function CLegionDefence:OnPlayerPickedHero( event )

	local player = PlayerResource:GetPlayer( event.player )
	if player then
		local hero = player:GetAssignedHero()
		if hero then
		
			-- Remove Dota gold
			hero:SetGold(0, false)
			hero:SetGold(0, true)

			-- Make all abilities max level
			for i = 0, hero:GetAbilityCount() - 1, 1 do
				local ability = hero:GetAbilityByIndex(i)
				if ability then
					ability:SetLevel( ability:GetMaxLevel() )
				end
			end

			-- Heroes can't attack
			hero:SetAttackCapability( DOTA_UNIT_CAP_NO_ATTACK )

			-- Remove skill points
			hero:SetAbilityPoints(0)

			-- Give items
			-- hero:AddItemByName("item_necronomicon")

		end
	end

end
