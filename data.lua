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
    key_sequence="SHIFT + V",
  },
  {
    type = "flying-text",
    name = "better-disconnect-success-flying-text",
    flags = {"not-on-map", "placeable-off-grid"},
    time_to_live = 80,
    speed = 0.04,
    text_alignment = "center"
  },
  {
    type = "flying-text",
    name = "better-disconnect-failure-flying-text",
    flags = {"not-on-map", "placeable-off-grid"},
    time_to_live = 120,
    speed = 0.031,
    text_alignment = "center"
  },
}
