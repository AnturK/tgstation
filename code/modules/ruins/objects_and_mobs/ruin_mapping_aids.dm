//These landmarks can be placed in rooms/ruins to set the baseturfs of every turf in the area. Easier than having potentially unlimited subtypes of every turf or having to manually edit the turfs in the map editor

/obj/effect/baseturf_helper
	name = "lava baseturf editor"
	icon = 'icons/obj/weapons.dmi'
	icon_state = "syndballoon"
	var/baseturf = /turf/open/floor/plating/lava/smooth/lava_land_surface

/obj/effect/baseturf_helper/Initialize()
	..()
	var/area/thearea = get_area(src)
	for(var/turf/T in get_area_turfs(thearea, z))
		if(T.baseturf != T.type) //Don't break indestructible walls and the like
			T.baseturf = baseturf
	qdel(src)


//Will load the template as separate zlevel for multi-level ruins
/obj/structure/ladder/unbreakable/z_load
	var/template_path //Template this will lead to as separate z
	var/target_ladder_id //Template
	var/static/loaded = FALSE //can have multiple entrances but only one template should load

/obj/structure/ladder/unbreakable/z_load/Initialize(mapload)
	. = ..()
	if(!loaded)
		var/datum/map_template/M = locate(template_path) in SSmapping.map_templates
		if(!M)
			CRASH("Template [template_path] not found for loading ladder")
		M.load_new_z_level()
		loaded = TRUE
	LinkLadder()

/obj/structure/ladder/unbreakable/z_load/rad_bunker_f1
	template_path = /datum/map_template/ruin/lavaland/rad_bunker_floor1

/obj/structure/ladder/unbreakable/z_load/rad_bunker_f2
	template_path = /datum/map_template/ruin/lavaland/rad_bunker_floor2
