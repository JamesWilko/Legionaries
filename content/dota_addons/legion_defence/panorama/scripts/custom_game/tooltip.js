
var m_Tooltip;
var m_TooltipValueStyles = [];
var m_TooltipOffset = [14, 12];

var m_OneFrame = 1.0 / 60.0;
var m_ScreenHeight;
var m_PanoramaHeight = 1080.0;
var m_PanoramaScaling;

function ShowTooltip( data )
{
	m_Tooltip.FindChild("TooltipTitle").text = data["title"];
	m_Tooltip.FindChild("TooltipDesc").text = data["desc"];

	if(data["value-name"] || data["value-value"])
	{
		var value = m_Tooltip.FindChild("TooltipValue");
		var valueText = value.FindChild("TooltipValueName");
		var valueValue = value.FindChild("TooltipValueValue");

		value.visible = true;
		valueText.text = data["value-name"];
		valueValue.text = data["value-value"];

		// Remove styles
		for(var i = 0; i < m_TooltipValueStyles.length; ++i)
		{
			valueValue.RemoveClass(m_TooltipValueStyles[i]);
		}

		// Add new styles
		if(data["value-value-color"])
		{
			var col = data["value-value-color"];
			valueValue.AddClass( col );
			m_TooltipValueStyles.push( col );
		}
	}
	else
	{
		m_Tooltip.FindChild("TooltipValue").visible = false;
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
		var mousePos = GameUI.GetCursorPosition();
		m_Tooltip.style.marginLeft = (mousePos[0] + m_TooltipOffset[0]) / m_PanoramaScaling + "px";
		m_Tooltip.style.marginTop = (mousePos[1] + m_TooltipOffset[1]) / m_PanoramaScaling + "px";
	}
	$.Schedule(m_OneFrame, UpdateTooltipPosition);
}

function SetupTooltip()
{
	// Calculate screen scaling to set positions correctly
	m_ScreenHeight = m_Tooltip.GetParent().actuallayoutheight;
	m_PanoramaScaling = m_ScreenHeight / m_PanoramaHeight;

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
