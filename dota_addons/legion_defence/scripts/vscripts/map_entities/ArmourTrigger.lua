
function ArmourTrigger1_OnStartTouch( trigger )
	local hUnit = trigger.activator
	GameRules.LegionDefence:GetWaveController():AttemptIncreaseArmourOnUnit( hUnit, 1 )
end

function ArmourTrigger2_OnStartTouch( trigger )
	local hUnit = trigger.activator
	GameRules.LegionDefence:GetWaveController():AttemptIncreaseArmourOnUnit( hUnit, 2 )
end
