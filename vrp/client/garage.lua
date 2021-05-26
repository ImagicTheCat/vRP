-- https://github.com/ImagicTheCat/vRP
-- MIT license (see LICENSE or vrp/vRPShared.lua)

if not vRP.modules.garage then return end

local Garage = class("Garage", vRP.Extension)

-- METHODS

function Garage:__construct()
  vRP.Extension.__construct(self)

  -- init decorators
  DecorRegister("vRP.owner", 3)

  self.vehicles = {} -- map of vehicle model => veh id (owned vehicles)
  self.hash_models = {} -- map of hash => model

  self.update_interval = 30 -- seconds
  self.check_interval = 15 -- seconds
  self.respawn_radius = 200

  self.state_ready = false -- flag, if true will try to re-own/spawn periodically out vehicles

  self.out_vehicles = {} -- map of vehicle model => {cstate, position, rotation}, unloaded out vehicles to spawn

  -- task: save vehicle states
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(self.update_interval*1000)

      if self.state_ready then
        local states = {}

        for model, veh in pairs(self.vehicles) do
          if IsEntityAVehicle(veh) then
            local state = self:getVehicleState(veh)
            state.position = {table.unpack(GetEntityCoords(veh, true))}
            state.rotation = {GetEntityQuaternion(veh)}

            states[model] = state

            if self.out_vehicles[model] then -- update out vehicle state data
              self.out_vehicles[model] = {state, state.position, state.rotation}
            end
          end
        end

        self.remote._updateVehicleStates(states)
        vRP.EXT.PlayerState.remote._update({ in_owned_vehicle = self:getInOwnedVehicleModel() or false})
      end
    end
  end)

  -- task: vehicles check
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(self.check_interval*1000)

      if self.state_ready then
        self:cleanupVehicles()
        self:tryOwnVehicles() -- get back network lost vehicles
        self:trySpawnOutVehicles()
      end
    end
  end)
end

local custom = {}
-- veh: vehicle game id
-- return owner character id and model or nil if not managed by vRP
function Garage:getVehicleInfo(veh)
  if veh and DecorExistOn(veh, "vRP.owner") then
    local model = self.hash_models[GetEntityModel(veh)]
    if model then
      return DecorGetInt(veh, "vRP.owner"), model
    end
  end
end

-- spawn vehicle
-- will be placed on ground properly
-- one vehicle per model allowed at the same time
--
-- state: (optional) vehicle state (client)
-- position: (optional) {x,y,z}, if not passed the vehicle will be spawned on the player (and will be put inside the vehicle)
-- rotation: (optional) quaternion {x,y,z,w}, if passed with the position, will be applied to the vehicle entity
function Garage:spawnVehicle(model, state, position, rotation) 
  self:despawnVehicle(model)

  -- load vehicle model
  local mhash = GetHashKey(model)

  local i = 0
  while not HasModelLoaded(mhash) and i < 10000 do
    RequestModel(mhash)
    Citizen.Wait(10)
    i = i+1
  end

  -- spawn car
  if HasModelLoaded(mhash) then
    local ped = GetPlayerPed(-1)

    local x,y,z
    if position then
      x,y,z = table.unpack(position)
    else
      x,y,z = vRP.EXT.Base:getPosition()
    end

    local nveh = CreateVehicle(mhash, x,y,z+0.5, 0.0, true, false)
    if position and rotation then
      SetEntityQuaternion(nveh, table.unpack(rotation))
    end
    if not position then -- set vehicle heading same as player
      SetEntityHeading(nveh, GetEntityHeading(ped))
    end

    SetVehicleOnGroundProperly(nveh)
    SetEntityInvincible(nveh,false)
    if not position then
      SetPedIntoVehicle(ped,nveh,-1) -- put player inside
    end
	local plate_txt = GetVehicleNumberPlateText(nveh)
	if plate_txt ~= custom.plate_txt then
		SetVehicleNumberPlateText(nveh, "P "..vRP.EXT.Identity.registration)
	else
		SetVehicleNumberPlateText(nveh, custom.plate_txt)
	end
    SetEntityAsMissionEntity(nveh, true, true)
    SetVehicleHasBeenOwnedByPlayer(nveh,true)

    -- set decorators
    DecorSetInt(nveh, "vRP.owner", vRP.EXT.Base.cid)
    self.vehicles[model] = nveh -- mark as owned

    SetModelAsNoLongerNeeded(mhash)

    if state then
      self:setVehicleState(nveh, state)
    end

    vRP:triggerEvent("garageVehicleSpawn", model)
  end
end
-- return true if despawned
function Garage:despawnVehicle(model)
  local veh = self.vehicles[model]
  if veh then
    vRP:triggerEvent("garageVehicleDespawn", model)

    -- remove vehicle
    SetVehicleHasBeenOwnedByPlayer(veh,false)
    SetEntityAsMissionEntity(veh, false, true)
    SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(veh))
    Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(veh))
    self.vehicles[model] = nil

    return true
  end
end

function Garage:despawnVehicles()
  for model in pairs(self.vehicles) do
    self:despawnVehicle(model)
  end
end

-- get all game vehicles
-- return list of veh
function Garage:getAllVehicles()
  local vehs = {}
  local it, veh = FindFirstVehicle()
  if veh then table.insert(vehs, veh) end
  local ok
  repeat
    ok, veh = FindNextVehicle(it)
    if ok and veh then table.insert(vehs, veh) end
  until not ok
  EndFindVehicle(it)

  return vehs
end

-- return map of veh => distance
function Garage:getNearestVehicles(radius)
  local r = {}

  local px,py,pz = vRP.EXT.Base:getPosition()

  for _,veh in pairs(self:getAllVehicles()) do
    local x,y,z = table.unpack(GetEntityCoords(veh,true))
    local distance = GetDistanceBetweenCoords(x,y,z,px,py,pz,true)
    if distance <= radius then
      r[veh] = distance
    end
  end

  return r
end

-- return veh
function Garage:getNearestVehicle(radius)
  local veh

  local vehs = self:getNearestVehicles(radius)
  local min = radius+10.0
  for _veh,dist in pairs(vehs) do
    if dist < min then
      min = dist 
      veh = _veh 
    end
  end

  return veh 
end

-- try re-own vehicles
function Garage:tryOwnVehicles()
  for _, veh in pairs(self:getAllVehicles()) do
    local cid, model = self:getVehicleInfo(veh)
    if cid and vRP.EXT.Base.cid == cid then -- owned
      local old_veh = self.vehicles[model]
      if old_veh and IsEntityAVehicle(old_veh) then -- still valid
        if old_veh ~= veh then -- remove this new one
          SetVehicleHasBeenOwnedByPlayer(veh,false)
          SetEntityAsMissionEntity(veh, false, true)
          SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(veh))
          Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(veh))
        end
      else -- no valid old veh
        self.vehicles[model] = veh -- re-own
      end
    end
  end
end

function Garage:trySpawnOutVehicles()
  local x,y,z = vRP.EXT.Base:getPosition()

  -- spawn out vehicles
  for model, data in pairs(self.out_vehicles) do
    if not self.vehicles[model] then -- not already spawned
      local vx,vy,vz = table.unpack(data[2])
      local distance = GetDistanceBetweenCoords(x,y,z,vx,vy,vz,true)

      if distance <= self.respawn_radius then
        self:spawnVehicle(model, data[1], data[2], data[3])
      end
    end
  end
end

-- cleanup invalid owned vehicles
function Garage:cleanupVehicles()
  for model, veh in pairs(self.vehicles) do
    if not IsEntityAVehicle(veh) then
      self.vehicles[model] = nil
    end
  end
end

function Garage:fixNearestVehicle(radius)
  local veh = self:getNearestVehicle(radius)
  if IsEntityAVehicle(veh) then
    SetVehicleFixed(veh)
  end
end

function Garage:replaceNearestVehicle(radius)
  local veh = self:getNearestVehicle(radius)
  if IsEntityAVehicle(veh) then
    SetVehicleOnGroundProperly(veh)
  end
end

-- return model or nil
function Garage:getNearestOwnedVehicle(radius)
  self:cleanupVehicles()
  self:tryOwnVehicles() -- get back network lost vehicles

  local px,py,pz = vRP.EXT.Base:getPosition()
  local min_dist
  local min_k
  for k,veh in pairs(self.vehicles) do
    local x,y,z = table.unpack(GetEntityCoords(veh,true))
    local dist = GetDistanceBetweenCoords(x,y,z,px,py,pz,true)

    if dist <= radius+0.0001 then
      if not min_dist or dist < min_dist then
        min_dist = dist
        min_k = k
      end
    end
  end

  return min_k
end

-- return ok,x,y,z
function Garage:getAnyOwnedVehiclePosition()
  self:cleanupVehicles()
  self:tryOwnVehicles() -- get back network lost vehicles

  for model,veh in pairs(self.vehicles) do
    if IsEntityAVehicle(veh) then
      local x,y,z = table.unpack(GetEntityCoords(veh,true))
      return true,x,y,z
    end
  end

  return false
end

-- return x,y,z or nil
function Garage:getOwnedVehiclePosition(model)
  self:cleanupVehicles()
  self:tryOwnVehicles() -- get back network lost vehicles

  local veh = self.vehicles[model]
  if veh then
    return table.unpack(GetEntityCoords(veh,true))
  end
end

function Garage:putInOwnedVehicle(model)
  local veh = self.vehicles[model]
  if veh then
    SetPedIntoVehicle(GetPlayerPed(-1),veh,-1) -- put player inside
  end
end

-- eject the ped from the vehicle
function Garage:ejectVehicle()
  local ped = GetPlayerPed(-1)
  if IsPedSittingInAnyVehicle(ped) then
    local veh = GetVehiclePedIsIn(ped,false)
    TaskLeaveVehicle(ped, veh, 4160)
  end
end

function Garage:isInVehicle()
  local ped = GetPlayerPed(-1)
  return IsPedSittingInAnyVehicle(ped) 
end

-- return model or nil if not in owned vehicle
function Garage:getInOwnedVehicleModel()
  local veh = GetVehiclePedIsIn(GetPlayerPed(-1),false)
  local cid, model = self:getVehicleInfo(veh)
  if cid and cid == vRP.EXT.Base.cid then
    return model
  end
end

-- VEHICLE STATE

function Garage:getVehicleCustomization(veh)

  custom.colours = {GetVehicleColours(veh)}
  custom.extra_colours = {GetVehicleExtraColours(veh)}
  custom.plate_txt = GetVehicleNumberPlateText(veh)				-- custom txt
  custom.plate_index = GetVehicleNumberPlateTextIndex(veh)
  custom.wheel_type = GetVehicleWheelType(veh)
  custom.window_tint = GetVehicleWindowTint(veh)
  custom.livery = GetVehicleLivery(veh)
  custom.neons = {}
  for i=0,3 do
    custom.neons[i] = IsVehicleNeonLightEnabled(veh, i)
  end
  custom.neon_colour = {GetVehicleNeonLightsColour(veh)}
  custom.tyre_smoke_color = {GetVehicleTyreSmokeColor(veh)}

  custom.mods = {}
  for i=0,49 do
    custom.mods[i] = GetVehicleMod(veh, i)
  end

  custom.turbo_enabled = IsToggleModOn(veh, 18)
  custom.smoke_enabled = IsToggleModOn(veh, 20)
  custom.xenon_enabled = IsToggleModOn(veh, 22)

  return custom
end

-- partial update per property
function Garage:setVehicleCustomization(veh, custom)
  SetVehicleModKit(veh, 0)

  if custom.colours then
    SetVehicleColours(veh, table.unpack(custom.colours))
  end

  if custom.extra_colours then
    SetVehicleExtraColours(veh, table.unpack(custom.extra_colours))
  end

  if custom.plate_index then 
    SetVehicleNumberPlateTextIndex(veh, custom.plate_index)
  end
  
  if custom.plate_txt then 
    SetVehicleNumberPlateText(veh, custom.plate_txt)					-- custom plate txt
  end
  
  if custom.wheel_type then
    SetVehicleWheelType(veh, custom.wheel_type)
  end

  if custom.window_tint then
    SetVehicleWindowTint(veh, custom.window_tint)
  end

  if custom.livery then
    SetVehicleLivery(veh, custom.livery)
  end

  if custom.neons then
    for i=0,3 do
      SetVehicleNeonLightEnabled(veh, i, custom.neons[i])
    end
  end

  if custom.neon_colour then
    SetVehicleNeonLightsColour(veh, table.unpack(custom.neon_colour))
  end

  if custom.tyre_smoke_color then
    SetVehicleTyreSmokeColor(veh, table.unpack(custom.tyre_smoke_color))
  end

  if custom.mods then
    for i, mod in pairs(custom.mods) do
      SetVehicleMod(veh, i, mod, false)
    end
  end

  if custom.turbo_enabled ~= nil then
    ToggleVehicleMod(veh, 18, custom.turbo_enabled)
  end

  if custom.smoke_enabled ~= nil then
    ToggleVehicleMod(veh, 20, custom.smoke_enabled)
  end

  if custom.xenon_enabled ~= nil then
    ToggleVehicleMod(veh, 22, custom.xenon_enabled)
  end
end

function Garage:getVehicleState(veh)
  local state = {
    customization = self:getVehicleCustomization(veh),
    condition = {
      health = GetEntityHealth(veh),
      engine_health = GetVehicleEngineHealth(veh),
      petrol_tank_health = GetVehiclePetrolTankHealth(veh),
      dirt_level = GetVehicleDirtLevel(veh)
    }
  }

  state.condition.windows = {}
  for i=0,7 do 
    state.condition.windows[i] = IsVehicleWindowIntact(veh, i)
  end

  state.condition.tyres = {}
  for i=0,7 do
    local tyre_state = 2 -- 2: fine, 1: burst, 0: completely burst
    if IsVehicleTyreBurst(veh, i, true) then
      tyre_state = 0
    elseif IsVehicleTyreBurst(veh, i, false) then
      tyre_state = 1
    end

    state.condition.tyres[i] = tyre_state
  end

  state.condition.doors = {}
  for i=0,5 do
    state.condition.doors[i] = not IsVehicleDoorDamaged(veh, i)
  end

  state.locked = (GetVehicleDoorLockStatus(veh) >= 2)

  return state
end

-- partial update per property
function Garage:setVehicleState(veh, state)
  -- apply state
  if state.customization then
    self:setVehicleCustomization(veh, state.customization)
  end
  
  if state.condition then
    if state.condition.health then
      SetEntityHealth(veh, state.condition.health)
    end

    if state.condition.engine_health then
      SetVehicleEngineHealth(veh, state.condition.engine_health)
    end

    if state.condition.petrol_tank_health then
      SetVehiclePetrolTankHealth(veh, state.condition.petrol_tank_health)
    end

    if state.condition.dirt_level then
      SetVehicleDirtLevel(veh, state.condition.dirt_level)
    end

    if state.condition.windows then
      for i, window_state in pairs(state.condition.windows) do
        if not window_state then
          SmashVehicleWindow(veh, i)
        end
      end
    end

    if state.condition.tyres then
      for i, tyre_state in pairs(state.condition.tyres) do
        if tyre_state < 2 then
          SetVehicleTyreBurst(veh, i, (tyre_state == 1), 1000.01)
        end
      end
    end

    if state.condition.doors then
      for i, door_state in pairs(state.condition.doors) do
        if not door_state then
          SetVehicleDoorBroken(veh, i, true)
        end
      end
    end
  end

  if state.locked ~= nil then 
    if state.locked then -- lock
      SetVehicleDoorsLocked(veh,2)
      SetVehicleDoorsLockedForAllPlayers(veh, true)
    else -- unlock
      SetVehicleDoorsLockedForAllPlayers(veh, false)
      SetVehicleDoorsLocked(veh,1)
      SetVehicleDoorsLockedForPlayer(veh, PlayerId(), false)
    end
  end
end

-- VEHICLE COMMANDS

function Garage:vc_openDoor(model, door_index)
  local vehicle = self.vehicles[model]
  if vehicle then
    SetVehicleDoorOpen(vehicle,door_index,0,false)
  end
end

function Garage:vc_closeDoor(model, door_index)
  local vehicle = self.vehicles[model]
  if vehicle then
    SetVehicleDoorShut(vehicle,door_index)
  end
end

function Garage:vc_detachTrailer(model)
  local vehicle = self.vehicles[model]
  if vehicle then
    DetachVehicleFromTrailer(vehicle)
  end
end

function Garage:vc_detachTowTruck(model)
  local vehicle = self.vehicles[model]
  if vehicle then
    local ent = GetEntityAttachedToTowTruck(vehicle)
    if IsEntityAVehicle(ent) then
      DetachVehicleFromTowTruck(vehicle,ent)
    end
  end
end

function Garage:vc_detachCargobob(model)
  local vehicle = self.vehicles[model]
  if vehicle then
    local ent = GetVehicleAttachedToCargobob(vehicle)
    if IsEntityAVehicle(ent) then
      DetachVehicleFromCargobob(vehicle,ent)
    end
  end
end

function Garage:vc_toggleEngine(model)
  local vehicle = self.vehicles[model]
  if vehicle then
    local running = Citizen.InvokeNative(0xAE31E7DF9B5B132E,vehicle) -- GetIsVehicleEngineRunning
    SetVehicleEngineOn(vehicle,not running,true,true)
    if running then
      SetVehicleUndriveable(vehicle,true)
    else
      SetVehicleUndriveable(vehicle,false)
    end
  end
end

-- return true if locked, false if unlocked
function Garage:vc_toggleLock(model)
  local vehicle = self.vehicles[model]
  if vehicle then
    local veh = vehicle
    local locked = GetVehicleDoorLockStatus(veh) >= 2
    if locked then -- unlock
      SetVehicleDoorsLockedForAllPlayers(veh, false)
      SetVehicleDoorsLocked(veh,1)
      SetVehicleDoorsLockedForPlayer(veh, PlayerId(), false)
      return false
    else -- lock
      SetVehicleDoorsLocked(veh,2)
      SetVehicleDoorsLockedForAllPlayers(veh, true)
      return true
    end
  end
end

-- TUNNEL
Garage.tunnel = {}

function Garage.tunnel:setConfig(update_interval, check_interval, respawn_radius)
  self.update_interval = update_interval
  self.check_interval = check_interval
  self.respawn_radius = respawn_radius
end

function Garage.tunnel:setStateReady(state)
  self.state_ready = state
end

function Garage.tunnel:registerModels(models)
  -- generate models hashes
  for model in pairs(models) do
    local hash = GetHashKey(model)
    if hash then
      self.hash_models[hash] = model
    end
  end
end

function Garage.tunnel:setOutVehicles(out_vehicles)
  for model, data in pairs(out_vehicles) do
    self.out_vehicles[model] = data
  end
end

function Garage.tunnel:removeOutVehicles(out_vehicles)
  for model in pairs(out_vehicles) do
    self.out_vehicles[model] = nil
  end
end

function Garage.tunnel:clearOutVehicles()
  self.out_vehicles = {}
end

Garage.tunnel.spawnVehicle = Garage.spawnVehicle
Garage.tunnel.despawnVehicle = Garage.despawnVehicle
Garage.tunnel.despawnVehicles = Garage.despawnVehicles
Garage.tunnel.fixNearestVehicle = Garage.fixNearestVehicle
Garage.tunnel.replaceNearestVehicle = Garage.replaceNearestVehicle
Garage.tunnel.getNearestOwnedVehicle = Garage.getNearestOwnedVehicle
Garage.tunnel.getAnyOwnedVehiclePosition = Garage.getAnyOwnedVehiclePosition
Garage.tunnel.getOwnedVehiclePosition = Garage.getOwnedVehiclePosition
Garage.tunnel.putInOwnedVehicle = Garage.putInOwnedVehicle
Garage.tunnel.getInOwnedVehicleModel = Garage.getInOwnedVehicleModel
Garage.tunnel.tryOwnVehicles = Garage.tryOwnVehicles
Garage.tunnel.trySpawnOutVehicles = Garage.trySpawnOutVehicles
Garage.tunnel.cleanupVehicles = Garage.cleanupVehicles
Garage.tunnel.ejectVehicle = Garage.ejectVehicle
Garage.tunnel.isInVehicle = Garage.isInVehicle
Garage.tunnel.vc_openDoor = Garage.vc_openDoor
Garage.tunnel.vc_closeDoor = Garage.vc_closeDoor
Garage.tunnel.vc_detachTrailer = Garage.vc_detachTrailer
Garage.tunnel.vc_detachTowTruck = Garage.vc_detachTowTruck
Garage.tunnel.vc_detachCargobob = Garage.vc_detachCargobob
Garage.tunnel.vc_toggleEngine = Garage.vc_toggleEngine
Garage.tunnel.vc_toggleLock = Garage.vc_toggleLock

vRP:registerExtension(Garage)
