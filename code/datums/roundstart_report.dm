/datum/roundstart_report
	var/alert_level = SEC_LEVEL_BLUE
	var/sections = list()


/proc/build_roundend_report


/datum/centcomm_hint
	var/section_name

/datum/centcomm_hint/proc/build_hint()
	return "The station is doomed"

/datum/centcomm_hint/proc/setup()
	//If hint needs to modify external things
	return

/datum/centcomm_hint/lavaland
	section_name = "Nanotrasen Planetery Survey"


/datum/centcomm_hint/lavaland/ruins/build_hint()
	var/list/parts = list()
	parts += "Orbital scans results:"
	parts += "<ul>"
	for(var/i in GLOB.ruin_landmarks)
		var/obj/effect/landmark/ruin/ruin_landmark = i
		var/datum/map_template/ruin/template = ruin_landmark.ruin_template
		if(ruin_landmark.z != Z_LEVEL_LAVALAND || !template.report_hint)
			continue
		parts += "<li>[template.report_hint]</li>"
	parts += "</ul>

/datum/centcomm_hint/lavaland/boss
/datum/centcomm_hint/lavaland/treasure

/datum/centcomm_hint/cargo/stock
/datum/centcomm_hint/cargo/request
/datum/centcomm_hint/cargo/modified_locks
/datum/centcomm_hint/cargo/material_market

/datum/centcomm_hint/engineering/access_issues
/datum/centcomm_hint/engineering/structural_weakness
/datum/centcomm_hint/engineering/broken_cameras

/datum/centcomm_hint/research/breakthrough
/datum/centcomm_hint/research/grants
/datum/centcomm_hint/research/oppurtunity

/datum/centcomm_hint/security/events
/datum/centcomm_hint/security/syndicate
/datum/centcomm_hint/security/first_contact