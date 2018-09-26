
/obj/structure/closet/secure_closet/exile
	name = "exile implants"
	req_access = list(ACCESS_HOS)

/obj/structure/closet/secure_closet/exile/New()
	..()
	new /obj/item/implanter/exile(src)
	new /obj/item/implantcase/exile(src)
	new /obj/item/implantcase/exile(src)
	new /obj/item/implantcase/exile(src)
	new /obj/item/implantcase/exile(src)
	new /obj/item/implantcase/exile(src)



/datum/probe_equipment
	var/name = "generic equipement"
	var/desc = "generic description"
	var/tags
	var/weight = 1
	var/required_node

/obj/machinery/probe_generator
	name = "Exploration Probe Fabricator"
	var/preset_name = "Zero"
	var/list/presets = list() // name -> eq list
	var/list/current_eq = list()
	var/list/unlocked_equipment = list()
	var/datum/techweb/techweb

/obj/machinery/probe_generator/Initialize()
	. = ..()
	techweb = SSresearch.science_tech //construction cleaning this stuff

/obj/machinery/probe_generator/proc/sync_research()
	if(!techweb)
		return
	for(var/T in subtypesof(/datum/probe_equipment))
		var/datum/probe_equipment/P = T
		var/ntype = initial(P.required_node)
		if(!ntype || (locate(ntype) in techweb.researched_nodes))
			unlocked_equipment |= P

/obj/machinery/probe_generator/proc/ui_act(action,params)
	switch(action)
		if("produce")
			dispense()
		if("set_preset")
			load_preset(params["preset_key"])
		if("save_preset")
			save_preset()
		if("delete_preset")
			delete_preset(params["preset_key"])
		if("sync")
			sync_research()
		if("add")
			var/eqp = get_eq(params["eq_key"])
			if(eqp in unlocked_equipment)
				current_eq |= eqp
		if("remove")
			var/eqp = get_eq(params["eq_key"])
			if(eqp)
				current_eq -= eqp

/obj/machinery/probe_generator/proc/save_preset(key)
	presets[key] = current_eq.Copy()
	preset_name = key

/obj/machinery/probe_generator/proc/delete_preset(key)
	presets -= key

/obj/machinery/probe_generator/proc/get_eq(key)
	var/p = text2path(key)
	if(p && ispath(p,/datum/probe_equipment))
		return p

/obj/machinery/probe_generator/proc/load_preset(key)
	if(!presets[key])
		return
	current_eq.Cut()
	for(var/T in presets[key])
		if(T in unlocked_equipment)
			current_eq |= T
	preset_name = key

/obj/machinery/probe_generator/proc/dispense()
	var/obj/item/probe/P = new(drop_location())
	if(preset_name)
		P.series = preset_name
	for(var/T in current_eq)
		if(ispath(T,/datum/probe_equipment))
			var/datum/probe_equipment/P = new T
			P.equipement |= P

/obj/item/probe
	var/series
	var/list/equipment

/obj/item/probe/examine(mob/user)
	..()
	to_chat(user,"<span class='notice'>Series [series]</span>"
	for(var/datum/probe_equipment/P in equipment)
		to_chat(user,"<span class='notice'>It's equipped with [P.name]</span>"

/obj/item/probe/all_tags()
	. = list()
	for(var/datum/probe_equipment/P in equipment)
		. |= P.tags
	. |= freeform_tags

