alias :mnesia, as: Mnesia
require Logger

Mnesia.create_schema([node()])

:ok = Mnesia.start()

tables = [
  {Admin, [:username, :password]}
]

# sets up the tables necessary to operate the app

for {table_name, attributes} <- tables do
  table_name
  |> Mnesia.create_table(attributes: attributes, disc_copies: [node()])
  |> case do
    {:atomic, :ok} ->
      Logger.info("#{table_name} table created with attributes #{inspect(attributes)}.")

    {:aborted, {:already_exists, ^table_name}} ->
      Logger.info("#{table_name} table already exists.")

    {:aborted, reason} ->
      Logger.error("Could not create #{table_name} table. Reason: #{inspect(reason)}")
  end
end

# setup the initial admin user
Logger.info("Inserting default admin user...")

%{username: "adminimum", password: "pleasechangethis"}
|> Polarized.Repo.ensure_user_inserted()
|> case do
  {:ok, :unchanged} ->
    Logger.info("Admin user was already inserted.")

  {:ok, :inserted} ->
    Logger.info("Admin user added.")

  {:error, reason} ->
    Logger.error("Insertion failed! #{inspect(reason)}")
end
