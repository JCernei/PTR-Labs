defmodule StarWarsApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      StarWarsApiWeb.Telemetry,
      # Start the Ecto repository
      StarWarsApi.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: StarWarsApi.PubSub},
      # Start Finch
      {Finch, name: StarWarsApi.Finch},
      # Start the Endpoint (http/https)
      StarWarsApiWeb.Endpoint
      # Start a worker by calling: StarWarsApi.Worker.start_link(arg)
      # {StarWarsApi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StarWarsApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StarWarsApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
