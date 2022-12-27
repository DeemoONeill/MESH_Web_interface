defmodule MeshServer.Directory.Server do
  use GenServer
  alias MeshServer.Directory

  def start_link(path) do
    name = (Path.split(path) |> List.last()) <> "box"

    case GenServer.start_link(__MODULE__, path, name: {:global, name}) do
      {:ok, pid} ->
        GenServer.cast(pid, {:new, path})
        schedule_update(pid)
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
  end

  def get_mailbox(pid) do
    GenServer.call(pid, :get)
  end

  @impl true
  def init(path) do
    {:ok, path}
  end

  @impl true
  def handle_cast({:new, path}, _state) do
    {:noreply, Directory.new(path)}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:updated, state}, _old_state), do: {:noreply, state}

  @impl true
  def handle_info({:scheduled_update, pid}, %Directory{} = state) do
    schedule_update(pid)

    Task.start(fn ->
      Directory.new(state.folder)
      |> then(&send(pid, {:updated, &1}))
    end)

    {:noreply, state}
  end

  defp schedule_update(pid) do
    Process.send_after(pid, {:scheduled_update, pid}, :timer.seconds(30))
  end
end
