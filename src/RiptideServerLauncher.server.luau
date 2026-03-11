local ServerStorage = game:GetService("ServerStorage")
local ServerInitializer = require(ServerStorage:WaitForChild("RiptideServer").Core.ServerInitializer)

print("🌊 [Riptide] Server Booting...")

ServerInitializer.Init()
