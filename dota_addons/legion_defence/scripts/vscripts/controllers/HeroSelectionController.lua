
if CHeroSelectionController == nil then
	CHeroSelectionController = class({})
end

function CLegionDefence:SetupHeroSelectionController()
	self.hero_selection_controller = CHeroSelectionController()
	self.hero_selection_controller:Setup()
end

function CLegionDefence:GetHeroSelectionController()
	return self.hero_selection_controller
end

-------------------------------------
-- Hero Selection
-------------------------------------
CHeroSelectionController.SELECTION_MAX_TIME = 60
CHeroSelectionController.THINK_TIME = 0.5
CHeroSelectionController.NET_TABLE = "HeroesList"
CHeroSelectionController.PICKING_NET_TABLE = "HeroPickingData"

function CHeroSelectionController:Setup()

	self:BuildHeroList()

	GameRules:GetGameModeEntity():SetThink("OnThink", self, "HeroSelectionController.OnThink", CHeroSelectionController.THINK_TIME)
	CustomGameEventManager:RegisterListener( "legion_hero_selected", Dynamic_Wrap(CHeroSelectionController, "HandleOnHeroSelected") )

end

function CHeroSelectionController:BuildHeroList()

	local MAX_ABILITIES = 6

	self._available_heroes = {}
	self._hero_abilities = {}

	-- Build list of available heroes
	local heroes = LoadKeyValues("scripts/npc/herolist.txt")
	local hero_abilities = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")

	for hero_id, _ in pairs( heroes ) do

		for override_id, hero_data in pairs( hero_abilities ) do

			-- Find overridden hero
			if hero_data["override_hero"] == hero_id then

				-- Add override abilities
				local data = {}
				for i = 1, MAX_ABILITIES, 1 do
					local ability_name = hero_data["Ability" .. tostring(i)]
					if ability_name then
						table.insert( data, ability_name )
					end
				end

				-- Add hero
				table.insert( self._available_heroes, hero_id )
				self._hero_abilities[hero_id] = data

				break

			end

		end
		

	end

	-- Send heroes to players
	CustomNetTables:SetTableValue( CHeroSelectionController.NET_TABLE, "heroes", heroes )
	CustomNetTables:SetTableValue( CHeroSelectionController.NET_TABLE, "abilities", self._hero_abilities )

end

function CHeroSelectionController:OnThink()

	if self._pick_time_remaining ~= nil then

		self._pick_time_remaining = self._pick_time_remaining - CHeroSelectionController.THINK_TIME
		if self._pick_time_remaining < 0 then
			self:ForceRandomPickOnUnpickedPlayers()
			self:EndPicking()
			self._pick_time_remaining = nil
		end

	end

	return CHeroSelectionController.THINK_TIME

end

function CHeroSelectionController:ForceRandomPickOnUnpickedPlayers()
	-- TODO
end

function CHeroSelectionController:EndPicking()
	-- TODO
end

function CHeroSelectionController.HandleOnHeroSelected( iCallingEntity, event )

	local self = GameRules.LegionDefence:GetHeroSelectionController()

	-- Give player hero
	local player = event["PlayerID"]
	local hero = event["sHeroId"]
	self:AssignHeroToPlayer( player, hero )

	-- Announce hero choice
	SendCustomChatMessage( "legion_player_picked_hero", { arg_player = player, arg_string = hero } )

end

function CHeroSelectionController:OnEnterHeroSelectionState()

	self.hero_history = {}
	self.hero_history = self.hero_history or {}
	self.max_players = 0
	self.players_picked = 0

	for pID = 0, DOTA_MAX_PLAYERS -1 do
		if PlayerResource:IsValidPlayer( pID ) then
			self.max_players = self.max_players + 1
		end
	end

	-- Start the pick timer, players will be forced to random at the end of the time
	self._pick_time_remaining = CHeroSelectionController.SELECTION_MAX_TIME

	-- Send pick time start and duration to clients
	CustomGameEventManager:Send_ServerToAllClients( "legion_show_hero_picker", {} )
	local data = {
		["lStartTime"] = GameRules:GetDOTATime(false, false),
		["lDuration"] = CHeroSelectionController.SELECTION_MAX_TIME
	}
	CustomGameEventManager:Send_ServerToAllClients( "legion_start_hero_selection", data )
	CustomNetTables:SetTableValue( CHeroSelectionController.PICKING_NET_TABLE, "data", data )

end

function CHeroSelectionController:AssignHeroToPlayer( playerId, heroId )

	if playerId then

		-- Record the hero in the players pick history
		self.hero_history[playerId] = self.hero_history[playerId] or {}
		table.insert( self.hero_history[playerId], heroId )

		-- Cache and swap the unit
		PrecacheUnitByNameAsync( heroId, function()
			PlayerResource:ReplaceHeroWith( playerId, heroId, 0, 0 )
		end, playerId)

	end

end
