--[[ Copyright (c) 2020 robot256 (MIT License)
 * Project: Vehicle Wagon 2 rewrite
 * File: data.lua
 * Description:  Main Data Stage function.  Include all the prototype definitions.
 --]]

data:extend{
  {
    type="custom-input",
    name="better-disconnect-train",
    key_sequence="",
    linked_game_control="disconnect-train",
    consuming="game-only",
  }
}
