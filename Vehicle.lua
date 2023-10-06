---NOTE: THIS FILE HAS CERTAIN SECTIONS (APPROX. 300 lines) REDACTED TO MAINTAIN GAME'S CONFIDENTIALITY---
---THIS FILE IS THE SERVER SIDE VEHICLE HANDLER, MAINlY FOR COLLISIONS AND EFFECTS---

Vehicle = {}
Vehicle.__index = Vehicle
--server side vehicle class
--services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GeneralUtils = require(game.ServerScriptService.GeneralUtils)
local DataUtils = require(game.ServerStorage.Modules.DataUtilities)
local DataStore2 = require(game.ServerStorage.Modules.DataStore2)
local DSDefaultValues = require(game.ServerStorage.Modules.DataStoreDefaults)
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local spawnVehicle = require(game.ServerStorage.Modules.spawnVehicle)
--Globals
_G.CarCategorys = {"City", "Off Road", "Sports",  "Specials", "Military"}

local function createInputEvent(vehicle)
	local event = Instance.new("RemoteEvent", vehicle)
	event.Name = "inputChangedEvent"
	return event
end

function Vehicle:initialiseVehicleModel() 

	local base = self.model.Base

	for i, wheel in pairs(self.model.Wheels:GetChildren()) do 
		--spring constraint initalisation code redacted 

		wheel.turn.trail.Position = Vector3.new(wheel.DisplayWheel.Size.X/2,-wheel.Wheel.Size.Y/2+ 0.15 ,0) 
		wheel.turn.trail2.Position = Vector3.new(-wheel.DisplayWheel.Size.X/2,-wheel.Wheel.Size.Y/2+ 0.15 ,0)
	end

	local density = self.mass / (base.Size.X*base.Size.Y*base.Size.Z)

	local physPropertiesBase = PhysicalProperties.new(density, 0.4, 0.25, 1, 1)

	base.CustomPhysicalProperties = physPropertiesBase
	
	local healthBar = game.ServerStorage.HealthBar:Clone()
	local Cframe, size = self.model:GetBoundingBox()

	healthBar.StudsOffsetWorldSpace = Vector3.new(0,size.Y + 2, 0)
	if self.owner then 
		healthBar.PlayerTag.Text = self.owner.Name

		local hasVip = false

		local success, message = pcall(function()
			hasVip = MarketplaceService:UserOwnsGamePassAsync(self.owner.UserId, _G.VIP_PASS_ID)
		end)

		if hasVip then
			healthBar.PlayerTag.TextColor3 = Color3.new(212, 152, 0)
		end

		if self.owner.Neutral == false then 
			local teamHighlight = game.ServerStorage.TeamHighlight:Clone()
			teamHighlight.OutlineColor = self.owner.TeamColor.Color
			teamHighlight.Parent = self.model
			teamHighlight.Adornee = self.model
		end
	else
		healthBar.PlayerTag.Visible = false
	end

	local InputEvent =  createInputEvent(self.model)
	InputEvent.OnServerEvent:Connect(function(player, throttle, steer)
		if player == self.owner then
			self.ConnectionThrottleFloat = throttle
			self.ConnectionSteerFloat = steer
		end
	end)

	local wasInWorkspace = nil

	self.model.AncestryChanged:Connect(function()
		if self.model.Parent == workspace.Vehicles then
			wasInWorkspace = true
		elseif wasInWorkspace and self.model.Parent == nil then
			if not self.wasKilled then
				if self.lastAttacker and self.lastAttacker.Parent then
					self:KillVehicle(self.lastAttacker, 10)
				else
					self:KillVehicle()
	
	
				end
			end
			
		end
		
	end)

	healthBar.Parent = base
end


function Vehicle.new(params)
	local newVehicle = {}
	setmetatable(newVehicle,Vehicle)

	for i, param in pairs(params) do
		newVehicle[i] = param
	end

	newVehicle.velocity = 0
	newVehicle.propVelocity = 0

	newVehicle.drifting = false

	newVehicle.boost = false
	newVehicle.boostDelay = false

	newVehicle.jumpDebounce = true
	newVehicle.flipDebounce = true
	newVehicle.hornSoundId = ""
	newVehicle.lastAttacker = nil

	newVehicle.ConnectionSteerFloat = 0
	newVehicle.ConnectionThrottleFloat = 0

	newVehicle.baseHealth = newVehicle.health
	
	newVehicle.connectionThrottle = nil
	newVehicle.wasKilled = false

	--ACKERMAN STEERING
  ---initialisation of variables redacted
	local wheels = x
	local fl = x
	local fr = x
	local bl = x
	local br = x
	newVehicle.t = (fl.Position - fr.Position).Magnitude
	newVehicle.l = (fl.Position - bl.Position).Magnitude

	newVehicle:initialiseVehicleModel()



	if newVehicle.owner then
		local paintJob = DataUtils.GetEquippedItemOnVehicle(newVehicle.owner, "color", newVehicle.model.Name)
			
		newVehicle:PaintVehicle(paintJob)
		
		local boostTrail = DataUtils.GetEquippedItemOnVehicle(newVehicle.owner, "boostTrail", newVehicle.model.Name)
		
		newVehicle:ChangeBoostTrail(boostTrail)
		
		local hornSound = DataUtils.GetEquippedItemOnVehicle(newVehicle.owner, "hornSound", newVehicle.model.Name)

		newVehicle:ChangeHornSound(hornSound) 


	end

	return newVehicle
end


function Vehicle:PaintVehicle(PaintName)
	
	
	local model = self.model
	local colorValue = nil
	
	if PaintName == "None" then
		for j, modelPiece in pairs(game.ServerStorage.VehicleModels:FindFirstChild(model.Name).Model:GetChildren())  do 

			if modelPiece:FindFirstChild("Colored") then 
				local value = Instance.new("Color3Value")
				value.Value = modelPiece.Color 
				colorValue = value
				break
			end
		end
	else
		colorValue = game.ServerStorage.Colors:FindFirstChild(PaintName)

	end
	

	for j, modelPiece in pairs(model.Model:GetChildren())  do 

		if modelPiece:FindFirstChild("Colored") then 
			modelPiece.Color = colorValue.Value
			modelPiece.Material = Enum.Material.Metal
			GeneralUtils.RemoveChildrenOfType(modelPiece, "Texture")
			
			for i, texture in pairs(colorValue:GetChildren()) do
				texture:Clone().Parent = modelPiece
			end
		end
	end
end


function Vehicle:ChangeBoostTrail(EffectName)
	---approx 11 lines redacted
end

function Vehicle:ChangeHornSound(hornSound) 
	local sound : Sound = game.ServerStorage.CarHorns:FindFirstChild(hornSound)
	if sound then
		self.hornSoundId = sound.SoundId

	end
end


function Vehicle:IsOwner(player) 
	return player == self.owner
end

function Vehicle:GetOwner() 
	return self.owner
end

function Vehicle:DealDamage(target, hitBox, velocity)
	if target.Seats.VehicleSeat.Occupant then 
		local targetPlayer = Players:GetPlayerFromCharacter(target.Seats.VehicleSeat.Occupant.Parent)
		
		--For TDM
		if self.owner.Neutral == false and targetPlayer.Team == self.owner.Team then
			return
		end

		local targetVehicle = _G.vehiclesTable[targetPlayer.UserId]

		local damage = 0
    ---EXACT VALUES redacted (x denotes a const value)
		if velocity < 0.5 then
			damage = x*self.damageMultiplier
		elseif velocity < 0.7 then
			damage = x*self.damageMultiplier
		elseif velocity < 1 then
			damage = x*self.damageMultiplier
		elseif velocity < 1.3 then
			damage = x*self.damageMultiplier
		elseif velocity > 1.3 then
			damage = x*self.damageMultiplier
		end

		targetVehicle:TakeDamage(damage, self.owner, hitBox, self.model.Hitboxes.damageBlock)
	end
end

----approx 18 lines redacted



function Vehicle:TakeDamage(damage, attacker, hitBox, damagePart)
	--print(attacker)
	---approx 14 lines redacted
end

function Vehicle:KillVehicle(attacker, damage)
	self.wasKilled = true
	if self.owner and self.owner.Character then
		self.owner.Character.Humanoid.Health = 0
	end
	spawnVehicle.KillVehicle(self.owner)
	game.ServerStorage.Events.PlayerDamaged:Fire(self.owner, attacker, damage, true)
end

local function CalculatePartVertexPositions(part)
	local partPosition = part.Position
	local partSize = part.Size
	local vertices = {}
	vertices[1] = part.CFrame:PointToWorldSpace(Vector3.new(part.Size.X/2,part.Size.Y/2,-part.Size.Z/2))
	vertices[2] = part.CFrame:PointToWorldSpace(Vector3.new(part.Size.X/2,-part.Size.Y/2,-part.Size.Z/2))
	vertices[3] = part.CFrame:PointToWorldSpace(Vector3.new(-part.Size.X/2,part.Size.Y/2,-part.Size.Z/2))
	vertices[4] = part.CFrame:PointToWorldSpace(Vector3.new(-part.Size.X/2,-part.Size.Y/2,-part.Size.Z/2))



	return vertices,  part.CFrame.LookVector
end
	


local function getCenterOfIntersectingPoints(hitBoxPart, damagePart)
	local vertices, direction = CalculatePartVertexPositions(damagePart)
	--createDebugingPartsAtHitpoints(vertices)
	local centerPoint = Vector3.new(0,0,0)
	local totalDistance = 0
	local centerPointCount = 0

	for i, vertex in pairs(vertices) do
		local raycastParams = RaycastParams.new()
		---2 lines of raycast initialisation redacted
		local raycastResult = workspace:Raycast(vertex, direction*200, raycastParams)
		if raycastResult then
			centerPoint = centerPoint +  raycastResult.Position
			centerPointCount = centerPointCount + 1
		end
	end
	
	centerPoint = centerPoint/centerPointCount
	return centerPoint
end

function createDebugingPartsAtHitpoints(hitPoints)
	---10 lines redacted
end

local function createDebugingPartForCenterPoint(centerPoint)
	---9 lines redacted
end

local function CreateMoneyUiAnimation(MoneyUi, screenPosition)
	MoneyUi.Position = UDim2.new(0,screenPosition.X,0,screenPosition.Y)

	local startPos = UDim2.new((math.random(1, 20)-10)/50, screenPosition.X,(math.random(1, 20)-10)/50, screenPosition.Y)

	local tweenIn = TweenService:Create(MoneyUi, TweenInfo.new ( 1 ,Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = startPos})
	tweenIn:Play()
	tweenIn.Completed:Wait()
	
	local tweenInfo =	TweenInfo.new ( 1 ,Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.wait(.6)
	
	local tweenOut = TweenService:Create(MoneyUi, tweenInfo, {Position = UDim2.new(startPos.X.Scale,startPos.X.Offset,1.5, startPos.Y.Offset)})
	tweenOut:Play()
end


local function showMoneyGainedOnAttackersScreen(attacker, damage, wasKill, collisionPoint)
	local Gui = attacker.PlayerGui.PlayerMoneyGainedPopups
	local screenPosition = nil

	if collisionPoint ~= collisionPoint then
		screenPosition = game.ReplicatedStorage.FunctionsAndEvents.GetPlayerPointToScreenSpace:InvokeClient(attacker, attacker.Character.HumanoidRootPart.Position)
	else
		screenPosition = game.ReplicatedStorage.FunctionsAndEvents.GetPlayerPointToScreenSpace:InvokeClient(attacker, collisionPoint)
	end

	local damageUi = game.ReplicatedStorage.Ui.DamageMoney:Clone()
	task.delay(.1, function()
		local damageMoney = _G.calculateMultMoney(attacker, damage*_G.DAMAGE_MONEY_MULT)
		local sound = game.ServerStorage.Sounds.cashSmall:Clone()
		if damageMoney >= 10 then
			local sound = game.ServerStorage.Sounds.cashBig:Clone()
		end
		sound.Parent = attacker.PlayerGui
		sound:Play()
		damageUi.Text = "+".. damageMoney.. "$"

		damageUi.Parent = Gui
		CreateMoneyUiAnimation(damageUi, screenPosition)
	end)

	if wasKill then
		for i=1,2 do
			local sound = game.ServerStorage.Sounds:FindFirstChild("killCoins".. i):Clone()
			sound.Parent = attacker.PlayerGui
			sound:Play()
		end
		local KillMoney = _G.calculateMultMoney(attacker, _G.KILL_MONEY)


		local killUi = game.ReplicatedStorage.Ui.KillMoney:Clone()
		killUi.Text = "+"..KillMoney .. "$"
		task.delay(.4, function()
			killUi.Parent = Gui
			CreateMoneyUiAnimation(killUi, screenPosition)

		end)
	end
	
	
end

function Vehicle:CollisionEffect(hitBoxPart, damagePart, attacker, damage, wasKill)
	
	local collisionPoint = getCenterOfIntersectingPoints(hitBoxPart, damagePart)
	showMoneyGainedOnAttackersScreen(attacker, damage, wasKill, collisionPoint)
	local effect = game.ServerStorage.Effects.VehicleCollision:Clone()
	effect.Parent = workspace.GameEffects
	if self.model:FindFirstChild("Base") then
		local sound = game.ServerStorage.Sounds.crash:Clone()
		sound.Parent = self.model.Base
		sound:Play()
	end
	effect.WorldCFrame = damagePart.CFrame
	effect.WorldPosition = collisionPoint
	--loop over ParticleEmitters and turn them on
	for i, emitter in pairs(effect:GetChildren()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = true
		end
	end
	task.wait(0.2)
	effect.BillboardGui.Enabled = false
	for i, emitter in pairs(effect:GetChildren()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = false
		end
	end	
	task.wait(3)
	effect:Destroy()
end

function Vehicle:DeathEffect()
	--print("death effect")
 	local effect = game.ServerStorage.Effects.VehicleDeath:Clone()
	effect.Parent = workspace.GameEffects
	local sound = game.ServerStorage.Sounds.explosion:Clone()
	sound.Parent = effect
	sound:Play()
	effect.WorldCFrame = self.model.Base.CFrame

	task.wait(0.4)
	for i, emitter in pairs(effect:GetChildren()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = false
		end
	end
	task.wait(3)
	effect:Destroy()

end

local volumes = {[484883392] = 0.1, [319804747] = 0.3, [532147820] = 0.5, [2458730465] = 0.2, [1724607017] = 0.3, [134024901] = 0.05}

function Vehicle:drive()
	if self.idleSoundId then 
		if volumes[self.idleSoundId] then 
			self.model.Base.IdleSound.Volume = volumes[self.idleSoundId]
		end
		self.model.Base.IdleSound.SoundId = "rbxassetid://" .. self.idleSoundId
	end
	
	self.model.Base.IdleSound:Play()

	local lastCarHit = nil

	self.model.Hitboxes.damageBlock.Touched:Connect(function(part)
		if (part.Parent == nil) then
			if (part ~= nil) then
				part:Destroy()
			end
			
			return
		end
		self.velocity = ----initalisation redacted
        self.propVelocity = math.abs(self.velocity)/self.targetVelocity --proportional velocity

		if self.propVelocity > 0.05 then 

			if (part.Parent.Name == "Hitboxes" or part.Name == "damageBlock") and part.Parent.Parent ~= self.model and part.Parent.Parent ~= lastCarHit then
				lastCarHit = ---redacted
				self:DealDamage(part.Parent.Parent, part, self.propVelocity)
								
				task.delay(1, function() --This is to stop hitting the same car twice at the same time. Only an issue if our hitboxes are made up of multiple parts
					lastCarHit = nil 
				end)
			end

		end

	end)

	game.ReplicatedStorage.FunctionsAndEvents.DriveVehicle:FireClient(self.owner, self)
end


function Vehicle:ChangeTrail(trailName)
	local boostPart = ---redacted
	
	boostPart.ParticleEmitter:Destroy()
	boostPart.Trail:Destroy()
	
	local trailModel = game.ServerStorage.BoostTrails:FindFirstChild(trailName)
	
	for i, trail in trailModel:GetChildren() do 		
		---2 lines redacted
	end
end

function UpdateBoostEffect(player, params)
	---redacted
end

function UpdateDriftEffect(player, toggle, params, steerFloat)
	pcall(function() 
		if toggle then
			if not params.model.Base.driftSound.Playing and steerFloat ~= 0 then
			params.model.Base.driftSound:Play()
	
		elseif steerFloat == 0 then
			---redacted
		end
	
		for i, wheel in pairs(params.model.Wheels:GetChildren()) do 
			if wheel.turn:FindFirstChild("Trail") then 
				wheel.turn:FindFirstChild("Trail").Enabled = true
			end
			end
			
		else
			if params.model:FindFirstChild("Base") then 
				params.model.Base.driftSound:Stop()
			end

			if params.model:FindFirstChild("Wheels") then
				---redacted
			end
		end
	end)
end

game.ReplicatedStorage.FunctionsAndEvents.UpdateBoostEffect.OnServerEvent:Connect(UpdateBoostEffect)
game.ReplicatedStorage.FunctionsAndEvents.UpdateDriftEffect.OnServerEvent:Connect(UpdateDriftEffect)

function Vehicle:Horn(inputState) 
	if inputState == Enum.UserInputState.Begin then
		if self.model and self.model:FindFirstChild("Base") then
			self.model.Base.hornSound.SoundId = self.hornSoundId

			self.model.Base.hornSound:Play()
		end
	end
end

function applySkinIfSkinned(part, skinTexture)
	if part:FindFirstChild("Skinned") then
		
		if part:FindFirstChildWhichIsA("Texture") then
			part:FindFirstChildWhichIsA("Texture"):Destroy()
		end
		
		local skin = skinTexture:Clone()
		skin.Parent = part
	end
end

function Vehicle:ApplySkin(skin) 
	local skinTexture = game.ServerStorage.Skins:FindFirstChild(skin)
	GeneralUtils.IterateOverDescendantsOfType(self.model, "BasePart", applySkinIfSkinned, skinTexture)
	
end

function Vehicle:GetCost()
--	print(self.health)
	return self.cost
end

function Vehicle:GetCategory()
	return self.category
	-- if self.category then return 
	-- 	self.category
	-- else
	-- 	return  _G.CarCategorys[math.random(1,#_G.CarCategorys)]
	-- end
end

function Vehicle:resetVehicle()
	
	local paintJob = DataUtils.GetEquippedItemOnVehicle(self.owner, "color", self.model.Name)
			
	self:PaintVehicle(paintJob)
	
	local boostTrail = DataUtils.GetEquippedItemOnVehicle(self.owner, "boostTrail", self.model.Name)
	
	self:ChangeBoostTrail(boostTrail)
	
	local hornSound = DataUtils.GetEquippedItemOnVehicle(self.owner, "hornSound", self.model.Name)

	self:ChangeHornSound(hornSound) 
end

return Vehicle
