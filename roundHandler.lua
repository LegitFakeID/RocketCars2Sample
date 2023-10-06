---NOTE: THIS FILE HAS CERTAIN SECTIONS (APPROX. 100 lines) MISSING TO MAINTAIN GAME'S CONFIDENTIALITY---

local handler = {}
local DataUtilities = require(game.ServerStorage.Modules.DataUtilities)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStore2 = require(game.ServerStorage.Modules.DataStore2)
local DSDefaultValues = require(game.ServerStorage.Modules.DataStoreDefaults)
local spawnVehicle = require(game.ServerStorage.Modules.spawnVehicle)

local maps = game.ServerStorage.Maps:GetChildren()

--GLOBAL VARIABLE DEFINITIONS SKIPPED FOR CONFIDENTIALITY OF THESE VALUES

local lastKiller = {}
_G.killstreak = {}
local moneyAwarded = {}

local VIP_MULTIPLIER = 1.3

function _G.calculateMultMoney(player, amount)
	local hasVip = false

	local success, message = pcall(function()
        hasVip = MarketplaceService:UserOwnsGamePassAsync(player.UserId, _G.VIP_PASS_ID)
    end)

	if hasVip then
		amount = amount * VIP_MULTIPLIER
	end

	local playerMultDS = DataStore2("multipliers", player)
	local MultTable = playerMultDS:Get(DSDefaultValues["multipliers"])

	local mult = 0
	for i,v in MultTable do
		if v[2] > os.time() then
			mult += v[1]
		else
			table.remove(MultTable, i)
			playerMultDS:Set(MultTable)
		end
	end

	if mult > 1 then 
		amount *= mult
	end

	return math.round(amount)
end

function incrementPlayerMoney(player, amount)
	local playerMoneyDS = DataStore2("money", player)

	local calcAmount = _G.calculateMultMoney(player, amount)

	if moneyAwarded[player] then
		moneyAwarded[player] = moneyAwarded[player] + calcAmount
	else
		moneyAwarded[player] = calcAmount
	end

	playerMoneyDS:Increment(calcAmount, 0)
end

--section skipped here

function handler.startRound()
	if math.random() < 0.7 then
		_G.gamemode = "FFA"
	else
		_G.gamemode = "TDM"
	end

	unassignTeams()

	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			player:WaitForChild("kills").Value = 0 
		player:WaitForChild("deaths").Value = 0
		player:WaitForChild("damageDealt").Value = 0
		player:WaitForChild("survivalTime").Value = -1
		player:WaitForChild("spawned").Value = 0
		player.PlayerGui:WaitForChild("Game").Information.Gamemode.Text = gamemodeName(_G.gamemode)
		end)
		
	end

	game.StarterGui.Game.Information.Gamemode.Text = gamemodeName(_G.gamemode)
	loadMap()

	moneyAwarded = {}
	
	if _G.gamemode == "FFA" then
		startFFA()
	end

	if _G.gamemode == "TDM" then
		startTDM()
	end
end

function handler.endRound()
	stopRoundTimer()
	EndScreen()
	
	workspace.Map:ClearAllChildren()
	workspace.SpawnPoints:ClearAllChildren()
	handler.startRound()
	sendToMenu()
end

-- function updateTimes()
-- 	for i, player in pairs(PlayerService:GetPlayers()) do
-- 		pcall(function()
-- 			if player:WaitForChild("survivalTime").Value == -1 then
-- 				player:WaitForChild("survivalTime").Value = _G.LMS_GAME_TIME - _G.roundTime
-- 			end
-- 		end)
		
-- 	end
-- end

function loadMap()
	local rand = math.random(1,#maps)
	local map = maps[rand]:Clone()

	for i, v in pairs(map.SpawnPoints:GetChildren()) do
		v.Parent = workspace.SpawnPoints
	end

	workspace.Terrain:Clear()
	if game.ServerStorage.MapTerrains:FindFirstChild(map.Name) then
		workspace.Terrain:PasteRegion(game.ServerStorage.MapTerrains[map.Name], workspace.Terrain.MaxExtents.Min, true)
	end
	loadLighting(map.Name)
	map.Parent = workspace.Map
end

function loadLighting(mapName)
	local lightingModule = game.ServerStorage.MapLightings:FindFirstChild(mapName)
	for paramName, value in pairs(require(lightingModule)) do
		game.Lighting[paramName] = value
	end
	game.Lighting:ClearAllChildren()
	game.Workspace.Terrain:ClearAllChildren()
	for i, child in pairs(lightingModule:GetChildren()) do
		if not child:IsA("ValueBase") then
			if child:IsA("Clouds") then
				child:Clone().Parent = game.Workspace.Terrain
			else
				child:Clone().Parent = game.Lighting
			end
		end
	end
end

function sendToMenu()
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			game.ServerStorage.Events.InitialisePlayerMenuUi:Fire(player)
		end)
		
	end
end

function EndScreen()
  --certain function calls skipped in this functions
	killAllVehicles()
	local winnerTable = getWinnerDetails()
	local rewardsTable = giveRewards(winnerTable)
	setupVictoryStage(winnerTable)
	game.ReplicatedStorage.FunctionsAndEvents.EndScreen:FireAllClients() --focus player camera's on stage
	fireEmitters()
	task.wait(END_SCREEN_DURATION)
end

function giveRewards(winnerTable)
	local rewardMoney = 0
	local rewardsTable = {}
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
		
			if player == winnerTable[1] then
				rewardMoney = _G.BASE_MONEY + FIRST_PLACE_MONEY
			elseif player == winnerTable[2] then
				rewardMoney = _G.BASE_MONEY + SECOND_PLACE_MONEY
			elseif player == winnerTable[3] then
				rewardMoney = _G.BASE_MONEY + THIRD_PLACE_MONEY
			elseif player.kills.Value > 0 then
				rewardMoney = _G.BASE_MONEY
			end

			incrementPlayerMoney(player, rewardMoney)

			rewardsTable[player] = moneyAwarded[player]
		end)
	end

	return rewardsTable
end

function disablePlayerUi()
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			for i, v in pairs(player.PlayerGui:WaitForChild("Game"):GetChildren()) do
				if (v:IsA("Frame") or v:IsA("TextButton")) and v.Name ~= "ResultScreen" then
					v.Visible = false
				end
			end
	
			for i, v in pairs(player.PlayerGui:WaitForChild("Garage"):GetChildren()) do
				if v:IsA("Frame") or v:IsA("TextButton") then
					v.Visible = false
				end
			end
		end)
		
	end
end

function setupVictoryStage(winnerTable)
	local VictoryStage = workspace.VictoryStage
	VictoryStage.floor.WinningTeam.Enabled = false

	for i=1, 3 do
		pcall(function()
			local winner = winnerTable[i]
			local winnerVehicleName = DataUtilities.getPlayerEquippedVehicle(winner)

			--Add car to stage
			local vehicleClass = require(game.ServerStorage.Classes.VehicleSubClass:FindFirstChild(winnerVehicleName))
			local carobject, model = vehicleClass.new()
			model:SetPrimaryPartCFrame(VictoryStage.Cars:FindFirstChild(i).CFrame)
			model.Parent = VictoryStage.Cars:FindFirstChild(i)
	
			-- --Set humanoid
			-- local character = VictoryStage.Players:FindFirstChild(i).Humanoid
			-- local humanoidDescriptionForUser = game.Players:GetHumanoidDescriptionFromUserId(winner.UserId)
			-- character:ApplyDescription(humanoidDescriptionForUser)
	
			--Fill ui
			local ui = VictoryStage.Podium:FindFirstChild(i).BillboardGui.frame
			local icon = _G.getPlayerIcon(winner)
			ui.ImageLabel.Image = icon
	
			ui.Frame.name.Text = winner.Name

			if _G.gamemode == "FFA" then
				ui.Frame.Knockouts.Text = "Kills: " .. winner:WaitForChild("kills").Value
			elseif _G.gamemode == "TDM" then
				ui.Frame.Knockouts.Text = "Kills: " .. winner:WaitForChild("kills").Value
			end
		end)
	end

	if _G.gamemode == "TDM" then 
		local winningAmount = game.Teams.Red.Kills.Value - game.Teams.Blue.Kills.Value
		if winningAmount > 0 then
			VictoryStage.floor.WinningTeam.TextLabel.Text = "Red wins by " .. math.abs(winningAmount) .. " kills !"
			VictoryStage.floor.WinningTeam.TextLabel.TextColor3 = Color3.new(1,0,0)
			VictoryStage.floor.WinningTeam.Enabled = true
		elseif winningAmount < 0 then
			VictoryStage.floor.WinningTeam.TextLabel.Text = "Blue wins by " .. math.abs(winningAmount) .. " kills !"
			VictoryStage.floor.WinningTeam.TextLabel.TextColor3 = Color3.new(0,0,1)
			VictoryStage.floor.WinningTeam.Enabled = true
		else
			VictoryStage.floor.WinningTeam.TextLabel.Text = "The game is a tie!"
			VictoryStage.floor.WinningTeam.TextLabel.TextColor3 = Color3.new(0,1,0)
			VictoryStage.floor.WinningTeam.Enabled = true
		end
	end
end

function fireEmitters()
	local VictoryStage = workspace.VictoryStage

	for i, emitter in pairs(VictoryStage.Emitters:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = true

			task.delay(0.3, function()
				emitter.Enabled = false
			end)
		end
	end
end

function showPlayerBanner(rewardsTable)
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			local resultScreen = player.PlayerGui:WaitForChild("Game"):FindFirstChild("ResultScreen")
			resultScreen.Visible = true

			local ui = resultScreen:WaitForChild("PlayerBanner")

			local icon = _G.getPlayerIcon(player)
			ui.playerIcon.Image = icon
			
			ui.username.Text = player.Name
			ui.kills.Text = "Kills: " .. player:WaitForChild("kills").Value
			ui.deaths.Text = "Deaths: " .. player:WaitForChild("deaths").Value
			ui.money.Text = "+" .. math.round(rewardsTable[player]) .. " $"
		end)
	end
end

function clearVictoryStage()
	local VictoryStage = workspace.VictoryStage
	for i=1, 3 do
		--clear cars
		VictoryStage.Cars:FindFirstChild(i):ClearAllChildren()

		--clear ui
		local ui = VictoryStage.Podium:FindFirstChild(i).BillboardGui.frame
		ui.ImageLabel.Image = ""
		ui.Frame.name.Text = ""
		ui.Frame.Knockouts.Text = ""
	end

	--clear and hide leaderboard
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			if player.PlayerGui:WaitForChild("Game") then
				player.PlayerGui.Game.ResultScreen.Visible = false
			end
		end)
	end
end

function killAllVehicles()
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			if player.Character then 
				player.Character.Humanoid.Health = 0
			end
	
			spawnVehicle.KillVehicle(player)
		end)
	end
end

function _G.getPlayerIcon(player)
	local userId = player.UserId
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size420x420
	local content, isReady = PlayerService:GetUserThumbnailAsync(userId, thumbType, thumbSize)

	return content
end

function getWinnerDetails()
	local ordered = {}
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			table.insert(ordered, player)
		end)
		
		
	end
	
	if _G.gamemode == "FFA" or _G.gamemode == "TDM" then
		table.sort(ordered, function(a,b) return a.kills.Value > b.kills.Value end)
	end

	return ordered
end

function startFFA()
	game.StarterGui.Game.TeamScore.Visible = false
	startRoundTimer(_G.FFA_GAME_TIME)
end

function startTDM()
	game.Teams.Red.Kills.Value = 0
	game.Teams.Blue.Kills.Value = 0
	assignTeams()
	turnOnTeamUi()
	startRoundTimer(_G.TDM_GAME_TIME)
end

function turnOnTeamUi()
	--code skipped
end

function assignTeams()
	game.Teams.Red.AutoAssignable = true
	game.Teams.Blue.AutoAssignable = true
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			local rand = math.random()
			if rand < 0.5 then
				player.Team = game.Teams.Red
			else
				player.Team = game.Teams.Blue
			end
			player.Neutral = false
		end)
	end
end

function unassignTeams()
	game.Teams.Red.AutoAssignable = false
	game.Teams.Blue.AutoAssignable = false
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			player.Team = nil
			player.Neutral = true
		end)
	end
end

function enableRespawn()
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			player.PlayerGui:WaitForChild("Game").Spectate.Information.Respawn.Visible = true
		end)
		
	end
end

function disableRespawn()
	for i, player in pairs(PlayerService:GetPlayers()) do
		pcall(function()
			player.PlayerGui:WaitForChild("Game").Spectate.Information.Respawn.Visible = false
		end)
		
	end
end

function startRoundTimer(gameTime)
	gameRunning = true
	_G.roundTime = gameTime
	toggleUiTimer()
	
	task.spawn(function()
		while (_G.roundTime > 0) do
			_G.roundTime -= 1 
			
			if _G.roundTime == 0 then
				gameRunning = false
				handler.endRound()
			end
	
			task.wait(1)
		end
	end)
	
end

function stopRoundTimer()
	_G.roundTime = -1
	task.wait(1)
end

function toggleUiTimer()
	game.ReplicatedStorage.FunctionsAndEvents.UiTimer:FireAllClients(gameRunning, _G.roundTime)
end

PlayerService.PlayerAdded:Connect(function(player)
	game.ReplicatedStorage.FunctionsAndEvents.UiTimer:FireClient(player, gameRunning, _G.roundTime)
end)

game.ServerStorage.Events.PlayerDamaged.Event:Connect(function(player, attacker, damage, isDeath)
--14 lines skipped
end)

function FFAUpdater(player, attacker, damage, isDeath)
--12 lines skipped
end

function TDMUpdater(player, attacker, damage, isDeath)
--14 lines skipped
end

function populateInfoUi(player, attacker)
	_G.killstreak[player] = 0
	local messages = {}

	checkKillstreak(attacker, messages)

	if lastKiller[attacker] and player == lastKiller[attacker] then 
		showRevenge(player, attacker, messages)
	else
		deathMessage(player, attacker, messages)
	end
	lastKiller[player] = attacker

	if messages then 
		game.ReplicatedStorage.FunctionsAndEvents.infoUi:FireAllClients(messages)
	end
	
end

function deathMessage(player, attacker, messages)
	local text = attacker.Name .. '<font face="GothamBlack"><font color="#F11111"> DEMOED </font></font>' .. player.Name
	table.insert(messages, text)
end

function showRevenge(player, attacker, messages)
	if lastKiller[attacker] then 
		if player == lastKiller[attacker] then 
			local text = attacker.Name .. '<font face="GothamBlack"><font color="#389d59"> got revenge on </font></font>' .. player.Name
			table.insert(messages, text)
		end
	end
end

function checkKillstreak(attacker, messages)
	if not _G.killstreak[attacker] then 
		_G.killstreak[attacker] = 0
	end

	_G.killstreak[attacker] += 1
	if _G.killstreak[attacker] >= 3 then
		local text = attacker.Name .. ' is on a <font face="GothamBlack"><font color="#389d59">' .. _G.killstreak[attacker] .. ' kill streak!</font></font>'
		table.insert(messages, text)
	end
end




-- function checkLMSConditions()
-- 	local playersAlive = 0

-- 	for i, player in pairs(PlayerService:GetPlayers()) do
-- 		pcall(function()
-- 			if player.survivalTime.Value == -1 then
-- 				playersAlive += 1
-- 				if playersAlive == 2 then
-- 					return
-- 				end
-- 			end
-- 		end)
		
-- 	end

-- 	print("ENDING ROUND")
-- 	handler.endRound()
-- end

return handler
