--require "defines"

local Logger = {prefix='log_'}
Logger.__index = Logger

function Logger:log(message)
  local run_time_seconds = math.floor(game.tick/60)
  local run_time_minutes = math.floor(run_time_seconds/60)
  local run_time_hours = math.floor(run_time_minutes/60)
  self.log_buffer[#self.log_buffer + 1] = string.format("%02d:%02d:%02d: %s\n", run_time_hours, run_time_minutes % 60, run_time_seconds % 60, message)
end

function Logger:dump()
	if #self.log_buffer == 0 then return false end
	game.write_file(self.filename, table.concat(self.log_buffer))
	return true
end

function Logger:clear()
	self.log_buffer = {}
end


function Logger.new_logger(filename)
	local filename = filename or "mod.log"
	local new_logger = {log_buffer = {}, filename = filename}
	setmetatable(new_logger, Logger)

	return new_logger
end

return Logger