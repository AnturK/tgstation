// Clothing/Equipement witht his will have a chance to be knocked off with disarms

/datum/component/knockoff
    var/chance = 1 //basic chance to knock off
    var/list/targeted_zones = list()

/hat/loose
    ADD_COMPONENT(knockoff,0.5,"head")