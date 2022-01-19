#define GUESS_UNKNOWN 0
#define GUESS_CORRECT 1
#define GUESS_MISPLACED 2
#define GUESS_WRONG 3

/datum/wordle
	/// Answer to the riddle. Uppercase
	var/answer = "ROBUST"
	/// List of associated list with guess results in format: list(guess = "WORD", result = list(GUESS_CORRECT,GUESS_MISPLACED,GUESS_WRONG,GUESS_WRONG))
	var/guesses = list()
	/// Tries left
	var/guessesLeft = 5
	/// Game finished in any way (win/lose)
	var/finished = FALSE
	/// List of all allowed letters with current guess status
	var/alphabet
	/// List of allowed words
	var/static/list/dictionary
	/// Info message
	var/message
	/// Last guess that was not found in the dictionary
	var/last_invalid_guess

/datum/wordle/New(answer,guessCount)
	. = ..()
	if(answer)
		src.answer = answer
	if(guessCount)
		guessesLeft = guessCount
	alphabet = list()
	for(var/letter in GLOB.alphabet_upper)
		alphabet[letter] = GUESS_UNKNOWN
	if(!dictionary)
		var/list/baseDictionary = world.file2list("strings/wordleDictionary.txt") //inbuilt dictionary
		var/list/customDictionary = world.file2list("data/customWordleDictionary.txt") //user added words
		dictionary = baseDictionary | customDictionary

/datum/wordle/proc/randomize()
	answer = uppertext(pick(dictionary))
	guessesLeft = initial(guessesLeft)

/datum/wordle/ui_state(mob/user)
	return FALSE

/datum/wordle/ui_state(mob/user)
	return GLOB.admin_state

/datum/wordle/ui_static_data(mob/user)
	. = ..()
	.["wordLength"] = length(answer)

/datum/wordle/ui_data(mob/user)
	. = ..()
	.["guessesLeft"] = guessesLeft
	.["guesses"] = guesses
	.["alphabet"] = alphabet
	.["message"] = message
	.["last_invalid_guess"] = last_invalid_guess
	.["finished"] = finished

/datum/wordle/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	message = ""
	switch(action)
		if("guess")
			if(finished)
				return TRUE
			var/current_guess = params["guess"]
			if(length(current_guess) != length(answer))
				return TRUE
			last_invalid_guess = null
			if(!dictionary.Find(lowertext(current_guess))) //dictionary is lowertext - standarize these to one format
				last_invalid_guess = current_guess
				message = "Word not in dictionary!"
				return TRUE
			guesses += list(parseGuess(current_guess))
			guessesLeft -= 1
			if(current_guess == answer)
				message = "You win!"
				finished = TRUE
			else if (guessesLeft == 0)
				message = "You lose!"
				finished = TRUE
			return TRUE
		if("suggest_word")
			//Todo: Fix the thing with button focus and pressing enter in tgui
			if(!last_invalid_guess)
				return TRUE
			if(sanitize(last_invalid_guess) != last_invalid_guess) //It's 6 letters max but better safe than sorry
				return TRUE
			// Add timeout ? Or just let admins smite people who spam
			// Show to admins for "Is this real word ? Y/N"
			to_chat(GLOB.admins, span_adminnotice("Wordle dictionary request: [ADMIN_LOOKUPFLW(usr)] proposes to add [last_invalid_guess] to the dictionary. [ADMIN_SMITE(usr)] (<A HREF='?_src_=holder;[HrefToken(TRUE)];approve_wordle_dictionary=[last_invalid_guess];user=[REF(usr)]'>APPROVE</A>)"))
			last_invalid_guess = null
			message = null
			return TRUE



/datum/wordle/proc/parseGuess(guess)
	var/list/guessData = list()
	for(var/character_index in 1 to length(guess))
		var/answer_char = copytext(answer,character_index,character_index+1)
		var/guess_char = copytext(guess,character_index,character_index+1)
		var/result = GUESS_UNKNOWN
		if(guess_char == answer_char)
			result = GUESS_CORRECT
		else
			if(findtext(answer,guess_char))
				result = GUESS_MISPLACED
			else
				result = GUESS_WRONG
		alphabet[guess_char] = result
		guessData += result
	var/result = list()
	result["guess"] = guess
	result["result"] = guessData
	return result

/datum/wordle/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Wordle")
		ui.set_autoupdate(FALSE)
		ui.open()

/mob
	var/datum/wordle/test_wordle

/mob/verb/test_wordle()
	if(!test_wordle)
		test_wordle = new
		test_wordle.randomize()
	test_wordle.ui_interact(usr)

#undef GUESS_CORRECT
#undef GUESS_MISPLACED
#undef GUESS_WRONG
