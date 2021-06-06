-- https://github.com/ImagicTheCat/vRP
-- MIT license (see LICENSE or vrp/vRPShared.lua)

if not vRP.modules.garage then return end

local lang = vRP.lang

-- a basic garage implementation
local Garage = class("Garage", vRP.Extension)

-- SUBCLASS

Garage.User = class("User")

-- get owned vehicles
-- return map of model => state
--- state: 0 (out), 1 (in garage)
function Garage.User:getVehicles()
  return self.cdata.vehicles
end

-- get vehicle model state table (may be async)
function Garage.User:getVehicleState(model)
  local state = self.vehicle_states[model]
  if not state then -- load state
    local sdata = vRP:getCData(self.cid, "vRP:vehicle_state:"..model)
    if sdata and string.len(sdata) > 0 then
      state = msgpack.unpack(sdata)
    else
      state = {}
    end

    self.vehicle_states[model] = state
  end

  return state
end

-- STATIC

-- get vehicle trunk chest id by character id and model
function Garage.getVehicleChestId(cid, model)
  return "vehtrunk:"..cid.."_"..model
end

-- PRIVATE METHODS

-- menu: garage owned
local function menu_garage_owned(self)
  local function m_get(menu, model)
    local user = menu.user

    local vehicles = user:getVehicles()

    if vehicles[model] == 1 then -- in
      local vstate = user:getVehicleState(model)
      local state = {
        customization = vstate.customization,
        condition = vstate.condition,
        locked = vstate.locked
      }

      vehicles[model] = 0 -- mark as out
      self.remote._spawnVehicle(user.source, model, state)
      self.remote._setOutVehicles(user.source, {[model] = {}})
      user:closeMenu(menu)
    elseif vehicles[model] == 0 then -- out
      vRP.EXT.Base.remote._notify(user.source, lang.garage.owned.already_out())

      -- force out request
      if user:request(lang.garage.owned.force_out.request({self.cfg.force_out_fee}), 15) then
        if user:tryPayment(self.cfg.force_out_fee) then
          local vstate = user:getVehicleState(model)
          local state = {
            customization = vstate.customization,
            condition = vstate.condition,
            locked = vstate.locked
          }

          vehicles[model] = 0 -- mark as out
          self.remote._spawnVehicle(user.source, model, state)
          self.remote._setOutVehicles(user.source, {[model] = {state, vstate.position, vstate.rotation}})
          user:closeMenu(menu)
        else
          vRP.EXT.Base.remote._notify(user.source, lang.money.not_enough())
        end
      end
    end
  end

  vRP.EXT.GUI:registerMenuBuilder("garage.owned", function(menu)
    menu.title = lang.garage.owned.title()
    menu.css.header_color = "rgba(255,125,0,0.75)"
    local user = menu.user

    for model in pairs(user:getVehicles()) do
      local veh = menu.data.vehicles[model]
      if veh then
        menu:addOption(veh[1], m_get, veh[3], model)
      end
    end
  end)
end

-- menu: garage buy
local function menu_garage_buy(self)
  local function m_buy(menu, model)
    local user = menu.user
    local uvehicles = user:getVehicles()

    -- buy vehicle
    local veh = menu.data.vehicles[model]
    if veh and user:tryPayment(veh[2]) then
      uvehicles[model] = 1

      vRP.EXT.Base.remote._notify(user.source, lang.money.paid({veh[2]}))
      user:actualizeMenu()
    else
      vRP.EXT.Base.remote._notify(user.source, lang.money.not_enough())
    end
  end

  vRP.EXT.GUI:registerMenuBuilder("garage.buy", function(menu)
    menu.title = lang.garage.buy.title()
    menu.css.header_color = "rgba(255,125,0,0.75)"
    local user = menu.user

    local uvehicles = user:getVehicles()

    -- for each existing vehicle in the garage group and not already owned
    for model,veh in pairs(menu.data.vehicles) do
      if model ~= "_config" and not uvehicles[model] then
        menu:addOption(veh[1], m_buy, lang.garage.buy.info({veh[2],veh[3]}), model)
      end
    end
  end)
end

-- menu: garage sell
local function menu_garage_sell(self)
  local function m_sell(menu, model)
    local user = menu.user
    local uvehicles = user:getVehicles()

    local veh = menu.data.vehicles[model]

    local price = math.ceil(veh[2]*self.cfg.sell_factor)

    if uvehicles[model] == 1 and not user.cdata.rent_vehicles[model] then -- has vehicle in, not rented
      user:giveWallet(price)
      uvehicles[model] = nil

      vRP.EXT.Base.remote._notify(user.source,lang.money.received({price}))
      user:actualizeMenu()
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.not_found())
    end
  end

  vRP.EXT.GUI:registerMenuBuilder("garage.sell", function(menu)
    menu.title = lang.garage.sell.title()
    menu.css.header_color = "rgba(255,125,0,0.75)"
    local user = menu.user
    local uvehicles = user:getVehicles()

    -- for each existing vehicle in the garage group and owned (and not rented)
    for model,veh in pairs(menu.data.vehicles) do
      if model ~= "_config" and uvehicles[model] and not user.cdata.rent_vehicles[model] then
        local price = math.ceil(veh[2]*self.cfg.sell_factor)
        menu:addOption(veh[1], m_sell, lang.garage.buy.info({price, veh[3]}), model)
      end
    end
  end)
end

-- menu: garage rent
local function menu_garage_rent(self)
  local function m_rent(menu, model)
    local user = menu.user
    local uvehicles = user:getVehicles()

    -- rent vehicle
    local veh = menu.data.vehicles[model]
    local price = math.ceil(veh[2]*self.cfg.rent_factor)
    if user:tryPayment(price) then
      uvehicles[model] = 1
      user.cdata.rent_vehicles[model] = true

      vRP.EXT.Base.remote._notify(user.source,lang.money.paid({price}))
      user:actualizeMenu()
    else
      vRP.EXT.Base.remote._notify(user.source,lang.money.not_enough())
    end
  end

  vRP.EXT.GUI:registerMenuBuilder("garage.rent", function(menu)
    menu.title = lang.garage.rent.title()
    menu.css.header_color = "rgba(255,125,0,0.75)"
    local user = menu.user
    local uvehicles = user:getVehicles()

    -- for each existing vehicle in the garage group and not already owned
    for model,veh in pairs(menu.data.vehicles) do
      if model ~= "_config" and not uvehicles[model] then
        local price = math.ceil(veh[2]*self.cfg.rent_factor)
        menu:addOption(veh[1], m_rent, lang.garage.buy.info({price,veh[3]}), model)
      end
    end
  end)
end

-- menu: garage
local function menu_garage(self)
  local function m_owned(menu)
    local smenu = menu.user:openMenu("garage.owned", menu.data)

    menu:listen("remove", function(menu)
      menu.user:closeMenu(smenu)
    end)
  end

  local function m_buy(menu)
    local smenu = menu.user:openMenu("garage.buy", menu.data)

    menu:listen("remove", function(menu)
      menu.user:closeMenu(smenu)
    end)
  end

  local function m_sell(menu)
    local smenu = menu.user:openMenu("garage.sell", menu.data)

    menu:listen("remove", function(menu)
      menu.user:closeMenu(smenu)
    end)
  end

  local function m_rent(menu)
    local smenu = menu.user:openMenu("garage.rent", menu.data)

    menu:listen("remove", function(menu)
      menu.user:closeMenu(smenu)
    end)
  end

  local function m_store(menu)
    local user = menu.user

    local model = self.remote.getNearestOwnedVehicle(user.source, 15)
    if model then
      if menu.data.vehicles[model] then -- model in this garage
        self.remote._removeOutVehicles(user.source, {[model] = true})

        if self.remote.despawnVehicle(user.source, model) then
          local vehicles = user:getVehicles()
          if vehicles[model] then 
            vehicles[model] = 1 -- mark as in garage
          end

          vRP.EXT.Base.remote._notify(user.source, lang.garage.store.stored())
        end
      else
        vRP.EXT.Base.remote._notify(user.source, lang.garage.store.wrong_garage())
      end
    else
      vRP.EXT.Base.remote._notify(user.source, lang.garage.store.too_far())
    end

  end

  vRP.EXT.GUI:registerMenuBuilder("garage", function(menu)
    menu.title = lang.garage.title({menu.data.type})
    menu.css.header_color = "rgba(255,125,0,0.75)"

    menu:addOption(lang.garage.owned.title(), m_owned, lang.garage.owned.description())
    menu:addOption(lang.garage.buy.title(), m_buy, lang.garage.buy.description())
    menu:addOption(lang.garage.sell.title(), m_sell, lang.garage.sell.description())
    menu:addOption(lang.garage.rent.title(), m_rent, lang.garage.rent.description())
    menu:addOption(lang.garage.store.title(), m_store, lang.garage.store.description())
  end)
end

-- menu: vehicle
local function menu_vehicle(self)
  -- open trunk
  local function m_trunk(menu)
    local user = menu.user
    local model = menu.data.model

    local chestid = Garage.getVehicleChestId(user.cid, model)
    local max_weight = self.cfg.vehicle_chest_weights[menu.data.model] or self.cfg.default_vehicle_chest_weight

    -- open chest
    self.remote._vc_openDoor(user.source, model, 5)
    local smenu = user:openChest(chestid, max_weight, function()
      self.remote._vc_closeDoor(user.source, model, 5)
    end)

    if smenu then
      menu:listen("remove", function()
        user:closeMenu(smenu)
      end)
    end
  end

  -- detach trailer
  local function m_detach_trailer(menu)
    local user = menu.user
    local model = menu.data.model

    self.remote._vc_detachTrailer(user.source, model)
  end

  -- detach towtruck
  local function m_detach_towtruck(menu)
    local user = menu.user
    local model = menu.data.model

    self.remote._vc_detachTowTruck(user.source, model)
  end

  -- detach cargobob
  local function m_detach_cargobob(menu)
    local user = menu.user
    local model = menu.data.model

    self.remote._vc_detachCargobob(user.source, model)
  end

  -- lock/unlock
  local function m_lock(menu)
    local user = menu.user
    local model = menu.data.model

    local locked = self.remote.vc_toggleLock(user.source, model)
    if locked ~= nil then
      vRP.EXT.Base.remote._notify(user.source, (locked and lang.vehicle.lock.locked() or lang.vehicle.lock.unlocked()))
    end
  end

  -- engine on/off
  local function m_engine(menu)
    local user = menu.user
    local model = menu.data.model

    self.remote._vc_toggleEngine(user.source, model)
  end

  vRP.EXT.GUI:registerMenuBuilder("vehicle", function(menu)
    menu.title = lang.vehicle.title()
    menu.css.header_color = "rgba(255,125,0,0.75)"

    menu:addOption(lang.vehicle.trunk.title(), m_trunk, lang.vehicle.trunk.description())
    menu:addOption(lang.vehicle.detach_trailer.title(), m_detach_trailer, lang.vehicle.detach_trailer.description())
    menu:addOption(lang.vehicle.detach_towtruck.title(), m_detach_towtruck, lang.vehicle.detach_towtruck.description())
    menu:addOption(lang.vehicle.detach_cargobob.title(), m_detach_cargobob, lang.vehicle.detach_cargobob.description())
    menu:addOption(lang.vehicle.lock.title(), m_lock, lang.vehicle.lock.description())
    menu:addOption(lang.vehicle.engine.title(), m_engine, lang.vehicle.engine.description())
  end)
end

-- send out vehicles to player
local function send_out_vehicles(self, user)
  -- out vehicles
  local out_vehicles = {}
  for model, state in pairs(user:getVehicles()) do
    if state == 0 then -- out
      local vstate = user:getVehicleState(model)
      if vstate.position then
        local cstate = {
          customization = vstate.customization,
          condition = vstate.condition,
          locked = vstate.locked
        }

        out_vehicles[model] = {cstate, vstate.position, vstate.rotation}
      end
    end
  end

  self.remote._setOutVehicles(user.source, out_vehicles)
end

-- METHODS

function Garage:__construct()
  vRP.Extension.__construct(self)

  self.cfg = module("cfg/garages")
  self:log(#self.cfg.garages.." garages")

  self.models = {} -- map of all garage defined models

  -- register models
  for gtype, vehicles in pairs(self.cfg.garage_types) do
    for model in pairs(vehicles) do
      self.models[model] = true
    end
  end

  -- items

  vRP.EXT.Inventory:defineItem("repairkit", lang.item.repairkit.name(), lang.item.repairkit.description(), nil, 0.5)

  -- fperms

  vRP.EXT.Group:registerPermissionFunction("in_vehicle", function(user, params)
    return self.remote.isInVehicle(user.source)
  end)

  vRP.EXT.Group:registerPermissionFunction("in_owned_vehicle", function(user, params)
    local model = self.remote.getInOwnedVehicleModel(user.source)
    if model then
      if params[2] then
        return model == params[2]
      end

      return true
    end

    return false
  end)

  -- menu

  menu_garage_owned(self)
  menu_garage_buy(self)
  menu_garage_sell(self)
  menu_garage_rent(self)
  menu_garage(self)
  menu_vehicle(self)

  -- main menu

  local function m_vehicle(menu)
    local user = menu.user

    -- check vehicle
    local model = self.remote.getNearestOwnedVehicle(user.source, 7)
    if model then
      local menu = user:openMenu("vehicle", {model = model})

      local running = true
      menu:listen("remove", function(menu)
        running = false
      end)

      -- task: close menu if not next to the vehicle
      Citizen.CreateThread(function()
        while running do
          Citizen.Wait(8000)
          local check_model = self.remote.getNearestOwnedVehicle(user.source, 7)
          if model ~= check_model then
            user:closeMenu(menu)
          end
        end
      end)
    else
      vRP.EXT.Base.remote._notify(user.source,lang.vehicle.no_owned_near())
    end
  end

  -- ask trunk (open other user car chest)
  local function m_asktrunk(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,10)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      vRP.EXT.Base.remote._notify(user.source,lang.vehicle.asktrunk.asked())
      if nuser:request(lang.vehicle.asktrunk.request(),15) then -- request accepted, open trunk
        local model = self.remote.getNearestOwnedVehicle(nuser.source,7)
        if model then
          local chestid = Garage.getVehicleChestId(nuser.cid, model)
          local max_weight = self.cfg.vehicle_chest_weights[model] or self.cfg.default_vehicle_chest_weight

          -- open chest
          local cb_out = function(chestid, fullid, amount)
            local citem = vRP.EXT.Inventory:computeItem(fullid)
            if citem then
              vRP.EXT.Base.remote._notify(nuser.source,lang.inventory.give.given({citem.name,amount}))
            end
          end

          local cb_in = function(chest_id, fullid, amount)
            local citem = vRP.EXT.Inventory:computeItem(fullid)
            if citem then
              vRP.EXT.Base.remote._notify(nuser.source,lang.inventory.give.received({citem.name,amount}))
            end
          end

          self.remote._vc_openDoor(nuser.source, model, 5)
          local smenu = user:openChest(chestid, max_weight, function()
            self.remote._vc_closeDoor(nuser.source, model, 5)
          end,cb_in,cb_out)

          local running = true
          smenu:listen("remove", function(menu)
            running = false
          end)

          -- task: close menu if not next to the vehicle
          Citizen.CreateThread(function()
            while running do
              Citizen.Wait(8000)
              local check_model = self.remote.getNearestOwnedVehicle(user.source, 7)
              if model ~= check_model then
                user:closeMenu(menu)
              end
            end
          end)
        else
          vRP.EXT.Base.remote._notify(user.source,lang.vehicle.no_owned_near())
          vRP.EXT.Base.remote._notify(nuser.source,lang.vehicle.no_owned_near())
        end
      else
        vRP.EXT.Base.remote._notify(user.source,lang.common.request_refused())
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  -- repair nearest vehicle
  local function m_repair(menu)
    local user = menu.user

    -- anim and repair
    if user:tryTakeItem("repairkit",1) then
      vRP.EXT.Base.remote._playAnim(user.source,false,{task="WORLD_HUMAN_WELDING"},false)
      SetTimeout(15000, function()
        self.remote._fixNearestVehicle(user.source,7)
        vRP.EXT.Base.remote._stopAnim(user.source,false)
      end)
    end
  end

  -- replace nearest vehicle
  local function m_replace(menu)
    local user = menu.user
    self.remote._replaceNearestVehicle(user.source,7)
  end

  vRP.EXT.GUI:registerMenuBuilder("main", function(menu)
    local user = menu.user

    -- add vehicle entry
    menu:addOption(lang.vehicle.title(), m_vehicle)

    -- add ask trunk
    menu:addOption(lang.vehicle.asktrunk.title(), m_asktrunk)

    -- add repair/replace functions
    if user:hasPermission("vehicle.repair") then
      menu:addOption(lang.vehicle.repair.title(), m_repair, lang.vehicle.repair.description())
    end
    if user:hasPermission("vehicle.replace") then
      menu:addOption(lang.vehicle.replace.title(), m_replace, lang.vehicle.replace.description())
    end
  end)
end

-- EVENT
Garage.event = {}

function Garage.event:characterLoad(user)
  if not user.cdata.vehicles then
    user.cdata.vehicles = {}
  end

  if not user.cdata.rent_vehicles then
    user.cdata.rent_vehicles = {}
  end

  -- remove rented vehicles
  local vehicles = user:getVehicles()
  for model in pairs(user.cdata.rent_vehicles) do
    vehicles[model] = nil
  end

  user.vehicle_states = {}

  send_out_vehicles(self, user)
end

function Garage.event:characterUnload(user)
  self.remote._setStateReady(user.source, false)

  -- save vehicle states
  for model, state in pairs(user.vehicle_states) do
    vRP:setCData(user.cid, "vRP:vehicle_state:"..model, msgpack.pack(state))
  end

  -- despawn vehicles
  self.remote._despawnVehicles(user.source)
  self.remote._clearOutVehicles(user.source)
end

function Garage.event:save()
  for id, user in pairs(vRP.users) do
    -- save vehicle states
    for model, state in pairs(user.vehicle_states) do
      vRP:setCData(user.cid, "vRP:vehicle_state:"..model, msgpack.pack(state))
    end
  end
end

function Garage.event:playerSpawn(user, first_spawn)
  if first_spawn then
    -- config
    self.remote._setConfig(user.source, self.cfg.vehicle_update_interval, self.cfg.vehicle_check_interval, self.cfg.vehicle_respawn_radius)

    -- register models
    self.remote._registerModels(user.source, self.models)

    send_out_vehicles(self, user)

    -- build garages
    for k,v in pairs(self.cfg.garages) do
      local gtype,x,y,z,radius,height = table.unpack(v)

      -- default values
      if radius == nil then radius = 1 end
      if height == nil then height = 1.5 end

      local group = self.cfg.garage_types[gtype]
      if group then
        local gcfg = group._config

        local menu
        local function enter(user)
          if user:hasPermissions(gcfg.permissions or {}) then
            menu = user:openMenu("garage", {type = gtype, vehicles = group})
          end
        end

        -- leave
        local function leave(user)
          if menu then
            user:closeMenu(menu)
          end
        end

        local ment = clone(gcfg.map_entity)
        ment[2].title = lang.garage.title({gtype})
        ment[2].pos = {x,y,z-1}
        vRP.EXT.Map.remote._addEntity(user.source,ment[1], ment[2])

        user:setArea("vRP:garage:"..k,x,y,z,radius,height,enter,leave)
      end
    end
  end
end

function Garage.event:playerStateLoaded(user)
  self.remote._tryOwnVehicles(user.source)
  self.remote.trySpawnOutVehicles(user.source)

  if user.cdata.state.in_owned_vehicle then
    self.remote._putInOwnedVehicle(user.source, user.cdata.state.in_owned_vehicle)
  end

  self.remote._setStateReady(user.source, true)
end

-- TUNNEL
Garage.tunnel = {}

function Garage.tunnel:updateVehicleStates(states)
  local user = vRP.users_by_source[source]

  if user then
    for model, state in pairs(states) do
      if user.cdata.vehicles[model] then -- has model
        local vstate = user:getVehicleState(model)

        if state.customization then
          vstate.customization = state.customization
        end

        if state.condition then
          vstate.condition = state.condition
        end

        if state.position then vstate.position = state.position end
        if state.rotation then vstate.rotation = state.rotation end

        if state.locked ~= nil then vstate.locked = state.locked end
      end
    end
  end
end

vRP:registerExtension(Garage)
