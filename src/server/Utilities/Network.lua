--!strict
-- RiptideServer/Utilities/Network.lua
-- Server Network Manager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

type Callback = (player: Player, ...any) -> any
type HandlerMap = { [string]: { Callback } }

export type NetworkServer = {
	Register: (funcName: string, callback: Callback) -> (),
	Unregister: (funcName: string, callback: Callback) -> (),
	FireClient: (player: Player, funcName: string, ...any) -> (),
	FireAllClients: (funcName: string, ...any) -> (),
	InvokeClient: (player: Player, funcName: string, ...any) -> any,
}

local Shared = ReplicatedStorage:WaitForChild("RiptideShared")
local Remotes = Shared:WaitForChild("RiptideRemotes")
local EventDispatcher = Remotes:WaitForChild("EventDispatcher") :: RemoteEvent
local FunctionDispatcher = Remotes:WaitForChild("FunctionDispatcher") :: RemoteFunction

local ServerHandlers: HandlerMap = {}

EventDispatcher.OnServerEvent:Connect(function(player: Player, funcName: string, ...: any)
	local handlers = ServerHandlers[funcName]

	if handlers then
		for _, handler in ipairs(handlers) do
			task.spawn(handler, player, ...)
		end
	end
end)

FunctionDispatcher.OnServerInvoke = function(player: Player, funcName: string, ...: any): any
	local handlers = ServerHandlers[funcName]

	if handlers and handlers[1] then
		-- A function should ideally only have one handler
		if #handlers > 1 then
			warn(
				string.format(
					"[NetworkServer] Multiple handlers registered for invoke '%s'. Only the first will be called.",
					funcName
				)
			)
		end

		return handlers[1](player, ...)
	end

	warn(string.format("[NetworkServer] Received invoke '%s' but no handler is registered.", funcName))
	return nil
end

local Network: NetworkServer = {
	Register = function(funcName: string, callback: Callback)
		if not ServerHandlers[funcName] then
			ServerHandlers[funcName] = {}
		end

		table.insert(ServerHandlers[funcName], callback)
	end,

	Unregister = function(funcName: string, callback: Callback)
		local handlers = ServerHandlers[funcName]
		if handlers then
			for i, handler in ipairs(handlers) do
				if handler == callback then
					table.remove(handlers, i)
					break
				end
			end
		end
	end,

	FireClient = function(player: Player, funcName: string, ...: any)
		EventDispatcher:FireClient(player, funcName, ...)
	end,

	FireAllClients = function(funcName: string, ...: any)
		EventDispatcher:FireAllClients(funcName, ...)
	end,

	InvokeClient = function(player: Player, funcName: string, ...: any): any
		return FunctionDispatcher:InvokeClient(player, funcName, ...)
	end,
}

return Network
