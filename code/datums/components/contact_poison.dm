/datum/component/contact_poison
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/hit_apply_type = TOUCH
	var/touch_apply_type = TOUCH
	var/datum/reagents/poison
	var/check_gloves = TRUE
	var/silent = FALSE

/datum/component/contact_poison/Initialize(datum/reagents/poison,check_gloves,expire_time,silent)
	if(touch_apply_type)
		RegisterSignal(COMSIG_OBJ_TOUCHED, .proc/Contact)
	if(hit_apply_type)
		RegisterSignal(COMSIG_OBJ_HITTING_MOB, .proc/Hit)
	src.poison = poison
	src.check_gloves = check_gloves
	if(expire_time > 0)
		addtimer(CALLBACK(src,.proc/Expire),expire_time)
	
/datum/component/contact_poison/proc/Expire()
	qdel(src)

/datum/component/contact_poison/proc/Contact(mob/user)
	if(check_gloves)
		if(user.has_gloves() || (PIERCEIMMUNE in user.dna.species.species_traits))
			return
	if(!silent)
		to_chat("<span class='notice'>[parent] was covered in some substance!</span>)

	poison.reaction_mob(user, touch_apply_type)
	poison.transfer_to(user,poison.total_volume)
	qdel(src)

/datum/component/contact_poison/proc/Hit(mob/target)
	poison.reaction_mob