```text
    ____  _       __  _     __   
   / __ \(_)___  / /_(_)___/ /__ 
  / /_/ / / __ \/ __/ / __  / _ \
 / _, _/ / /_/ / /_/ / /_/ /  __/
/_/ |_/_/ .___/\__/_/\__,_/\___/ 
       /_/                       
```

# 🌊 Riptide Framework

Riptide is a lightweight, strictly-typed, and modular Roblox framework built for Wally. It features phased initialization, safe dependency injection, and a robust unified networking layer.

## 📦 Installation (Wally)

Add Riptide to your `wally.toml`:
```toml
[dependencies]
Riptide = "thereplicatedfirst/riptide@^0.1.0"
```

## 🏁 How to Start

Riptide does not start automatically. You must launch the framework from your own Server and Client entry points.

### Server Initialization (`main.server.lua`)
```lua
local Riptide = require(ReplicatedStorage.Packages.Riptide)
local MyServerModules = ServerScriptService:WaitForChild("MyServerModules")

Riptide.Server.Launch({
    ModulesFolder = MyServerModules
})
```

### Client Initialization (`main.client.lua`)
```lua
local Riptide = require(ReplicatedStorage.Packages.Riptide)
local MyClientModules = ReplicatedStorage:WaitForChild("MyClientModules")

Riptide.Client.Launch({
    ModulesFolder = MyClientModules
})
```

## 🚀 Module Lifecycle & Dependency Injection (DI)

Riptide completely eliminates the need for `require()` circles. Any `ModuleScript` inside your designated `ModulesFolder` will be automatically loaded into the Riptide Registry.

> [!NOTE]
> Services and Controllers are registered by their `ModuleScript` name.

Methods are executed in strict phases:
1. **`Init(Riptide)`**: Called synchronously. Use this to `GetService` or `GetController` and set up your variables.
2. **`Start(Riptide)`**: Called asynchronously via `task.spawn`. All modules are fully initialized at this point, so it is safe to interact with them and run game logic.

### Example DI Module
```lua
--!strict
local RiptidePkg = require(ReplicatedStorage.Packages.Riptide)
type Riptide = RiptidePkg.Riptide

local PlayerState = {}

function PlayerState:Init(Riptide: Riptide)
    -- Easily inject other modules
    self.DataService = Riptide.GetService("DataService")
    
    -- Listen to the unified Network layer
    Riptide.Network.Register("PlayerJumped", function(player, height)
        print(player.Name .. " jumped " .. height .. " studs!")
    end)
end

function PlayerState:Start(Riptide: Riptide)
    self.DataService:GiveMoney(100)
end

return PlayerState
```

## 📡 Networking (`Riptide.Network`)

Riptide automatically creates a single RemoteEvent and RemoteFunction inside its own package under the hood. No `ReplicatedStorage` clutter!

**Client-Side API**
- `Network.Register(name, callback)`: Listen for server events.
- `Network.FireServer(name, ...)`: Send event data to the server.
- `Network.InvokeServer(name, ...)`: Request data from the server.

**Server-Side API**
- `Network.Register(name, callback)`: Listen for client events. Callback automatically receives `player` as the first argument.
- `Network.FireClient(player, name, ...)`: Send event data to a specific player.
- `Network.FireAllClients(name, ...)`: Broadcast event data to everyone.
- `Network.InvokeClient(player, name, ...)`: Request data from a client.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.