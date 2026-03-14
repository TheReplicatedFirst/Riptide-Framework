--!strict
-- RiptideClient/Core/ComponentService.lua
-- A unified manager for Roblox CollectionService component objects

local CollectionService = game:GetService("CollectionService")

export type ComponentClass = {
	new: (instance: Instance) -> any,
	Destroy: ((self: any) -> ())?,
}

export type ComponentServiceAPI = {
	_registry: { [Instance]: { [string]: any } },
	Get: (self: ComponentServiceAPI, instance: Instance) -> any?,
	_start: (self: ComponentServiceAPI, componentsFolder: Folder) -> (),
}

local ComponentService = {} :: ComponentServiceAPI

-- Using a Weak Table dictionary so that destroyed Instances don't memory leak their component wrappers.
-- Key = Instance, Value = Dictionary mapping mapping TagNames to Component wrappers
ComponentService._registry = setmetatable({}, { __mode = "k" }) :: { [Instance]: { [string]: any } }

--[[
	Attempts to retrieve a registered Component wrapper attached to a specific instance.
	@param instance The Roblox instance referencing the original Tag
]]
function ComponentService:Get(instance: Instance): any?
	local components = self._registry[instance]
	if components then
		-- Return the first component we find, or we could extend this to `GetAll`
		for _, componentObj in pairs(components) do
			return componentObj
		end
	end
	return nil
end

function ComponentService:_start(componentsFolder: Folder)
	for _, moduleScript in ipairs(componentsFolder:GetDescendants()) do
		if moduleScript:IsA("ModuleScript") then
			local tagName = moduleScript.Name
			local ok, ComponentClass = pcall(require, moduleScript)
			
			if not ok or type(ComponentClass) ~= "table" then
				warn(string.format("[ComponentService] Failed to load component '%s':\n%s", tagName, tostring(ComponentClass)))
				continue
			end

			-- Safety check for 'new'
			if type(ComponentClass.new) ~= "function" then
				warn(string.format("[ComponentService] Skipping component '%s': missing 'new(instance)' constructor.", tagName))
				continue
			end

			-- Bind to CollectionService added signals
			CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance: Instance)
				local success, result = pcall(function()
					return ComponentClass.new(instance)
				end)

				if success and result then
					if not self._registry[instance] then
						self._registry[instance] = {}
					end
					self._registry[instance][tagName] = result
				else
					warn(string.format("[ComponentService] Failed to initialize instance of '%s':\n%s", tagName, tostring(result)))
				end
			end)

			-- Bind to CollectionService removed signals
			CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance: Instance)
				local components = self._registry[instance]
				if components then
					local componentObj = components[tagName]
					if componentObj then
						if type(componentObj.Destroy) == "function" then
							pcall(componentObj.Destroy, componentObj)
						end
						components[tagName] = nil
					end
				end
			end)

			-- Find any instances that already exist in the world right now
			for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
				local success, result = pcall(function()
					return ComponentClass.new(instance)
				end)

				if success and result then
					if not self._registry[instance] then
						self._registry[instance] = {}
					end
					self._registry[instance][tagName] = result
				else
					warn(string.format("[ComponentService] Failed to initialize pre-existing instance of '%s':\n%s", tagName, tostring(result)))
				end
			end
		end
	end
end

return ComponentService
