```text
    ____  _       __  _     __   
   / __ \(_)___  / /_(_)___/ /__ 
  / /_/ / / __ \/ __/ / __  / _ \
 / _, _/ / /_/ / /_/ / /_/ /  __/
/_/ |_/_/ .___/\__/_/\__,_/\___/ 
       /_/                       
```

# 🌊 Riptide Framework

Riptide is a modern, modular Roblox framework supporting phased initialization and unified networking.

## 📂 Project Structure

- **`src/`**
  - **`client/`** → Maps to `ReplicatedStorage.RiptideClient`
    - `Core/ClientInitializer` → Main client-side engine.
    - `Modules/` → Place your client modules here. Auto-loaded recursively.
    - `Utilities/Network` → Client networking (Register, FireServer, etc.).
  - **`server/`** → Maps to `ServerStorage.RiptideServer`
    - `Core/ServerInitializer` → Main server-side engine.
    - `Modules/` → Place your server modules here. Auto-loaded recursively.
    - `Utilities/Network` → Server networking (FireClient, Register, etc.).
  - **`shared/`** → Maps to `ReplicatedStorage.RiptideShared`
    - `RiptideRemotes/` → Folder automatically created by the server for networking.

## 🏁 How to Start
To start the framework in your project, simply require the initializers in your own launcher scripts.
- **Client**: `require(ReplicatedStorage.RiptideClient.Core.ClientInitializer).Init()` (Put this in a `LocalScript` inside `StarterPlayerScripts`)
- **Server**: `require(ServerStorage.RiptideServer.Core.ServerInitializer).Init()` (Put this in a `Script` inside `ServerScriptService`)

## 🚀 Module Lifecycle

Modules in the `Modules/` folder are automatically loaded. You can define two optional methods:

1. **`Init()`**: Called synchronously during the first phase. Use this for variable setup, internal events, and state.
2. **`Start()`**: Called using `task.spawn` in the second phase. Safe to interact with other initialized modules.

```lua
local MyModule = {}

function MyModule.Init()
    print("Module initialized!")
end

function MyModule.Start()
    print("Module started!")
end

return MyModule
```

## 📡 Networking (`Network.lua`)

### Client-Side
- `Network.Register(name, callback)`: Listen for server events.
- `Network.FireServer(name, ...)`: Send event to server.
- `Network.InvokeServer(name, ...)`: Request data from server.

### Server-Side
- `Network.Register(name, callback)`: Listen for client events. Callback gets `player` as first argument.
- `Network.FireClient(player, name, ...)`: Send event to specific player.
- `Network.FireAllClients(name, ...)`: Send event to everyone.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.