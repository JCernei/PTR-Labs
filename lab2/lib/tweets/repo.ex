defmodule Tweets.Repo do
  use Ecto.Repo,
    otp_app: :lab2,
    adapter: Ecto.Adapters.Postgres
end
