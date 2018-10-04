/datum/spell
	var/mode
	var/requirements
	var/list/root_sources
	//source -> source* -> spell_effect

/datum/recharge_mode
	recharge
	charges

/datum/target_source
	var/requires_input = FALSE //Only one of these with TRUE in root
	
	var/requires_target = FALSE //Same here
	var/required_target_type
	
	var/output_target_type

	var/configurables

	caster
	aimed
	targeted
	view
	held_item
	around

/datum/spell_effect
	var/required_target_type = SPELL_TARGET_MOB | SPELL_TARGET_OBJ | SPELL_TARGET_TURF
	var/configurables