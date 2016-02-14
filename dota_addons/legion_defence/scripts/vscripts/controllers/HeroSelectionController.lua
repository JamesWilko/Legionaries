
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
CHeroSelectionController.MAXIMUM_REPICKS = 5
CHeroSelectionController.REPICK_DRAFT_NUMBER = 2

function CHeroSelectionController:Setup()

	self:BuildHeroList()

	GameRules:GetGameModeEntity():SetThink("OnThink", self, "HeroSelectionController.OnThink", CHeroSelectionController.THINK_TIME)
	CustomGameEventManager:RegisterListener( "legion_hero_selected", Dynamic_Wrap(CHeroSelectionController, "HandleOnHeroSelected") )

	Convars:RegisterCommand( "legion_hero_select", function(name, parameter)
		self:OnEnterHeroSelectionState()
	end, "", FCVAR_CHEAT )

	Convars:RegisterCommand( "legion_hero_select_limited", function(name, parameter)
		self:PlayerRepickHero( SafeGetPlayerID(Convars:GetCommandClient()), 0, 0 )
	end, "", FCVAR_CHEAT )

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
			if type(hero_data) == "table" and hero_data["override_hero"] == hero_id then

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

function CHeroSelectionController:IsHeroPickerStateActive()
	return self._pick_time_remaining ~= nil
end

function CHeroSelectionController:OnThink()

	if self._pick_time_remaining ~= nil then

		self._pick_time_remaining = self._pick_time_remaining - CHeroSelectionController.THINK_TIME
		if self._pick_time_remaining < 0 then
			self._pick_time_remaining = nil
			self:ForceRandomPickOnUnpickedPlayers()
			self:EndPicking()
		end

	end

	return CHeroSelectionController.THINK_TIME

end

function CHeroSelectionController:ForceRandomPickOnUnpickedPlayers()
	
	for pID = 0, DOTA_MAX_PLAYERS -1 do
		if PlayerResource:IsValidPlayer( pID ) and (not self.hero_history[pID] or #self.hero_history[pID] == 0) then
			
			print("Forcing random pick on player " .. tostring(pID))
			local data = {
				["PlayerID"] = pID,
				["sHeroId"] = self._available_heroes[math.random(#self._available_heroes)]
			}
			CHeroSelectionController.HandleOnHeroSelected( -1, data )

		end
	end

end

function CHeroSelectionController:EndPicking()
	CustomGameEventManager:Send_ServerToAllClients( "legion_close_hero_picker", {} )
	FireGameEventLocal( "legion_hero_selection_complete", {} )
end

function CHeroSelectionController.HandleOnHeroSelected( iCallingEntity, event )

	local self = GameRules.LegionDefence:GetHeroSelectionController()

	-- Give player hero
	local player = event["PlayerID"]
	local hero = event["sHeroId"]
	self:AssignHeroToPlayer( player, hero )

	print(string.format("Player %i picked %s", player, hero))

	-- Announce hero choice
	if not self.hero_history[player] or #self.hero_history[player] <= 1 then
		SendCustomChatMessage( "legion_player_picked_hero", { player = player, arg_string = hero } )
	else
		SendCustomChatMessage( "legion_player_repicked_hero", { player = player, arg_string = hero } )
	end

	-- Close hero picker on client
	local hPlayer = PlayerResource:GetPlayer(player)
	if hPlayer then
		CustomGameEventManager:Send_ServerToPlayer( hPlayer, "legion_close_hero_picker", {} )
	end

	-- Check if all players have picked and start game
	if self:IsHeroPickerStateActive() then

		local all_picked = true

		for playerId = 0, DOTA_MAX_PLAYERS -1 do
			if PlayerResource:IsValidPlayer( playerId ) then
				if not self.hero_history[playerId] or #self.hero_history[playerId] < 1 then
					all_picked = false
					break
				end
			end
		end

		if all_picked then
			print("All players have picked heroes...")
			self:EndPicking()
		end

	end

end

function CHeroSelectionController:OnEnterHeroSelectionState()

	self.hero_history = self.hero_history or {}

	-- Start the pick timer, players will be forced to random at the end of the time
	self._pick_time_remaining = CHeroSelectionController.SELECTION_MAX_TIME

	-- Send pick time start and duration to clients
	local data = {
		["lStartTime"] = GameRules:GetDOTATime(false, false),
		["lDuration"] = CHeroSelectionController.SELECTION_MAX_TIME,
		["bLimitedSelection"] = false
	}
	CustomGameEventManager:Send_ServerToAllClients( "legion_show_hero_picker", data )
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

			local data = {
				["player"] = playerId,
				["hero"] = heroId,
			}
			FireGameEventLocal("dota_player_pick_hero", data)

		end, playerId)

		-- Analytics
		local history_length = #self.hero_history[playerId]
		if #self.hero_history[playerId] <= 1 then
			Analytics:RecordPlayerPickedHero( playerId, heroId )
		else
			Analytics:RecordPlayerRepickedHero( playerId, heroId )
		end

	end

end

function CHeroSelectionController:PlayerRepickHero( playerId, upgradeLevel, levelsAdded )

	local player = PlayerResource:GetPlayer(playerId)
	if player then

		-- Set hero selection data for player
		local heroes = {}
		

		while #heroes < CHeroSelectionController.REPICK_DRAFT_NUMBER do

			local hero = self._available_heroes[math.random(#self._available_heroes)]
			while true do
				local unique = true
				hero = self._available_heroes[math.random(#self._available_heroes)]
				for k, v in pairs(heroes) do
					if v == hero then
						unique = false
						break
					end
				end
				if unique then
					table.insert( heroes, hero )
					break
				end
			end

		end

		CustomNetTables:SetTableValue( CHeroSelectionController.PICKING_NET_TABLE, tostring(playerId), heroes )

		-- Open hero selection for player
		local data = {
			["lStartTime"] = GameRules:GetDOTATime(false, false),
			["lDuration"] = -1,
			["bLimitedSelection"] = true
		}
		CustomGameEventManager:Send_ServerToPlayer( player, "legion_show_hero_picker", data )

	end

end
