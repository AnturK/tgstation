/datum/autowiki/fish
	page = "Template:Autowiki/Content/Fish"

/datum/autowiki/fish/generate()
	var/output = ""

	for (var/fish_type in sort_list(subtypesof(/obj/item/fish), /proc/cmp_typepaths_asc))
		var/obj/item/fish/fish = new fish_type()

		var/filename = SANITIZE_FILENAME(escape_value(format_text(fish.name)))

		output += include_template("Autowiki/FishTableHeader")
		output += include_template("Autowiki/FishTableEntry", list(
			"icon" = escape_value(filename),
			"name" = escape_value(format_text(fish.name)),
			"favourite_bait" = "Haha",
			"disliked_bait" = "Yeah",
			"fishing_spots" = "Who knows",
			"description" = "yeah"
		))
		output += include_template("Autowiki/FishTableFooter")

		// It would be cool to make this support gifs someday, but not now
		upload_icon(getFlatIcon(fish, no_anim = TRUE), filename)

		qdel(fish)

	return output
