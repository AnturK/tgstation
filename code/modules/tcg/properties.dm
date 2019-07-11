/datum/tcg_property/defenseboost
	name = "Defense Boost"
	desc = "Increase DEF gain by 1 per stack."
	ui_icon = "fas fa-shield-alt"

/datum/tcg_property/defenseboost/apply_to(datum/tcg_actor/target)
	RegisterSignal(target,COMSIG_TCG_DEFENSE_CHANGED, .proc/defense_boost)

/datum/tcg_property/defenseboost/proc/defense_boost(datum/tcg_actor/source, amount)
	if(amount > 0)
		var/bonus = source.properties[type]
		source.defense += bonus


/datum/tcg_property/swarm
	name = "Swarm"
	desc = "Deals 1 more damage for every ally alive."
	ui_icon = "fas fa-users"

/datum/tcg_property/swarm/apply_to(datum/tcg_actor/target)
	RegisterSignal(target,COMSIG_TCG_DAMAGE_MOD, .proc/add_damage)

/datum/tcg_property/swarm/proc/add_damage(datum/tcg_actor/source,datum/tcg_actor/target,list/damage_mod_reflist,datum/tcg_game/context)
	var/ally_count = 0
	for(var/datum/tcg_actor/A in context.actors)
		if(A != source && A.team == source.team)
			ally_count++
	damage_mod_reflist[1] = damage_mod_reflist[1] + ally_count