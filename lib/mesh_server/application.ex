defmodule MeshServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MeshServerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MeshServer.PubSub},
      # Start the Endpoint (http/https)
      MeshServerWeb.Endpoint,
      # Start a worker by calling: MeshServer.Worker.start_link(arg)
      # {MeshServer.Worker, arg}
      {MeshServer.Directory.Server,
       "C:/Users/oneil/Documents/Programming/mesh_server/mesh_test_folder/mailbox1/in"}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MeshServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MeshServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
