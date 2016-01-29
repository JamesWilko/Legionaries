
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

function ShowTooltip( panel )
{
	var waveId = panel.wave.toString();
	var waveData;
	var title = "";
	var desc;
	var boss;
	var arena;

	var nettable = CustomNetTables.GetTableValue( "UpcomingWaveData", "waves" );
	if(nettable && nettable[waveId] && nettable[waveId]["wave"])
	{
		// Set tooltip info
		var waveData = nettable[waveId]["wave"];
		for (var key in waveData)
		{
			if(key.indexOf("npc_") == 0)
			{
				title = ($.Localize(key)).toUpperCase() + " (x" + waveData[key] + ")";
				desc = $.Localize(key + "_Description");
				break;
			}
		}

		// Show tooltip boss wave tag
		var isBoss = waveData["boss"] != undefined && waveData["boss"] == "true";
		if(isBoss)
		{
			boss = $.Localize("legion_boss_wave").toUpperCase();
		}

		// Show tooltip boss wave tag
		var isArena = waveData["arena"] != undefined && waveData["arena"] == "true";
		if(isArena)
		{
			arena = $.Localize("legion_arena_wave_Tag").toUpperCase();
			title = $.Localize("legion_arena_wave").toUpperCase();
			desc = $.Localize("legion_arena_wave_Description");
		}
	}

	var data = {
		"panelId" : panel.id,
		"title" : title,
	};

	if(desc && desc != "")
	{
		data["desc"] = desc;
	}
	if(waveData)
	{
		var attackType = waveData["attack_capability"];
		var damageType = waveData["damage_type"];
		var defenceType = waveData["defence_type"];

		if(attackType)
		{
			data["value-1-name"] = "";
			data["value-1-value"] = $.Localize(m_AttackTypes[attackType]);
			data["value-1-value-color"] = m_AttackTypesColours[attackType];
		}
		if(damageType)
		{
			data["value-2-name"] = "";
			data["value-2-value"] = $.Localize(m_DamageTypes[damageType]);
			data["value-2-value-color"] = m_DamageTypesColours[damageType];
		}
		if(defenceType)
		{
			data["value-3-name"] = "";
			data["value-3-value"] = $.Localize(m_DefenceTypes[defenceType]);
			data["value-3-value-color"] = m_DefenceTypesColours[defenceType];
		}
	}

	if(boss)
	{
		data["value-4-name"] = "";
		data["value-4-value"] = boss;
		data["value-4-value-color"] = "red";
	}
	else if(arena)
	{
		data["value-4-name"] = "";
		data["value-4-value"] = arena;
		data["value-4-value-color"] = "gold";
	}

	GameEvents.SendEventClientSide("show_legion_tooltip", data );
}

function HideTooltip( panel )
{
	GameEvents.SendEventClientSide("hide_legion_tooltip", {} );
}
