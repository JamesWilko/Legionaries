
var m_Tooltip;
var m_TooltipValueStyles = [];
var m_TooltipOffset = [14, 12];
var m_TooltipValues = 4;

var m_OneFrame = 1.0 / 60.0;
var m_ScreenSize = [];
var m_PanoramaHeight = 1080.0;
var m_PanoramaScaling;

var m_SavedTooltipData;
var m_AltDown;

function ShowTooltip( data )
{
	m_SavedTooltipData = data;

	m_Tooltip.FindChild("TooltipTitle").text = data["title"];
	m_Tooltip.FindChild("TooltipDesc").text = data["desc"];

	var tooltipAltDesc = m_Tooltip.FindChild("TooltipAltDesc");
	var altDesc = data["alt-desc"];
	if(altDesc && GameUI.IsAltDown())
	{
		tooltipAltDesc.visible = true;
		tooltipAltDesc.text = altDesc;
	}
	else
	{
		tooltipAltDesc.visible = false;
	}

	// Remove styles
	for(var key in m_TooltipValueStyles)
	{
		var childId = "TooltipValue" + key;
		var childValueId = "TooltipValue" + key + "Value";
		var value = m_Tooltip.FindChild(childId);
		var valueValue = value.FindChild(childValueId);
		valueValue.RemoveClass( m_TooltipValueStyles[key] );
	}
	m_TooltipValueStyles = [];

	// Process values
	for(var i = 1; i <= m_TooltipValues; ++i)
	{
		var idName = "value-" + i + "-name";
		var idValue = "value-" + i + "-value";
		var idColor = "value-" + i + "-value-color";

		var childId = "TooltipValue" + i;
		var childNameId = "TooltipValue" + i + "Name";
		var childValueId = "TooltipValue" + i + "Value";

		if(data[idName] || data[idValue])
		{
			var value = m_Tooltip.FindChild(childId);
			var valueText = value.FindChild(childNameId);
			var valueValue = value.FindChild(childValueId);

			value.visible = true;
			valueText.text = data[idName];
			valueValue.text = data[idValue];

			// Add new styles
			if(data[idColor])
			{
				var col = data[idColor];
				valueValue.AddClass( col );
				m_TooltipValueStyles[i] = col;
			}
		}
		else
		{
			m_Tooltip.FindChild(childId).visible = false;
		}
	}

	// Show cooldown
	var cooldown = m_Tooltip.FindChild("CooldownParent");
	if(cooldown)
	{
		var cooldownAmount = data["cooldown"];
		if(cooldownAmount)
		{
			cooldown.visible = true;
			var cooldownText = cooldown.FindChild("CooldownText");
			cooldownText.text = cooldownAmount;
		}
		else
		{
			cooldown.visible = false;
		}
	}

	m_Tooltip.visible = true;
}

function HideTooltip( data )
{
	m_Tooltip.visible = false;
}

function UpdateTooltipPosition()
{
	if(m_Tooltip)
	{
		// Put tooltip at mouse position
		var mousePos = GameUI.GetCursorPosition();
		var posX = mousePos[0] + m_TooltipOffset[0];
		var posY = mousePos[1] + m_TooltipOffset[1];

		// Flip tooltip if it's too close to an edge
		if(posX + m_Tooltip.desiredlayoutwidth > $.GetContextPanel().GetParent().actuallayoutwidth)
		{
			posX -= m_Tooltip.desiredlayoutwidth;
		}
		if(posY + m_Tooltip.desiredlayoutwidth > $.GetContextPanel().GetParent().actuallayoutheight)
		{
			posY -= m_Tooltip.desiredlayoutheight;
		}

		// Move tooltip to correct position with scaling
		m_Tooltip.style.marginLeft = posX / m_PanoramaScaling + "px";
		m_Tooltip.style.marginTop = posY / m_PanoramaScaling + "px";
	}
	$.Schedule(m_OneFrame, UpdateTooltipPosition);
}

function UpdateTooltipAltText()
{
	if(m_Tooltip && m_SavedTooltipData)
	{
		var altDown = GameUI.IsAltDown();
		if(m_AltDown != altDown)
		{
			var tooltipAltDesc = m_Tooltip.FindChild("TooltipAltDesc");
			var altDesc = m_SavedTooltipData["alt-desc"];
			if(altDown && altDesc)
			{
				tooltipAltDesc.visible = true;
				tooltipAltDesc.text = altDesc;
			}
			else
			{
				tooltipAltDesc.visible = false;
			}

			m_AltDown = altDown;
		}
	}
	$.Schedule(m_OneFrame, UpdateTooltipAltText);
}

function SetupTooltip()
{
	// Calculate screen scaling to set positions correctly
	m_ScreenSize[0] = m_Tooltip.GetParent().actuallayoutwidth;
	m_ScreenSize[1] = m_Tooltip.GetParent().actuallayoutheight;
	m_PanoramaScaling = m_ScreenSize[1] / m_PanoramaHeight;

	UpdateTooltipAltText();
	UpdateTooltipPosition();
}

(function()
{
	// Hide tooltip by default
	m_Tooltip = $("#Tooltip");
	m_Tooltip.visible = false;	

	// Tooltip events
	GameEvents.Subscribe("show_legion_tooltip", ShowTooltip);
	GameEvents.Subscribe("hide_legion_tooltip", HideTooltip);

	// Setup after creating UI
	$.Schedule(1, SetupTooltip);

})();
