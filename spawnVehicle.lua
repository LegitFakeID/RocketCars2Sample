---NOTE: THIS FILE HAS CERTAIN SECTIONS (APPROX. 30 lines) REDACTED TO MAINTAIN GAME'S CONFIDENTIALITY---

local spawnVehicleModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local physicsService = game:GetService("PhysicsService")
local  RunService = game:GetService("RunService")

_G.vehiclesTable = {}

function GetSpawnCFrame(humanoidRootPart, vehicleModel)
	local spawnCFrame = game.Workspace.spawnPartTemp.CFrame
	return spawnCFrame
end


local function SeatPlayer(player, newModel)
	local seat = newModel:FindFirstChildWhichIsA("VehicleSeat", true)
	player.Character:WaitForChild("Humanoid")
	RunService.Stepped:Wait()

	seat:Sit(player.Character.Humanoid)
end

local HumanoidSeatedConnection = {}

local function InitialiseControl(player, newModel)
	
	if HumanoidSeatedConnection[player] ~= nil then
		HumanoidSeatedConnection[player]:Disconnect()
		HumanoidSeatedConnection[player] = nil
	end
	
	HumanoidSeatedConnection[player] = player.Character.Humanoid.Seated:Connect(function()

		if player.Character and newModel.Seats:FindFirstChild("VehicleSeat") and player.Character.Humanoid == newModel.Seats.VehicleSeat.Occupant then
			_G.vehiclesTable[player.UserId]:drive()
		end	
		
	end)
	
end



local function makeWheelsUncollidable(vehicleModel)
	for i, part in pairs(vehicleModel:GetDescendants()) do
		if part:IsA("BasePart")   then
			if part.Parent.Parent == vehicleModel.Wheels then
				part.CollisionGroup = "VehicleWheels"
			else
				part.CollisionGroup = "vehicle"
			end
		end
	end

end

function spawnVehicleModule.SpawnVehicle(player, drivable, vehicleName, spawnCFrame, clientSided)
	local VehicleClass = require(game.ServerStorage.Classes.VehicleSubClass:FindFirstChild(vehicleName, true)) 
	
	---redacted lines
	
	local newModel
	
	_G.vehiclesTable[player.UserId], newModel = VehicleClass.new(player)

	if not newModel then
		return
	end
	
	if clientSided then --for creating a vehicle in the menu
    --25 lines redacted
	else
		newModel.Parent = workspace.Vehicles
		newModel.Name = newModel.Name .. "" .. player.UserId
	end
	
	

	
	local modelSize = newModel:GetExtentsSize()

	newModel:SetPrimaryPartCFrame(spawnCFrame+Vector3.new(0,modelSize.Y/2,0))
	
	makeWheelsUncollidable(newModel)
	
	if drivable then 
		workspace.Vehicles:WaitForChild(newModel.Name)

		InitialiseControl(player, newModel)

		---n lines redacted

		player.PlayerGui.Game.BoostMeter.Visible = true
		
		task.wait(2)

	end

	local loopTimer = 0
	while not newModel:IsDescendantOf(workspace) do
		task.wait(.5)
		loopTimer+=1
		if loopTimer == 10 then
			return
		end
	end
	
	newModel.Base:SetNetworkOwner(player)
end



function spawnVehicleModule.KillVehicle(player, doubleO)
	if _G.vehiclesTable[player.UserId] then
		----redacted
		
		for _, instance in pairs(_G.vehiclesTable[player.UserId].model:GetDescendants()) do
			if (instance:IsA("WeldConstraint") or instance:IsA("CylindricalConstraint") or instance:IsA("SpringConstraint") or instance:IsA("HingeConstraint") or instance:IsA("Attachment")) then
				instance:Destroy()
			end
		end
		_G.vehiclesTable[player.UserId].model:Destroy()
		
		
		_G.vehiclesTable[player.UserId] = nil
	end
	
	local playerGarage = _G.findPlayerGarage(player)
	if playerGarage and playerGarage:FindFirstChild("VehicleFolder") then
		for i, v in pairs(playerGarage:FindFirstChild("VehicleFolder"):GetChildren()) do
			for _, instance in pairs(v:GetDescendants()) do
				if (instance:IsA("WeldConstraint") or instance:IsA("CylindricalConstraint") or instance:IsA("SpringConstraint") or instance:IsA("HingeConstraint") or instance:IsA("Attachment")) then
					instance:Destroy()
				end
			end
			v:Destroy()
		end
		--playerGarage:FindFirstChild("VehicleFolder"):ClearAllChildren()
	end


	if HumanoidSeatedConnection[player] ~= nil then
		HumanoidSeatedConnection[player]:Disconnect()
		HumanoidSeatedConnection[player] = nil
	end
end

local function KeyHandler(player, actionName, inputState, inputObject)
	local Vehicle = _G.vehiclesTable[player.UserId]
	if Vehicle then 
		if actionName == "FlipVehicle" and inputState == Enum.UserInputState.Begin then 
			Vehicle:Flip()
		elseif actionName == "HonkHorn" then
			Vehicle:Horn(inputState)
		elseif  actionName == "Drift" then
			Vehicle:DriftHandler(inputState)
		elseif actionName == "Boost" then
			Vehicle:Boost(inputState)
		elseif actionName == "Jump1" or actionName == "Jump2" then
			Vehicle:Jump(inputState)
		elseif actionName == "RollLeft" then
			Vehicle:RollLeft(inputState)
		elseif actionName == "RollRight" then
			Vehicle:RollRight(inputState)
		end
	end
end

Players.PlayerAdded:Connect(function(player) 
	player.CharacterRemoving:Connect(function(character)
		local player = game.Players:GetPlayerFromCharacter(character)
		spawnVehicleModule.KillVehicle(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	spawnVehicleModule.KillVehicle(player)
	task.delay(5, function() 
			print(_G.vehiclesTable)
	end)
end)
game.ReplicatedStorage.FunctionsAndEvents.KeyHandler.OnServerEvent:Connect(KeyHandler)

return spawnVehicleModule
