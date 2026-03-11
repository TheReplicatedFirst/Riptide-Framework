local ServerInitializer = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RiptideServer = ServerStorage:WaitForChild("RiptideServer")
local ModulesFolder = RiptideServer:WaitForChild("Modules")

local loadedModules = {}

local function SetupNetwork()
	local sharedFolder = ReplicatedStorage:FindFirstChild("RiptideShared")
	if not sharedFolder then
		sharedFolder = Instance.new("Folder")
		sharedFolder.Name = "RiptideShared"
		sharedFolder.Parent = ReplicatedStorage
	end

	local folder = sharedFolder:FindFirstChild("RiptideRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RiptideRemotes"
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
				warn("[Server] Failed to load module: " .. instance.Name .. "\n" .. tostring(module))
			end
		end
	end
end

ServerInitializer.Init = function()
	print("🌊 [Riptide] Server Initialization Started...")

	SetupNetwork()

	LoadModules(ModulesFolder)

	for _, data in ipairs(loadedModules) do
		if type(data.module.Init) == "function" then
			local ok, err = pcall(data.module.Init)
			if not ok then
				warn(string.format("[Server] ❌ Error initializing %s: %s", data.name, tostring(err)))
			end
		end
	end

	for _, data in ipairs(loadedModules) do
		if type(data.module.Start) == "function" then
			task.spawn(data.module.Start)
		end
	end

	print("🌊 [Riptide] ✅ Server Ready.")
end

return ServerInitializer
