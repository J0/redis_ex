defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """

  use Application
  require Logger

  def start(_type, _args) do
    Supervisor.start_link(
      [{Task.Supervisor, name: Server.TaskSupervisor}, {Task, fn -> Server.listen() end}],
      strategy: :one_for_one
    )
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    # Uncomment this block to pass the first stage
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

  defp write_line(line, socket) do
    command_arr = String.split(line, "\\r\\n")
    echo_statement = Enum.at(command_arr, -2)

    case line do
      "Ping" -> :gen_tcp.send(socket, "+PONG\r\n")
      _ -> :gen_tcp.send(socket, "+#{echo_statement}\r\n")
    end
  end
end
