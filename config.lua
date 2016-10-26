--require "defines"
require "util"

debug_enabled = true

local Logger_lib = require "libs/logger"
local logger = Logger_lib.new_logger("to_config.log")

if not to then to = {} end
if not to.config then to.config = {} end

to.config.straight_rail_count = 20
to.config.curved_rail_count = 20

to.config.resource_min = 175
to.config.resource_normal = 350
to.config.liquid_min = 500
to.config.liquid_normal = 5000

to.config.region_size = 7
to.config.resource_starting_area_size = {width = 64, height = 64}

to.config.enemy_protection_zone_by_starting_area = {
	["none"] = 0,
	["very-low"] = 200,			-- very-small
	["low"] = 400,				-- small
	["normal"] = 600,			-- medium
	["high"] = 800,				-- big
	["very-high"] = 1000,		-- very-big
}

to.config.generation_frequency = {
	["none"]		= 0,
	["very-low"]	= 0.35,
	["low"]			= 0.7,
	["normal"]		= 1,
	["high"]		= 2,
	["very-high"]	= 3,
}

to.config.generation_size = {
	["none"]		= 0,
	["very-low"]	= 0.35,
	["low"]		= 0.7,
	["normal"]		= 1,
	["high"]			= 1.5,
	["very-high"]	= 2,
}

to.config.generation_richness = {
	["very-low"]	= {min=150, max=350},
	["low"]		= {min=250, max=500},
	["normal"]		= {min=400, max=600},
	["high"]		= {min=600, max=800},
	["very-high"]	= {min=800, max=1000},
}

to.config.generation_richness_liquid = {
	["very-low"]	= {min=2500, max=4500},
	["low"]		= {min=3500, max=5500},
	["normal"]		= {min=4500, max=6500},
	["high"]		= {min=5500, max=7500},
	["very-high"]	= {min=6500, max=8500},
}

to.config.global_size_distance_factor = 1.35
to.config.global_richness_distance_factor = 1.01
to.config.global_spawn_probability = 0.15

to.config.global_enemy_size_distance_factor = 0.7
to.config.enemy_bases_per_region = 2

-- max_retries = 20
to.config.max_retries = 20



local base 		= require "modconfigs.base"
local bobores 	= require "modconfigs.bobores"
local bobenemies	= require "modconfigs.bobenemies"

function to.config.init_ore()
	to.config.resources_default = {
		size_base = 2,
		size_min = 2,
		size_max = 4,
		size_starting_min = 2,
		size_starting_max = 4,
		size_distance_adjust = 1,
		richness_distance_adjust = 1,
		probability_multiplier = 1,
		min_distance = 0,
	}

	if not to.config.resources then to.config.resources = {} end
	base:update_ores(to.config.resources)
	if game.entity_prototypes["tin-ore"] then bobores:update_ores(to.config.resources) end
end

function to.config.init_enemies()
	if not to.config.unit_spawner then to.config.unit_spawner = {} end
	if not to.config.turret then to.config.turret = {} end
	
	to.config.unit_spawner = base:update_spawner(to.config.unit_spawner)
	to.config.turret = base:update_turret(to.config.turret)
	
	if game.entity_prototypes["bob-biter-spawner"] then bobenemies:update_spawner(to.config.unit_spawner) end
	if game.entity_prototypes["bob-big-fire-worm-turret"] then bobenemies:update_turret(to.config.turret) end
end

-- TODO
-- allow for setting richness, min/max, frequency individually as well
-- remote function to re-read settings
-- setting to force-place resources upon unsuccessful find
-- make enemy.frequency have an effect
-- optional: make enemy.richness have an effect