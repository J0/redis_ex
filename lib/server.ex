defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """
  use Application
  require Logger

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

  defp echo(socket, command_arr) do
    echo_statement = Enum.at(command_arr, -2)
    IO.inspect(echo_statement)
    :gen_tcp.send(socket, "+#{echo_statement}\r\n")
  end

  defp set(socket, command_arr) do
    key = Enum.at(command_arr, -2)
    val = Enum.at(command_arr, -4)
    :ets.insert(:kv, {key, val})
    IO.inspect(:ets.lookup(:kv,key))
    :gen_tcp.send(socket, "+OK\r\n")
  end

  defp get(socket, command_arr) do
    key = Enum.at(command_arr, -2)
    res = :ets.match(:kv, {key, :"$1"})
    IO.inspect(res)
    :gen_tcp.send(socket, "#{res}\r\n")


    
  end
  defp write_line(line, socket) do
    command_arr = String.split(line, "\r\n")
    IO.inspect(command_arr)
    command = Enum.at(command_arr, 2) |>String.downcase
    IO.inspect(command_arr)
    IO.inspect(command)
    IO.inspect(line)
    case command do
      "ping" -> :gen_tcp.send(socket, "+PONG\r\n")
      "set"-> set(socket, command_arr)
      "get"-> get(socket, command_arr)
      "echo"-> echo(socket,command_arr)
      _ -> :gen_tcp.send(socket, "Nope")
    end
  end
end
