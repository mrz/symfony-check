defmodule Mix.Tasks.Init do
  alias :mnesia, as: Mnesia
  import SymfonyVulnChecker.Repo

  def run(_) do
    case init_mnesia() do
      :error ->
        IO.puts("An error occurred while initializing the database")

      :ok ->
        repo = "https://github.com/FriendsOfPHP/security-advisories"
        dest = "priv/security-advisories"

        unless File.exists?(dest) do
          case Git.clone([repo, dest]) do
            {:ok, _} -> IO.puts("#{repo} cloned successfully in #{dest}")
            {:error, reason} -> IO.puts("Unable to clone: #{reason}")
          end
        end

        Mnesia.wait_for_tables([:dependency], 5000)

        populate_db()
    end
  end
end
