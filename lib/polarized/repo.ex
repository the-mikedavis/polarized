defmodule Polarized.Repo do
  use GenServer
  import Polarized.Helper, only: [call: 2]

  alias Comeonin.Argon2, as: Crypto

  @moduledoc "The persistence repository."

  ## Client implementation

  call(:ensure_user_inserted, &ensure_user_inserted_impl/1)
  call(:remove_user, &remove_user_impl/1)
  call(:insert_user, &insert_user_impl/1)
  call(:upsert_user, &upsert_user_impl/1)
  call(:user_exists?, &user_exists_impl/1)
  call(:get_user, &get_user_impl/1)

  def list_users, do: GenServer.call(__MODULE__, :list_users)
  def handle_call(:list_users, _from, state), do: {:reply, list_users_impl(), state}

  ## Server implementation

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @impl GenServer
  def init(args) do
    :mnesia
    |> Application.fetch_env!(:dir)
    |> File.mkdir_p!()

    :mnesia.create_schema([node()])

    :ok = :mnesia.start()

    :ok = :mnesia.wait_for_tables(:mnesia.system_info(:local_tables), 5_000)

    {:ok, args}
  end

  @spec ensure_user_inserted_impl(%{username: String.t(), password: String.t()}) ::
          {:ok, :unchanged | :inserted} | {:error, any()}
  defp ensure_user_inserted_impl(%{username: username, password: password}) do
    read_user = fn -> :mnesia.read({Admin, username}) end

    with {:atomic, []} <- :mnesia.transaction(read_user),
         hashed_password <- Crypto.hashpwsalt(password),
         write_user <- fn -> :mnesia.write({Admin, username, hashed_password}) end,
         {:atomic, :ok} <- :mnesia.transaction(write_user) do
      :ok = :mnesia.wait_for_tables([Admin], 5_000)
      {:ok, :inserted}
    else
      {:atomic, [{Admin, ^username, _password}]} -> {:ok, :unchanged}
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec remove_user_impl(String.t()) :: :ok | {:error, any()}
  defp remove_user_impl(username) do
    remove_user = fn -> :mnesia.delete({Admin, username}) end

    case :mnesia.transaction(remove_user) do
      {:atomic, :ok} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec insert_user_impl(%{username: String.t(), password: String.t()}) ::
          {:ok, String.t()} | {:error, any()}
  defp insert_user_impl(%{username: uname, password: _pass} = user) do
    case :mnesia.transaction(fn -> :mnesia.read({Admin, uname}) end) do
      {:atomic, []} -> upsert_user_impl(user)
      {:atomic, _} -> {:error, :exists}
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec upsert_user_impl(%{username: String.t(), password: String.t()}) ::
          {:ok, String.t()} | {:error, any()}
  defp upsert_user_impl(%{username: uname, password: pass}) do
    hash = Crypto.hashpwsalt(pass)

    case :mnesia.transaction(upsert_user_transaction(uname, hash)) do
      {:atomic, :ok} -> {:ok, uname}
      {:aborted, reason} -> {:error, reason}
    end
  end

  # returns an mnesia transaction function
  # higher order
  @spec upsert_user_transaction(String.t(), String.t()) :: {:atomic, :ok} | {:aborted, any()}
  defp upsert_user_transaction(user, hash) do
    fn ->
      with {:atomic, [{Admin, ^user, _other_hash}]} <- :mnesia.read({Admin, user}),
           {:atomic, :ok} <- :mnesia.delete({Admin, user}) do
        :mnesia.write({Admin, user, hash})
      else
        {:atomic, []} -> :mnesia.write({Admin, user, hash})
        {:aborted, _reason} = a -> a
      end
    end
  end

  @spec list_users_impl() :: {:ok, [String.t()]} | {:error, any()}
  defp list_users_impl do
    case :mnesia.transaction(fn -> :mnesia.all_keys(Admin) end) do
      {:atomic, users} -> {:ok, users}
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec user_exists_impl(String.t()) :: {:ok, boolean()} | {:error, any()}
  defp user_exists_impl(uname) do
    case :mnesia.transaction(fn -> :mnesia.read({Admin, uname}) end) do
      {:atomic, [{Admin, ^uname, _password_hash}]} -> {:ok, true}
      {:atomic, _} -> {:ok, false}
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec get_user_impl(String.t()) ::
          {:ok, %{username: String.t(), hashed_password: String.t()}} | {:error, any()}
  def get_user_impl(uname) do
    case :mnesia.transaction(fn -> :mnesia.read({Admin, uname}) end) do
      {:atomic, [{Admin, ^uname, hash}]} -> {:ok, %{username: uname, hashed_password: hash}}
      {:atomic, _} -> {:ok, nil}
      {:aborted, reason} -> {:error, reason}
    end
  end
end
