
function ShowTooltip( panel )
{
	var upgradesData = CustomNetTables.GetTableValue( "Upgrades", "upgrades" );

	var title = $.Localize(panel.id);
	var desc = $.Localize(panel.id + "_Description");
	var value_name = $.Localize(panel.id + "_Value");
	var value = upgradesData[panel.id.toString()]["value"];

	var data = {
		"panelId" : panel.id,
		"title" : title.toUpperCase(),
		"desc" : desc,
		"value-name" : value_name,
		"value-value" : value,
		"value-value-color" : "yellow",
	};
	GameEvents.SendEventClientSide("show_legion_tooltip", data );
}

function HideTooltip( panel )
{
	GameEvents.SendEventClientSide("hide_legion_tooltip", {} );
}

function PurchaseUpgrade( panel )
{
	GameEvents.SendCustomGameEventToServer( "legion_purchase_upgrade", { "sUpgradeId" : panel.id } );
}
