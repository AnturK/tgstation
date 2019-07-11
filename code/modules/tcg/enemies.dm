
// Appears in groups of 3
// Bite: Deals 1 damage
// Swarm: Deal 3 more damage per friend in combat
/datum/tcg_actor/ai/simple/carp
	name = "Space Carp"
	health = 15
	innate_properties = list(/datum/tcg_property/swarm=1)
	card_list = list(/datum/tcg/basic_attack/bite=2,/datum/tcg/basic_defend/dodge=1)
	icon_state = "carp"


/datum/tcg_actor/ai/simple/megacarp
	name = "Mega Carp"
	health = 30
	card_list = list(/datum/tcg/basic_attack/bite=1)

/datum/tcg/basic_attack/bite
	name = "Bite"
	desc = "Deals 2 damage."
	damage = 2

/datum/tcg/basic_defend/dodge
	name = "Dodge"
	desc = "Grants 5 defense."