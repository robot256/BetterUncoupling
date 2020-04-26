--[[ Copyright (c) 2020 robot256 (MIT License)
 * Project: Better Uncoupling Control
 * File: control.lua
 * Description:  Main runtime control script and event handling.
 *   Events handled:
 *   - on_lua_shortcut
--]]

Position = require('__stdlib__/stdlib/area/position')


-- global.player_data:
--   rolling_stock 

--== ON_INIT ==--
-- Initialize global data tables
function OnInit()
  global.player_data = {}
end
script.on_init(OnInit)


--== ON_CONFIGURATION_CHANGED ==--
function OnConfigurationChanged()
  global.player_data = global.player_data or {}
end
script.on_configuration_changed(OnConfigurationChanged)


--== ON_EVENT("better-disconnect-train") ==--
-- Replace the default disconnect behavior so that it prefers to uncouple an adjacent 
function OnDisconnectTrain(event)
  -- Check if player is riding in train
  local player = game.players[event.player_index]
  local text_position = nil
  local text_type = "tutorial-flying-text"
  if player then
    local text_position = {x=player.position.x, y=player.position.y}
    local text = nil
    if player.vehicle and player.vehicle.valid then
      if player.vehicle.train then
        local wagon = player.vehicle
        local train = wagon.train
        local wagon_pos = 0
        -- Find what position of the train this wagon is
        for i=1,#train.carriages do
          if train.carriages[i].unit_number == wagon.unit_number then
            wagon_pos = i
            break
          end
        end
        assert(wagon_pos > 0, "Could not find wagon in its own train!")
        -- Find what types of wagons are in front and behind
        local my_type = wagon.type
        local wagon1 = nil
        local wagon2 = nil
        local front_type = ""
        local back_type = ""
        if wagon_pos > 1 then
          wagon1 = train.carriages[wagon_pos-1]
          front_type = wagon1.type
        end
        if wagon_pos < #train.carriages then
          wagon2 = train.carriages[wagon_pos+1]
          back_type = wagon2.type
        end
        
        -- Figure out which one is in front of this wagon.
        -- Disconnect direction is based on orientation of wagon, not direction or ordering in train.
        local front_wagon = nil
        local back_wagon = nil
        local front_text_position = nil
        local back_text_position = nil
        
        if wagon1 and wagon1.valid then
          -- Find angle to this wagon
          local vector = {x=wagon1.position.x - wagon.position.x, y=wagon1.position.y - wagon.position.y}
          local wagon_orientation = math.rad(wagon.orientation*360)
          local rotated_vector = {x=(math.cos(wagon_orientation)*vector.x+math.sin(wagon_orientation)*vector.y), 
                                  y=(math.sin(wagon_orientation)*vector.x-math.cos(wagon_orientation)*vector.y)}
          if rotated_vector.y > 1 then
            front_wagon = wagon1
            front_text_position = Position.between(wagon1.position, wagon.position)
          elseif rotated_vector.y < -1 then
            back_wagon = wagon1
            back_text_position = Position.between(wagon1.position, wagon.position)
          end
        end
        if wagon2 and wagon2.valid then
          -- Find angle to this wagon
          local vector = {x=wagon2.position.x - wagon.position.x, y=wagon2.position.y - wagon.position.y}
          local wagon_orientation = math.rad(wagon.orientation*360)
          local rotated_vector = {x=(math.cos(wagon_orientation)*vector.x+math.sin(wagon_orientation)*vector.y), 
                                  y=(math.sin(wagon_orientation)*vector.x-math.cos(wagon_orientation)*vector.y)}
          if rotated_vector.y > 1 then
            front_wagon = wagon2
            front_text_position = Position.between(wagon2.position, wagon.position)
          elseif rotated_vector.y < -1 then
            back_wagon = wagon2
            back_text_position = Position.between(wagon2.position, wagon.position)
          end
        end
        
        
        local front_type = nil
        local back_type = nil
        if front_wagon then front_type = front_wagon.type end
        if back_wagon then back_type = back_wagon.type end
        
        -- Decide what to disconnect
        -- Default to "back" unless the wagon-locomotive gap is in the front, or there is no back
        if front_type or back_type then
          if front_type and back_type then
            if my_type == "locomotive" and front_type ~= "locomotive" and back_type == "locomotive" then
              wagon.disconnect_rolling_stock(defines.rail_direction.front)
              text_position = front_text_position
            elseif my_type ~= "locomotive" and front_type == "locomotive" and back_type ~= "locomotive" then
              wagon.disconnect_rolling_stock(defines.rail_direction.front)
              text_position = front_text_position
            else
              wagon.disconnect_rolling_stock(defines.rail_direction.back)
              text_position = back_text_position
            end
          elseif back_type then
            wagon.disconnect_rolling_stock(defines.rail_direction.back)
            text_position = back_text_position
          elseif front_type then
            wagon.disconnect_rolling_stock(defines.rail_direction.front)
            text_position = front_text_position
          end
          
          player.surface.create_entity({name = "better-disconnect-success-flying-text", position = text_position, 
                                        text = {"rolling-stock-disconnected"}, render_player = player})
        else
          text = {"no-stock-to-disconnect-found"}
        end
      else -- player.vehicle.train
        text = {"cant-disconnect-rolling-stock-not-in-rolling-stock"}
      end
    else -- player.vehicle
      text = {"cant-disconnect-rolling-stock-not-in-vehicle"}
    end
    
    if text then
      player.surface.create_entity({name = "better-disconnect-failure-flying-text", position = text_position, text = text, render_player = player})
    end
  end -- player
end
script.on_event("better-disconnect-train", OnDisconnectTrain)


--== ON_EVENT("better-disconnect-locomotive") ==--
-- This control will only act if player is in a locomotive, and will disconnect the closest wagon
function OnDisconnectLocomotive(event)
  -- Check if player is riding in train
  local player = game.players[event.player_index]
  local text_position = nil
  if player then
    local text_position = {x=player.position.x, y=player.position.y}
    local text = nil
    if player.vehicle and player.vehicle.valid then
      if player.vehicle.train then
        if player.vehicle.type == "locomotive" then
          local wagon = player.vehicle
          local train = wagon.train
          local wagon_pos = 0
          -- Find what position of the train this wagon is
          for i=1,#train.carriages do
            if train.carriages[i].unit_number == wagon.unit_number then
              wagon_pos = i
              break
            end
          end
          assert(wagon_pos > 0, "Could not find wagon in its own train!")
          
          -- Search front and back to find a wagon that is not a locomotive
          local wagon1 = nil  -- dissimilar wagon to disconnect
          local wagon1a = nil -- the closest wagon adjacent to it
          
          -- Find the first closest non-locomotive wagon and its nearest adjacent wagon
          for i=1,#train.carriages do
            if wagon_pos-i >= 1 then
              if train.carriages[wagon_pos-i].type ~= "locomotive" then
                wagon1 = train.carriages[wagon_pos-i]
                wagon1a = train.carriages[wagon_pos-i+1]
                break
              end
            end
            if wagon_pos+i <= #train.carriages then
              if train.carriages[wagon_pos+i].type ~= "locomotive" then
                wagon1 = train.carriages[wagon_pos+i]
                wagon1a = train.carriages[wagon_pos+i-1]
                break
              end
            end
          end
          
          -- Figure out which one is in front of this wagon.
          -- Disconnect direction is based on orientation of wagon, not direction or ordering in train.
          if wagon1 and wagon1.valid and wagon1a and wagon1a.valid then
            -- Find angle to this wagon
            local vector = {x=wagon1.position.x - wagon1a.position.x, y=wagon1.position.y - wagon1a.position.y}
            local wagon_orientation = math.rad(wagon1a.orientation*360)
            local rotated_vector = {x=(math.cos(wagon_orientation)*vector.x+math.sin(wagon_orientation)*vector.y), 
                                    y=(math.sin(wagon_orientation)*vector.x-math.cos(wagon_orientation)*vector.y)}
            text_position = Position.between(wagon1.position, wagon1a.position)
            if rotated_vector.y > 1 then
              wagon1a.disconnect_rolling_stock(defines.rail_direction.front)
            elseif rotated_vector.y < -1 then
              wagon1a.disconnect_rolling_stock(defines.rail_direction.back)
            end
            
            player.surface.create_entity({name = "better-disconnect-success-flying-text", position = text_position,
                                          text = {"rolling-stock-disconnected"}, render_player = player})
          else
            text = {"no-wagons-to-disconnect-found"}
          end
        else -- player.vehicle
          text = {"cant-disconnect-wagons-not-in-locomotive"}
        end
      else -- player.vehicle.train
        text = {"cant-disconnect-rolling-stock-not-in-rolling-stock"}
      end
    else -- player.vehicle
      text = {"cant-disconnect-rolling-stock-not-in-vehicle"}
    end
    
    if text then
      player.surface.create_entity({name = "better-disconnect-failure-flying-text", position = text_position, text = text, render_player = player})
    end
  end -- player
end
script.on_event("better-disconnect-locomotive", OnDisconnectLocomotive)
