
var m_CurrencyIcons = new Array();
m_CurrencyIcons["CurrencyGems"] = "file://{images}/custom_game/icons/icon_gems_small.png";
m_CurrencyIcons["CurrencyGold"] = "file://{images}/custom_game/icons/icon_gold_small.png";
m_CurrencyIcons["CurrencyFood"] = "file://{images}/custom_game/icons/icon_food_small.png";

var m_AttackTypes = [];
m_AttackTypes["DOTA_UNIT_CAP_MELEE_ATTACK"] = "legion_attack_type_melee";
m_AttackTypes["DOTA_UNIT_CAP_RANGED_ATTACK"] = "legion_attack_type_ranged";

var m_AttackTypesColours = [];
m_AttackTypesColours["DOTA_UNIT_CAP_MELEE_ATTACK"] = "crimson";
m_AttackTypesColours["DOTA_UNIT_CAP_RANGED_ATTACK"] = "turquoise";

var m_DamageTypes = [];
m_DamageTypes["DOTA_COMBAT_CLASS_ATTACK_BASIC"] = "legion_attack_type_basic";
m_DamageTypes["DOTA_COMBAT_CLASS_ATTACK_PIERCE"] = "legion_attack_type_pierce";
m_DamageTypes["DOTA_COMBAT_CLASS_ATTACK_SIEGE"] = "legion_attack_type_siege";
m_DamageTypes["DOTA_COMBAT_CLASS_ATTACK_HERO"] = "legion_attack_type_hero";

var m_DamageTypesColours = [];
m_DamageTypesColours["DOTA_COMBAT_CLASS_ATTACK_BASIC"] = "greenyellow";
m_DamageTypesColours["DOTA_COMBAT_CLASS_ATTACK_PIERCE"] = "gold";
m_DamageTypesColours["DOTA_COMBAT_CLASS_ATTACK_SIEGE"] = "orangered";
m_DamageTypesColours["DOTA_COMBAT_CLASS_ATTACK_HERO"] = "fuchsia";

var m_DefenceTypes = [];
m_DefenceTypes["DOTA_COMBAT_CLASS_DEFEND_SOFT"] = "legion_defence_type_soft";
m_DefenceTypes["DOTA_COMBAT_CLASS_DEFEND_STRONG"] = "legion_defence_type_strong";
m_DefenceTypes["DOTA_COMBAT_CLASS_DEFEND_STRUCTURE"] = "legion_defence_type_structure";
m_DefenceTypes["DOTA_COMBAT_CLASS_DEFEND_HERO"] = "legion_defence_type_hero";

var m_DefenceTypesColours = [];
m_DefenceTypesColours["DOTA_COMBAT_CLASS_DEFEND_SOFT"] = "limegreen";
m_DefenceTypesColours["DOTA_COMBAT_CLASS_DEFEND_STRONG"] = "darkorange";
m_DefenceTypesColours["DOTA_COMBAT_CLASS_DEFEND_STRUCTURE"] = "tomato";
m_DefenceTypesColours["DOTA_COMBAT_CLASS_DEFEND_HERO"] = "orchid";

function UpdateButton( mercIndex )
{
	var costText = $("#CostText");
	if(costText)
	{
		costText.text = GetMercenariesData()[mercIndex]["cost"];
	}

	var costCurrency = $("#CostImage");
	if(costCurrency)
	{
		costCurrency.src = m_CurrencyIcons["CurrencyGems"];
	}

	/*
	var mercImage = $("#UpgradeImage");
	if(mercImage)
	{
		mercImage.itemname = GetMercenariesData()[mercIndex]["icon"];
	}
	*/
}

function ShowTooltip( panel )
{
	var mercIndex = panel.id;
	var mercData = GetMercenariesData()[mercIndex];
	if(mercData && GetMercenariesData()[mercIndex]["id"])
	{
		var mercId = mercData["id"];
		var title = $.Localize("#" + mercId);
		var desc = $.Localize("#" + mercId + "_Description");

		var data = {
			"panelId" : panel.id,
			"title" : title.toUpperCase(),
			"desc" : desc,
			"value-1-name" : "",
			"value-2-name" : "",
			"value-3-name" : "",
			"value-4-name" : $.Localize("legion_income_tooltip").toUpperCase(),
			"cooldown" : mercData["cooldown"],
		};

		if(mercData)
		{
			var attackType = mercData["attack_capability"];
			var damageType = mercData["damage_type"];
			var defenceType = mercData["defence_type"];
			var income = mercData["income"];

			data["value-1-value"] = $.Localize(m_AttackTypes[attackType]);
			data["value-1-value-color"] = m_AttackTypesColours[attackType];

			data["value-2-value"] = $.Localize(m_DamageTypes[damageType]);
			data["value-2-value-color"] = m_DamageTypesColours[damageType];

			data["value-3-value"] = $.Localize(m_DefenceTypes[defenceType]);
			data["value-3-value-color"] = m_DefenceTypesColours[defenceType];

			data["value-4-value"] = " " + income + " " + $.Localize("legion_currency_gold");
			data["value-4-value-color"] = "gold";
		}

		GameEvents.SendEventClientSide("show_legion_tooltip", data );
	}
}

function HideTooltip( panel )
{
	GameEvents.SendEventClientSide("hide_legion_tooltip", {} );
}

function PurchaseMercenary( panel )
{
	var mercIndex = panel.id;
	var mercData = GetMercenariesData()[mercIndex];
	if(mercData && GetMercenariesData()[mercIndex]["id"])
	{
		GameEvents.SendCustomGameEventToServer( "legion_purchase_mercenary", { "sMercenaryId" : GetMercenariesData()[mercIndex]["id"] } );
	}
}

function OnMercenariesDataChanges()
{
	UpdateButton( $.GetContextPanel().id );
}

function GetMercenariesData()
{
	return CustomNetTables.GetTableValue( "MercenariesData", "units" );
}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "MercenariesData", OnMercenariesDataChanges );
	UpdateButton( $.GetContextPanel().id );
})();
