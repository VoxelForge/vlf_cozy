local S = minetest.get_translator(minetest.get_current_modname())
local show_actions = minetest.settings:get_bool("vlf_cozy_print_actions", false)
local EYE_OFFSETS = {sit = {x = 0, y = -7, z = 2}, lay = {x = 0, y = -13, z = -5}, default = {x = 0, y = 0, z = 0}}
local cozy = {positions = {}, mods = {"vlf_title"}}

local function send_action(player_name, action)
	if show_actions then
		minetest.chat_send_all("* " .. player_name .. S({sit = " sits", lay = " lies", stand = " stands up"}))
	end
end

local function show_status(player, message)
	for _, mod in ipairs(cozy.mods) do
		if minetest.get_modpath(mod) then
			return mod == "vlf_title" and vlf_title.set(player, "actionbar", {text = message or S("Move to stand up"), color = "white", stay = 60})
		end
	end
	minetest.log("warning", "[vlf_cozy] No mod found for actionbar display!")
end

local function reset_player(player, name)
	player:set_eye_offset(EYE_OFFSETS.default, EYE_OFFSETS.default)
	playerphysics.remove_physics_factor(player, "speed", "vlf_cozy:attached")
	playerphysics.remove_physics_factor(player, "jump", "vlf_cozy:attached")
	vlf_player.player_attached[name] = false
	cozy.positions[name] = nil
end

local function handle_action(player, name, action)
	if vlf_playerinfo[name].node_stand_below.name == "air" then return end
	if vlf_player.player_attached[name] then reset_player(player, name) send_action(name, "stand")
	else
		for _, pos in pairs(cozy.positions) do
			if vector.distance(player:get_pos(), pos) < 1 then return show_status(player, S("This spot is already occupied!")) end
		end
		player:set_eye_offset(EYE_OFFSETS[action], EYE_OFFSETS[action])
		playerphysics.add_physics_factor(player, "speed", "vlf_cozy:attached", 0)
		playerphysics.add_physics_factor(player, "jump", "vlf_cozy:attached", 0)
		vlf_player.player_attached[name] = true vlf_player.player_set_animation(player, action, action == "sit" and 30 or 0)
		cozy.positions[name] = player:get_pos() send_action(name, action) show_status(player)
	end
end

minetest.register_globalstep(function()
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local ctrl = player:get_player_control()
		if vlf_player.player_attached[name] and not player:get_attach() and (ctrl.up or ctrl.down or ctrl.left or ctrl.right or ctrl.jump or ctrl.sneak) then
			reset_player(player, name) send_action(name, "stand")
		elseif minetest.get_node(vector.offset(player:get_pos(), 0, -1, 0)).name == "air" then reset_player(player, name) end
	end
end)

minetest.register_on_joinplayer(function(player) reset_player(player, player:get_player_name()) end)
minetest.register_chatcommand("sit", {description = S("Sit down"), func = function(name) handle_action(minetest.get_player_by_name(name), name, "sit") end})
minetest.register_chatcommand("lay", {description = S("Lay down"), func = function(name) handle_action(minetest.get_player_by_name(name), name, "lay") end})
