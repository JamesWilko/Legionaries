
function SendCustomChatMessage( sMessage, args )

	args = args or {}

	local data = {
		["sMessage"] = sMessage,
		["iTeam"] = args.team ~= nil and args.team or -1,
		["lPlayer"] = args.player ~= nil and args.player or -1,
		["bPlayerOnly"] = args.to_player_only or false,
		["argPlayer"] = args.arg_player ~= nil and args.arg_player or -1,
		["argNumber"] = args.arg_number ~= nil and args.arg_number or -1,
		["argString"] = args.arg_string ~= nil and args.arg_string or -1,
	}
	FireGameEvent( "legion_custom_chat", data )

end
