local ServerInitializer = {}
ServerInitializer._RiptideRef = nil

local loadedModules = {}

type Config = {
	ModulesFolder: Folder,
}

local function SetupNetwork()
	local sharedFolder = script.Parent.Parent.Parent:WaitForChild("shared")

	local folder = sharedFolder:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = sharedFolder

		local event = Instance.new("RemoteEvent")
		event.Name = "EventDispatcher"
		event.Parent = folder

		local func = Instance.new("RemoteFunction")
		func.Name = "FunctionDispatcher"
		func.Parent = folder

		print("🌊 [Riptide] Network Remotes Created")
	end
end

local function LoadModules(folder: Folder)
	local riptide = ServerInitializer._RiptideRef
	for _, instance in ipairs(folder:GetDescendants()) do
		if instance:IsA("ModuleScript") then
			local ok, module = pcall(require, instance)
			if ok and type(module) == "table" then
				riptide._modules[instance.Name] = module
				table.insert(loadedModules, {
					name = instance.Name,
					module = module,
				})
			else
				warn("[Server] Failed to load module: " .. instance.Name .. "\n" .. tostring(module))
			end
		end
	end
end

ServerInitializer.Launch = function(config: Config)
	if not config or not config.ModulesFolder then
		error("[Riptide] ServerInitializer.Launch requires a config table with a ModulesFolder.")
	end

	local riptide = ServerInitializer._RiptideRef
	if not riptide then
		error("[Riptide] ServerInitializer missing _RiptideRef. Ensure it's launched through the main Riptide module.")
	end

	print("🌊 [Riptide] Server Initialization Started...")

	SetupNetwork()

	LoadModules(config.ModulesFolder)

	for _, data in ipairs(loadedModules) do
		if type(data.module.Init) == "function" then
			local ok, err = pcall(data.module.Init, data.module, riptide)
			if not ok then
				warn(string.format("[Server] ❌ Error initializing %s: %s", data.name, tostring(err)))
			end
		end
	end

	for _, data in ipairs(loadedModules) do
		if type(data.module.Start) == "function" then
			task.spawn(function()
				local ok, err = pcall(data.module.Start, data.module, riptide)
				if not ok then
					warn(string.format("[Server] ❌ Error starting %s: %s", data.name, tostring(err)))
				end
			end)
		end
	end

	print("🌊 [Riptide] ✅ Server Ready.")
end

return ServerInitializer
