defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """

  use Application
  require Logger

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Server.listen() end}], strategy: :one_for_one)
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
    Logger.info("test")
    serve(client)
    Logger.info("Accepting")
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
    case line do
      "Ping\n" -> :gen_tcp.send(socket, "+PONG\r\n")
       _ -> :gen_tcp.send(socket, "+PONG\r\n")
    end
  end
end
