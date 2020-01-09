GLOBAL_DATUM_INIT(station_only_machine, /datum/ui_state/station_only_machine, new)

/datum/ui_state/station_only_machine/can_use_topic(src_object, mob/user)
	. = user.default_can_use_topic(src_object)
	
	var/turf/T = get_turf(src_object)
	if(!T || !is_station_level(T.z)
		return min(.,UI_UPDATE)