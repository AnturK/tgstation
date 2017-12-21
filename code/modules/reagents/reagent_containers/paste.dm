/obj/item/reagent_containers/pastetube
	name = "paste tube"
	desc = "Contains dense chemical paste."
	icon = 'icons/obj/bloodpack.dmi'
	icon_state = "empty"
	flags_1 = NOBLUDGEON_1
	volume = 30

/obj/item/reagent_containers/pastetube/on_reagent_change(changetype)
	update_icon()

/obj/item/reagent_containers/pastetube/update_icon()
	if(reagents.total_volume)
		icon_state = "tube_full"
	else
		icon_state = "tube_empty"

/obj/item/reagent_containers/pastetube/patch/afterattack(obj/target, mob/user , proximity)
	if(proximity)
	
	return
