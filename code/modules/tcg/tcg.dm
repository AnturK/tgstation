#define CARD_TARGET_ENEMY "enemy"
#define CARD_TARGET_FRIEND "friend"
#define CARD_TARGET_CARD_IN_HAND "card_in_hand"
#define CARD_TARGET_CARD_IN_DECK "card_in_deck"
#define CARD_TARGET_CARD_IN_DISCARD "card_in_discard"

#define PLAYER_TEAM 0
#define ENEMY_TEAM 1

/// Base card datum
/datum/tcg
	var/name = "Generic Card"
	var/desc = "Does nothing"
	var/cost = 0
	//var/properties = list() todo add classifiers like plasma/attack/buff etc
	var/requires_target = FALSE
	var/target_type = CARD_TARGET_ENEMY
	var/target_count = 1
	var/target //can be a list
	
	//UI card image vars
	var/icon = 'icons/misc/tcg.dmi'
	var/icon_state
	var/current_ui_id

/datum/tcg/New()
	. = ..()
	recalculate_ui_id()

/datum/tcg/proc/recalculate_ui_id()
	if(icon && icon_state)
		current_ui_id = generate_tcg_asset_id(icon,icon_state)

/// Returns the card play cost for given user and game context
/datum/tcg/proc/get_cost(datum/tcg_game/context,datum/tcg_actor/user)
	return cost //variable cost later

/// Checks if the given user can play the card
/datum/tcg/proc/can_use(datum/tcg_game/context,datum/tcg_actor/user)
	var/list/cost_list = list(get_cost(context,user))
	SEND_SIGNAL(user,COMSIG_TCG_MODIFY_COST,cost_list,FALSE)
	if(requires_target && !valid_target_exists(context,user))
		return FALSE
	return user.ap >= cost_list[1]

/// Plays the card, this includes selecting target if not present yet and discarding the card afterwards. Returns TRUE on success
/datum/tcg/proc/use(datum/tcg_game/context,datum/tcg_actor/user,discard=TRUE)
	var/list/cost_list = list(cost)
	SEND_SIGNAL(user,COMSIG_TCG_MODIFY_COST,cost_list,TRUE)
	user.ap -= cost_list[1]
	if(requires_target && !target)
		var/sanity_turn = context.turn
		var/sanity_current = context.current
		select_targets(context,user)
		if(context.current != sanity_current || context.turn != sanity_turn)
			return FALSE
		if(!target)
			stack_trace("select_targets failed to assign card target.")
			return FALSE
	on_use(context,user)
	SEND_SIGNAL(user,COMSIG_TCG_CARD_USED,user,src) //actor specific hook
	SEND_SIGNAL(context,COMSIG_TCG_CARD_USED,user,src) //game-wide hook
	context.log_tcg("[user.name] used [name]")
	target = null //Reset target
	//Discard used card
	if(discard)
		user.discard(src)
	
	//Check if whatever we done ended the combat
	context.check_resolution()
	return TRUE

/// Actual card effect hook
/datum/tcg/proc/on_use(datum/tcg_game/context,datum/tcg_actor/user)
	return

/datum/tcg/proc/select_targets(datum/tcg_game/context,datum/tcg_actor/user)
	var/list/valid_targets = get_valid_targets(context,user)
	target = user.select_card_targets(valid_targets,target_count)

/datum/tcg/proc/get_valid_targets(datum/tcg_game/context,datum/tcg_actor/user)
	. = list()
	switch(target_type)
		if(CARD_TARGET_ENEMY)
			for(var/datum/tcg_actor/A in context.actors)
				if(A.active && A.team != user.team)
					. += A
		if(CARD_TARGET_FRIEND)
			for(var/datum/tcg_actor/A in context.actors)
				if(A.active && A.team == user.team)
					. += A
		if(CARD_TARGET_CARD_IN_HAND)
			for(var/datum/tcg/card in user.hand)
				if(card != src)
					. += card
		if(CARD_TARGET_CARD_IN_DISCARD)
			for(var/datum/tcg/card in user.discard)
				. += card
		if(CARD_TARGET_CARD_IN_DECK)
			for(var/datum/tcg/card in user.deck)
				. += card

/datum/tcg/proc/valid_target_exists(datum/tcg_game/context,datum/tcg_actor/user)
	var/valid_targets_found = 0
	switch(target_type)
		if(CARD_TARGET_ENEMY)
			for(var/datum/tcg_actor/A in context.actors)
				if(A.team != user.team)
					valid_targets_found++
		if(CARD_TARGET_FRIEND)
			for(var/datum/tcg_actor/A in context.actors)
				if(A.team == user.team)
					valid_targets_found++
		if(CARD_TARGET_CARD_IN_HAND)
			for(var/datum/tcg/card in user.hand)
				if(card != src)
					valid_targets_found++
		if(CARD_TARGET_CARD_IN_DISCARD)
			valid_targets_found = user.discard.len
		if(CARD_TARGET_CARD_IN_DECK)
			valid_targets_found = user.deck.len
	return valid_targets_found >= target_count

/datum/tcg/proc/deal_damage(datum/tcg_actor/source,datum/tcg_actor/target,value,datum/tcg_game/context)
	var/list/damage_mod_reflist = list(value)
	SEND_SIGNAL(source,COMSIG_TCG_DAMAGE_MOD,target,damage_mod_reflist,context)
	var/modified_damage = damage_mod_reflist[1]
	
	if(target.defense > 0)
		var/shield_damage = min(target.defense,modified_damage)
		target.adjust_defense(-shield_damage)
		modified_damage -= shield_damage

	if(modified_damage > 0)
		target.adjust_health(-modified_damage)

	SEND_SIGNAL(target,COMSIG_TCG_ATTACKED,source)


/datum/tcg_actor
	var/name = "Generic Actor"
	var/team = PLAYER_TEAM
	var/active = TRUE /// Aka dead or not
	
	var/icon = 'icons/misc/tcg.dmi'//Interface icon
	var/icon_state //Interface icon state
	var/current_ui_id /// Calculated at init so we don't have to do replacetext in ui_data

	var/card_list = list()	/// Deck is generated from these at combat start
	var/innate_properties = list() /// type = amount, these will be autoadded at combat start
	var/health = 10
	var/cards_drawn_at_turn_start = 1 //
	var/max_hand_size = 10
	var/ap_per_turn = 3
	var/discard_hand_at_turn_end = TRUE

	var/list/hand = list()
	var/list/deck = list()
	var/list/discard = list()
	var/list/removed = list()
	var/list/properties = list()
	var/ap = 0
	var/defense = 0

	var/controllable = FALSE //controlled by a player
	var/mob/user //If not null only that mob can make moves for that actor and see their hand
	var/ui_cue /// font awesome class for next action cue

/datum/tcg_actor/New()
	. = ..()
	recalculate_ui_id()

/datum/tcg_actor/proc/recalculate_ui_id()
	if(icon && icon_state)
		current_ui_id = generate_tcg_asset_id(icon,icon_state)

/datum/tcg_actor/proc/generate_deck()
	for(var/card_type in card_list)
		for(var/count in 1 to card_list[card_type])
			var/datum/tcg/new_card = new card_type
			deck += new_card
	shuffle_inplace(deck)

/datum/tcg_actor/proc/end_turn()
	if(discard_hand_at_turn_end)
		for(var/datum/tcg/card in hand)
			discard(card)
	SEND_SIGNAL(src,COMSIG_TCG_TURN_END)

#define DRAW_TOP "top"
#define DRAW_RANDOM "random"

/datum/tcg_actor/proc/draw_cards(number,turnstart = FALSE, drawtype = DRAW_TOP)
	for(var/i in 1 to number)
		if(!deck.len)
			return_discard()
			if(!deck.len)
				return
		var/datum/tcg/card
		switch(drawtype)
			if(DRAW_TOP)
				card = popleft(deck)
			if(DRAW_RANDOM)
				card = pick_n_take(deck)
		if(hand.len < max_hand_size)
			hand += card
			SEND_SIGNAL(src,COMSIG_TCG_CARD_DRAWN,card, turnstart)
		else
			discard(card)

/datum/tcg_actor/proc/return_discard()
	deck += discard
	discard.Cut()
	shuffle_inplace(deck)

/datum/tcg_actor/proc/discard(datum/tcg/card)
	hand -= card
	deck -= card
	discard |= card

/datum/tcg_actor/proc/handle_turn(datum/tcg_game/context)
	if(cards_drawn_at_turn_start > 0)
		draw_cards(cards_drawn_at_turn_start,turnstart = TRUE)
	ap = ap_per_turn

/datum/tcg_actor/proc/adjust_health(amount)
	health += amount
	SEND_SIGNAL(src,COMSIG_TCG_HEALTH_CHANGED,amount)

	if(health <= 0)
		death()

/datum/tcg_actor/proc/adjust_defense(amount)
	defense += amount
	SEND_SIGNAL(src,COMSIG_TCG_DEFENSE_CHANGED,amount)

/datum/tcg_actor/proc/death()
	var/recovered = SEND_SIGNAL(src,COMSIG_TCG_DEATH)
	if(recovered)
		return
	active = FALSE

/datum/tcg_actor/proc/select_card_targets(list/valid_targets,target_count)
	if(target_count == 1)
		return pick(valid_targets)
	else
		. = list()
		for(var/i in 1 to target_count)
			. += pick_n_take(valid_targets)

// This one plays randomly picked cards same way as player
/datum/tcg_actor/ai
	name = "Enemy Player"
	team = ENEMY_TEAM
	cards_drawn_at_turn_start = 5

/datum/tcg_actor/ai/handle_turn(datum/tcg_game/context)
	..()
	execute_turn(context)
	end_turn()

/datum/tcg_actor/ai/proc/execute_turn(datum/tcg_game/context)
	var/list/availible_moves = get_availible_moves(context)
	while(availible_moves.len > 0)
		var/datum/tcg/chosen = pick_n_take(availible_moves)
		var/result = chosen.use(context,src)
		if(!result)
			stack_trace("Failed card use for [chosen.name] - [name]")
			break
		availible_moves = get_availible_moves(context)

/datum/tcg_actor/ai/proc/get_availible_moves(datum/tcg_game/context)
	. = list()
	for(var/datum/tcg/card in hand)
		if(card.can_use(context,src))
			. += card

//Simple AI with one move per turn and action cues
//Card list values are used as default action pick weights
//They only use deck as card instance holder and instead pick actions from cardlist
/datum/tcg_actor/ai/simple
	name = "Simple Enemy"
	cards_drawn_at_turn_start = 0
	discard_hand_at_turn_end = FALSE
	ap_per_turn = 1
	var/datum/tcg/next_action

/datum/tcg_actor/ai/simple/execute_turn(datum/tcg_game/context)
	if(!next_action || !next_action.can_use(context,src))
		plan_next_action(context)
	if(next_action && next_action.can_use(context,src))
		next_action.use(context,src,discard = FALSE) //Don't discard
	plan_next_action(context)

/datum/tcg_actor/ai/simple/generate_deck()
	//Only one instace per type
	for(var/card_type in card_list)
		var/datum/tcg/new_card = new card_type
		deck += new_card
	shuffle_inplace(deck)


/datum/tcg_actor/ai/simple/proc/plan_next_action(datum/tcg_game/context)
	var/old_ap = ap
	ap = ap_per_turn //If we're planning for next turn current ap is used up already so can_use would return false
	var/list/weighted_allowed = list()
	for(var/datum/tcg/card in deck)
		if(card.can_use(context,src))
			weighted_allowed[card] = card_list[card.type]
	ap = old_ap
	next_action = pickweight(weighted_allowed)
	update_cue()

/datum/tcg_actor/ai/simple/proc/update_cue()
	if(next_action)
		ui_cue = "fas fa-question"
		//scan properties here to select attack/defense/special cue
	else
		ui_cue = "fas fa-hourglass"

/datum/tcg_actor/ai/simple/death()
	. = ..()
	ui_cue = "fas fa-skull"

//CONTROLLABLE PLAYER
/datum/tcg_actor/player
	name = "Player"
	ap_per_turn = 3
	cards_drawn_at_turn_start = 5
	controllable = TRUE
	icon_state = "probe"
	

/datum/tcg_actor/player/select_card_targets(list/valid_targets,target_count)
	var/list/chosen = list()
	if(valid_targets.len != target_count)
		var/list/targets_by_name = list()
		var/list/name_counts = list()
		for(var/T in valid_targets)
			var/unique_name
			if(istype(T,/datum/tcg))
				var/datum/tcg/card = T
				unique_name = card.name
			else if(istype(T,/datum/tcg_actor))
				var/datum/tcg_actor/actor = T
				unique_name = actor.name
			else
				stack_trace("Non card/actor in valid targets list")
				continue
			if(!name_counts[unique_name])
				name_counts[unique_name] = 1
			else
				name_counts[unique_name] += 1
				unique_name = "[unique_name] #[name_counts[unique_name]]"
			targets_by_name[unique_name] = T
		for(var/i in 1 to target_count)
			//todo usr -> user
			var/selected = input("Select target:", "Card target") as anything in targets_by_name
			chosen += targets_by_name[selected]
	else
		chosen = valid_targets
	if(target_count == 1)
		return chosen[1]
	else
		return chosen

/datum/tcg_game
	var/turn = 0
	var/list/actors = list()
	var/list/property_handlers = list()
	var/datum/tcg_actor/current
	var/list/alog = list()

	var/started = FALSE	 //Started
	var/complete = FALSE //game finished
	var/winner			 //winning TEAM

/datum/tcg_game/proc/log_tcg(data)
	alog += data

/datum/tcg_game/proc/add_actor(datum/tcg_actor/A)
	actors += A
	A.generate_deck()
	if(started)
		for(var/p in A.innate_properties)
			modify_property(A,p,A.innate_properties[p])
	RegisterSignal(A,COMSIG_TCG_TURN_END,.proc/actor_turn_ended)
	log_tcg("[A.name] joins the combat")
	SEND_SIGNAL(src,COMSIG_TCG_ACTOR_JOINED,A)

/datum/tcg_game/proc/start_game()
	//Generate innate properties
	for(var/datum/tcg_actor/A in actors)
		for(var/p in A.innate_properties)
			modify_property(A,p,A.innate_properties[p])
	started = TRUE
	next_turn() //Begin first turn

/datum/tcg_game/proc/end_game()
	complete = TRUE
	for(var/datum/tcg_actor/A in actors)
		if(A.active)
			winner = A.team
			break

/datum/tcg_game/proc/actor_turn_ended(datum/source)
	if(source == current)
		check_resolution()
		log_tcg("[current.name] turn ended.")
		next_turn()

/datum/tcg_game/proc/next_turn()
	var/current_id = current ? actors.Find(current) : 0


	do
		current_id = WRAP(current_id + 1, 1 , actors.len + 1)
		current = actors[current_id]
		if(current_id == 1)
			turn++
	while(!current.active) //skipping dead

	log_tcg("[current.name] turn started")
	SEND_SIGNAL(current,COMSIG_TCG_TURN_START)
	current.handle_turn(src)

/datum/tcg_game/proc/check_resolution()
	if(resolved())
		end_game()

/datum/tcg_game/proc/resolved()
	var/list/teams_left = list()
	for(var/datum/tcg_actor/A in actors)
		if(A.active)
			teams_left |= A.team
	return teams_left.len <= 1

/datum/tcg_game/ui_interact(mob/user, ui_key = "tcg", datum/tgui/ui = null, force_open = FALSE, \
							datum/tgui/master_ui = null, datum/ui_state/state = GLOB.always_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "tcg", "tcg combat", 800, 600, master_ui, state)
		ui.open()

/datum/tcg_game/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	var/mob/M = usr
	var/datum/tcg_actor/player/P = current
	if(istype(P) && (!P.user || P.user == M))
		switch(action)
			if("end-turn")
				P.end_turn()
			if("play-card")
				try_playing_card(M,text2num(params["card"]))
		. = TRUE

/datum/tcg_game/proc/try_playing_card(mob/user,card_index)
	if(!card_index || current.hand.len < card_index)
		stack_trace("invalid card index")
		return
	var/datum/tcg/card = current.hand[card_index]
	if(card.can_use(src,current))
		card.use(src,current)
	else
		to_chat(user,"<span class='warning'>Can't use that card</span>")

/datum/tcg_game/ui_data(mob/user)
	. = list()

	if(complete)
		.["complete"] = TRUE
		var/your_side = PLAYER_TEAM
		for(var/datum/tcg_actor/A in actors)
			if(A.user == user)
				your_side = A.team
				break
		.["win"] = winner == your_side
		return .
	.["complete"] = FALSE
	.["turn"] = turn
	.["your_turn"] = FALSE
	.["actors"] = list()
	.["hand"] = list()
	//Find our pov character we want to display hand for, default to current if it does not exist
	var/datum/tcg_actor/pov = current

	for(var/datum/tcg_actor/A in actors)
		var/list/ad = list()
		ad["name"] = A.name
		ad["health"] = A.health
		ad["defense"] = A.defense
		ad["ap"] = A.ap
		ad["team"] = A.team
		ad["properties"] = list()
		ad["current"] = current == A
		ad["icon"] = A.current_ui_id || "default_actor"
		if(A.ui_cue)
			ad["cue"] = A.ui_cue
		for(var/p in A.properties)
			var/datum/tcg_property/P = property_handlers[p]
			ad["properties"] += list(list("name" = P.name,"desc" = P.desc, "value" = A.properties[p], "icon" = P.ui_icon))
		.["actors"] += list(ad)
		
		if(A.user == user)
			pov = A

	if(pov.controllable && (!pov.user || pov.user == user)) //Only display if we are their user/ have no user
		.["pov_index"] = actors.Find(pov)
		.["your_turn"] = current == pov
		for(var/datum/tcg/card in pov.hand)
			var/cd = list()
			cd["name"] = card.name
			cd["desc"] = card.desc
			cd["cost"] = card.cost
			cd["icon"] = card.current_ui_id || "default_card"
			if(card.requires_target)
				cd["target_type"] = card.target_type
				cd["target_count"] = card.target_count
			.["hand"] += list(cd)

	//How to do this without sending 999 lines every time...
	.["log"] = alog.Copy(max(1,alog.len - 10))

/datum/tcg_game/ui_base_html(html)
	var/datum/asset/spritesheet/assets = get_asset_datum(/datum/asset/spritesheet/tcg)
	. = replacetext(html, "<!--customheadhtml-->", assets.css_tag())

//PROPERTIES

/datum/tcg_game/proc/modify_property(datum/tcg_actor/target,proptype,amount)
	if(!ispath(proptype,/datum/tcg_property))
		stack_trace("invalid property")
		return
	if(!property_handlers[proptype])
		property_handlers[proptype] = new proptype
	var/datum/tcg_property/P = property_handlers[proptype]
	if(!target.properties[proptype])
		P.apply_to(target)
	target.properties[proptype] += amount
	SEND_SIGNAL(target,COMSIG_TCG_PROPERTY_CHANGED,proptype,amount)

/datum/tcg_property
	var/name = "Generic Property"
	var/desc = "generic property"
	var/ui_icon = "question" //font awesome icon to use as property symbol on the ui

/datum/tcg_property/proc/apply_to(datum/tcg_actor/target)
	return

/datum/tcg_property/proc/remove_from(datum/tcg_actor/target)
	return

/mob
	var/datum/tcg_game/test_game

/mob/verb/debug_tcg()
	set name = "TCG"

	test_game = new

	var/list/example_deck = list()
	example_deck[/datum/tcg/basic_attack] = 5
	example_deck[/datum/tcg/basic_defend] = 5
	example_deck[/datum/tcg/core_defensive_algo] = 1
	
	var/datum/tcg_actor/player/P1 = new
	P1.name = "Player A"
	P1.card_list = example_deck
	
	var/datum/tcg_actor/ai/simple/carp/carp1 = new
	carp1.name = "Carp A"

	var/datum/tcg_actor/ai/simple/carp/carp2 = new
	carp2.name = "Carp B"

	test_game.add_actor(P1)
	test_game.add_actor(carp1)
	test_game.add_actor(carp2)

	test_game.start_game()

	test_game.ui_interact(usr)