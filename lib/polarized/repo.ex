defmodule Polarized.Repo do
  use GenServer
  import Polarized.Helper, only: [call: 2]

  alias :mnesia, as: Mnesia
  alias Comeonin.Argon2, as: Crypto

  @moduledoc "The persistence repository."

  ## Client implementation

  call(:ensure_user_inserted, &ensure_user_inserted_impl/1)

  call(:remove_user, &remove_user_impl/1)

  ## Server implementation

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @impl GenServer
  def init(args) do
    :mnesia
    |> Application.fetch_env!(:dir)
    |> File.mkdir_p!()

    Mnesia.create_schema([node()])

    :ok = Mnesia.start()

    :ok = Mnesia.wait_for_tables(:mnesia.system_info(:local_tables), 5_000)

    {:ok, args}
  end

  @spec ensure_user_inserted_impl(%{username: String.t(), password: String.t()}) ::
          {:ok, :unchanged | :inserted} | {:error, any()}
  defp ensure_user_inserted_impl(%{username: username, password: password}) do
    read_user = fn -> Mnesia.read({Admin, username}) end

    with {:atomic, []} <- Mnesia.transaction(read_user),
         hashed_password <- Crypto.hashpwsalt(password),
         write_user <- fn -> Mnesia.write({Admin, username, hashed_password}) end,
         {:atomic, :ok} <- Mnesia.transaction(write_user) do
      :ok = Mnesia.wait_for_tables([Admin], 5_000)
      {:ok, :inserted}
    else
      {:atomic, [{Admin, ^username, _password}]} -> {:ok, :unchanged}
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec remove_user_impl(%{username: String.t(), password: String.t()}) :: :ok | {:error, any()}
  defp remove_user_impl(%{username: username, password: _password}) do
    remove_user = fn -> Mnesia.delete({Admin, username}) end

    case Mnesia.transaction(remove_user) do
      {:atomic, :ok} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end
end
