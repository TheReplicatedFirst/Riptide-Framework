--!strict
-- Riptide/Utilities/Async.lua
-- Wrapper for yielding functions with timeout constraints

export type AsyncModule = {
	Run: (fn: (...any) -> ...any, timeout: number, ...any) -> ...any,
}

local Async = {}

--[[
	Executes a function and waits for it to finish. 
	If `timeout` seconds pass before the function finishes, it returns `fallback`.
	
	@param fn The yielding function to execute.
	@param timeout The maximum duration to wait (in seconds).
	@param fallback The value(s) to return if the execution times out.
]]
function Async.Run(fn: (...any) -> ...any, timeout: number, ...: any): ...any
	local thread = coroutine.running()
	local isFinished = false
	local isTimedOut = false

	local fallbackArgs = { ... }

	-- Run the target function asynchronously
	task.spawn(function()
		local results = { pcall(fn) }
		
		if isTimedOut then
			-- The parent thread has already resumed and returned the fallback. 
			-- We don't want to double resume or emit unhandled errors.
			return
		end
		
		isFinished = true
		local success = table.remove(results, 1)

		if success then
			task.spawn(thread, true, table.unpack(results))
		else
			task.spawn(thread, false, results[1])
		end
	end)

	-- Run the timeout watcher
	task.delay(timeout, function()
		if not isFinished then
			isTimedOut = true
			isFinished = true
			task.spawn(thread, true, table.unpack(fallbackArgs))
		end
	end)

	local ok, result = coroutine.yield()
	if not ok then
		-- Only throw underlying errors if the function failed before timing out
		error(tostring(result), 2)
	end

	return result
end

return Async :: AsyncModule
