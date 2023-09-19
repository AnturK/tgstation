// Allows non-carbons to arm wrestle
/datum/component/custom_arm_wrestler
	var/arm_strength = 100
	var/arm_stamina = 100
	var/arm_properties = NONE

/datum/component/custom_arm_wrestler/Initialize(arm_strength = 100, arm_stamina = 100, arm_properties = NONE)
	. = ..()
	if(!istype(parent,/mob))
		return COMPONENT_INCOMPATIBLE

	src.arm_strength = arm_strength
	src.arm_stamina = arm_stamina
	src.arm_properties = arm_properties

	RegisterSignal(parent, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(handle_accepting_challenges))

/datum/component/custom_arm_wrestler/proc/handle_accepting_challenges(datum/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(istype(target, /obj/effect/arm_wrestling_visual))
		var/obj/effect/arm_wrestling_visual/visual = target
		visual.accept_attempt(source)
		return COMPONENT_CANCEL_ATTACK_CHAIN

#define ARM_WRESTLING_SELECT_TABLE 1
#define ARM_WRESTLING_WAITING_FOR_OPPONENT 2
#define ARM_WRESTLING_COUNTDOWN 3
#define ARM_WRESTLING_WRESTLING 4

#define ARM_WRESTLING_VICTORY_STANDARD "standard"
#define ARM_WRESTLING_VICTORY_STAMINA "stamina"
#define ARM_WRESTLING_VICTORY_SURRENDER "surrender"

#define ARMWRESTLING_PROPERTY_UNTIRING 1
#define ARMWRESTLING_PROPERTY_UNTRAINABLE 2

#define DEFAULT_ARM_STRENGTH 100
#define DEFAULT_ARM_STAMINA 15

// Time of training in deciseconds to gain 1 strength point
#define TRAINING_COEFF 50

/// Simple holder for arm-wrestling properties and training status
/datum/arm_wrestling_properties
	var/strength = DEFAULT_ARM_STRENGTH
	var/stamina = DEFAULT_ARM_STAMINA
	var/arm_properties = NONE
	/// Training progress in deciseconds
	var/training_progress = 0

/// Initialize the properties from bodypart
/datum/arm_wrestling_properties/proc/setup(obj/item/bodypart/arm/arm)
	strength = DEFAULT_ARM_STRENGTH
	stamina = DEFAULT_ARM_STAMINA
	// Robo arms don't tire but also can't be trained
	if(arm.biological_state & BIO_ROBOTIC)
		arm_properties &= ARMWRESTLING_PROPERTY_UNTIRING|ARMWRESTLING_PROPERTY_UNTRAINABLE

/datum/arm_wrestling_properties/proc/handle_training(duration)
	training_progress += duration
	// Could maybe make this scale difficulty with value
	if(training_progress > TRAINING_COEFF)
		strength += round(training_progress / TRAINING_COEFF)
		training_progress %= TRAINING_COEFF


/datum/arm_wrestling_challenge
	/// What stage of arm-wrestling we're at
	var/state = ARM_WRESTLING_SELECT_TABLE

	/// The thing we're arm-wrestling on, usually a table
	var/atom/movable/flat_surface

	/// Effect that displays challenge visuals and needs to be interacted by the opponent
	var/obj/effect/arm_wrestling_visual/visual

	/// Action to choose table to wrestle on, deleted after use
	var/datum/action/cooldown/arm_wrestling/designate_table/designate_table_action

	/// This is whoever initialized the challenge
	var/mob/starter
	/// Which arm starter uses
	var/starter_arm_index

	/// This is whoever picked the challenge
	var/mob/opponent
	/// Which arm opponent uses
	var/opponent_arm_index

	var/datum/action/cooldown/arm_wrestling/surrender/starter_surrender_action
	var/datum/action/cooldown/arm_wrestling/surrender/opponent_surrender_action

	// Current score balance. Negative value is starter advantage, positive value is opponent
	var/score = 0
	/// Number of consecutive strength checks needed to win
	var/score_limit = 5

	/// Starter's current stamina
	var/starter_stamina
	/// Opponent's current stamina
	var/opponent_stamina

	/// List of hand filler items
	var/list/hand_items = list()

/datum/arm_wrestling_challenge/Destroy(force, ...)
	. = ..()
	if(designate_table_action)
		QDEL_NULL(designate_table_action)
	if(starter_surrender_action)
		QDEL_NULL(starter_surrender_action)
	if(opponent_surrender_action)
		QDEL_NULL(opponent_surrender_action)
	if(state != ARM_WRESTLING_SELECT_TABLE)
		remove_participant(starter)
	if(opponent)
		remove_participant(opponent)
	if(visual)
		QDEL_NULL(visual)
	QDEL_LIST(hand_items)

/datum/arm_wrestling_challenge/proc/start(mob/starter)
	src.starter = starter
	designate_table_action = new(src)
	designate_table_action.Grant(starter)
	starter_surrender_action = new(src)
	starter_surrender_action.Grant(starter)

/datum/arm_wrestling_challenge/proc/start_waiting_for_opponent(atom/movable/surface)
	add_participant(starter)
	starter_arm_index = starter.active_hand_index
	starter_stamina = calculate_arm_stamina(starter,starter_arm_index)

	flat_surface = surface
	visual = new(get_turf(flat_surface), src)
	state = ARM_WRESTLING_WAITING_FOR_OPPONENT

/datum/arm_wrestling_challenge/proc/surrender(mob/surrendering_mob)
	//We're before the actual challenge, just clean up
	if(state != ARM_WRESTLING_WRESTLING)
		qdel(src)
		return
	if(starter == surrendering_mob)
		win(opponent, ARM_WRESTLING_VICTORY_SURRENDER)
	else
		win(starter, ARM_WRESTLING_VICTORY_SURRENDER)

/datum/arm_wrestling_challenge/proc/win(mob/winner, victory_type = ARM_WRESTLING_VICTORY_STANDARD)
	var/mob/loser = winner == starter ? opponent : starter
	if(victory_type == ARM_WRESTLING_VICTORY_STANDARD)
		var/starter_arm_strength = calculate_arm_strength(starter,starter_arm_index)
		var/opponent_arm_strength = calculate_arm_strength(opponent,opponent_arm_index)
		// Handle damage from big strength difference instant wins - i just want gorillas to break arms
		// 100p advantage - instant win
		// 200p advantage - instant win and opponent arm damaged
		// 300p advantage - instant win and opponent arm broken
		var/point_advantage = winner == starter ? (starter_arm_strength - opponent_arm_strength) : (opponent_arm_strength - starter_arm_strength)
		if(point_advantage > 300)
			//300p advantage - opponent arm broken
			var/obj/item/bodypart/arm/losers_arm = loser.get_active_hand()
			if(losers_arm)
				losers_arm.force_wound_upwards(/datum/wound/blunt/bone/moderate, wound_source = "arm wrestling")
		else if(point_advantage > 200)
			//200p advantage - opponent arm damaged
			var/obj/item/bodypart/arm/losers_arm = loser.get_active_hand()
			if(losers_arm)
				losers_arm.take_damage(20)
	if(victory_type != ARM_WRESTLING_VICTORY_SURRENDER)
		playsound(get_turf(flat_surface), 'sound/effects/tableslam.ogg', 100, TRUE)
		flat_surface.balloon_alert_to_viewers("[winner] wins") //balloon on flat surface because visual will get deleted in a moment
	else
		flat_surface.balloon_alert_to_viewers("[loser] surrenders")
	SEND_SIGNAL(winner, COMSIG_ARMWRESTLING_WON, winner, loser, victory_type)
	SEND_SIGNAL(loser, COMSIG_ARMWRESTLING_LOST, winner, loser, victory_type)
	qdel(src)

/datum/arm_wrestling_challenge/process(seconds_per_tick)
	var/starter_arm_strength = calculate_arm_strength(starter,starter_arm_index)
	var/opponent_arm_strength = calculate_arm_strength(opponent,opponent_arm_index)
	var/starter_arm_properties = calculate_arm_properties(starter, starter_arm_index)
	var/opponent_arm_properties = calculate_arm_properties(opponent, opponent_arm_index)
	//Handle instant wins
	var/starter_advantage = starter_arm_strength - opponent_arm_strength
	if(starter_advantage > 100)
		win(starter, ARM_WRESTLING_VICTORY_STANDARD)
		return PROCESS_KILL
	if(starter_advantage < -100)
		win(opponent, ARM_WRESTLING_VICTORY_STANDARD)
		return PROCESS_KILL

	var/starter_effective_strength = starter_arm_strength + rand(0,50)
	var/opponent_effective_strength = opponent_arm_strength + rand(0,50)

	if(starter_effective_strength > opponent_effective_strength)
		//point for the starter
		score -= 1
		visual.opponent_hand.animate_damage()
	else if(starter_effective_strength < opponent_effective_strength)
		//point for the opponent
		score += 1
		visual.starter_hand.animate_damage()
	else
		//just skip turn
		visual.starter_hand.animate_damage()
		visual.opponent_hand.animate_damage()

	/// Standard Victory
	if(score < -score_limit)
		win(starter, ARM_WRESTLING_VICTORY_STANDARD)
		return PROCESS_KILL
	else if(score > score_limit)
		win(opponent, ARM_WRESTLING_VICTORY_STANDARD)
		return PROCESS_KILL

	/// Decrease stamina on both arms - roboarms have advantage here
	if(!(starter_arm_properties & ARMWRESTLING_PROPERTY_UNTIRING))
		starter_stamina -= 1
	if(!(opponent_arm_properties & ARMWRESTLING_PROPERTY_UNTIRING))
		opponent_stamina -=1

	/// Stamina Victory
	if(opponent_stamina <= 0 && starter_stamina <= 0)
		//Tie, just flip a coin
		if(prob(50))
			win(starter, ARM_WRESTLING_VICTORY_STAMINA)
		else
			win(opponent, ARM_WRESTLING_VICTORY_STAMINA)
		return PROCESS_KILL
	if(opponent_stamina <= 0)
		win(starter, ARM_WRESTLING_VICTORY_STAMINA)
		return PROCESS_KILL
	if(starter_stamina <= 0)
		win(opponent, ARM_WRESTLING_VICTORY_STAMINA)
		return PROCESS_KILL

/datum/arm_wrestling_challenge/proc/calculate_arm_strength(mob/owner,arm_index)
	//DEBUG
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		var/obj/item/bodypart/arm/used_arm = carbon_owner.hand_bodyparts[arm_index]
		var/effective_strength = used_arm.arm_wrestling_properties.strength
		// Damaged arms are weaker, could make this more precise
		if(length(used_arm.wounds))
			effective_strength *= 0.5
		if(used_arm.brute_dam)
			effective_strength *= 0.75
		if(HAS_TRAIT(owner, TRAIT_HULK))
			effective_strength *= 2
		// todo Go over other possible positive/negative circumstances. Reagents, Changeling
		return effective_strength
	else
		var/datum/component/custom_arm_wrestler/custom_wrestler_info = owner.GetComponent(/datum/component/custom_arm_wrestler)
		return custom_wrestler_info.arm_strength

/datum/arm_wrestling_challenge/proc/calculate_arm_stamina(mob/owner,arm_index)
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		var/obj/item/bodypart/arm/used_arm = carbon_owner.hand_bodyparts[arm_index]
		return used_arm.arm_wrestling_properties.stamina
	else
		var/datum/component/custom_arm_wrestler/custom_wrestler_info = owner.GetComponent(/datum/component/custom_arm_wrestler)
		return custom_wrestler_info.arm_stamina

/datum/arm_wrestling_challenge/proc/calculate_arm_properties(mob/owner,arm_index)
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		var/obj/item/bodypart/arm/used_arm = carbon_owner.hand_bodyparts[arm_index]
		return used_arm.arm_wrestling_properties.arm_properties
	else
		var/datum/component/custom_arm_wrestler/custom_wrestler_info = owner.GetComponent(/datum/component/custom_arm_wrestler)
		return custom_wrestler_info.arm_properties

/datum/arm_wrestling_challenge/proc/try_accept_opponent(mob/prospective_opponent)
	if(starter == prospective_opponent) //No wrestling with yourself
		return
	if(!is_valid_participant(prospective_opponent))
		return
	if(!prospective_opponent.Adjacent(flat_surface))
		to_chat(prospective_opponent,span_warning("You need to be next to the table"))
		return
	var/turf/opponent_should_be_here = get_step(get_turf(flat_surface),get_dir(starter,flat_surface))
	if(get_turf(prospective_opponent) != opponent_should_be_here)
		to_chat(prospective_opponent,span_warning("You need to be on the other side of the table from your opponent"))
		return

	opponent = prospective_opponent
	opponent_surrender_action = new(src)
	opponent_surrender_action.Grant(opponent)

	add_participant(opponent)
	opponent_arm_index = prospective_opponent.active_hand_index
	opponent_stamina = calculate_arm_stamina(opponent,opponent_arm_index)

	visual.update_hands()

	start_countdown_phase()


/datum/arm_wrestling_challenge/proc/is_valid_participant(mob/user, silent = FALSE)
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		if(!carbon_user.has_active_hand())
			if(!silent)
				to_chat(carbon_user, span_warning("You need an arm to arm-wrestle."))
				//playsound_local(user, 'sound/misc/sadtrombone.ogg', 50, FALSE)
			return FALSE
		var/obj/item/bodypart/arm/used_arm = carbon_user.get_active_hand()
		if(istype(used_arm))
			if(!silent)
				to_chat(carbon_user,span_warning("You don't know how to armwrestle with [used_arm.name]"))
			return FALSE
		if(used_arm?.bodypart_disabled)
			if(!silent)
				to_chat(carbon_user, span_warning("Your arm can't be disabled to arm-wrestle."))
			return FALSE
		return TRUE
	else
		var/datum/component/custom_arm_wrestler/custom_wrestling = user.GetComponent(/datum/component/custom_arm_wrestler)
		if(custom_wrestling != null)
			return TRUE
		return FALSE

/datum/arm_wrestling_challenge/proc/add_participant(mob/participant, id)
	//Immobilize
	ADD_TRAIT(participant, TRAIT_IMMOBILIZED, ARM_WRESTLING_TRAIT)
	//Moving/getting stunned interrupts the challenge
	RegisterSignal(participant, COMSIG_MOVABLE_MOVED, PROC_REF(interrupt_challenge))
	RegisterSignal(participant, SIGNAL_ADDTRAIT(TRAIT_INCAPACITATED), PROC_REF(interrupt_challenge))
	participant.put_in_active_hand(create_hand_filler())

/datum/arm_wrestling_challenge/proc/create_hand_filler()
	var/obj/item/hand_item/arm_wrestling_filler/hand_item = new()
	hand_items += hand_item
	return hand_item

/datum/arm_wrestling_challenge/proc/remove_participant(mob/participant)
	REMOVE_TRAIT(participant, TRAIT_IMMOBILIZED, ARM_WRESTLING_TRAIT)
	UnregisterSignal(participant, list(COMSIG_MOVABLE_MOVED,SIGNAL_ADDTRAIT(TRAIT_INCAPACITATED)))

/datum/arm_wrestling_challenge/proc/interrupt_challenge()
	//Notify users that it was interrupted somehow
	qdel(src)

/datum/arm_wrestling_challenge/proc/start_countdown_phase()
	state = ARM_WRESTLING_COUNTDOWN
	visual.update_hands()
	//Display 3,2,1
	addtimer(CALLBACK(src, PROC_REF(show_countdown_number), 3), 10)
	addtimer(CALLBACK(src, PROC_REF(show_countdown_number), 2), 20)
	addtimer(CALLBACK(src, PROC_REF(show_countdown_number), 1), 30)
	addtimer(CALLBACK(src, PROC_REF(end_countdown_phase)), 40)

/datum/arm_wrestling_challenge/proc/end_countdown_phase()
	visual.balloon_alert_to_viewers("go")
	state = ARM_WRESTLING_WRESTLING
	visual.update_hands()
	START_PROCESSING(SSobj, src)

/datum/arm_wrestling_challenge/proc/show_countdown_number(number)
	visual.balloon_alert_to_viewers("[number]")

/datum/action/cooldown/arm_wrestling
	button_icon = 'icons/effects/arm_wrestling.dmi'
	var/datum/arm_wrestling_challenge/parent

/datum/action/cooldown/arm_wrestling/New(Target, original)
	//cooldown or base one could really use name change
	parent = Target
	. = ..()

/datum/action/cooldown/arm_wrestling/designate_table
	name = "designate arm wrestling table"
	button_icon_state = "designate_table_action"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED
	click_to_activate = TRUE
	ranged_mousepointer = 'icons/effects/mouse_pointers/supplypod_target.dmi'

/datum/action/cooldown/arm_wrestling/designate_table/Activate(atom/target)
	if(!is_valid_table(target))
		to_chat(owner,span_notice("pick a table"))
		return FALSE
	var/mob/user = owner
	if(!user.Adjacent(target))
		to_chat(owner,span_warning("you need to be next to the selected table"))
		return FALSE
	parent.start_waiting_for_opponent(target)
	. = ..()
	qdel(src)

/// Check if you can armwrestle on the given thing, right now only allows tables
/datum/action/cooldown/arm_wrestling/designate_table/proc/is_valid_table(atom/movable/target)
	return istype(target,/obj/structure/table)

/datum/action/cooldown/arm_wrestling/surrender
	name = "Give up arm wrestling"
	button_icon_state = "surrender"

/datum/action/cooldown/arm_wrestling/surrender/Activate(atom/target)
	. = ..()
	parent.surrender(owner)

/obj/effect/arm_wrestling_hand
	icon = 'icons/effects/arm_wrestling.dmi'
	vis_flags = VIS_INHERIT_ID

/obj/effect/arm_wrestling_hand/proc/animate_damage()
	var/damage_flash_color = "#960000"
	var/initial_color = color
	animate(src, time = 1, pixel_x = -1, flags = ANIMATION_PARALLEL)
	animate(time = 1, pixel_x = 0)
	animate(time = 1, pixel_x = 1)
	animate(time = 1, pixel_x = 0)
	animate(src, time = 5, color = damage_flash_color, flags = ANIMATION_PARALLEL)
	animate(time = 5, color = initial_color)

/obj/effect/arm_wrestling_visual
	name = "arm wrestling challenge"
	desc = "blah blah click with open hand to accept challenge"
	icon = 'icons/effects/arm_wrestling.dmi'
	var/obj/effect/arm_wrestling_hand/starter_hand
	var/obj/effect/arm_wrestling_hand/opponent_hand
	var/datum/arm_wrestling_challenge/parent

/obj/effect/arm_wrestling_visual/Initialize(mapload, datum/arm_wrestling_challenge/origin)
	. = ..()
	parent = origin

	starter_hand = new(src)
	vis_contents += starter_hand

	opponent_hand = new(src)
	vis_contents += opponent_hand

	update_hands()

/obj/effect/arm_wrestling_visual/proc/update_hands()
	starter_hand.dir = get_dir(get_turf(parent.starter),get_turf(src))
	starter_hand.icon_state = parent.state == ARM_WRESTLING_WRESTLING ? "hand_closed" : "hand_open"

	if(parent.state == ARM_WRESTLING_WAITING_FOR_OPPONENT || parent.state == ARM_WRESTLING_SELECT_TABLE)
		opponent_hand.vis_flags |= VIS_HIDE
	else
		if(opponent_hand.vis_flags & VIS_HIDE)
			opponent_hand.vis_flags &= ~VIS_HIDE
		opponent_hand.dir = get_dir(get_turf(parent.opponent),get_turf(src))
		opponent_hand.icon_state = parent.state == ARM_WRESTLING_WRESTLING ? "hand_closed" : "hand_open"

/obj/effect/arm_wrestling_visual/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	accept_attempt(user)

/obj/effect/arm_wrestling_visual/proc/accept_attempt(mob/user)
	if(parent.state != ARM_WRESTLING_WAITING_FOR_OPPONENT)
		return
	parent.try_accept_opponent(user)
