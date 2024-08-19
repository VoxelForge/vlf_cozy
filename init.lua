local S = minetest.get_translator(minetest.get_current_modname())
local show_actions = minetest.settings:get_bool("vlf_cozy_print_actions", false)
local EYE_OFFSETS = {sit = {x = 0, y = -7, z = 2}, lay = {x = 0, y = -13, z = -5}, default = {x = 0, y = 0, z = 0}}
local cozy = {positions = {}, mods = {"vlf_title", "vlf_tmp_message"}}

local function send_action(player_name, action)
	if show_actions then
		minetest.chat_send_all("* " .. player_name .. S({sit = " sits", lay = " lies", stand = " stands up"}))
	end
end

local function show_status(player, message)
	for _, mod in ipairs(cozy.mods) do
		if minetest.get_modpath(mod) then
			return mod == "vlf_title" and vlf_title.set(player, "actionbar", {text = message or S("Move to stand up"), color = "white", stay = 60}) or vlf_tmp_message.message(player, message)
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

--[[local S = minetest.get_translator(minetest.get_current_modname())
local show_actions = minetest.settings:get_bool("vlf_cozy_print_actions", false)
local EYE_OFFSETS = {sit = {x = 0, y = -7, z = 2}, lay = {x = 0, y = -13, z = -5}, default = {x = 0, y = 0, z = 0}}

local cozy = {positions = {}, attach_mods = {"vlf_title"}}

local function send_action_message(player_name, action)
	if show_actions then
		local actions = {sit = " sits", lay = " lies", stand = " stands up"}
		minetest.chat_send_all("* " .. player_name .. S(actions[action]))
	end
end

local function display_status(player, message)
	message = message or S("Move to stand up")
	for _, mod in ipairs(cozy.attach_mods) do
		if minetest.get_modpath(mod) then
			if mod == "vlf_title" then
				vlf_title.set(player, "actionbar", {text = message, color = "white", stay = 60})
			end
			return
		end
	end
	minetest.log("warning", "[vlf_cozy] No mod found for actionbar display!")
end

local function reset_player(player, player_name)
	player:set_eye_offset(EYE_OFFSETS.default, EYE_OFFSETS.default)
	playerphysics.remove_physics_factor(player, "speed", "vlf_cozy:attached")
	playerphysics.remove_physics_factor(player, "jump", "vlf_cozy:attached")
	vlf_player.player_attached[player_name] = false
	cozy.positions[player_name] = nil
end

local function handle_action(player, player_name, action)
	local pos = player:get_pos()
	if vlf_playerinfo[player_name].node_stand_below.name == "air" then return end
	
	if vlf_player.player_attached[player_name] then
		reset_player(player, player_name)
		send_action_message(player_name, "stand")
	else
		for _, occupied_pos in pairs(cozy.positions) do
			if vector.distance(pos, occupied_pos) < 1 then
				display_status(player, S("This spot is already occupied!"))
				return
			end
		end
		player:set_eye_offset(EYE_OFFSETS[action], EYE_OFFSETS[action])
		playerphysics.add_physics_factor(player, "speed", "vlf_cozy:attached", 0)
		playerphysics.add_physics_factor(player, "jump", "vlf_cozy:attached", 0)
		vlf_player.player_attached[player_name] = true
		vlf_player.player_set_animation(player, action, action == "sit" and 30 or 0)
		cozy.positions[player_name] = pos
		send_action_message(player_name, action)
		display_status(player)
	end
end

minetest.register_globalstep(function()
	for _, player in ipairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()
		local ctrl = player:get_player_control()
		if vlf_player.player_attached[player_name] and not player:get_attach() and (ctrl.up or ctrl.down or ctrl.left or ctrl.right or ctrl.jump or ctrl.sneak) then
			reset_player(player, player_name)
			send_action_message(player_name, "stand")
		elseif minetest.get_node(vector.offset(player:get_pos(), 0, -1, 0)).name == "air" then
			reset_player(player, player_name)
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	reset_player(player, player:get_player_name())
end)

minetest.register_chatcommand("sit", {
	description = S("Sit down"),
	func = function(name) handle_action(minetest.get_player_by_name(name), name, "sit") end
})

minetest.register_chatcommand("lay", {
	description = S("Lay down"),
	func = function(name) handle_action(minetest.get_player_by_name(name), name, "lay") end
})]]


--[[local S = minetest.get_translator(minetest.get_current_modname())
local print_actions = minetest.settings:get_bool("vlf_cozy_print_actions") or false

local EYE_OFFSETS = {
	sit = {x = 0, y = -7, z = 2},
	lay = {x = 0, y = -13, z = -5},
	stand = {x = 0, y = 0, z = 0}
}

local vlf_cozy = {pos = {}}

local function print_action(name, kind)
	if print_actions then
		local actions = {sit = " sits", lay = " lies", stand = " stands up"}
		minetest.chat_send_all("* " .. name .. S(actions[kind]))
	end
end

local function actionbar_show_status(player, message)
	message = message or S("Move to stand up")
	if minetest.get_modpath("vlf_title") then
		vlf_title.set(player, "actionbar", {text = message, color = "white", stay = 60})
	else
		minetest.log("warning", "[vlf_cozy] No mod found to set titles in actionbar (vlf_title)!")
	end
end

local function stand_up(player, name)
	player:set_eye_offset(EYE_OFFSETS.stand, EYE_OFFSETS.stand)
	playerphysics.remove_physics_factor(player, "speed", "vlf_cozy:attached")
	playerphysics.remove_physics_factor(player, "jump", "vlf_cozy:attached")
	vlf_player.player_attached[name] = false
	vlf_player.player_set_animation(player, "stand", 30)
	vlf_cozy.pos[name] = nil
	print_action(name, "stand")
end

local function handle_player_movement(player, name)
	local controls = player:get_player_control()
	if vlf_player.player_attached[name] and not player:get_attach() and (controls.up or controls.down or controls.left or controls.right or controls.jump or controls.sneak) then
		stand_up(player, name)
	elseif minetest.get_node(vector.offset(player:get_pos(), 0, -1, 0)).name == "air" then
		player:set_eye_offset(EYE_OFFSETS.stand, EYE_OFFSETS.stand)
		playerphysics.remove_physics_factor(player, "speed", "vlf_cozy:attached")
		playerphysics.remove_physics_factor(player, "jump", "vlf_cozy:attached")
		vlf_player.player_attached[name] = false
		vlf_cozy.pos[name] = nil
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		handle_player_movement(player, player:get_player_name())
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	playerphysics.remove_physics_factor(player, "speed", "vlf_cozy:attached")
	playerphysics.remove_physics_factor(player, "jump", "vlf_cozy:attached")
	vlf_cozy.pos[name] = nil
end)

local function toggle_sit_or_lay(player, name, kind)
	local pos = player:get_pos()
	if vlf_playerinfo[name].node_stand_below.name == "air" then return end

	if vlf_player.player_attached[name] then
		stand_up(player, name)
	else
		for _, other_pos in pairs(vlf_cozy.pos) do
			if vector.distance(pos, other_pos) < 1 then
				actionbar_show_status(player, S("This spot is already occupied!"))
				return
			end
		end
		player:set_eye_offset(EYE_OFFSETS[kind], EYE_OFFSETS[kind])
		playerphysics.add_physics_factor(player, "speed", "vlf_cozy:attached", 0)
		playerphysics.add_physics_factor(player, "jump", "vlf_cozy:attached", 0)
		vlf_player.player_attached[name] = true
		vlf_player.player_set_animation(player, kind, kind == "sit" and 30 or 0)
		vlf_cozy.pos[name] = pos
		print_action(name, kind)
		actionbar_show_status(player)
	end
end

minetest.register_chatcommand("sit", {
	description = S("Sit down"),
	func = function(name) toggle_sit_or_lay(minetest.get_player_by_name(name), name, "sit") end
})

minetest.register_chatcommand("lay", {
	description = S("Lay down"),
	func = function(name) toggle_sit_or_lay(minetest.get_player_by_name(name), name, "lay") end
})]]

--[[local S = minetest.get_translator(minetest.get_current_modname())
local vlf_cozy_print_actions = minetest.settings:get_bool("vlf_cozy_print_actions") or false

local SIT_EYE_OFFSET = {x=0, y=-7,  z=2 }
local LAY_EYE_OFFSET = {x=0, y=-13, z=-5}

vlf_cozy = {}
vlf_cozy.pos = {}

-- functions
function vlf_cozy.print_action(name, kind)
	if not vlf_cozy_print_actions then return end
	local msg
	if kind == "sit" then
		msg = " sits"
	elseif kind == "lay" then
		msg = " lies"
	elseif kind == "stand" then
		msg = " stands up"
	end
	minetest.chat_send_all("* "..name..S(msg))
end

function vlf_cozy.actionbar_show_status(player, message)
	if not message then message = S("Move to stand up") end
	if minetest.get_modpath("vlf_title") then
		vlf_title.set(player, "actionbar", {text=message, color="white", stay=60})
	elseif minetest.get_modpath("vlf_tmp_message") then
		vlf_tmp_message.message(player, message)
	else
		minetest.log("warning", "[vlf_cozy] Didn't find any mod to set titles in actionbar (vlf_title or vlf_tmp_message)!")
	end
end

local function stand_up(player, name)
	player:set_eye_offset({x=0, y=0, z=0}, {x=0, y=0, z=0})
	playerphysics.remove_physics_factor(player, "speed", "vlf_cozy:attached")
	playerphysics.remove_physics_factor(player, "jump", "vlf_cozy:attached")
	vlf_player.player_attached[name] = false
	vlf_player.player_set_animation(player, "stand", 30)
	vlf_cozy.pos[name] = nil
	vlf_cozy.print_action(name, "stand")
end

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for i=1, #players do
		local name = players[i]:get_player_name()
		-- unmount when player tries to move
		if vlf_player.player_attached[name] and not players[i]:get_attach() and
			(players[i]:get_player_control().up == true or
			players[i]:get_player_control().down == true or
			players[i]:get_player_control().left == true or
			players[i]:get_player_control().right == true or
			players[i]:get_player_control().jump == true or
			players[i]:get_player_control().sneak == true) then
				stand_up(players[i], name)
		end
		-- check the node below player (and if it's air, just unmount)
		if minetest.get_node(vector.offset(players[i]:get_pos(),0,-1,0)).name == "air" then
			players[i]:set_eye_offset({x=0, y=0, z=0}, {x=0, y=0, z=0})
			playerphysics.remove_physics_factor(players[i], "speed", "vlf_cozy:attached")
			playerphysics.remove_physics_factor(players[i], "jump", "vlf_cozy:attached")
			vlf_player.player_attached[name] = false
			vlf_cozy.pos[name] = nil
		end
	end
end)

-- fix players getting stuck after they leave while still sitting
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	playerphysics.remove_physics_factor(player, "speed", "vlf_cozy:attached")
	playerphysics.remove_physics_factor(player, "jump", "vlf_cozy:attached")
	vlf_cozy.pos[name] = nil
end)

minetest.register_chatcommand("sit", {
	description = S("Sit down"),
	func = function(name)
		local player = minetest.get_player_by_name(name)
		local pos = player:get_pos()
		-- check the node below player (and if it's air, just don't sit)
		if vlf_playerinfo[name].node_stand_below.name == "air" then return end

		if vlf_player.player_attached[name] then stand_up(player, name)
		else
			-- check if occupied
			for _, other_pos in pairs(vlf_cozy.pos) do
				if vector.distance(pos, other_pos) < 1 then
					vlf_cozy.actionbar_show_status(player, S("This spot is already occupied!"))
					return
				end
			end
			player:set_eye_offset(SIT_EYE_OFFSET, SIT_EYE_OFFSET)
			playerphysics.add_physics_factor(player, "speed", "vlf_cozy:attached", 0)
			playerphysics.add_physics_factor(player, "jump", "vlf_cozy:attached", 0)
			vlf_player.player_attached[name] = true
			vlf_player.player_set_animation(player, "sit", 30)
			vlf_cozy.pos[name] = pos
			vlf_cozy.print_action(name, "sit")
			vlf_cozy.actionbar_show_status(player)
		end
	end
})

minetest.register_chatcommand("lay", {
	description = S("Lay down"),
	func = function(name)
		local player = minetest.get_player_by_name(name)
		local pos = player:get_pos()
		if vlf_playerinfo[name].node_stand_below.name == "air" then return end

		if vlf_player.player_attached[name] then stand_up(player, name)
		else
			-- check if occupied
			for _, other_pos in pairs(vlf_cozy.pos) do
				if vector.distance(pos, other_pos) < 1 then
					vlf_cozy.actionbar_show_status(player, S("This spot is already occupied!"))
					return
				end
			end
			player:set_eye_offset(LAY_EYE_OFFSET, LAY_EYE_OFFSET)
			playerphysics.add_physics_factor(player, "speed", "vlf_cozy:attached", 0)
			playerphysics.add_physics_factor(player, "jump", "vlf_cozy:attached", 0)
			vlf_player.player_attached[name] = true
			vlf_player.player_set_animation(player, "lay", 0)
			vlf_cozy.pos[name] = pos
			vlf_cozy.print_action(name, "lay")
			vlf_cozy.actionbar_show_status(player)
		end
	end
})
]]
