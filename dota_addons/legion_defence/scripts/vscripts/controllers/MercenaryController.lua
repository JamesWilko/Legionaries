
if CMercenaryController == nil then
	CMercenaryController = class({})
end

function CLegionDefence:SetupMercenaryController()
	self.mercenary_controller = CMercenaryController()
	self.mercenary_controller:Setup()
end

function CLegionDefence:GetMercenaryController()
	return self.mercenary_controller
end

---------------------------------------
-- Mercenary Controller
---------------------------------------
CMercenaryController.NET_TABLE = "MercenariesData"

function CMercenaryController:Setup()

	self._mercenaries = {}

	self:BuildMercenariesList()

end

function CMercenaryController:BuildMercenariesList()

	-- Find all mercenary units
	local kv_units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	for k, unit_data in pairs( kv_units ) do

		if string.find(k, "npc_legion_merc_") then

			-- Add data
			local data = {
				id = k,
				cost = unit_data["GemsCost"],
				attack_capability = unit_data["AttackCapabilities"],
				damage_type = unit_data["CombatClassAttack"],
				defence_type = unit_data["CombatClassDefend"],
			}
			table.insert( self._mercenaries, data )

		end
	end

	-- Sort units by cost
	table.sort(self._mercenaries, function(a, b) return a.cost < b.cost end)


	-- Update net table
	CustomNetTables:SetTableValue( CMercenaryController.NET_TABLE, "units", self._mercenaries )

end
