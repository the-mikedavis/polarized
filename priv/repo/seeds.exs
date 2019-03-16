require Logger

Logger.info("Running seeds for #{Mix.env()}")

# setup the initial admin user
Logger.info("Inserting default admin user...")

%{username: "adminimum", password: "pleasechangethis"}
|> Polarized.Repo.ensure_user_inserted()
|> case do
  {:ok, :unchanged} ->
    Logger.info("Admin user was already inserted.")

  {:ok, :inserted} ->
    Logger.info("Admin user added.")

    # wait for changes to mnesia to propagate to disk
    Process.sleep(2_000)

  {:error, reason} ->
    Logger.error("Insertion failed! #{inspect(reason)}")
end
