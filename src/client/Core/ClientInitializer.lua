-- RiptideClient/Core/ClientInitializer.lua
local ClientInitializer = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RiptideClient = ReplicatedStorage:WaitForChild("RiptideClient")

local Core = RiptideClient:WaitForChild("Core")
local ModulesFolder = RiptideClient:WaitForChild("Modules")
local Utilities = RiptideClient:WaitForChild("Utilities")

local loadedModules = {}

local function LoadModules(folder)
	for _, instance in ipairs(folder:GetDescendants()) do
		if instance:IsA("ModuleScript") then
			local ok, module = pcall(require, instance)
			if ok and type(module) == "table" then
				table.insert(loadedModules, {
					name = instance.Name,
					module = module,
				})
			else
				warn("[Client] Failed to load module: " .. instance.Name .. "\n" .. tostring(module))
			end
		end
	end
end

ClientInitializer.Init = function()
	print("[Client] Initialization started...")

	-- 1. LOAD PHASE
	LoadModules(ModulesFolder)

	-- 2. INIT PHASE
	-- Execute Init methods synchronously.
	for _, data in ipairs(loadedModules) do
		if type(data.module.Init) == "function" then
			-- Wrap in pcall to prevent one module's error from breaking the framework
			local start = tick()
			local ok, err = pcall(data.module.Init)
			if not ok then
				warn(string.format("[Client] ❌ Error initializing %s: %s", data.name, tostring(err)))
			end
		end
	end

	-- 3. START PHASE
	-- Modules are now initialized and can safely interact with each other.
	for _, data in ipairs(loadedModules) do
		if type(data.module.Start) == "function" then
			task.spawn(function()
				local start = tick()
				local ok, err = pcall(data.module.Start)
				if not ok then
					warn(string.format("[Client] ❌ Error starting %s: %s", data.name, tostring(err)))
				end
			end)
		end
	end

	-- 4. FINALIZE
	-- Notify the server that the client framework is fully loaded
	-- Network.FireServer("FrameworkCompleted")

	print("[Client] ✅ Initialization completed.")
end

return ClientInitializer
