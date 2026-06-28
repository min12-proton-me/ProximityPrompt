local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local prompts = {}

local function registerPrompt(prompt)
	if not prompts[prompt] then
		prompts[prompt] = true
	end
end

local function unregisterPrompt(prompt)
	prompts[prompt] = nil
end

local function findBasePart(prompt)
	local parent = prompt.Parent
	while parent do
		if parent:IsA("BasePart") then
			return parent
		end
		parent = parent.Parent
	end

	local function searchDown(obj)
		for _, child in ipairs(obj:GetChildren()) do
			if child:IsA("BasePart") then
				return child
			end
			local found = searchDown(child)
			if found then
				return found
			end
		end
		return nil
	end

	return searchDown(prompt.Parent)
end

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	for prompt in pairs(prompts) do
		if prompt.Parent then
			local name = prompt.Name
			if name ~= "ModulePrompt" and name ~= "UnlockPrompt" and name ~= "ActivateEventPrompt" then
				continue
			end

			local part = findBasePart(prompt)
			if part then
				local distance = (part.Position - root.Position).Magnitude
				if distance <= prompt.MaxActivationDistance then
					pcall(function()
						prompt:InputHoldBegin()
						prompt:InputHoldEnd()
					end)
				end
			end
		end
	end
end)

local function addHighlightToKey(inst)
	if inst:IsA("Model") and inst.Name == "KeyObtain" then
		if not inst:FindFirstChild("Highlight") then
			Instance.new("Highlight", inst)
		end
	end
end

local function addHighlightToDoorPart(inst)
	if inst:IsA("MeshPart") and inst.Name == "Door" then
		local parentModel = inst.Parent
		if parentModel and parentModel:IsA("Model") and parentModel.Name == "Door" then
			if not inst:FindFirstChild("Highlight") then
				Instance.new("Highlight", inst)
			end
		end
	end
end

local function addHighlightToLever(inst)
	if inst:IsA("Model") and inst.Name == "LeverForGate" then
		if not inst:FindFirstChild("Highlight") then
			Instance.new("Highlight", inst)
		end
	end
end

local function addHighlightToHintBook(inst)
	if inst:IsA("Model") and inst.Name == "LiveHintBook" then
		if not inst:FindFirstChild("Highlight") then
			Instance.new("Highlight", inst)
		end
	end
end

local function zeroPrompt(inst)
	if inst:IsA("ProximityPrompt") then
		inst.HoldDuration = 0
		registerPrompt(inst)
	end
end

local function process(inst)
	addHighlightToKey(inst)
	addHighlightToDoorPart(inst)
	addHighlightToLever(inst)
	addHighlightToHintBook(inst)
	zeroPrompt(inst)
end

for _, inst in ipairs(workspace:GetDescendants()) do
	process(inst)
end

workspace.DescendantAdded:Connect(function(inst)
	process(inst)
end)

workspace.DescendantRemoving:Connect(function(inst)
	if inst:IsA("ProximityPrompt") then
		unregisterPrompt(inst)
	end
end)
