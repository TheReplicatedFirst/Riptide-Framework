--!strict
-- Riptide/Utilities/Signal.lua
-- A fast, custom Signal implementation

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
	_signal: Signal,
	_fn: (...any) -> (),
	_next: Connection?,
}

export type Signal = {
	_head: Connection?,
	Connect: (self: Signal, fn: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	Wait: (self: Signal) -> ...any,
	DisconnectAll: (self: Signal) -> (),
}

local Connection = {}
Connection.__index = Connection

function Connection.new(signal: Signal, fn: (...any) -> ()): Connection
	local self = setmetatable({
		Connected = true,
		_signal = signal,
		_fn = fn,
		_next = nil :: Connection?,
	}, Connection)
	return (self :: any) :: Connection
end

function Connection:Disconnect()
	if not self.Connected then return end
	self.Connected = false

	if self._signal._head == self then
		self._signal._head = self._next
	else
		local curr = self._signal._head
		while curr and curr._next ~= self do
			curr = curr._next
		end
		if curr then
			curr._next = self._next
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new(): Signal
	local self = setmetatable({
		_head = nil,
	}, Signal)
	return (self :: any) :: Signal
end

function Signal:Connect(fn: (...any) -> ()): Connection
	local connection = Connection.new(self, fn)
	if self._head then
		connection._next = self._head
	end
	self._head = connection
	return connection
end

function Signal:Fire(...: any)
	local curr = self._head
	while curr do
		local nextConn = curr._next
		if curr.Connected then
			-- Spawn prevents one yielding connection from blocking the rest
			task.spawn(curr._fn, ...)
		end
		curr = nextConn
	end
end

function Signal:Wait(): ...any
	local thread = coroutine.running()
	local connection: Connection

	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

function Signal:DisconnectAll()
	local curr = self._head
	while curr do
		curr.Connected = false
		curr = curr._next
	end
	(self :: any)._head = nil
end

return Signal
