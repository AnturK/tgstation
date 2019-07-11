//Generic ones - add table of type -> card so you can eg use laser guns for slightly stronger attack cards.
/obj/item/probe_part
	name = "Recon Drone Part"
	desc = "Part of modular recon drone."
	//DEBUG
	icon = 'icons/mob/drone.dmi'
	icon_state = "drone_maint_hat"
	//DEBUG
	var/tcg_type

/obj/item/recon_drone
	name = "Recon Drone"
	desc = "Goes where no spaceman gone before. And then dies there."
	//DEBUG
	icon = 'icons/mob/drone.dmi'
	icon_state = "drone_maint_hat"
	//DEBUG
	var/list/deck = list()

/obj/machinery/recon_designer
	name = "Recon Drone Designer"
	icon_state = "jukebox"
	var/list/availible = list()
	var/list/prototype_deck = list()
	var/max_size = 50
	var/min_size = 10
	var/max_copies_per_deck = 5
	var/dispense_cooldown = 5 MINUTES
	var/last_dispensed = 0
	var/obj/item/recon_drone/inserted_drone

/obj/machinery/recon_designer/Initialize()
	. = ..()
	//Debug, mark some as initial or just let them be printed
	availible[/datum/tcg/basic_attack] = 4
	availible[/datum/tcg/basic_defend] = 4

/obj/machinery/recon_designer/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(istype(I,/obj/item/recon_drone))
		if(inserted_drone)
			to_chat(user,"<span class='warning'>There's already a drone inside.</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return
		insert_drone(I)

/obj/machinery/recon_designer/interact(mob/user, special_state)
	. = ..()

	var/list/dat = list()
	var/list/target_deck = prototype_deck
	if(inserted_drone)
		target_deck = inserted_drone.deck
		dat += "Modyfing [inserted_drone] configuration:<br>"

	dat += "Availible:<br><ul>"
	for(var/tcg_type in availible)
		var/datum/tcg/card = tcg_type
		var/name = initial(card.name)
		dat += "<li><a href='byond://?src=[REF(src)];add=[tcg_type]'>[name] x [availible[tcg_type]]</a></li>"
	dat += "</ul><br>Current:<br><ul>"
	var/count = 0
	for(var/tcg_type in target_deck)
		var/datum/tcg/card = tcg_type
		var/name = initial(card.name)
		count += target_deck[tcg_type]
		dat += "<li><a href='byond://?src=[REF(src)];remove=[tcg_type]'>[name] x [target_deck[tcg_type]]</a></li>"
	dat += "</ul><br>Capacity used : [count]/[max_size]"

	if(!inserted_drone)
		if(last_dispensed + dispense_cooldown < world.time)
			dat += "<a href='byond://?src=[REF(src)];dispense=1'>Print new drone</a>"
		else
			dat += "<span>Drone printer recharging.</span>"
	else
		dat += "<a href='byond://?src=[REF(src)];eject=1'>Eject Drone</a>"

	var/datum/browser/popup = new(user, "partpicker", "Recon Drone Part Picker")
	popup.set_content(dat.Join())
	popup.open()

/obj/machinery/recon_designer/proc/dispense_drone()
	if(last_dispensed + dispense_cooldown > world.time)
		return
	var/obj/item/recon_drone/D = new(drop_location())
	D.deck = prototype_deck
	prototype_deck = list()

/obj/machinery/recon_designer/proc/insert_drone(obj/item/recon_drone/D)
	for(var/x in prototype_deck)
		availible[x] += prototype_deck[x]
	prototype_deck.Cut()
	inserted_drone = D

/obj/machinery/recon_designer/Topic(href, href_list)
	. = ..()
	if(.)
		return

	var/list/target_deck = prototype_deck
	if(inserted_drone)
		target_deck = inserted_drone.deck
	
	if(href_list["add"])
		var/tcg_path = text2path(href_list["add"])
		if(!tcg_path || availible[tcg_path] < 1 || target_deck[tcg_path] >= max_copies_per_deck)
			return
		availible[tcg_path]--
		if(availible[tcg_path] <= 0)
			availible -= tcg_path
		target_deck[tcg_path] += 1
	else if(href_list["remove"])
		var/tcg_path = text2path(href_list["remove"])
		if(!tcg_path || !target_deck[tcg_path])
			return
		target_deck[tcg_path]--
		if(target_deck[tcg_path] <= 0)
			target_deck -= tcg_path
		availible[tcg_path] += 1
	else if(href_list["dispense"])
		dispense_drone()
	else if (href_list["eject"])
		if(inserted_drone)
			inserted_drone.forceMove(drop_location())
			inserted_drone = null
	updateUsrDialog()