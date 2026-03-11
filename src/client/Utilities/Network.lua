--!strict
-- RiptideClient/Utilities/Network.lua
-- Client Network Manager

local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Callback = (...any) -> any
type HandlerMap = { [string]: { Callback } }

export type NetworkClient = {
	Register: (funcName: string, callback: Callback) -> (),
	Unregister: (funcName: string, callback: Callback) -> (),
	FireServer: (funcName: string, ...any) -> (),
	InvokeServer: (funcName: string, ...any) -> any,
}

local Shared = ReplicatedStorage:WaitForChild("RiptideShared")
local Remotes = Shared:WaitForChild("RiptideRemotes")
local EventDispatcher = Remotes:WaitForChild("EventDispatcher") :: RemoteEvent
local FunctionDispatcher = Remotes:WaitForChild("FunctionDispatcher") :: RemoteFunction

local ClientHandlers: HandlerMap = {}

EventDispatcher.OnClientEvent:Connect(function(funcName: string, ...: any)
	local handlers = ClientHandlers[funcName]

	if handlers then
		for _, handler in ipairs(handlers) do
			task.spawn(handler, ...)
		end
	end
end)

FunctionDispatcher.OnClientInvoke = function(funcName: string, ...: any): any
	local handlers = ClientHandlers[funcName]

	if handlers and handlers[1] then
		-- A function should ideally only have one handler
		if #handlers > 1 then
			warn(
				string.format(
					"[NetworkClient] Multiple handlers registered for invoke '%s'. Only the first will be called.",
					funcName
				)
			)
		end

		return handlers[1](...)
	end

	warn(string.format("[NetworkClient] Received invoke '%s' but no handler is registered.", funcName))
	return nil
end

local Network: NetworkClient = {
	Register = function(funcName: string, callback: Callback)
		if not ClientHandlers[funcName] then
			ClientHandlers[funcName] = {}
		end

		table.insert(ClientHandlers[funcName], callback)
	end,

	Unregister = function(funcName: string, callback: Callback)
		local handlers = ClientHandlers[funcName]
		if handlers then
			for i, handler in ipairs(handlers) do
				if handler == callback then
					table.remove(handlers, i)
					break
				end
			end
		end
	end,

	FireServer = function(funcName: string, ...: any)
		EventDispatcher:FireServer(funcName, ...)
	end,

	InvokeServer = function(funcName: string, ...: any): any
		return FunctionDispatcher:InvokeServer(funcName, ...)
	end,
}

return Network
