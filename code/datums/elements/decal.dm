/datum/element/decal
	element_flags = ELEMENT_BESPOKE|ELEMENT_DETACH
	id_arg_index = 2
	var/cleanable
	var/description
	/// If true this was initialized with no set direction - will follow the parent dir.
	var/directional
	var/mutable_appearance/pic


/// Remove old decals and apply new decals after rotation as necessary
/datum/controller/subsystem/processing/dcs/proc/rotate_decals(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER

	if(old_dir == new_dir)
		return
	var/list/resulting_decals_params = list() // param lists
	var/list/old_decals = list() //instances

	if(!source.comp_lookup || !source.comp_lookup[COMSIG_ATOM_UPDATE_OVERLAYS])
		//should probably also unregister itself
		return

	switch(length(source.comp_lookup[COMSIG_ATOM_UPDATE_OVERLAYS]))
		if(0)
			var/datum/element/decal/D = source.comp_lookup[COMSIG_ATOM_UPDATE_OVERLAYS]
			if(!istype(D))
				return
			old_decals += D
			resulting_decals_params += list(D.get_rotated_parameters(old_dir,new_dir))
		else
			for(var/datum/element/decal/D in source.comp_lookup[COMSIG_ATOM_UPDATE_OVERLAYS])
				old_decals += D
				resulting_decals_params += list(D.get_rotated_parameters(old_dir,new_dir))
	//Instead we could generate ids and only remove duplicates to save on churn on four-corners symmetry ?
	for(var/datum/element/decal/D in old_decals)
		D.Detach(source)

	for(var/result in resulting_decals_params)
		source._AddElement(result)


/datum/element/decal/proc/get_rotated_parameters(old_dir,new_dir)
	var/rotation = 0
	if(directional) //Even when the dirs are the same rotation is coming out as not 0 for some reason
		rotation = SIMPLIFY_DEGREES(dir2angle(new_dir)-dir2angle(old_dir))
		new_dir = turn(pic.dir,-rotation)
	return list(/datum/element/decal, pic.icon, pic.icon_state, new_dir, cleanable, pic.color, pic.layer, description, pic.alpha)

/datum/element/decal/Attach(atom/target, _icon, _icon_state, _dir, _cleanable=FALSE, _color, _layer=TURF_LAYER, _description, _alpha=255)
	. = ..()
	if(!isatom(target) || !generate_appearance(_icon, _icon_state, _dir, _layer, _color, _alpha, target))
		return ELEMENT_INCOMPATIBLE
	description = _description
	cleanable = _cleanable
	directional = _dir

	RegisterSignal(target,COMSIG_ATOM_UPDATE_OVERLAYS,.proc/apply_overlay, TRUE)
	if(target.flags_1 & INITIALIZED_1)
		target.update_icon() //could use some queuing here now maybe.
	else
		RegisterSignal(target,COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE,.proc/late_update_icon, TRUE)
	if(isitem(target))
		INVOKE_ASYNC(target, /obj/item/.proc/update_slot_icon, TRUE)
	if(_dir)
		SSdcs.RegisterSignal(target,COMSIG_ATOM_DIR_CHANGE, /datum/controller/subsystem/processing/dcs/proc/rotate_decals, TRUE)
		//RegisterSignal(target, COMSIG_ATOM_DIR_CHANGE, .proc/rotate_react,TRUE)
	if(_cleanable)
		RegisterSignal(target, COMSIG_COMPONENT_CLEAN_ACT, .proc/clean_react,TRUE)
	if(_description)
		RegisterSignal(target, COMSIG_PARENT_EXAMINE, .proc/examine,TRUE)

	RegisterSignal(target, COMSIG_TURF_ON_SHUTTLE_MOVE, .proc/shuttle_move_react,TRUE)

/datum/element/decal/proc/generate_appearance(_icon, _icon_state, _dir, _layer, _color, _alpha, source)
	if(!_icon || !_icon_state)
		return FALSE
	var/temp_image = image(_icon, null, _icon_state, _layer, _dir)
	pic = new(temp_image)
	pic.color = _color
	pic.alpha = _alpha
	return TRUE

/datum/element/decal/Detach(atom/source, force)
	UnregisterSignal(source, list(COMSIG_ATOM_DIR_CHANGE, COMSIG_COMPONENT_CLEAN_ACT, COMSIG_PARENT_EXAMINE, COMSIG_ATOM_UPDATE_OVERLAYS, COMSIG_TURF_ON_SHUTTLE_MOVE))
	source.update_icon()
	if(isitem(source))
		INVOKE_ASYNC(source, /obj/item/.proc/update_slot_icon)
	return ..()

/datum/element/decal/proc/late_update_icon(atom/source)
	SIGNAL_HANDLER

	if(source && istype(source))
		source.update_icon()
		UnregisterSignal(source,COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE)


/datum/element/decal/proc/apply_overlay(atom/source, list/overlay_list)
	SIGNAL_HANDLER

	overlay_list += pic


/datum/element/decal/proc/rotate_react(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER

	if(source.component_debug)
		to_chat_immediate(world,"<span class='notice'>Rotate react with old_dir:[old_dir] and new_dir:[new_dir] and pic.dir [pic.dir]</span>")

	if(old_dir == new_dir)
		return

	var/rotation = 0
	var/counter_dir = null //the same rotation applied to this direction would result in this decal
	if(directional) //Even when the dirs are the same rotation is coming out as not 0 for some reason
		rotation = dir2angle(new_dir)-dir2angle(old_dir)
		rotation = SIMPLIFY_DEGREES(rotation)
		new_dir = angle2dir(rotation+dir2angle(pic.dir))
		counter_dir = angle2dir(SIMPLIFY_DEGREES(dir2angle(pic.dir) - rotation))
		if(source.component_debug)
			to_chat_immediate(world,"<span class='notice'>Rotate react new_dir recalc:[new_dir] and counter_dir:[counter_dir]</span>")

	// So we do not remove our previous rotation in same rotation batch.
	if(counter_dir)
		var/counter_element = SSdcs.GetElement(list(/datum/element/decal, pic.icon, pic.icon_state, counter_dir, cleanable, pic.color, pic.layer, description, pic.alpha))
		if(!source.comp_lookup || !source.comp_lookup[COMSIG_ATOM_DIR_CHANGE] || !(counter_element in source.comp_lookup[COMSIG_ATOM_DIR_CHANGE])) //Not checking single entry since then it doesn't actually matter if we detach
			Detach(source)
			if(source.component_debug)
				to_chat_immediate(world,"<span class='notice'>counter element not found. counter_dir: [counter_dir]</span>")
		else
			if(source.component_debug)
				to_chat_immediate(world,"<span class='notice'>Found counter element. counter_dir: [counter_dir]</span>")
	else
		Detach(source)
	source.AddElement(/datum/element/decal, pic.icon, pic.icon_state, new_dir, cleanable, pic.color, pic.layer, description, pic.alpha)

/datum/element/decal/proc/post_rotate_unify()
	//replace rot_temp elements with base ones

/datum/element/decal/proc/clean_react(datum/source, clean_types)
	SIGNAL_HANDLER

	if(clean_types & cleanable)
		Detach(source)
		return COMPONENT_CLEANED
	return NONE

/datum/element/decal/proc/examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += description

/datum/element/decal/proc/shuttle_move_react(datum/source, turf/newT)
	SIGNAL_HANDLER

	if(newT == source)
		return
	Detach(source)
	newT.AddElement(/datum/element/decal, pic.icon, pic.icon_state, directional , cleanable, pic.color, pic.layer, description, pic.alpha)
