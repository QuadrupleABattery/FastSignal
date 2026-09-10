--!strict

local freeThreads : {thread} = {}

local Signal = {}
local Connection = {}

type Signal<T...> = {
	_head : LinkNode,
	_tail : LinkNode,
	_size : number,
	Connect : (self : Signal<T...>, Callback<T...>) -> Connection,
	DisconnectAll : (self : Signal<T...>) -> (),
	Fire : (self : Signal<T...>, T...) -> (),
}

type Connection = {
	_signal : Signal<any>,
	_node : LinkNode,
	Disconnect : (self : Connection) -> (),
}

type LinkNode = {
	_previous : LinkNode?,
	_next : LinkNode?,
	_connection : Connection?,
	_fn : Callback<any>,
}

type Callback<T...> = (T...) -> ()

local function runCallback<T...>(thread : thread, callback : Callback<T...>, ... : T...) : ()
	callback(...)
	table.insert(freeThreads, thread)
end

local function threadFunction<T...>() : ()
	while true do
		runCallback(coroutine.yield())
	end
end

function Connection.new(signal : Signal<any>, node : LinkNode) : Connection
	return setmetatable({
		_signal = signal,
		_node = node,
		Disconnect = Connection.Disconnect,
	}, Connection)
end

function Signal.new<T...>() : Signal<T...>
	local node = {} :: LinkNode
	
	return {
		_head = node,
		_tail = node,
		_size = 1,
		Connect = Signal.Connect,
		DisconnectAll = Signal.DisconnectAll,
		Fire = Signal.Fire,
	}
end

function Signal.Connect<T...>(self : Signal<T...>, callback : Callback<T...>) : Connection
	local node : LinkNode
	
	if self._head._connection == nil then
		self._head._fn = callback
		node = self._head
	else
		local newNode: LinkNode = {
			_previous = self._tail,
			_fn = callback,
		}
		
		newNode._previous = self._tail
		
		self._tail._next = newNode
		self._tail = newNode
		
		node = newNode
		
		self._size += 1
	end
	
	local connection = {
		_signal = self,
		_node = node,
		Disconnect = Connection.Disconnect,
	}
	
	node._connection = connection
	return connection
end

@native function Signal.Fire<T...>(self : Signal<T...>, ... : T...) : ()
	local node = self._head
	
	if node._connection == nil then
		return
	end
	
	for _ = 1, self._size do
		local freeThread : thread? = nil
		local length = #freeThreads

		freeThread = freeThreads[length]

		if freeThread == nil then
			freeThread = task.spawn(threadFunction)
		else
			freeThreads[length] = nil
		end

		coroutine.resume(freeThread, freeThread, node._fn, ...)

		node = node._next
	end
	
	return
end

function Signal.DisconnectAll<T...>(self : Signal<T...>) : ()
	local node = {
		_fn = function() end,
		_connection = {} :: Connection,
	} :: LinkNode
	
	self._head = node
	self._tail = node
	self._size = 1
	
	return
end

function Connection.Disconnect(self : Connection) : ()
	local signal = self._signal
	local node : LinkNode = self._node
	
	local nextNode = node._next
	local prevNode = node._previous
	
	if nextNode ~= nil then
		nextNode._previous = prevNode
	end
	
	if prevNode then
		prevNode._next = nextNode
	elseif signal._head == node then
		if nextNode ~= nil then
			signal._head = nextNode
			table.clear(node)
		else
			node._connection = nil
			node._next = nil
		end
	end
	
	signal._size -= 1

	return
end

return Signal
