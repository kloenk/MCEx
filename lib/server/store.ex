defmodule MCEx.Server.Store do
  use GenServer
  require Logger

  def start_link(config) do
    GenServer.start_link(__MODULE__, %{}, name: config[:name])
  end

  def init(_) do
    # TODO: populate base data construct?
    # TODO: fetch servername and description from env to make hot changes possible?
    {:ok, %{}}
  end

  def get_user(name, num) do
    # TODO: only create a sample
    GenServer.call(name, {:get_user, num})
  end

  def get_user_count(name) do
    GenServer.call(name, {:get_user_count})
  end

  def add_user(name, {user_name, uuid, pid}) do
    GenServer.cast(name, {:add_user, {user_name, uuid, pid}})
  end

  def handle_call({:get_user, num}, _from, state) do
    user = state
    |> Map.get("users", %{})
    |> Map.to_list()
    |> Stream.map(fn {user_name, {uuid, _pid}} -> %{"name" => user_name, "id" => uuid} end)
    |> Enum.take(num)
    {:reply, user, state}
  end

  def handle_call({:get_user_count}, _from, state) do
    count = state
    |> Map.get("users", %{})
    |> Map.to_list()
    |> length()
    {:reply, count, state}
  end

  def handle_cast({:add_user, {user_name, uuid, pid}}, state) do
    Logger.debug("adding user #{user_name} to server #{inspect(self())}")
    users = state
    |> Map.get("users", %{})
    |> Map.put(user_name, {uuid, pid})
    state = Map.put(state, "users", users)
    {:noreply, state, {:continue, {:add_user, pid}}}
  end

  def handle_continue({:add_user, _pid}, state) do

    users = state
    |> Map.get("users", %{})
    |> Map.to_list()
    pids = users
    |> Stream.map(fn {_user_name, {_uuid, pid}} -> pid end)
    #|> Stream.filter(fn pid_stream -> pid_stream != pid end)
    |> Enum.into([])

    data = users
    |> Stream.map(fn {user_name, {uuid, _pid}} -> {user_name, uuid} end)
    |> Enum.into([])
    data = {:package, {:add_user, data}}

    Logger.debug("informing #{inspect(pids)} of user change with the data: #{inspect(data)}")

    Manifold.send(List.first(pids), data)

    {:noreply, state}
  end

end
