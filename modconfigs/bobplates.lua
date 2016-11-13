Cfg = {}
Cfg.__index = Cfg

function Cfg:update_ores(config)
        -- just copying the crude-oil config
	config["ground-water"] = {
		size_base = 0,
		size_min = 1,
		size_max = 2,
		size_starting_min = 1,
		size_starting_max = 3,
		size_distance_adjust = 0.7,
		richness_distance_adjust = 1.2,
		probability_multiplier = 1,
	}
	config["lithia-water"] = {
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
