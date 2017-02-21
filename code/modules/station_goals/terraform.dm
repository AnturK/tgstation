//aka Lag Machine
/obj/machinery/atmospherics/components/unary/terraformer
	name = "terraformer"
	desc = "Transforms planetery atmosphere."
	icon_state = "cold_map"
	var/icon_state_on = "cold_on"
	var/icon_state_open = "cold_off"
	density = TRUE
	anchored = TRUE
	obj_integrity = 300
	max_integrity = 300
	armor = list(melee = 0, bullet = 0, laser = 0, energy = 100, bomb = 0, bio = 100, rad = 100, fire = 80, acid = 30)

	var/on = FALSE
	var/interactive = TRUE // So mapmakers can disable interaction.

/obj/machinery/atmospherics/components/unary/terraformer/New()
	..()
	initialize_directions = dir
	var/obj/item/weapon/circuitboard/machine/B = new /obj/item/weapon/circuitboard/machine/terraformer(null)
	B.apply_default_parts(src)

/obj/item/weapon/circuitboard/machine/terraformer
	name = "Terraformer (Machine Board)"
    build_path = /obj/machinery/atmospherics/components/unary/terraformer
	origin_tech = "programming=3;plasmatech=3"
	req_components = list(
							/obj/item/weapon/stock_parts/matter_bin = 2,
							/obj/item/weapon/stock_parts/micro_laser = 2,
							/obj/item/stack/cable_coil = 1,
							/obj/item/weapon/stock_parts/console_screen = 1)

/obj/machinery/atmospherics/components/unary/terraformer/on_construction()
	..(dir,dir)

/obj/machinery/atmospherics/components/unary/terraformer/update_icon()
	if(panel_open)
		icon_state = icon_state_open
	else if(on && is_operational())
		icon_state = icon_state_on
	else
		icon_state = initial(icon_state)
	return

/obj/machinery/atmospherics/components/unary/terraformer/update_icon_nopipes()
	cut_overlays()
	if(showpipe)
		add_overlay(getpipeimage(icon, "scrub_cap", initialize_directions))

/* 
/obj/machinery/atmospherics/components/unary/terraformer/process_atmos()
	..()
    return
*/

/obj/machinery/atmospherics/components/unary/terraformer/power_change()
	..()
	update_icon()

/obj/machinery/atmospherics/components/unary/terraformer/attackby(obj/item/I, mob/user, params)
	if(!(on || state_open))
		if(default_deconstruction_screwdriver(user, icon_state_open, initial(icon_state), I))
			return
		if(exchange_parts(user, I))
			return
	if(default_change_direction_wrench(user, I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/atmospherics/components/unary/terraformer/default_change_direction_wrench(mob/user, obj/item/weapon/wrench/W)
	if(!..())
		return 0
	SetInitDirections()
	var/obj/machinery/atmospherics/node = NODE1
	if(node)
		node.disconnect(src)
		NODE1 = null
	nullifyPipenet(PARENT1)

	atmosinit()
	node = NODE1
	if(node)
		node.atmosinit()
		node.addMember(src)
	build_network()
	return 1

/obj/machinery/atmospherics/components/unary/terraformer/ui_status(mob/user)
	if(interactive)
		return ..()
	return UI_CLOSE

/obj/machinery/atmospherics/components/unary/terraformer/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = 0, \
																	datum/tgui/master_ui = null, datum/ui_state/state = default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "terraformer", name, 400, 240, master_ui, state)
		ui.open()

/obj/machinery/atmospherics/components/unary/terraformer/ui_data(mob/user)
	var/list/data = list()
	data["on"] = on

	var/datum/gas_mixture/air1 = AIR1
    data["mix"] = air1.
	data["temperature"] = air1.temperature
	data["pressure"] = air1.return_pressure()
	return data

/obj/machinery/atmospherics/components/unary/terraformer/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("power")
			on = !on
			use_power = 1 + on
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", "atmos")
			. = TRUE
	update_icon()


/obj/machinery/atmospherics/components/unary/terraformer/proc/terraform()
    if(src.z != ZLEVEL_LAVALAND)
        return
    var/datum/gas_mixture/current = AIR1
    var/target_mix = current.to_gasstring(temp=False)
    //change initial_air_mix
    for(var/turf/T in block(locate(1,1,ZLEVEL_LAVALAND),locate(maxx,maxy,ZLEVEL_LAVALAND)))
        if(T.planetery_atmos)
            T.initial_gas_mix = target_mix
            if(isopenturf(T))
                SSair.add_to_active(T)
    //remove ash storms
    SSweather.disable_weather(/datum/weather/ash_storm)

/obj/machinery/atmospherics/components/unary/terraformer/proc/stop()
    for(var/turf/T in block(locate(1,1,ZLEVEL_LAVALAND),locate(maxx,maxy,ZLEVEL_LAVALAND)))
        if(T.planetery_atmos)
            T.initial_gas_mix = initial(T.initial_gas_mix)
            if(isopenturf(T))
                SSair.add_to_active(T)
    //readd ash storms
    SSweather.enable_weather(/datum/weather/ash_storm)