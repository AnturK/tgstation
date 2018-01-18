/obj/item/boardgame
	name = "boardgame"
	desc = "Very traditional."
	var/set_up = FALSE
	var/datum/boardgame/game //actual_game
	var/gametype = /datum/boardgame
	icon = 'icons/obj/boardgames.dmi'
	icon_state = "board_packed"

//Drag to table or floor to set it up
/obj/item/boardgame/MouseDrop(atom/over)
	var/mob/living/user = usr
	if(!istype(user))
		return ..()

	if(!set_up)
		if((isturf(over) || istype(over,/obj/structure/table)) && user.is_holding(src) && user.Adjacent(over))
			return set_up(get_turf(over),user)
	else
		if(over == user && Adjacent(user))
			pack_up(user)
	. = ..() //Just do whatever

/obj/item/boardgame/proc/set_up(turf/T,mob/user)
	user.transferItemToLoc(src,T)
	game = new gametype()
	set_up = TRUE
	anchored = TRUE
	visible_message("<span class='notice'>[user] sets up [src].</span>")
	update_icon()

/obj/item/boardgame/proc/pack_up(mob/user)
	user.visible_message("<span class='notice'>[user] starts packing up [src].</span>", \
							"<span class='notice'>You start packing up [src].</span>")
	if(!do_after(user, 100, target = src))
		return
	user.visible_message("<span class='notice'>[user] packs up [src].</span>", \
						"<span class='notice'>You pack up [src].</span>")
	QDEL_NULL(game)
	set_up = FALSE
	anchored = FALSE
	update_icon()

/obj/item/boardgame/update_icon()
	if(set_up)
		icon_state = "board_set"
	else
		icon_state = "board_packed"

/obj/item/boardgame/attack_hand(mob/user)
	if(set_up)
		ui_interact(user)
	else
		. = ..()

/obj/item/boardgame/interact(mob/user)
	if(set_up)
		ui_interact(user)

/obj/item/boardgame/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
								datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, game.ui_name , game.name, 440, 650, master_ui, state)
		ui.open()

/obj/item/boardgame/ui_act(action,params)
	var/mob/user = usr
	if(!istype(user))
		return
	switch(action)
		if("command")
			if(game.make_move(user,params["command"])) //valid move
				game.after_move()
		if("join")
			try_join(user)
		if("ready")
			ready_up(user)
		if("quit")
			quit(user)
		if("start_game")
			game.start_game()
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
	data["game_started"] = game.game_started
	//Setup part
	if(!user)
		return
	if(!game.game_started)
		var/list/player_list = list()
		for(var/mob/M in game.players)
			player_list += list(list("name" = M.name, "ready" = game.ready_state[M]))
		for(var/i in player_list.len to game.max_players)//Fill up empty spots
			player_list += list(list("name" = "---","ready" = FALSE))
		data["players"] = player_list
		data["ready_to_start"] = game.ready_state.len >= game.min_players
		data["user_joined"] = (user in game.players) ? TRUE : FALSE
		data["user_ready"] = (user in game.ready_state) ? TRUE : FALSE
		data["user_can_join"] = game.players.len < game.max_players
		
	//Actual game
	if(game.game_started && !game.game_finished)
		data["my_turn"] = game.active_player == user
		data["turn_number"] = game.current_turn
		data["active_player"] = game.active_player.name
		if(game.active_player == user)
			data["commands"] = game.get_commands(user)
		data["game"] = game.get_data(user)
		data["game_log"] = game.log
	return data

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
	var/game_finished = FALSE
	var/current_turn = 0
	var/mob/active_player
	var/min_players = 2
	var/max_players = 2
	var/list/log = list()

/datum/boardgame/proc/start_game()
	current_turn = 1
	game_started = TRUE
	on_setup()

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
	shuffle_inplace(players) //Should this be default
	active_player = players[1]
	return

//Should return a list of strings
/datum/boardgame/proc/get_commands(mob/player)
	return list()

//command will be one of the commands from get_commands
//return FALSE on invalid move
/datum/boardgame/proc/make_move(mob/player,command)
	if(player != active_player)
		return FALSE

//After command executes
/datum/boardgame/proc/after_move()
	var/next_player
	current_turn++
	active_player = next_player
	if(check_endgame())
		endgame()

//Data for the ui
/datum/boardgame/proc/get_data(mob/user)
	return list()

/datum/boardgame/proc/endgame()
	game_finished = TRUE