--[[ Copyright (c) 2020 robot256 (MIT License)
 * Project: Better Uncoupling Control
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
  },
  {
    type="custom-input",
    name="better-disconnect-locomotive",
    key_sequence="SHIFT + K",
  }
}
