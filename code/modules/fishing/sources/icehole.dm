/datum/fish_source/icehole
	catalog_description = "iceholes"
	fish_table = list(
		FISHING_DUD = 30,
		/obj/item/fish/icefish1 = 20,
		/obj/item/fish/icefish2 = 20,
		/obj/item/fish/icefish3 = 20,
		/obj/item/fish/icefish4 = 10,
		/obj/item/fish/icefish5 = 10,
		/obj/item/fish/icefish6 = 5
	)

	// Should each icehole be limited so you're forced to make more ?

/obj/effect/icehole
	name = "icehole"
	icon = 'icons/obj/fishing.dmi'
	icon_state = "icehole"

/obj/effect/icehole/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/fishing_spot, /datum/fish_source/icehole)
	RegisterSignal(get_turf(src), COMSIG_TURF_CHANGE, .proc/on_turf_change)

/obj/effect/icehole/proc/on_turf_change()
	SIGNAL_HANDLER
	qdel(src)
