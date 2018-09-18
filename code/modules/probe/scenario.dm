/datum/scenario
	var/list/steps = list()
	var/active_step

/datum/scenario/proc/deserialize_json(list/input, list/options)
	. = ..()

/datum/scenario_step

//PRESET COMMANDS for on_enter

/datum/scenario/node_commands(command,value,probe)
	switch(command)
		if("DAMAGE")
			if(isnum(value))
				probe.take_damage(value)
		if("TAG")
			if(istext(value))
				probe.tags += value