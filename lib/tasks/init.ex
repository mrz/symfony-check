defmodule Mix.Tasks.Init do
  import SymfonyVulnChecker.Repo

  def run(_) do
    case init_mnesia() do
      :error ->
        IO.puts("An error occurred while initializing the database")

      :ok ->
        case Git.clone([
                "https://github.com/FriendsOfPHP/security-advisories",
                "priv/security-advisories"
              ]) do
          {:ok, repo} -> IO.puts("#{repo} cloned successfully")
          {:error, reason} -> IO.puts("Unable to clone #{repo}: #{reason}")
        end

        populate_db()
    end
  end
end
