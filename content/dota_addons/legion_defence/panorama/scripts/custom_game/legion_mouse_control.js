
"use strict";

var m_MinDistance = 1134;
var m_MaxDistance = 1650;
var m_CurrentDistance = m_MinDistance;

GameUI.SetMouseCallback( function( eventName, arg )
{
	if(eventName == "wheeled")
	{
		return ProcessWheelEvent(eventName, arg);
	}
	else
	{
		return ProcessClickEvent(eventName, arg);
	}
} );

function ProcessClickEvent( eventName, arg )
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
}

function ProcessWheelEvent( eventName, arg )
{
	m_CurrentDistance += -arg * ((m_MaxDistance - m_MinDistance) / 20.0);
	if(m_CurrentDistance < m_MinDistance){ m_CurrentDistance = m_MinDistance; }
	if(m_CurrentDistance > m_MaxDistance){ m_CurrentDistance = m_MaxDistance; }
	GameUI.SetCameraDistance(m_CurrentDistance);
}
