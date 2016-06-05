Cfg = {}
Cfg.__index = Cfg

function Cfg:update_spawner(config)
	if not config.types then config.types = {} end
	
	config.types["bob-biter-spawner"] = {
		weight = 20,
		min_distance = 2
	}
	
	config.types["bob-spitter-spawner"] = {
		weight = 10,
		min_distance = 2
	}
	
	return config
end

function Cfg:update_turret(config)
	if not config.types then config.types = {} end
	
	config.types["bob-big-explosive-worm-turret"] = {
		weight = 2,
		min_distance = 3,
	}
	config.types["bob-big-fire-worm-turret"] = {
		weight = 2,
		min_distance = 3,
	}
	config.types["bob-big-poison-worm-turret"] = {
		weight = 2,
		min_distance = 3,
	}
	return config
end


return Cfg