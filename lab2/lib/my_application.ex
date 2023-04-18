defmodule MyApplication do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Tweets.Repo,
      %{
        id: MyApp,
        start: {MyApp, :start_link, []},
        # type: :worker,
        restart: :permanent
        # shutdown: 500
      }
      # Starts a worker by calling: Lab2.Worker.start_link(arg)
      # {Lab2.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lab2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
