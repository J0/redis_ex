defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """
  use Application
  require Logger
  @key_pos Application.get_env(:redis, :key_pos)
  @value_pos Application.get_env(:redis, :value_pos)
  @command_pos Application.get_env(:redis, :command_pos)
  @noexpiry Application.get_env(:redis, :noexpiry)
  @setpx_key_pos Application.get_env(:redis, :setpx_key_pos)
  @setpx_value_pos Application.get_env(:redis, :setpx_val_pos)

  def start(_type, _args) do
    :ets.new(:kv, [:set, :public, :named_table])

    Supervisor.start_link(
      [{Task.Supervisor, name: Server.TaskSupervisor}, {Task, fn -> Server.listen() end}],
      strategy: :one_for_one
    )
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
    Logger.info("Accepting connections on 6379")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Server.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(client) do
    client
    |> read_line()
    |> write_line(client)

    serve(client)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  @doc """
  Take in an input and reply with the exact same statement
  """
  def echo(socket, command_arr) do
    echo_statement = Enum.at(command_arr, -2)
    :gen_tcp.send(socket, "+#{echo_statement}\r\n")
  end

  def set(socket, command_arr) do
    val = Enum.at(command_arr, @value_pos)

    case val do
      "px" -> set_px(command_arr)
      _ -> set_reg(command_arr)
    end

    :gen_tcp.send(socket, "+OK\r\n")
  end

  @doc """
  Set a key to a particular value with a timeout value defined by the flag PX
  """
  def set_px(command_arr) do
    # Assume a fixed position within the array
    key = Enum.at(command_arr, @setpx_key_pos)
    val = Enum.at(command_arr, @setpx_value_pos)
    expiry = :os.system_time(:millisecond) + String.to_integer(Enum.at(command_arr, -2))
    :ets.insert(:kv, {key, val, expiry})
  end

  def set_reg(command_arr) do
    key = Enum.at(command_arr, @key_pos)
    val = Enum.at(command_arr, @value_pos)
    # Define X to be a marker for no expiry
    :ets.insert(:kv, {key, val, @noexpiry})
  end

  def get(socket, command_arr) do
    key = Enum.at(command_arr, @key_pos)
    res = :ets.match(:kv, {key, :"$1", :"$2"}) |> List.flatten() |> check_freshness()
    :gen_tcp.send(socket, "#{res}\r\n")
  end

  defp check_freshness([result, expiration]) do
    cond do
      expiration > :os.system_time(:millisecond) -> "+#{result}"
      expiration == @noexpiry -> "+#{result}"
      :else -> "$-1"
    end
  end

  defp write_line(line, socket) do
    command_arr = String.split(line, "\r\n")
    command = Enum.at(command_arr, @command_pos) |> String.downcase()

    case command do
      "ping" -> :gen_tcp.send(socket, "+PONG\r\n")
      "set" -> set(socket, command_arr)
      "get" -> get(socket, command_arr)
      "echo" -> echo(socket, command_arr)
      _ -> nil
    end
  end
end
