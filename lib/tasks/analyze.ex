defmodule Mix.Tasks.Analyze do
  alias :mnesia, as: Mnesia

  def run([composer_file|_]) do

    Mnesia.start()
    Mnesia.wait_for_tables([:dependency], 2500)

    File.read!(composer_file)
    |> Poison.decode!
    |> SymfonyVulnChecker.analyze
  end

end
