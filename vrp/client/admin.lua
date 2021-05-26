-- https://github.com/ImagicTheCat/vRP
-- MIT license (see LICENSE or vrp/vRPShared.lua)

if not vRP.modules.admin then return end

local Admin = class("Admin", vRP.Extension)

-- METHODS

function Admin:__construct()
  vRP.Extension.__construct(self)

  self.noclip = false
  self.noclip_speed = 1.0

  -- noclip task
  Citizen.CreateThread(function()
    local Base = vRP.EXT.Base

    while true do
      Citizen.Wait(0)
      if self.noclip then
        local ped = GetPlayerPed(-1)
        local x,y,z = Base:getPosition()
        local dx,dy,dz = Base:getCamDirection()
        local speed = self.noclip_speed

        -- reset velocity
        SetEntityVelocity(ped, 0.0001, 0.0001, 0.0001)

        -- forward
        if IsControlPressed(0,32) then -- MOVE UP
          x = x+speed*dx
          y = y+speed*dy
          z = z+speed*dz
        end

        -- backward
        if IsControlPressed(0,269) then -- MOVE DOWN
          x = x-speed*dx
          y = y-speed*dy
          z = z-speed*dz
        end

        SetEntityCoordsNoOffset(ped,x,y,z,true,true,true)
      end
    end
  end)
end

function Admin:toggleNoclip()
  self.noclip = not self.noclip

  local ped = GetPlayerPed(-1)
  if self.noclip then -- set
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)
  else -- unset
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
  end
end

-- ref: https://github.com/citizenfx/project-lambdamenu/blob/master/LambdaMenu/teleportation.cpp#L301
function Admin:teleportToMarker()
  local ped = GetPlayerPed(-1)

  -- find GPS blip

  local it = GetBlipInfoIdIterator()
  local blip = GetFirstBlipInfoId(it)
  local ok, done
  repeat
    ok = DoesBlipExist(blip)
    if ok then
      if GetBlipInfoIdType(blip) == 4 then
        ok = false
        done = true
      else
        blip = GetNextBlipInfoId(it)
      end
    end
  until not ok

  if done then
    local x,y = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, blip, Citizen.ResultAsVector())) -- GetBlipInfoIdCoord fix

    local gz, ground = 0.0, false
    for z=0,1000,5 do
      SetEntityCoords(ped, x+0.0, y+0.0, z+0.0, 1,0,0,1)
      Citizen.Wait(5)
      ground, gz = GetGroundZFor_3dCoord(x + 0.0,y + 0.0,z + 0.0)
      if ground then break end
    end

    if ground then
      vRP.EXT.Base:teleport(x,y,gz+1.5)
    else
      vRP.EXT.Base:teleport(x,y,1000)
      GiveDelayedWeaponToPed(ped, 0xFBAB5776, 1, 0)
    end
  end
end

-- TUNNEL

Admin.tunnel = {}
Admin.tunnel.toggleNoclip = Admin.toggleNoclip
Admin.tunnel.teleportToMarker = Admin.teleportToMarker

vRP:registerExtension(Admin)
