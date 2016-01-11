
var m_Mercs = [];

function UpdateScrollBar()
{
	var visibleHeight = $("#MercsList").actuallayoutheight;
	var totalHeight = $("#MercsList").contentheight;
	if(!totalHeight){ totalHeight = 0.001; }
	var scrollMax = totalHeight - visibleHeight;
	var scrollOffset = Math.abs($("#MercsList").scrolloffset_y);
	var scrollPercent = scrollOffset / scrollMax;
	var heightPercent = 1 - visibleHeight / totalHeight;
	var scrollHeight = $("#ScrollBarBackground").actuallayoutheight * heightPercent;

	$("#ScrollBar").style.marginBottom = scrollHeight * (1 - scrollPercent) + "px";
	$("#ScrollBar").style.marginTop = scrollHeight * scrollPercent + "px";

	$.Schedule( 0.016, UpdateScrollBar );
}

function OnMercenaryUnitDataChanged()
{
	var nettable = CustomNetTables.GetTableValue( "MercenariesData", "units" );
	if(nettable)
	{
		// Get number of units
		var length = 0;
		for(var key in nettable)
		{
			length++;
		}

		// Create unit spawn buttons
		for(var i = 1; i < length; ++i)
		{
			var merc = $.CreatePanel( "Panel", $("#MercsList"), i.toString() );
			merc.BLoadLayout( "file://{resources}/layout/custom_game/mercenary_item.xml", true, false );
			m_Mercs.push( merc );
		}
	}
}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "MercenariesData", OnMercenaryUnitDataChanged );
	OnMercenaryUnitDataChanged();
	UpdateScrollBar();
})();
