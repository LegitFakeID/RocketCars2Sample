---NOTE: THIS FILE HAS CERTAIN SECTIONS (APPROX. 200 lines) REDACTED TO MAINTAIN GAME'S CONFIDENTIALITY---
---THIS FILE IS THE CLIENT SIDE VEHICLE HANDLER, MOSTLY FOR CONTROLS---

Vehicle = {}
Vehicle.__index = Vehicle

local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local GetKeyBinding = game.ReplicatedStorage.FunctionsAndEvents.GetKeyBinding

function Vehicle.new(params)
	local newVehicle = {}
	setmetatable(newVehicle,Vehicle)

	for i, param in pairs(params) do
		newVehicle[i] = param
	end


    --JUMP
    local function jumpFunction(actionName, inputState, inputObject)
        newVehicle:Jump(inputState)
    end

    ContextActionService:BindAction("Jump1", jumpFunction, false, GetKeyBinding:InvokeServer("Jump"))
    local connection
    connection = game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.ButtonA then
            connection:Disconnect()
            ContextActionService:BindAction("Jump2", jumpFunction, false, Enum.KeyCode.ButtonA)
        end
    end)

    --DRIFT
    local function driftFunction(actionName, inputState, inputObject)
        newVehicle:DriftHandler(inputState)
    end

    ContextActionService:BindAction("Drift", driftFunction, false, GetKeyBinding:InvokeServer("Drift"), Enum.KeyCode.ButtonL1)

    --BOOST
    local function boostFunction(actionName, inputState, inputObject)
        newVehicle:Boost(inputState)
    end

    ContextActionService:BindAction("Boost", boostFunction, false, GetKeyBinding:InvokeServer("Boost"), Enum.KeyCode.ButtonR1)

    --ROLL
    local function rollLeft(actionName, inputState, inputObject)
        newVehicle:RollLeft(inputState)
    end

    local function rollRight(actionName, inputState, inputObject)
        newVehicle:RollRight(inputState)
    end

    ContextActionService:BindAction("RollLeft", rollLeft, false, GetKeyBinding:InvokeServer("RollLeft"), Enum.KeyCode.ButtonL3)
	ContextActionService:BindAction("RollRight", rollRight, false,GetKeyBinding:InvokeServer("RollRight"), Enum.KeyCode.ButtonR3)
    

    newVehicle:drive()


	return newVehicle
end

function getThrottle()
    local throttle = 0

    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR2) then
        throttle += 1
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2) then
        throttle -= 1
    end  

    return throttle
end

function getSteer()
    local steer = 0

    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        steer += 1
    end 

    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        steer -= 1
    end
     
    return steer
end

function Vehicle:drive()

	--gears are defined as percentage of max speed
	local gearLimits = ---redacted, this is an array for defining gear change values

	local gearTorques = ---redacted
-- 2, 3, 5
	local playbackSpeeds = --redacted, playback speeds defined for gears
	local gearSpeedDrop = .6 ---audio drop to signify gear change

	local canDealDamage = true

	local lastIncrementTime = time()

	local lastThrottle = 0
	local releasedThrottle = false

	while self.owner.Character and self.owner.Character.Humanoid.Sit and self.model and self.model:FindFirstChild("Base") do
		pcall(function()
            local throttle = 0
            local steerFloat = 0
            throttle = getThrottle()
            steerFloat = getSteer()

            local targetVelocity = throttle*self.targetVelocity --Target velocity
            local totalMass = self:GetTotalMass()
            local onGround = self:onGround()
            local closeGroundBool, gyroCFrame = self:closeGround()

            --acceleration defined as an attribute multiplied by total mass
            local forceAtt = self.acceleration*totalMass
            local force = forceAtt
            self.velocity = --velocity of vehicle, calculation redacted
            self.propVelocity = math.abs(self.velocity)/self.targetVelocity --proportional velocity


            --SOUNDS
            for i, gear in ipairs(gearLimits) do 
                ---gear audio system code redacted
            end

            --Aerial Correction and controls
            if onGround then 
                --2 lines redacted
                if releasedThrottle then 
                    self:Pitch(0)
                end
                releasedThrottle = false
            elseif not(closeGroundBool) then
                self.model.Base.BodyGyro.MaxTorque = Vector3.new(0,0,0)
                self:Yaw(steerFloat)

                ---3 lines redacted

                if lastThrottle == 0 and throttle ~= 0 then 
                    releasedThrottle = true
                end
            else --closeGround
                ---3 lines redacted
                if lastThrottle == 0 and throttle ~= 0 then 
                    releasedThrottle = true
                end
            end		
            lastThrottle = throttle

            self:turnWheels(throttle, steerFloat, onGround)

            local lookVector = self.model.Base.CFrame.LookVector
            local upVector = self.model.Base.CFrame.UpVector
            local rightVector = self.model.Base.CFrame.RightVector
            
            local slopeCounterForce = 0 --ensures vehicle stays on slope when sideways without being dragged down by gravity
            ----a, b and c are redacted code fragments
            if math.abs(a) > 0.1 and math.abs(b) < math.sin(c) then 
                slopeCounterForce = ---redacted
            end

            if throttle > 0  and onGround then --holding W
                if self.velocity >= 0 then --moving forwards (gears)	
                    for i, gear in ipairs(x) do ---x is redacted code fragment
                        if self.propVelocity <= gear then 
                            force *= ---calculation redacted
                            break
                        end
                    end				

                else --moving backwards
                    force *= 2.6
                end

                if lookVector.Y > 0.1  and lookVector.Y < math.sin(x) then --ensures forwards driving on upwards slope, x is redacted
                    force += --redacted uses vector multiplication
                end 

            elseif throttle < 0 and onGround then --holding S
                if self.velocity <= 0 then --moving backwards
                    targetVelocity *= 0.3 
                    force *= 0.6

                else -- braking
                    targetVelocity *= 0.1
                    force *= 2.6
                end

                if lookVector.Y < -0.1 and lookVector.Y > -math.sin(x) then --ensures backwards driving on downward slope, x is redacted code fragment
                    force -= ---redacted
                end 

            elseif not(onGround) then
                force = 0
            end

            if self.boost == true and self.boostAmount >= 0 then --if boosting go back to gear 1 accel
                ---6 lines redacted
            elseif not(self.boostDelay) then
                lastIncrementTime = self:boostIncrement(true, lastIncrementTime) --increase boostAmount
            end

            if self.propVelocity > 1 and self.boost == false then --if faster than max velocity, slow down
                force = forceAtt
            end

            self.model.Base.LinearVelocity.MaxForce = force
            self.model.Base.LinearVelocity.LineVelocity = targetVelocity
            self.model.Base.slopeCounterVelocity.MaxForce = slopeCounterForce		
		end)

		RunService.Heartbeat:Wait()
	end

	pcall(function () 
		self.model.Base.LinearVelocity.MaxForce = 100000
		self.model.Base.LinearVelocity.LineVelocity = 0
		self:turnWheels(0)
	end)
end

function Vehicle:turnWheels(throttle, steerFloat, onGround)
	--https://datagenetics.com/blog/december12016/index.html, used an inspiration for ackerman system (note we do not use exactly ackerman but an undisclosed variables)
	if self.drifting == true and onGround then 
		self:drift(steerFloat, self.velocity)
	else
		self:undrift()
	end

	local fl = self.model.Wheels.FL.turn.HingeConstraint
	local fr = self.model.Wheels.FR.turn.HingeConstraint

	local turnRadius = self.minTurnRadius
	fl.AngularSpeed = self.maxAngularSpeed
	fr.AngularSpeed = self.maxAngularSpeed

	if self.propVelocity > 0.5 then
		turnRadius += math.clamp(self.propVelocity*(self.maxTurnRadius-turnRadius), 0, 2*(self.maxTurnRadius-turnRadius))

		---2 lines redacted
	end

	----redacted undisclosed variation of ackerman steering system, a and b are redacted code fragments
  local gammaI = a
  local gammaE = b
  
	if steerFloat > 0 then 
		--n lines missing
	elseif steerFloat < 0 then
		--n lines missing
	else 
		--n lines missing
	end
end

function Vehicle:DriftHandler(inputState)
	if inputState == Enum.UserInputState.Begin then 
		self.drifting = true 
	else 
		self.drifting = false
	end
end

function Vehicle:drift(steerFloat)
	---7 lines missing
end

function Vehicle:undrift()
	self.model.Base.DriftThrust.Force = Vector3.new(0,0,0)

    game.ReplicatedStorage.FunctionsAndEvents.UpdateDriftEffect:FireServer(false, self)
end

function Vehicle:Boost(inputState)
	---redacted 8 lines

	self:UpdateBoostEffect()
end

function Vehicle:boostIncrement(increase, lastInc)
	local currentTime = time()
	if currentTime - lastInc >= 0.2 then 
		if increase then
			self.boostAmount = math.clamp(self.boostAmount + 1, 0, 100) --increase boost
			self:setBoostMeter()
			return currentTime
		else
			if self.boostAmount == 0 then
				self:Boost(Enum.UserInputState.End) --if boost == 0, delays increase for 3s
				self:setBoostMeter()
				return currentTime
			else
				self.boostAmount = math.clamp(self.boostAmount - 4, 0, 100) --decrease boost if boost >0
				self:setBoostMeter()
                return currentTime
			end
		end
	end
	self:setBoostMeter()
	return lastInc
end

function Vehicle:setBoostMeter()
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

	local tween = TweenService:Create(self.owner.PlayerGui.Game.BoostMeter.GuageBar.BarThingy, tweenInfo, {Size = UDim2.new(self.owner.PlayerGui.Game.BoostMeter.GuageBar.BarThingy.Size.X.Scale, self.owner.PlayerGui.Game.BoostMeter.GuageBar.BarThingy.Size.X.Offset, 
	self.boostAmount/100,0)})
	tween:Play()
end

function Vehicle:UpdateBoostEffect()
	game.ReplicatedStorage.FunctionsAndEvents.UpdateBoostEffect:FireServer(self)
end

local groundRaycastParams = RaycastParams.new()
groundRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
groundRaycastParams.IgnoreWater = true

function GetDecendantsOfType(instance, typeName)
	local descendantsOfType = {}
	for i, desc in pairs(instance:GetDescendants()) do
		if desc:IsA(typeName) then
			table.insert(descendantsOfType, desc)
		end

	end
	return descendantsOfType
end

function Vehicle:onGround() 
	---10 lines redacted, but uses raycast system with vector multiplication
end

function Vehicle:closeGround() 
	---13 lines redacted, uses raycast system, this time with matrix multiplication
end

function getMassOfModel(model)
	local totalMass = 0
	for i, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			totalMass += part:GetMass()
		end
	end
	return totalMass
end

function Vehicle:GetTotalMass()
	local totalMass = getMassOfModel(self.model)
	if self.model:FindFirstChild("Seats") then
		for i, seat in pairs(self.model.Seats:GetChildren()) do
			totalMass += getMassOfModel(seat.Occupant.Parent)
		end	
	end
	
	return totalMass
end

function Vehicle:Jump(inputState)
	if inputState == Enum.UserInputState.Begin and self.jumpDebounce == true then 
		---8 lines redacted
	end
end



function Vehicle:Flip()
  --this system detects if a vehicle is on the ground/close to the group upside down and auto flips it, taking into account scenarios where you dont want a flip
  ---such as flying close to the ground, tilted upawrds or other special cases
	if self.flipDebounce == true and math.abs(self.velocity) < 5 and self:closeGround() then
		if self.model.PrimaryPart.Orientation.X > 60 or self.model.PrimaryPart.Orientation.X < -60 or self.model.PrimaryPart.Orientation.Z > 60 or self.model.PrimaryPart.Orientation.Z < -60 then
			self.flipDebounce = false
			local vehicleLV = self.model.PrimaryPart.CFrame.LookVector
			local upVector = Vector3.new(0,1,0)
			local newRV = (vehicleLV:Cross(upVector)).Unit
			local newUV = (newRV:Cross(vehicleLV)).Unit
			local flipCFrame = CFrame.fromMatrix(self.model.PrimaryPart.Position + Vector3.new(0,10,0), newRV, newUV, -vehicleLV)

			self.model.Base.FlipMover.Position = self.model.PrimaryPart.Position + Vector3.new(0,10,0)
			self.model.Base.FlipMover.MaxForce = Vector3.new(0,math.huge,0)
			self.model.Base.BodyGyro.CFrame = flipCFrame
			self.model.Base.BodyGyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
			wait(1)
			self.model.Base.FlipMover.MaxForce = Vector3.new(0,0,0)
			self.model.Base.BodyGyro.MaxTorque = Vector3.new(0,0,0)
			wait(2)
			self.flipDebounce = true
		end
	end
end

function Vector3ComponentSetter(vector, axis, value)
	if axis == 'X' then
		vector = Vector3.new(value, vector.Y, vector.Z)
		return vector
	elseif axis == 'Y' then 
		vector = Vector3.new(vector.X, value, vector.Z)
		return vector
	elseif axis == 'Z' then
		vector = Vector3.new(vector.X, vector.Y, value)
		return vector
	end
end

function Vector3ComponentChecker(vector, axis, value)
	if axis == 'X' and vector == Vector3.new(value, vector.Y, vector.Z) then
		return true

	elseif axis == 'Y' and vector == Vector3.new(vector.X, value, vector.Z) then 
		return true

	elseif axis == 'Z' and vector == Vector3.new(vector.X, vector.Y, value) then
		return true
	end
	return false
end

function Vehicle:aerialControls(axis, value)
	local aerial = self.model.Base.Aerial
	aerial.MaxTorque = self:GetTotalMass()*378 --Aerial Controls
	aerial.AngularVelocity = Vector3ComponentSetter(aerial.AngularVelocity, axis, value)
end

function Vehicle:aerialControlsReset(axis, compValue)
	---redacted 9 lines
end

function Vehicle:RollLeft(inputState)
	local axis = 'X'
	local value = -6
	if inputState == Enum.UserInputState.Begin and not(self:closeGround()) then 
		self:aerialControls(axis, value)
	else 
		self:aerialControlsReset(axis, value)
	end
end

function Vehicle:RollRight(inputState)
	local axis = 'X'
	local value = 6
	if inputState == Enum.UserInputState.Begin and not(self:closeGround()) then 
		self:aerialControls(axis, value)
	else 
		self:aerialControlsReset(axis, value)
	end
end


function Vehicle:Yaw(steerFloat)
	local axis = 'Y'
	local value = ---redacted
	self:aerialControls(axis, value)
	local aerial = self.model.Base.Aerial
	if aerial.AngularVelocity == Vector3.new(0,0,0) then
		aerial.MaxTorque = 0
	end
end

function Vehicle:Pitch(throttle)
	local axis = 'Z'
	local value = ---redacted
	self:aerialControls(axis, value)
	local aerial = self.model.Base.Aerial
	if aerial.AngularVelocity == Vector3.new(0,0,0) then
		aerial.MaxTorque = 0
	end
end

game.ReplicatedStorage.FunctionsAndEvents.DriveVehicle.OnClientEvent:Connect(Vehicle.new)
