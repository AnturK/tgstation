/obj/item/boardgame
	name = "boardgame"
	desc = "Very traditional."
	var/set_up = FALSE
	var/datum/boardgame/game //actual_game
	var/gametype = /datum/boardgame
	icon = 'icons/obj/boardgames.dmi'
	icon_state = "board_packed"

//Drag to table or floor to set it up
/obj/item/boardgame/atom/MouseDrop(atom/over)
	if((isturf(over) || istable(over)) && Adjacent(usr) && Adjacent(over))
		return set_up(get_turf(over))
	. = ..() //Just do whatever

/obj/item/boardgame/proc/set_up(turf/T)
	forceMove(T)
	game = new gametype()
	set_up = TRUE
	anchored = TRUE
	update_icon()

/obj/item/boardgame/proc/pack_up(turf/T)
	QDEL_NULL(game)
	set_up = FALSE
	anchored = FALSE
	update_icon()

/obj/item/boardgame/proc/attack_hand(mob/user)
	if(!set_up)
		. == ..()
	else
		ui_interact(user)

/obj/item/boardgame/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
								datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, game.ui_name , name, 440, 650, master_ui, state)
		ui.open()

/obj/item/boardgame/ui_act(mob/user,act)
	switch(act)
		if("command")
			game.make_move(user,params["command"])
		if("join")
			try_join(user)
		if("ready")
			ready_up(user)
		if("quit")
			quit(user)
		if("start_game")
			game.game_started = TRUE
	. = TRUE

/obj/item/boardgame/proc/try_join(mob/user)
	if(game.game_started)
		to_chat(user,"<span class='warning'>Game already started!</span>")
		return FALSE
	if(game.players.len >= game.max_players)
		to_chat(user,"<span class='warning'>No free spot left!</span>")
		return FALSE
	game.players += user
	return TRUE

/obj/item/boardgame/proc/ready_up(mob/user)
	if((user in game.players) && !game.ready_state[user])
		game.ready_state[user] = TRUE

/obj/item/boardgame/proc/quit(mob/user)
	if(game.ready_state[user])
		game.ready_state -= user
	game.players -= user

/obj/item/boardgame/ui_data(mob/user)
	var/list/data = list()
	data["game_started"] = game_started
	//Setup part
	if(!game_started)
		data["players"] = list()
		for(var/mob/M in game.players)
			data["players"] += list(list("name" = M.name, "ready" = game.ready_state[M]))
		data["ready_to_start"] = game.ready_state.len >= game.min_players
		data["user_joined"] = user in game.players
		data["user_ready"] = user in game.ready_state
		data["user_can_join"] = game.players.len < game.max_players
		
	//Actual game
	if(game_started && !game_finished)
		data["my_turn"] = game.active_player == user
		data["turn_number"] = game.current_turn
		data["active_player"] = game.active_player.name
		if(game.active_player == user)
			data["commands"] = get_commands(user)
		data["game"] = game.get_data()
		data["game_log"] = game.log
			

//Restrictions : 
// Turn-based only
// Players each take turns one by one in the order of players() list
/datum/boardgame
	var/name = "The Game"
	var/desc = "You just lost it."
	var/ui_name = "boardgame_example"
	var/list/players = list()
	var/list/ready_state = list()
	var/game_started = FALSE
	var/current_turn = 0
	var/mob/active_player
	var/min_players = 2
	var/max_players = 2
	var/list/log = list()

//Player signs up
/datum/boardgame/proc/on_player_join(mob/player)
	if(players.len < max_players)
		players |= player
		ready_state[player] = FALSE
	else
		to_chat(player,"<span class='warning'>No free spots left!</span>")

/datum/boardgame/proc/on_player_ready(mob/player)
	if(player in players)
		ready_state[player] = TRUE


/datum/boardgame/proc/check_endgame()
	return FALSE

//Will happen once as soon as all players join and ready up
/datum/boardgame/proc/on_setup()
	return

//Should return a list of strings
/datum/boardgame/proc/get_commands(mob/player)
	return list()

//command will be one of the commands from get_commands
/datum/boardgame/proc/make_move(mob/player,command)
	return

//After command executes
/datum/boardgame/proc/after_move()
	return

//Data for the ui
/datum/boardgame/proc/get_data()
	return list()