/obj/item/weapon/relic
	name = "strange object"
	desc = "What mysteries could this hold?"
	icon = 'icons/obj/assemblies.dmi'
	origin_tech = "combat=1;plasmatech=1;powerstorage=1;materials=1"
	var/realName = "defined object"
	var/revealed = FALSE
	var/realProc
	var/cooldownMax = 60
	var/cooldown

	var/act_mapping
	var/phase_targets
	var/phase_values
	var/current_phase = 0
	var/phases = 1
	var/technobabble

#define RELIC_PLUS
#define RELIC_MINUS
#define RELIC_RANDOM
#define RELIC_FLIP
#define RELIC_ACTIVATE

/obj/item/weapon/relic/proc/hot_cold_message(value,target)
	var/diff = abs(value - target)
	switch(diff)
		if(0 to 1)
			return "[src] [technobabble] synchronization : High."
		if(2 to 10)
			return "[src] [technobabble] synchronization : Medium."
		if(11 to 20)
			return "[src] [technobabble] synchronization : Low."
		if(21 to 40)
			return "[src] [technobabble] synchronization : Critical."
		if(41 to 60)
			return "[src] emits a faint noise."
		else
			return "Nothing happens."

/obj/item/weapon/relic/Initialize(mapload)
	var/actions = list(RELIC_PLUS,RELIC_MINUS,RELIC_RANDOM,RELIC_FLIP,RELIC_ACTIVATE)
	var/tools = list(/obj/item/weapon/screwdriver,/obj/item/weapon/wrench,/obj/item/weapon/multiool,/obj/item/weapon/crowbar,/obj/item/weapon/welder)

	act_mapping = list()
	for(var/tool_type in tools)
		act_mapping[tool_type] = pick_n_take(actions)

	phase_values = list()
	phase_targets = list()
	for(var/phase in 1 to phases)
		phase_values.Add(rand(0,100))
		phase_targs.Add(rand(0,100))
	
	technobabble = pick("polarity","phase matrix","subspace frequency","tick period")

/obj/item/weapon/relic/proc/tool_act(act,user)
	switch(act)
		if(RELIC_PLUS)
			phase_values[current_phase] = Min(phase_values[current_phase]+1,100)
			user << "You increase [src] [technobabble]."
		if(RELIC_MINUS)
			phase_values[current_phase] = Max(phase_values[current_phase]-1,0)
			user << "You decrease [src] [technobabble]."
		if(RELIC_FLIP)
			phase_values[current_phase] = 100 - phase_values[current_phase]
			user << "You reverse [src] [technobabble]."
		if(RELIC_RANDOM)
			phase_values[current_phase] = rand(0,100)
			user << "You scramble [src] [technobabble]."
		if(RELIC_ACTIVATE)
			try_activating(user)

/obj/item/weapon/relic/proc/effect(mob/user,phase)
	playsound(loc,'sound/machines/ding.ogg',50,1)

/obj/item/weapon/relic/attacked_by(obj/item/I, mob/living/user)
	for(var/tool_type in act_mapping)
		if(istype(I,tool_type))
			tool_act(act_mapping[tool_type],user)
			return
	return ..()

/obj/item/weapon/relic/proc/try_activating(user)
	if(phase_targets[current_phase] == phase_values[current_phase])
		if(phases > current_phase)
			user << "[src] starts working [phase > 0 ? "better" : ""]!"
			current_phase++
			if(!revealed)
				reveal()
	else
		user << hot_cold_message(phase_values[current_phase],phase_targets[current_phase])

/obj/item/weapon/relic/New()
	..()
	icon_state = pick("shock_kit","armor-igniter-analyzer","infra-igniter0","infra-igniter1","radio-multitool","prox-radio1","radio-radio","timer-multitool0","radio-igniter-tank")
	realName = "[pick("broken","twisted","spun","improved","silly","regular","badly made")] [pick("device","object","toy","illegal tech","weapon")]"

/obj/item/weapon/relic/proc/reveal()
	if(revealed) //Re-rolling your relics seems a bit overpowered, yes?
		return
	revealed = TRUE
	name = realName
	cooldownMax = rand(60,300)
	origin_tech = pick("engineering=[rand(2,5)]","magnets=[rand(2,5)]","plasmatech=[rand(2,5)]","programming=[rand(2,5)]","powerstorage=[rand(2,5)]")

/obj/item/weapon/relic/attack_self(mob/user)
	if(revealed)
		if(cooldown)
			user << "<span class='warning'>[src] does not react!</span>"
			return
		else if(src.loc == user)
			cooldown = TRUE
			effect(user,phase)
			addtimer(CALLBACK(src,./reset_timer),cooldownMax,TIMER_UNIQUE)
	else
		user << "<span class='notice'>You aren't quite sure what to do with this yet.</span>"

/obj/item/weapon/relic/proc/reset_timer()
	cooldown = FALSE

//////////////// RELIC PROCS /////////////////////////////

/obj/item/weapon/relic/smoke/proc/effect(mob/user,phase)
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(0, get_turf(user))
	smoke.start()

/obj/item/weapon/relic/corgicannon/proc/effect(mob/user,phase)
	playsound(src.loc, "sparks", rand(25,50), 1)
	var/mob/living/simple_animal/pet/dog/corgi/C = new/mob/living/simple_animal/pet/dog/corgi(get_turf(user))
	C.throw_at(pick(oview(10,user)), 10, rand(3,8), callback = CALLBACK(src, .throwSmoke, C))
	warn_admins(user, "Corgi Cannon", 0)

/obj/item/weapon/relic/clean/proc/effect(mob/user,phase)
	playsound(src.loc, "sparks", rand(25,50), 1)
	var/obj/item/weapon/grenade/chem_grenade/cleaner/CL = new/obj/item/weapon/grenade/chem_grenade/cleaner(get_turf(user))
	CL.prime()
	warn_admins(user, "Smoke", 0)

/obj/item/weapon/relic/flash/proc/effect(mob/user,phase)
	playsound(src.loc, "sparks", rand(25,50), 1)
	var/obj/item/weapon/grenade/flashbang/CB = new/obj/item/weapon/grenade/flashbang(get_turf(user))
	CB.prime()
	warn_admins(user, "Flash")

/obj/item/weapon/relic/petspray/proc/effect(mob/user,phase)
	var/message = "<span class='danger'>[src] begans to shake, and in the distance the sound of rampaging animals arises!</span>"
	visible_message(message)
	user << message
	var/animals = rand(1,25)
	var/counter
	var/list/valid_animals = list(/mob/living/simple_animal/parrot,/mob/living/simple_animal/butterfly,/mob/living/simple_animal/pet/cat,/mob/living/simple_animal/pet/dog/corgi,/mob/living/simple_animal/crab,/mob/living/simple_animal/pet/fox,/mob/living/simple_animal/hostile/lizard,/mob/living/simple_animal/mouse,/mob/living/simple_animal/pet/dog/pug,/mob/living/simple_animal/hostile/bear,/mob/living/simple_animal/hostile/poison/bees,/mob/living/simple_animal/hostile/carp)
	for(counter = 1; counter < animals; counter++)
		var/mobType = pick(valid_animals)
		new mobType(get_turf(src))
	warn_admins(user, "Mass Mob Spawn")
	if(prob(60))
		user << "<span class='warning'>[src] falls apart!</span>"
		qdel(src)

/obj/item/weapon/relic/rapiddupe/proc/effect(mob/user,phase)
	audible_message("[src] emits a loud pop!")
	var/list/dupes = list()
	var/counter
	var/max = rand(5,10)
	for(counter = 1; counter < max; counter++)
		var/obj/item/weapon/relic/R = new src.type(get_turf(src))
		R.name = name
		R.desc = desc
		R.realName = realName
		R.realProc = realProc
		R.revealed = TRUE
		dupes |= R
		R.throw_at(pick(oview(7,get_turf(src))),10,1)
	counter = 0
	spawn(rand(10,100))
		for(counter = 1; counter <= dupes.len; counter++)
			var/obj/item/weapon/relic/R = dupes[counter]
			qdel(R)
	warn_admins(user, "Rapid duplicator", 0)

/obj/item/weapon/relic/explode/proc/effect(mob/user,phase)
	user << "<span class='danger'>[src] begins to heat up!</span>"
	spawn(rand(35,100))
		if(src.loc == user)
			visible_message("<span class='notice'>The [src]'s top opens, releasing a powerful blast!</span>")
			explosion(user.loc, -1, rand(1,5), rand(1,5), rand(1,5), rand(1,5), flame_range = 2)
			warn_admins(user, "Explosion")
			qdel(src) //Comment this line to produce a light grenade (the bomb that keeps on exploding when used)!!

/obj/item/weapon/relic/teleport/proc/effect(mob/user,phase)
	user << "<span class='notice'>The [src] begins to vibrate!</span>"
	spawn(rand(10,30))
		var/turf/userturf = get_turf(user)
		if(src.loc == user && userturf.z != ZLEVEL_CENTCOM) //Because Nuke Ops bringing this back on their shuttle, then looting the ERT area is 2fun4you!
			visible_message("<span class='notice'>The [src] twists and bends, relocating itself!</span>")
			throwSmoke(userturf)
			do_teleport(user, userturf, 8, asoundin = 'sound/effects/phasein.ogg')
			throwSmoke(get_turf(user))
			warn_admins(user, "Teleport", 0)


/obj/item/weapon/relic/random

/obj/item/weapon/relic/random/New()
	..()
	var real_type = pick(subtypesof(/obj/item/weapon/relic) - type)
    new T(get_turf(src))
    qdel(src)

//Admin Warning proc for relics
/obj/item/weapon/relic/proc/warn_admins(mob/user, RelicType, priority = 1)
	var/turf/T = get_turf(src)
	var/log_msg = "[RelicType] relic used by [key_name(user)] in ([T.x],[T.y],[T.z])"
	if(priority) //For truly dangerous relics that may need an admin's attention. BWOINK!
		message_admins("[RelicType] relic activated by [key_name_admin(user)](<A HREF='?_src_=holder;adminmoreinfo=\ref[user]'>?</A>) (<A HREF='?_src_=holder;adminplayerobservefollow=\ref[user]'>FLW</A>) in ([T.x],[T.y],[T.z] - <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[T.x];Y=[T.y];Z=[T.z]'>JMP</a>)",0,1)
	log_game(log_msg)
	investigate_log(log_msg, "experimentor")