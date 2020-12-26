import Config

config :redis,
  key_pos: -2,
  value_pos: -4,
  command_pos: 2,
  noexpiry: "X",
  setpx_key_pos: -8,
  setpx_val_pos: -6

config :logger,
  level: :debug




  
