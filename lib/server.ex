defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """

  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Server.listen() end}], strategy: :one_for_one)
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    IO.puts("Your code goes here!")

    # Uncomment this block to pass the first stage
    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])
    {:ok, _client} = :gen_tcp.accept(socket)
    socket |> read_line |> :gen_tcp.send(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    case data do
      "PING" -> "+PONG\r\n"
       _ -> :error
    end
  end
end
