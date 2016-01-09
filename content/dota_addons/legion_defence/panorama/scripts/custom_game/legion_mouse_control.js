"use strict";

GameUI.SetMouseCallback( function( eventName, arg )
{
	var nMouseButton = arg
	var CONSUME_EVENT = true;
	var CONTINUE_PROCESSING_EVENT = false;

	var LEGION_UNIT_NAME = "npc_legion_";
	var LEGION_CAN_CONTROL_TOWERS = false;

	var clickBehaviour = GameUI.GetClickBehaviors();
	
	if( clickBehaviour !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE &&
		clickBehaviour !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_CAST &&
		clickBehaviour !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_DRAG )
	{
		return CONSUME_EVENT;
	}

	// If player can't control tower units
	if ( !LEGION_CAN_CONTROL_TOWERS )
	{
		if ( nMouseButton === 1 )
		{
			// Prevent player from issuing commands while selecting tower units
			var localPly = Players.GetLocalPlayer();
			var selected = Players.GetSelectedEntities( localPly );
			for ( var e of selected )
			{
				var name = Entities.GetUnitName( e );
				name = name.substr(0, 11);
				if ( name.toLowerCase() == LEGION_UNIT_NAME )
				{
					return CONSUME_EVENT;
				} 
			}
		}
	}
	return CONTINUE_PROCESSING_EVENT;
} );
