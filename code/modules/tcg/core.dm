/datum/tcg/basic_attack
	name = "Basic Attack"
	desc = "Deals 5 damage"
	requires_target = TRUE
	cost = 1
	var/damage = 5

/datum/tcg/basic_attack/on_use(datum/tcg_game/context,datum/tcg_actor/A)
	deal_damage(A,target,damage,context)

/datum/tcg/basic_defend
	name = "Basic Defend"
	desc = "Grants 5 Defense"
	cost = 1
	var/amount = 5

/datum/tcg/basic_defend/on_use(datum/tcg_game/context,datum/tcg_actor/A)
	A.adjust_defense(amount)

/datum/tcg/core_defensive_algo
	name = "Defensive algorithm"
	desc = "Every time you gain Defense gain 1 more."
	cost = 1

/datum/tcg/core_defensive_algo/on_use(datum/tcg_game/context, datum/tcg_actor/user)
	context.modify_property(user,/datum/tcg_property/defenseboost,1)