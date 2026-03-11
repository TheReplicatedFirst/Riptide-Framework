if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RiptideClient = ReplicatedStorage:WaitForChild("RiptideClient")
local Core = RiptideClient:WaitForChild("Core")
local ClientInitializerModule = Core:WaitForChild("ClientInitializer")

local ClientInitializer = require(ClientInitializerModule)

print("🌊 [Riptide] Booting Client...")
ClientInitializer.Init()
