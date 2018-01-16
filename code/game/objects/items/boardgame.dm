/obj/item/boardgame
	name = "boardgame"
	desc = "Very traditional."
	var/set_up = FALSE
	var/game_started = FALSE
	var/datum/boardgame/game //actual_game

	icon = 'icons/obj/boardgames.dmi'
	icon_state = "board_packed"

/obj/item/boardgame/Initialize()
	. = ..()
	if(ispath(game,/datum/boardgame))
		game = new game()

//Drag to table or floor to set it up
/obj/item/boardgame/atom/MouseDrop(atom/over)
	if((isturf(over) || istable(over)) && Adjacent(usr) && Adjacent(over))
		return set_up(get_turf(over))
	. = ..() //Just do whatever

/obj/item/boardgame/proc/set_up(turf/T)
	return

/obj/item/boardgame/proc/pack_up(turf/T)
	return

/obj/item/boardgame/proc/on_new_turn()

/obj/item/boardgame/proc/commands(mob/player)

/obj/item/boardgame/proc/resolve_turn()
	return

/obj/item/boardgame/proc/attack_hand(mob/user)
	if(!set_up)
		. == ..()
	else
		ui_interact()

/obj/item/boardgame/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
								datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "boardgame", name, 440, 650, master_ui, state)
		ui.open()

/obj/item/boardgame/ui_data()

// [BOARD][PLAYER PANEL]
// 

//Restrictions : 
// Turn-based only
// Players each take turns one by one in the order of players() list
/datum/boardgame
	var/name = "The Game"
	var/desc = "You just lost it."
	var/list/players = list()
	var/list/ready_state = list()
	var/min_players = 2
	var/max_players = 2

//Player signs up
/datum/boardgame/proc/on_player_join(mob/player)
	if(players.len < max_players)
		players |= player
		ready_state[player] = FALSE
	else
		to_chat(player,"<span class='warning'>No free spots left!</span>")

/datum/boardgame/proc/on_player_read(mob/player)
	if(player in players)
		ready_state[player] = TRUE

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

/datum/boardgame/proc/

/datum/boardgame/cursed