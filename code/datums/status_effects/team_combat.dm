#define TEAM_COMBAT_RANGE 3
/*
Team Combat:
Design your buddies and if they do the same, you get automatic stun reduction and minor deflection if they are nearby

1 Buddy : 
2 Buddies :
3 Buddies :
4 Buddies or more:
*/
/datum/status_effect/team_combat
	id = "team_combat"
	duration = -1
	alert_type = /obj/screen/alert/status_effect/team_combat
	var/list/buddies = list()

/obj/screen/alert/status_effect/team_combat
	name = "Team Combat"
	desc = "Your buddies have your back in a fight. Click this alert to stop team fighting."
	icon_state = "team_combat_0"

/obj/screen/alert/status_effect/team_combat/Click(location, control, params)
	. = ..()
	var/datum/status_effect/team_combat/T = attached_effect
	T.buddies.Cut()
	to_chat(T.owner,"You stop fighting in a team.")

/datum/status_effect/team_combat/tick()
	if(!HAS_TRAIT(owner,TRAIT_TEAM_COMBAT_TRAINING))
		on_remove()
		return
	var/buddy_count = 0
	for(var/mob/living/M in buddies)
		var/datum/status_effect/team_combat/T = M.has_status_effect(/datum/status_effect/team_combat)
		if(!T || M.incapacitated() || !in_range_n(owner,M,TEAM_COMBAT_RANGE))
			continue
		if(owner in T.buddies)
			buddy_count++
	UpdateEffects(buddy_count)

/datum/status_effect/team_combat/proc/UpdateEffects(buddy_count)
	switch(buddy_count)
		if(0)
			owner.add_stun_absorption("team_combat", 0)
			linked_alert.icon_state = "team_combat_0"
		if(1)
			owner.add_stun_absorption("team_combat", INFINITY, 1, "'s buddy has their back!", "Your buddy absorbs the stun!", " ready to fight back to back with [owner.p_their()] buddy!")
			linked_alert.icon_state = "team_combat_1"
		if(2 to INFINITY)
			owner.add_stun_absorption("team_combat", INFINITY, 1, "'s buddies have their back!", "Your buddy absorbs the stun!", " ready to fight back to back with [owner.p_their()] buddies!")
			linked_alert.icon_state = "team_combat_2"

/datum/status_effect/team_combat/on_remove()
	UpdateEffects(0)
	UnregisterSignal(owner,COMSIG_MOB_MIDDLECLICKON)

/datum/status_effect/team_combat/on_apply()
	. = ..()
	RegisterSignal(owner,COMSIG_MOB_MIDDLECLICKON,.proc/DesignateBuddy)

/datum/status_effect/team_combat/proc/DesignateBuddy(datum/source,mob/M)
	if(isliving(M) && M != owner)
		buddies |= M
	to_chat(owner,"<span class='notice'>You prepare to fight together with [M].</span>")

/mob/living/proc/gimme_team()
	ADD_TRAIT(src,TRAIT_TEAM_COMBAT_TRAINING,"memes")
	apply_status_effect(/datum/status_effect/team_combat)