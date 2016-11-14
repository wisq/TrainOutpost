--require "defines"
require "config"

local Logger_lib = require "libs/logger"
local logger = Logger_lib.new_logger("to_debug.log")
local Polygon = require "libs/polygon"
local random_number = require "libs/randomlua"
local rng = {}

--- math shortcuts ---
local floor = math.floor
local ceil = math.ceil
local round = function(x) return floor(x + 0.5) end
local abs = math.abs
local cos = math.cos
local sin = math.sin
local pi = math.pi
local max = math.max

function players_print(message)
	for _,player in ipairs(game.players) do
		player.print(message)
	end
end

--- constants ---
local CHUNK_SIZE = 32
local REGION_TILE_SIZE = CHUNK_SIZE*to.config.region_size

--- conversions ---
function tile_to_chunk(tile_position)
	local chunk_x = floor(tile_position.x / CHUNK_SIZE)
	local chunk_y = floor(tile_position.y / CHUNK_SIZE)
	
	return {x=chunk_x, y=chunk_y}
end

function chunk_to_global_area(chunk_coordinates)
	local top_left = {x = chunk_coordinates.x * CHUNK_SIZE, y = chunk_coordinates.y * CHUNK_SIZE}
	
	return { {top_left.x, top_left.y}, {top_left.x + CHUNK_SIZE - 1, top_left.y + CHUNK_SIZE - 1} }
end

function tile_to_region(tile_position)
	local region_x = floor((tile_position.x - floor(REGION_TILE_SIZE/2)) / REGION_TILE_SIZE)
	local region_y = floor((tile_position.y - floor(REGION_TILE_SIZE/2)) / REGION_TILE_SIZE)
	
	return {x=region_x, y=region_y}
end

function region_position_to_global(region_coordinates, tile_within_region_position)
	local region_x_offset = region_coordinates.x * REGION_TILE_SIZE - floor(REGION_TILE_SIZE/2)
	local region_y_offset = region_coordinates.y * REGION_TILE_SIZE - floor(REGION_TILE_SIZE/2)
	
	return {x=region_x_offset + tile_within_region_position.x, y=region_y_offset + tile_within_region_position.y}
end

--- random functions ---
local function roll()
	-- global.times_rolled = global.times_rolled + 1
	-- return rng:random(0,100) / 100
	return math.random()
end

local function roll_min_max(min_value, max_value)
	-- global.times_rolled = global.times_rolled + 1
	-- return rng:random(min_value, max_value)
	return math.random(min_value, max_value)
end

local function roll_resource_amount(richness)
	return roll_min_max(richness.min, richness.max)
end

local function roll_position(max_x, max_y)
	-- global.times_rolled = global.times_rolled + 2
	-- return {x=rng:random(1, maxX + 1) - 1, y=rng:random(1, maxY + 1) - 1}
	return {x=math.random(1, max_x + 1) - 1, y=math.random(1, max_y + 1) - 1}
end

local function roll_region_position()
	return roll_position(REGION_TILE_SIZE, REGION_TILE_SIZE)
end

--- surface access ---
local function get_surface()
	return game.surfaces["nauvis"]
end



--- helper functions ---
local function dump_table(t)
	if not debug_enabled then return end
	if t == nil then 
		logger:log("trying to dump nil table")
		logger:dump()
		return
	end
	
	logger:log("---- table " .. tostring(t) .. "----")
	for k,v in pairs(t) do
		logger:log("k=" .. tostring(k) .. "; v=" .. tostring(v))
	end
	logger:dump()
end

local function copy_table(source, target)
	for k,v in pairs(source) do
		target[k] = v
	end
end

local function region_distance(region_position)
	return (region_position.x^2 + region_position.y^2)^0.5
end

local function placeingamedebugResource(tilePosition, name)
	get_surface().create_entity{name = name, position = tilePosition, amount = 20000}
end

local function place_ore_patch(global_position, resource, polygon, richness)
	for y = polygon:getMinY(), polygon:getMaxY() do
		for x = polygon:getMinX(), polygon:getMaxX() do
			if polygon:contains({x=x, y=y}) then
				get_surface().create_entity{
						name = resource,
						position = {x + global_position.x, y + global_position.y},	-- polygon is always in local coordinates
						amount = roll_resource_amount(richness)}
			end
		end
	end
end

local function ensure_chunk_is_generated(global_tile_position)
	if not (get_surface().is_chunk_generated(tile_to_chunk(global_tile_position))) then
		get_surface().request_to_generate_chunks(global_tile_position, 1)
	end
end

local function check_resource_position(global_position, resource)
	-- local generated = get_surface().is_chunk_generated(tile_to_chunk(global_position))
	-- if not generated then
		-- logger:log("check_resource_position [ " .. resource .. "] (" .. global_position.x .. ", " .. global_position.y .. "): chunk has not yet been generated")
		-- return true
	-- else 
		-- logger:log("check_resource_position [ " .. resource .. "] (" .. global_position.x .. ", " .. global_position.y .. "): " .. get_surface().get_tile(global_position.x, global_position.y).name)
	-- end
	
	return get_surface().can_place_entity{name = resource, position = global_position}
end

local function is_solid(resource_name)
	return game.entity_prototypes[resource_name] and 
		game.entity_prototypes[resource_name].resource_category == "basic-solid"
end

local function is_ore(resource_name)
	return is_solid(resource_name)
end

local function is_fluid(resource_name)
	return game.entity_prototypes[resource_name] and 
		game.entity_prototypes[resource_name].resource_category == "basic-fluid"
end

local function is_liquid(resource_name)
	return is_fluid(resource_name)
end

---########################## ENEMIES ################################---

-- spawns a bunch of enemies at the given position
-- parameter: global position to serve for the spawning
local function spawn_enemies_at_position(global_position)
	local region_coordinates = tile_to_region(global_position)

	local function check_distance(min_distance)
		return region_distance(tile_to_region(global_position)) > min_distance
	end

	local function determine_size(enemy_properties)
		local size_min = floor(enemy_properties.size_base + enemy_properties.size_min * to.config.global_enemy_size_distance_factor * enemy_properties.size_distance_adjust * region_distance(region_coordinates))
		local size_max = ceil(enemy_properties.size_base + enemy_properties.size_max * to.config.global_enemy_size_distance_factor * enemy_properties.size_distance_adjust * region_distance(region_coordinates))
		return roll_min_max(size_min, size_max) * global.to_enemies.generation_size
	end
	
	local function determine_kinds(enemy_properties, count, result)
		local draw_from_population_value = roll_min_max(1, #enemy_properties.weight_mapping)
		local enemy_to_spawn = enemy_properties.weight_mapping[draw_from_population_value]
		if check_distance(enemy_properties.types[enemy_to_spawn].min_distance) then
			result[#result+1] = enemy_to_spawn
		end
	end
	
	local function spawn_enemies(enemies)
		local spread = #enemies * 3
		for _,enemy in ipairs(enemies) do
			for try = 1, to.config.max_retries do -- try to find a position for the single enemy building
				local local_enemy_position = roll_position(spread, spread)
				local global_enemy_position = {x=global_position.x + local_enemy_position.x, 
											  y=global_position.y + local_enemy_position.y} -- translate local to global coordinates
				if check_resource_position(global_enemy_position, enemy) then
					get_surface().create_entity{name=enemy,
												position=global_enemy_position,
										 }
					break; -- stop trying, we were successful
				end
			end
		end
	end

	-- avoid crashing if Peace Mod is installed
	if not global.to_enemies.generation_size then
		logger:log("Peace Mod (or similar) detected, not spawning enemies")
		return
	end
	
	-- make sure we do not spawn anything in the starting area
	if 	global_position.x > global.enemy_protection_zone.x_min and
		global_position.x < global.enemy_protection_zone.x_max and
		global_position.y > global.enemy_protection_zone.y_min and
		global_position.y < global.enemy_protection_zone.y_max then
		return
	end
	
	local spawner_size = determine_size(global.to_enemies.unit_spawner)
	local turret_size = determine_size(global.to_enemies.turret)
	
	local enemies_to_spawn = {}
	determine_kinds(global.to_enemies.unit_spawner, spawner_size, enemies_to_spawn)
	determine_kinds(global.to_enemies.turret, turret_size, enemies_to_spawn)
	spawn_enemies(enemies_to_spawn)
end

-- spawns a bunch of enemies in the region
-- parameter: region coordinates of the current region
local function spawn_enemies_in_region(region_coordinates)
	for i = 1, to.config.enemy_bases_per_region do
		local global_position = region_position_to_global(region_coordinates, roll_region_position())
		spawn_enemies_at_position(global_position)
	end
end

---########################## RESOURCES ################################---

local function check_resource_polygon(global_position, polygon, resource)
	for y = polygon:getMinY(), polygon:getMaxY() do
		for x = polygon:getMinX(), polygon:getMaxX() do
			if polygon:contains({x=x, y=y}) then
				if not check_resource_position({x=global_position.x + x, y=global_position.y + y}, resource) then return false end
			end
		end
	end
	return true
end

local function generate_ore_patch_in_region(resource_name, resource_size, resource_richness, region_coordinates)
	local resource_polygon = Polygon.newCircular(roll_min_max, resource_size.min, resource_size.max)
	
	for i = 1, to.config.max_retries do
		local global_position = region_position_to_global(region_coordinates, roll_region_position())
		-- players_print("trying position " .. global_position.x .. "," .. global_position.y)
		if check_resource_polygon(global_position, resource_polygon, resource_name) then
			place_ore_patch(global_position, resource_name, resource_polygon, resource_richness)
			return global_position -- we were successful so break out of the loop and return
		end
	end
	return nil
end

local function generate_liquid_wells_in_region(resource_name, resource_size, resource_richness, region_coordinates)
	local rolled_size = roll_min_max(resource_size.min, resource_size.max)
	local spread = floor(rolled_size * 4) -- limit the possible positions to a certain area
	
	for i = 1, to.config.max_retries do	-- retry a number of times to find a suitable rectangle
		local failures = 0
		local rectangle_upper_left = region_position_to_global(region_coordinates, roll_region_position())
		
		for well = 1, rolled_size do
			local success = false -- keep track if we were successful
			for try = 1, to.config.max_retries do -- try to find a position for the single well
				local local_well_position = roll_position(spread, spread)
				local global_well_position = {x=rectangle_upper_left.x + local_well_position.x, 
											  y=rectangle_upper_left.y + local_well_position.y} -- translate local to global coordinates
				if check_resource_position(global_well_position, resource_name) then
					get_surface().create_entity{name=resource_name,
												position=global_well_position,
												amount=roll_resource_amount(resource_richness)}
					success = true
					break;
				end
			end
			-- if we could not place the resource after max_retries, register that
			if not success then
				failures = failures + 1
			end
		end
		
		-- if we failed too often, restart the whole generation
		if (failures > (rolled_size / 2) and i ~= to.config.max_retries) then
			for _,liquid in ipairs(get_surface().find_entities_filtered{ area = {rectangle_upper_left, {rectangle_upper_left.x+spread, rectangle_upper_left.y+spread}},
																   name = resource_name}) do
				liquid.destroy()
			end
		else
			-- we generated enough
			return rectangle_upper_left
		end
	end
	return nil
end


-- randomly determine the size of a specific resource patch
-- parameters: 	resource_name: the entity-name of the resource to generate
-- 				resource_specs: the specifications of the resource for which to determine the size
--				region_coordinates: the current region's coordinates
local function determine_resource_size(resource_name, resource_specs, region_coordinates)
	local size_min = floor((resource_specs.size_base + resource_specs.size_min * to.config.global_size_distance_factor * resource_specs.size_distance_adjust * region_distance(region_coordinates)) * resource_specs.generation_size)
	local size_max = ceil((resource_specs.size_base + resource_specs.size_max * to.config.global_size_distance_factor * resource_specs.size_distance_adjust * region_distance(region_coordinates)) * resource_specs.generation_size)
	
	-- return size_min, size_max
	return {min=size_min, max=size_max}
end

-- returns the lower and upper bound for the resource richness
-- parameters: 	resource_name: the entity-name of the resource to generate
--				resource_specs: the specifications of the resource for which to determine the richness bounds
--				region_coordinates: the current region's coordinates
local function determine_resource_richness(resource_name, resource_specs, region_coordinates)
	local richness_min = floor(resource_specs.generation_richness.min * to.config.global_richness_distance_factor * resource_specs.richness_distance_adjust * (1+region_distance(region_coordinates)/10))
	local richness_max = ceil(resource_specs.generation_richness.max * to.config.global_richness_distance_factor * resource_specs.richness_distance_adjust * (1+region_distance(region_coordinates)/10))
	
	return {min=richness_min, max=richness_max}
end

local function handle_single_resource_in_region(resource_name, resource_specs, region_coordinates)
	-- only handle resource if minimum distance is kept
	if region_distance(region_coordinates) < resource_specs.min_distance then
		return nil
	end
	
	-- check if this resource should be placed in the region
	absolute_probability = to.config.global_spawn_probability 
							* resource_specs.probability_multiplier 
							* resource_specs.generation_frequency
	if not (roll() <= absolute_probability) then return end
	
	local resource_size = determine_resource_size(resource_name, resource_specs, region_coordinates)
	local resource_richness = determine_resource_richness(resource_name, resource_specs, region_coordinates)
	
	if resource_size.max <= 0 then return end -- shortcut if size is 0
	
	if is_ore(resource_name) then
		return generate_ore_patch_in_region(resource_name, resource_size, resource_richness, region_coordinates)
	elseif is_liquid(resource_name) then
		return generate_liquid_wells_in_region(resource_name, resource_size, resource_richness, region_coordinates)
	end
end

---########################## REGIONS ################################---

-- loops through all configured resources
-- parameter: region coordinates of the current region
local function loop_resources_for_region(region_coordinates)
	for resource_name, resource_specs in pairs(global.to_resources) do
		local position = handle_single_resource_in_region(resource_name, resource_specs, region_coordinates)
		if position ~= nil then
			-- spawn_enemies_at_position(position)
		end
	end
end

-- check if this region is new; return true if this region is new
-- parameter: the region coordinates
local function check_new_region(region_coordinates)
	-- we keep track of treated regions in the global.regions 2d-table
	if global.regions[region_coordinates.x] and global.regions[region_coordinates.x][region_coordinates.y] then
		return false
	end
	return true
end

-- register the region so it is no longer treated as new
-- parameter: the region coordinates
local function register_new_region(region_coordinates)
	if not global.regions[region_coordinates.x] then global.regions[region_coordinates.x] = {} end
	global.regions[region_coordinates.x][region_coordinates.y] = true
end

-- coordination function for a region
-- parameter: the position of the tile that is part of a generated chunk
local function handle_region(tile_position)
	--in what region is this chunk?
	local region_coordinates = tile_to_region(tile_position)

	-- if we handled this region before, do not do so again
	if not check_new_region(region_coordinates) then return end
	-- and register the region
	register_new_region(region_coordinates)
	
	-- iterate all chunks and ensure they are there
	-- logger:log("starting forced chunk generation: [" .. region_coordinates.x .. "," .. region_coordinates.y .. "]")
	-- logger:dump()
	-- for x = 0, to.config.region_size do
		-- for y = 0, to.config.region_size do
			-- local tile_within_region_position = {x=x*CHUNK_SIZE, y=y*CHUNK_SIZE}
			-- ensure_chunk_is_generated(region_position_to_global(region_coordinates, tile_within_region_position))
		-- end
	-- end
	-- logger:log("done with forced chunk generation: [" .. region_coordinates.x .. "," .. region_coordinates.y .. "]")
	-- logger:dump()
	
	loop_resources_for_region(region_coordinates)
	spawn_enemies_in_region(region_coordinates)
end

---########################## INIT ################################---

-- initializes the random number generator
local function init_rng()
	-- rng = twister(global.map_gen_seed)
	
	-- pop a few numbers to avoid system specific non-randomess
	-- rng:random(0, 10)
	-- rng:random(0, 10)
	-- rng:random(0, 10)
	
	-- for n=1,global.times_rolled do 
		-- rng:random(0, 10)
	-- end
end

local function init_weights()
	local function create_weight_mapping(types)
		local total_weight = 0
		
		-- calculate total weight from all known types
		for enemy, enemy_specs in pairs(types) do
			total_weight = total_weight + enemy_specs.weight
		end
		
		-- now normalize and store in quick-access table
		local offset = 0
		weight_mapping = {}
		for enemy, enemy_specs in pairs(types) do
			local relative_weight = round(enemy_specs.weight / total_weight * 100)
			local index = 0
			while index <= relative_weight do
				index = index + 1
				weight_mapping[index + offset] = enemy
			end
			offset = offset + index
		end
		return weight_mapping
	end

	global.to_enemies.unit_spawner.weight_mapping = create_weight_mapping(global.to_enemies.unit_spawner.types)
	global.to_enemies.turret.weight_mapping = create_weight_mapping(global.to_enemies.turret.types)
end

-- reads the map settings and determines the generation size modification factor for each resource
-- parameter: the surface of the world, used to get access to the world generation settings
local function read_map_gen_settings(surface)
	for resource_name, autoplace_controls in pairs(surface.map_gen_settings.autoplace_controls) do
		-- is this a resource at all?
		if game.entity_prototypes[resource_name] and game.entity_prototypes[resource_name].type == "resource" then
			-- create empty resource entry
			global.to_resources[resource_name] = {}
			
			global.to_resources[resource_name].generation_frequency = to.config.generation_frequency[autoplace_controls.frequency]
			global.to_resources[resource_name].generation_size = to.config.generation_size[autoplace_controls.size]
			if game.entity_prototypes[resource_name].resource_category == "basic-fluid" then
				global.to_resources[resource_name].generation_richness = to.config.generation_richness_liquid[autoplace_controls.richness]
			else
				global.to_resources[resource_name].generation_richness = to.config.generation_richness[autoplace_controls.richness]
			end
		elseif resource_name == "enemy-base" then
			global.to_enemies.generation_frequency = to.config.generation_frequency[autoplace_controls.frequency]
			global.to_enemies.generation_size = to.config.generation_size[autoplace_controls.size]
			global.to_enemies.generation_richness = to.config.generation_richness[autoplace_controls.richness]
		end
	end
end

-- reads the configured settings for enemies and stores them in global enemy tables for convenicent access
local function read_enemy_settings()
	global.to_enemies.unit_spawner.size_base = to.config.unit_spawner.size_base
	global.to_enemies.unit_spawner.size_min = to.config.unit_spawner.size_min
	global.to_enemies.unit_spawner.size_max = to.config.unit_spawner.size_max
	global.to_enemies.unit_spawner.size_distance_adjust = to.config.unit_spawner.size_distance_adjust
	
	global.to_enemies.turret.size_base = to.config.turret.size_base
	global.to_enemies.turret.size_min = to.config.turret.size_min
	global.to_enemies.turret.size_max = to.config.turret.size_max
	global.to_enemies.turret.size_distance_adjust = to.config.turret.size_distance_adjust
	
	for entity, entity_specs in pairs(game.entity_prototypes) do
		if entity_specs.type == "unit-spawner" then
			-- create empty table to which we can copy
			global.to_enemies.unit_spawner.types[entity] = {}
			copy_table(to.config.unit_spawner.default, global.to_enemies.unit_spawner.types[entity])
			if to.config.unit_spawner.types[entity] then
				copy_table(to.config.unit_spawner.types[entity], global.to_enemies.unit_spawner.types[entity])
			end
		elseif entity_specs.type == "turret" then
			-- create empty table to which we can copy
			global.to_enemies.turret.types[entity] = {}

			copy_table(to.config.turret.default, global.to_enemies.turret.types[entity])
			if to.config.turret.types[entity] then
				copy_table(to.config.turret.types[entity], global.to_enemies.turret.types[entity])
			end
		end
	end
end

-- reads the configured settings and stores them in the global resource table for convenient access
local function read_resource_settings()
	for resource_name, _ in pairs(global.to_resources) do
		copy_table(to.config.resources_default, global.to_resources[resource_name])
		-- now copy any resource-specific settings and override
		if to.config.resources[resource_name] then
			copy_table(to.config.resources[resource_name], global.to_resources[resource_name])
		end
	end
end

-- convenience computation for the starting area
local function init_resource_starting_area()
	return {x_min = -to.config.resource_starting_area_size.width/2,
			x_max = to.config.resource_starting_area_size.width/2,
			y_min = -to.config.resource_starting_area_size.height/2,
			y_max = to.config.resource_starting_area_size.height/2 }
end

-- convenience computation for the area in which no enemies can be spawned
-- parameter: the surface of the world, used get access the world generation settings
local function init_enemy_protection_zone(surface)
	return {x_min = -to.config.enemy_protection_zone_by_starting_area[surface.map_gen_settings.starting_area]/2,
			y_min = -to.config.enemy_protection_zone_by_starting_area[surface.map_gen_settings.starting_area]/2,
			x_max = to.config.enemy_protection_zone_by_starting_area[surface.map_gen_settings.starting_area]/2,
			y_max = to.config.enemy_protection_zone_by_starting_area[surface.map_gen_settings.starting_area]/2}
end

-- guaranteed spawns in the starting area
-- parameter: the starting area in which to spawn the resources defined by a rectangle
local function spawn_starting_resources(resource_starting_area)
	-- if global.start_resources_spawned or game.tick > 3600 then return end -- starting resources already there or game was started without mod
	
	for resource_name, resource_specs in pairs(global.to_resources) do
		success = false -- loop as long as we have not successfully placed the resource
		if resource_specs.size_starting_max <= 0 then success = true end -- shortcut any resource with size 0
		while not success do
			global_position = {	x = roll_min_max(resource_starting_area.x_min, resource_starting_area.x_max),
								y = roll_min_max(resource_starting_area.y_min, resource_starting_area.y_max)}
			if (is_ore(resource_name)) then
				polygon = Polygon.newCircular(roll_min_max, resource_specs.size_starting_min, resource_specs.size_starting_max)
				if check_resource_polygon(global_position, polygon, resource_name) then
					place_ore_patch(global_position, resource_name, polygon, resource_specs.generation_richness) 
					success = true
				end
			elseif is_fluid(resource_name) then

				generate_liquid_wells_in_region(
							resource_name,
							{min=resource_specs.size_starting_min, max=resource_specs.size_starting_max},
							resource_specs.generation_richness,
							{x=0,y=0})
				success = true
			else
				logger:log(resource_name .. " is neither ore nor fluid, aborting...")
				logger:dump()
			end
		end
	end
	
	-- global.start_resources_spawned = true
	if not global.regions[0] then global.regions[0] = {} end
	global.regions[0][0] = true
end

-- coordinates the initialization
local function on_init()

	-- TODO move these to a general table-init function
	global.to_resources = {}
	global.to_enemies = {}
	global.to_enemies.unit_spawner = {}
	global.to_enemies.unit_spawner.types = {}
	global.to_enemies.turret = {}
	global.to_enemies.turret.types = {}

	to.config.init_ore()
	to.config.init_enemies()

	if not global.regions then global.regions = {} end
	-- if not global.times_rolled then global.times_rolled = 0 end
	if not global.map_gen_seed then global.map_gen_seed = get_surface().map_gen_settings.seed end
	global.enemy_protection_zone = init_enemy_protection_zone(get_surface())
	init_rng()
	
	-- read map generation settings to index resources
	read_map_gen_settings(get_surface())
	read_resource_settings()
	read_enemy_settings()
	init_weights()
	spawn_starting_resources(init_resource_starting_area())
end

-- coordinates what happens when the configuration changed (i.e. added a mod)
local function on_configuration_changed()
	-- check for any added resources
	read_map_gen_settings(get_surface())
end


---########################## EVENT HANDLERS ################################---

script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)

script.on_event(defines.events.on_chunk_generated, function(event)
	local tile_x = event.area.left_top.x
	local tile_y = event.area.left_top.y
	-- PlayerPrint("Generated chunk: x=" .. event.area.left_top.x .. " y=" .. event.area.left_top.y)
	-- place_ingamedebug_resource(tile_x, tile_y, "iron-ore")
	handle_region(event.area.left_top)
end)

remote.add_interface("TR", {
	config = function()
		players_print("config:")
		for k,v in pairs(to.config.resources) do
			players_print("k=" .. k .. "; v= " .. tostring(v))
		end
	end,
	test = function()
		if debug_enabled then
			-- for copper_x = 0, 1000*CHUNK_SIZE do
				-- get_surface().create_entity{name="copper-ore", position={copper_x, 0}}
				-- if get_surface().can_place_entity{name="coal", position={copper_x, 1}} then
					-- get_surface().create_entity{name="coal", position={copper_x, 1}}
				-- end
			-- end
		
			local x_offset = 16
			local y_offset = 16
			for x = 0, 1000 do
				local chunk_position = {x, 0}
				local tile_position = {x*CHUNK_SIZE+x_offset, y_offset}
				local generated = get_surface().is_chunk_generated(chunk_position)
				local can_place = get_surface().can_place_entity{name="iron-ore", position=tile_position}
				logger:log("chunk [" .. x .. ",0]: " .. tostring(generated) .. " | " .. tostring(can_place))
				for i = 0, CHUNK_SIZE do
					local pos = {x*CHUNK_SIZE + i, y_offset+2}
					if get_surface().can_place_entity{name="iron-ore", position=pos} then
						get_surface().create_entity{name="iron-ore", position=pos}
					end
				end
			end
			logger:dump()
		end
		game.player.print("done")
	end,
	weights = function()
		players_print("weights:")
		players_print("spawner:")
		dump_table(global.to_enemies.unit_spawner.weight_mapping)
		players_print("turret:")
		dump_table(global.to_enemies.turret.weight_mapping)
	end,
	reinit = function()
		to.config.init_ore()
		to.config.init_enemies()
		
		read_map_gen_settings(get_surface())
		read_resource_settings()
		read_enemy_settings()
		init_weights()
		players_print("done")
	end,
	updateoil = function(surface)
		for chunk in surface.get_chunks() do
			local resources = surface.find_entities_filtered{area = chunk_to_global_area(chunk),
														 type = "resource"}
			for _,resource in ipairs(resources) do
				if to.config.resources[resource.name].type == "resource-liquid" then
					
					local region_coords = tile_to_region(resource.position)
					local richness = determine_resource_richness(resource.name, to.config.resources[resource.name], region_coords)
					resource.amount = roll_resource_amount(richness)
					
					players_print("set amount to " .. resource.amount)
				end
			end
		end
	end,
})