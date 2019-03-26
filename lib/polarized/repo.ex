defmodule Polarized.Repo do
  use GenServer
  use Private
  import Polarized.Helper, only: [call: 2]

  alias Comeonin.Argon2, as: Crypto
  alias Polarized.Content.Handle

  @moduledoc "The persistence repository."

  ## Client implementation

  call(:ensure_user_inserted, &ensure_user_inserted_impl/1)
  call(:remove_user, &remove_user_impl/1)
  call(:insert_user, &insert_user_impl/1)
  call(:upsert_user, &upsert_user_impl/1)
  call(:user_exists?, &user_exists_impl/1)
  call(:get_user, &get_user_impl/1)
  call(:insert_handle, &insert_handle_impl/1)
  call(:remove_handle, &remove_handle_impl/1)
  call(:follow_handle, &follow_handle_impl/1)
  call(:get_follow, &get_follow_impl/1)
  call(:unfollow_handle, &unfollow_handle_impl/1)

  def list_users, do: GenServer.call(__MODULE__, :list_users)
  def list_handles, do: GenServer.call(__MODULE__, :list_handles)
  def list_follows, do: GenServer.call(__MODULE__, :list_follows)
  def handle_call(:list_users, _from, state), do: {:reply, list_users_impl(), state}
  def handle_call(:list_handles, _from, state), do: {:reply, list_handles_impl(), state}
  def handle_call(:list_follows, _from, state), do: {:reply, list_follows_impl(), state}

  ## Server implementation

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @tables [
    {Admin, [:username, :password]},
    {Polarized.Content.Handle, [:name, :right_wing]},
    {Follow, [:name, :right_wing]}
  ]

  @impl GenServer
  def init(args) do
    :mnesia
    |> Application.fetch_env!(:dir)
    |> File.mkdir_p!()

    :mnesia.create_schema([node()])

    :ok = :mnesia.start()

    :ok = :mnesia.wait_for_tables(:mnesia.system_info(:local_tables), 5_000)

    Polarized.Effects.setup_tables(@tables)

    Polarized.Effects.seed()

    :ok = :mnesia.wait_for_tables(:mnesia.system_info(:local_tables), 5_000)

    {:ok, args}
  end

  @spec ensure_user_inserted_impl(%{username: String.t(), password: String.t()}) ::
          {:ok, :unchanged | :inserted} | {:error, any()}
  def ensure_user_inserted_impl(%{username: username, password: password}) do
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

  @spec list_users_impl() :: {:ok, [String.t()]} | {:error, any()}
  def list_users_impl do
    :ok = :mnesia.wait_for_tables([Admin], 5_000)

    case :mnesia.transaction(fn -> :mnesia.all_keys(Admin) end) do
      {:atomic, users} -> {:ok, users}
      {:aborted, reason} -> {:error, reason}
    end
  end

  private do
    @spec remove_user_impl(String.t()) :: :ok | {:error, any()}
    defp remove_user_impl(username) do
      remove_user = fn -> :mnesia.delete({Admin, username}) end

      case :mnesia.transaction(remove_user) do
        {:atomic, :ok} ->
          :ok = :mnesia.wait_for_tables([Admin], 5_000)

        {:aborted, reason} ->
          {:error, reason}
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
    @spec upsert_user_transaction(String.t(), String.t()) :: (() -> :ok | any())
    defp upsert_user_transaction(user, hash) do
      fn ->
        with [{Admin, ^user, _other_hash}] <- :mnesia.read({Admin, user}),
             :ok <- :mnesia.delete({Admin, user}) do
          :mnesia.write({Admin, user, hash})
        else
          [] -> :mnesia.write({Admin, user, hash})
        end
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
    defp get_user_impl(uname) do
      case :mnesia.transaction(fn -> :mnesia.read({Admin, uname}) end) do
        {:atomic, [{Admin, ^uname, hash}]} -> {:ok, %{username: uname, hashed_password: hash}}
        {:atomic, _} -> {:ok, nil}
        {:aborted, reason} -> {:error, reason}
      end
    end

    @spec list_handles_impl() :: {:ok, [%Handle{}]} | {:error, any()}
    defp list_handles_impl do
      case :mnesia.transaction(fn -> :mnesia.select(Handle, [{:_, [], [:"$_"]}]) end) do
        {:atomic, handles} -> {:ok, Enum.map(handles, &into_handle/1)}
        {:aborted, reason} -> {:error, reason}
      end
    end

    defp into_handle({_handle, name, lr}), do: %Handle{name: name, right_wing: lr}

    @spec insert_handle_impl(%Handle{}) :: :ok | {:error, :full | any()}
    defp insert_handle_impl(%Handle{} = handle) do
      case :mnesia.transaction(insert_handle_transaction(handle)) do
        {:atomic, :ok} -> :ok
        {:atomic, {:error, :full}} -> {:error, :full}
        {:aborted, reason} -> {:error, reason}
      end
    end

    @max_handles 100

    defp insert_handle_transaction(handle) do
      fn ->
        with handles when length(handles) < @max_handles <- :mnesia.all_keys(Handle),
             :ok <- :mnesia.write({Handle, handle.name, handle.right_wing}) do
          :ok
        else
          handles when is_list(handles) -> {:error, :full}
        end
      end
    end

    @spec remove_handle_impl(String.t()) :: {:ok, String.t()} | {:error, any()}
    def remove_handle_impl(name) do
      case :mnesia.transaction(fn -> :mnesia.delete({Handle, name}) end) do
        {:atomic, :ok} -> {:ok, name}
        {:aborted, reason} -> {:error, reason}
      end
    end

    @spec list_follows_impl() :: {:ok, [%Handle{}]} | {:error, any()}
    defp list_follows_impl do
      case :mnesia.transaction(fn -> :mnesia.select(Follow, [{:_, [], [:"$_"]}]) end) do
        {:atomic, follows} -> {:ok, Enum.map(follows, &into_handle/1)}
        {:aborted, reason} -> {:error, reason}
      end
    end

    @spec follow_handle_impl(String.t()) :: :ok | {:error, any()}
    defp follow_handle_impl(name) do
      follow = fn ->
        with [{Handle, ^name, right_wing} | _] <- :mnesia.read({Handle, name}),
             :ok <- :mnesia.delete({Handle, name}) do
          :mnesia.write({Follow, name, right_wing})
        else
          [] -> {:error, :does_not_exist}
        end
      end

      case :mnesia.transaction(follow) do
        {:atomic, :ok} -> :ok
        {:atomic, {:error, :does_not_exist}} -> {:error, :does_not_exist}
        {:aborted, reason} -> {:error, reason}
      end
    end

    @spec unfollow_handle_impl(String.t()) :: :ok | {:error, any()}
    defp unfollow_handle_impl(name) do
      case :mnesia.transaction(fn -> :mnesia.delete({Follow, name}) end) do
        {:atomic, :ok} -> :ok
        {:aborted, reason} -> {:error, reason}
      end
    end

    @spec get_follow_impl(String.t()) :: {:ok, %Handle{} | nil} | {:error, any()}
    defp get_follow_impl(name) do
      case :mnesia.transaction(fn -> :mnesia.read({Follow, name}) end) do
        {:atomic, [{Follow, ^name, right_wing}]} ->
          {:ok, %Handle{name: name, right_wing: right_wing}}

        {:atomic, _} ->
          {:ok, nil}

        {:aborted, reason} ->
          {:error, reason}
      end
    end
  end
end
