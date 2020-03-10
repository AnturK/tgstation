GLOBAL_DATUM(the_gateway, /obj/machinery/gateway/centerstation)
GLOBAL_LIST_EMPTY(gateway_destinations)

/// Corresponds to single entry in gateway control
/datum/gateway_destination
	var/name = "Unknown Destination"
	var/wait = 0 // How long after roundstart this destination becomes active
	var/enabled = TRUE //If disabled, the destination won't be availible
	var/hidden = FALSE // Will not show on gateway controls at all.

/// Can a gateway link to this destination right now.
/datum/gateway_destination/proc/is_availible()
	return enabled && world.time >= wait

/// Returns user-friendly description why you can't connect to this destination display in UI
/datum/gateway_destination/proc/get_availible_reason()
	. = "Unreachable"
	if(world.time < wait)
		. = "Connection desynchronized. Recalibration in progress."

// Check if the movable is allowed to arrive (exile implants mostly)
/datum/gateway_destination/proc/incoming_pass_check(atom/movable/AM)
	return TRUE

/// Get the actual turf we'll arrive at
/datum/gateway_destination/proc/get_target_turf()
	CRASH("get target turf not implemented for this destination type")

/// Things to do after arrival
/datum/gateway_destination/proc/post_transfer(atom/movable/AM)
	if (ismob(AM))
		var/mob/M = AM
		if (M.client)
			M.client.move_delay = max(world.time + 5, M.client.move_delay)

/// Called when gateway activates with this destination.
/datum/gateway_destination/proc/activate(obj/machinery/gateway/activated)
	return

/// Called when gateway targeting this destination deactivates.
/datum/gateway_destination/proc/deactivate(obj/machinery/gateway/deactivated)
	return

/// Returns data used by gateway controller ui
/datum/gateway_destination/proc/get_ui_data()
	. = list()
	.["ref"] = REF(src)
	.["name"] = name
	.["availible"] = is_availible()
	.["reason"] = get_availible_reason()
	if(wait)
		.["timeout"] = max(1 - (wait - world.time) / wait, 0)

/// Destination is another gateway
/datum/gateway_destination/gateway
	var/obj/machinery/gateway/G

// We set the target gateway target to activator
/datum/gateway_destination/gateway/activate(obj/machinery/gateway/activated)
	if(!G.target)
		G.activate(activated)

// We turn off the target gateway too
/datum/gateway_destination/gateway/deactivate(obj/machinery/gateway/deactivated)
	if(G.target == deactivated.destination)
		G.deactivate()

/datum/gateway_destination/gateway/is_availible()
	return ..() && G.calibrated && !G.target && G.powered()

/datum/gateway_destination/gateway/get_availible_reason()
	. = ..()
	if(!G.calibrated)
		. = "Exit gateway malfunction. Manual recalibration required."
	if(G.target)
		. = "Exit gateway in use."
	if(!G.powered())
		. = "Exit gateway unpowered."

/datum/gateway_destination/gateway/get_target_turf()
	return get_step(G.portal,SOUTH)

/datum/gateway_destination/gateway/post_transfer(atom/movable/AM)
	. = ..()
	AM.setDir(SOUTH)

/// Special home destination, so we can check exile implants
/datum/gateway_destination/gateway/home

/datum/gateway_destination/gateway/home/incoming_pass_check(atom/movable/AM)
	if(isliving(AM))
		if(check_exile_implant(AM))
			return FALSE
	else
		for(var/mob/living/L in AM.contents)
			if(check_exile_implant(L))
				G.say("Rejecting [AM]: Exile implant detected in contained lifeform.")
				return FALSE
	if(AM.has_buckled_mobs())
		for(var/mob/living/L in AM.buckled_mobs)
			if(check_exile_implant(L))
				G.say("Rejecting [AM]: Exile implant detected in close proximity lifeform.")
				return FALSE
	return TRUE

/datum/gateway_destination/gateway/home/proc/check_exile_implant(mob/living/L)
	for(var/obj/item/implant/exile/E in L.implants)//Checking that there is an exile implant
		to_chat(L, "<span class='userdanger'>The station gate has detected your exile implant and is blocking your entry.</span>")
		return TRUE
	return FALSE


/// Destination is one ore more turfs - created by landmarks
/datum/gateway_destination/point
	var/list/target_turfs = list()
	var/id /// Used by away landmarks

/datum/gateway_destination/point/get_target_turf()
	return pick(target_turfs)

/obj/effect/gateway_portal_bumper
	var/obj/machinery/gateway/gateway
	density = TRUE
	invisibility = INVISIBILITY_ABSTRACT

//okay, here's the good teleporting stuff
/obj/effect/gateway_portal_bumper/Bumped(atom/movable/AM)
	gateway.Transfer(AM)

/obj/effect/gateway_portal_bumper/Destroy(force)
	. = ..()
	gateway = null

/obj/machinery/gateway
	name = "gateway"
	desc = "A mysterious gateway built by unknown hands, it allows for faster than light travel to far-flung locations."
	icon = 'icons/obj/machines/gateway2.dmi'
	icon_state = "off"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/calibrated = TRUE
	var/destination_type = /datum/gateway_destination/gateway // Type of instanced gateway destination, needs to be subtype of /datum/gateway_destination/gateway
	var/datum/gateway_destination/gateway/destination // This is our own destination, pointing at this gateway
	var/datum/gateway_destination/target // This is current active destination
	var/obj/effect/gateway_portal_bumper/portal // bumper object, the thing that starts actual teleport

	pixel_x = -32
	pixel_y = -32
	bound_height = 64
	bound_width = 96
	bound_x = -32
	bound_y = 0
	density = TRUE

/obj/machinery/gateway/Initialize()
	generate_destination()
	update_icon()
	return ..()

/obj/machinery/gateway/proc/generate_destination()
	destination = new destination_type
	destination.name = name
	destination.G = src
	GLOB.gateway_destinations += destination

/obj/machinery/gateway/proc/deactivate()
	var/datum/gateway_destination/dest = target
	target = null
	dest.deactivate(src)
	QDEL_NULL(portal)
	update_icon()

/obj/machinery/gateway/process()
	if((machine_stat & (NOPOWER)) && use_power)
		if(target)
			deactivate()
		return

	if(target)
		use_power(5000)

/obj/machinery/gateway/update_icon_state()
	if(target)
		icon_state = "on"
	else
		icon_state = "off"

/obj/machinery/gateway/safe_throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback, force = MOVE_FORCE_STRONG, gentle = FALSE)
	return

/obj/machinery/gateway/proc/generate_bumper()
	portal = new(get_turf(src))
	portal.gateway = src

/obj/machinery/gateway/proc/activate(datum/gateway_destination/D)
	if(!powered() || target)
		return
	target = D
	target.activate(destination)
	generate_bumper()
	update_icon()

/obj/machinery/gateway/proc/Transfer(atom/movable/AM)
	if(!target || !target.incoming_pass_check(AM))
		return
	AM.forceMove(target.get_target_turf())
	target.post_transfer(AM)

/obj/machinery/gateway/centerstation
	destination_type = /datum/gateway_destination/gateway/home

/obj/machinery/gateway/centerstation/Initialize()
	. = ..()
	if(!GLOB.the_gateway)
		GLOB.the_gateway = src

/obj/machinery/gateway/centerstation/Destroy()
	if(GLOB.the_gateway == src)
		GLOB.the_gateway = null
	return ..()

/obj/machinery/gateway/multitool_act(mob/living/user, obj/item/I)
	if(calibrated)
		to_chat(user, "<span class='alert'>The gate is already calibrated, there is no work for you to do here.</span>")
	else
		to_chat(user, "<span class='boldnotice'>Recalibration successful!</span>: \black This gate's systems have been fine tuned. Travel to this gate will now be on target.")
		calibrated = TRUE
	return TRUE

/////////////////////////////////////Away////////////////////////


/obj/machinery/gateway/away
	density = TRUE
	use_power = NO_POWER_USE

//TODO make this work by autolinking to home even without control console
/obj/machinery/gateway/away/admin
	desc = "A mysterious gateway built by unknown hands, this one seems more compact."

/obj/machinery/computer/gateway_control
	name = "Gateway Control"
	var/obj/machinery/gateway/G

/obj/machinery/computer/gateway_control/ui_interact(mob/user, ui_key = "main", datum/tgui/ui, force_open, datum/tgui/master_ui, datum/ui_state/state = GLOB.default_state)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "gateway", name, ui_x, ui_y, master_ui, state)
		ui.open()

/obj/machinery/computer/gateway_control/ui_data(mob/user)
	. = ..()
	.["gateway_present"] = G
	.["gateway_status"] = G ? G.powered() : FALSE
	.["current_target"] = G?.target?.get_ui_data()
	var/list/destinations = list()
	if(G)
		for(var/datum/gateway_destination/D in GLOB.gateway_destinations)
			if(D == G.destination)
				continue
			destinations += list(D.get_ui_data())
	.["destinations"] = destinations

/obj/machinery/computer/gateway_control/ui_act(action, list/params)
	. = ..()
	switch(action)
		if("linkup")
			try_to_linkup()
			return TRUE
		if("activate")
			var/datum/gateway_destination/D = locate(params["destination"]) in GLOB.gateway_destinations
			try_to_connect(D)
			return TRUE
		if("deactivate")
			if(G && G.target)
				G.deactivate()
			return TRUE

/obj/machinery/computer/gateway_control/proc/try_to_linkup()
	G = locate(/obj/machinery/gateway) in view(7)

/obj/machinery/computer/gateway_control/proc/try_to_connect(datum/gateway_destination/D)
	if(!D || !G)
		return
	if(!D.is_availible() || G.target)
		return
	G.activate(D)

/obj/item/paper/fluff/gateway
	info = "Congratulations,<br><br>Your station has been selected to carry out the Gateway Project.<br><br>The equipment will be shipped to you at the start of the next quarter.<br> You are to prepare a secure location to house the equipment as outlined in the attached documents.<br><br>--Nanotrasen Bluespace Research"
	name = "Confidential Correspondence, Pg 1"
