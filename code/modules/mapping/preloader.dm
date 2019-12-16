// global datum that will preload variables on atoms instanciation
GLOBAL_VAR_INIT(use_preloader, FALSE)
GLOBAL_DATUM_INIT(_preloader, /datum/map_preloader, new)

/// Preloader datum
/datum/map_preloader
	parent_type = /datum
	var/list/attributes
	var/target_path

/world/proc/preloader_setup(list/the_attributes, path)
	if(the_attributes.len)
		GLOB.use_preloader = TRUE
		var/datum/map_preloader/preloader_local = GLOB._preloader
		preloader_local.attributes = the_attributes
		preloader_local.target_path = path

/world/proc/preloader_load(atom/what)
	GLOB.use_preloader = FALSE
	var/datum/map_preloader/preloader_local = GLOB._preloader
	for(var/attribute in preloader_local.attributes)
		var/value = preloader_local.attributes[attribute]
		if(islist(value))
			value = deepCopyList(value)
		#ifdef TESTING
		if(what.vars[attribute] == value)
			var/message = "<font color=green>[what.type]</font> at [AREACOORD(what)] - <b>VAR:</b> <font color=red>[attribute] = [isnull(value) ? "null" : (isnum(value) ? value : "\"[value]\"")]</font>"
			log_mapping("DIRTY VAR: [message]")
			GLOB.dirty_vars += message
		#endif
		what.vars[attribute] = value

/area/template_noop
	name = "Area Passthrough"

/turf/template_noop
	name = "Turf Passthrough"
	icon_state = "noop"
	bullet_bounce_sound = null


GLOBAL_LIST(admin_abuse)

/world/proc/apply_admin_abuse(atom/what)
	for(var/preloader_data in GLOB.admin_abuse[what.type])
		for(var/attribute in preloader_data.attributes)
			var/value = preloader_data.attributes[attribute]
			if(islist(value))
				value = deepCopyList(value)
			what.vars[attribute] = value

/datum/admin_abuse_preloader
	var/name = "Admin Preloader"
	var/list/attributes = list()