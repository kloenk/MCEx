import Config

config :mcex, :default,
  max_players: 10,
  motd: "fallback server entry for %address%:%port%",
  server: MCEx.Servers.Default

config :mcex, :localhost,
  max_players: 999,
  motd: "Test \u00a7bServer \u00a71With \u00a74Colors %address%",
  server: MCEx.Servers.Default
