Cfg = {}
Cfg.__index = Cfg

function Cfg:update_ores(config)
	config["bauxite-ore"] = {
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 2,
	}
	config["cobalt-ore"] = {
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 2,
	}
	config["gem-ore"] = {
		size_base = 1,
		size_min = 1,
		size_max = 2,
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 3,
		probability_multiplier = 0.65,
	}
	config["gold-ore"] = {
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 1,
	}
	config["lead-ore"] = {
		size_base = 2,
		size_min = 1,
		size_max = 4,
		size_starting_min = 1,
		size_starting_max = 3,
		size_distance_adjust = 1.1,
	}
	config["nickel-ore"] = {
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 1,
	}
	config["quartz"] = {
		size_base = 2,
		size_min = 1,
		size_max = 4,
		size_starting_min = 1,
		size_starting_max = 3,
		size_distance_adjust = 1.1,
	}
	config["rutile-ore"] = {
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 1,
		probability_multiplier = 1.1,
	}
	config["silver-ore"] = {
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 1,
		probability_multiplier = 1.1,
	}
	config["sulfur"] = {
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 1,
		probability_multiplier = 0.8,
	}
	config["tin-ore"] = {
		size_base = 2,
		size_min = 1,
		size_max = 4,
		size_starting_min = 1,
		size_starting_max = 3,
		size_distance_adjust = 1.1,
	}
	config["tungsten-ore"] = {
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 1,
		probability_multiplier = 1.05,
	}
	config["zinc-ore"] = {
		size_starting_min = 0,
		size_starting_max = 0,
		min_distance = 1,
		probability_multiplier = 1.2,
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


return Cfg