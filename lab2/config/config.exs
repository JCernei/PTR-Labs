import Config

config :lab2, Tweets.Repo,
  database: "lab2_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :lab2, ecto_repos: [Tweets.Repo]
