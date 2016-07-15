Cfg = {}
Cfg.__index = Cfg

function Cfg:update_ores(config)
	config["iron-ore"] = {
		size_base = 3,
		size_min = 2,
		size_max = 5,
		size_starting_min = 3,
		size_starting_max = 6,
		size_distance_adjust = 1.1,
		richness_distance_adjust = 1,
		probability_multiplier = 1,
	}
	config["copper-ore"] = {
		size_base = 3,
		size_min = 2,
		size_max = 5,
		size_starting_min = 3,
		size_starting_max = 6,
		size_distance_adjust = 1.1,
		richness_distance_adjust = 1,
		probability_multiplier = 1,
	}
	config["coal"] = {
		size_base = 2,
		size_min = 2,
		size_max = 4,
		size_starting_min = 3,
		size_starting_max = 6,
		size_distance_adjust = 1,
		richness_distance_adjust = 1,
		probability_multiplier = 1,
	}
	config["stone"] = {
		size_base = 2,
		size_min = 1,
		size_max = 2,
		size_starting_min = 1,
		size_starting_max = 3,
		size_distance_adjust = 0.6,
		richness_distance_adjust = 1,
		probability_multiplier = 0.9,
	}
	config["crude-oil"] = {
		size_base = 0,
		size_min = 1,
		size_max = 2,
		size_starting_min = 1,
		size_starting_max = 3,
		size_distance_adjust = 0.7,
		richness_distance_adjust = 1.2,
		probability_multiplier = 1,
	}
	
	return config
end

function Cfg:update_spawner(config)
	config = {
		size_base = 1,
		size_min = 0,
		size_max = 2,
		size_distance_adjust = 0.9,
		default = {
			weight = 10,
			min_distance = 2
		},
		types = {
			["biter-spawner"] = {
				weight = 20,
				min_distance = 1
			},
			["spitter-spawner"] = {
				weight = 10,
				min_distance = 2
			},
		},
	}
	
	return config
end

function Cfg:update_turret(config)
	config = {
		size_base = 0,
		size_min = 0,
		size_max = 1,
		size_distance_adjust = 0.9,
		default = {
			weight = 10,
			min_distance = 2
		},
		types = {
			["small-worm-turret"] = {
				weight = 15,
				min_distance = 1
			},
			["medium-worm-turret"] = {
				weight = 10,
				min_distance = 2
			},
			["big-worm-turret"] = {
				weight = 5,
				min_distance = 3
			}
		},
	}
	
	return config
end

return Cfg