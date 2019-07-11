local S = minetest.get_translator("xmana")

xmana = {}

function xmana.level_to_mana(level)
	return math.pow(1.1, level) * 100
end

function xmana.mana_to_level(mana)
	return math.floor(math.max(0, math.log(math.max(0.001, mana / 100)) / math.log(1.1)) + 0.5)
end

-- Maximum mana possible.
xmana.MAX_LEVEL = tonumber(minetest.settings:get("xmana.max_level")) or 30
xmana.MAX = math.ceil(xmana.level_to_mana(xmana.MAX_LEVEL))

-- Access a player object's mana. If set is false, return current value. If set is a number, set to that. If relative is true, add the current value to the set.
function xmana.mana(player, set, relative)
	if set then
		-- Actual amount set when relative is true is current + set.
		local set = relative and (set + xmana.mana(player)) or set
		-- Clamp to reasonable values.
		set = math.max(0, math.min(set, xmana.MAX))

		player:get_meta():set_float("xmana:mana", set)
		hb.change_hudbar(player, "xmana", xmana.mana_to_level(xmana.mana(player)), xmana.MAX_LEVEL)
	else
		return player:get_meta():get_float("xmana:mana", set)
	end
end

minetest.register_on_respawnplayer(function(player)
	xmana.mana(player, 0)
end)

minetest.register_on_joinplayer(function(player)
	hb.init_hudbar(player, "xmana", 0, xmana.MAX_LEVEL)
	xmana.mana(player, 0)
end)

hb.register_hudbar("xmana", 0xFFFFFF, S"Mana", {
	bar = "xmana_bg.png",
	icon = "xmana_icon.png",
	bgicon = "xmana_bgicon.png"
}, 0, xmana.MAX_LEVEL, false)

minetest.register_privilege("xmana", {
	"Can modify player mana.",
	give_to_singleplayer = false
})

minetest.register_chatcommand("xmana", {
	params = "<amount> [<username or self>] [<absolute boolean>]",
	description = "Set player mana.",
	privs = {xmana = true},
	func = function(caller, param)
		local split = param:split(" ")

		local amount = tonumber(split[1])
		local target = split[2] and minetest.get_player_by_name(split[1]) or minetest.get_player_by_name(caller)
		local relative = not minetest.is_yes(split[3])

		if not amount then
			return false, S"Invalid amount."
		end

		if not target then
			return false, S"Invalid target."
		end

		xmana.mana(target, amount, relative)
		return true, S("@1 now has @2 levels (@3 mana)", target:get_player_name(), xmana.mana_to_level(xmana.mana(target)), xmana.mana(target))
	end,
})

if minetest.get_modpath("doc") then
	doc.add_entry("basics", "xmana", {
		name = S"Mana",
		data = {
			text = table.concat({
				S"Mana is the measure of energy gathered within you.",
				S"Mana is organized into levels, with higher levels consisting of exponentially more mana.",
				S"You may gain mana through various means.",
				S"You may spend mana on special effects or items.",
			}, "\n"),
		},
	})
end
