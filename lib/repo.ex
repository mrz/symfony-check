defmodule SymfonyVulnChecker.Repo do
  alias :mnesia, as: Mnesia

  @doc """
  Initialize mnesia schema and required table.

  Our table is called :dependency and has two attributes, the name and a list of vulnerable
  versions. This list is a list of lists in the form:
  [
    [ '>=1.0.0', '< 1.5.0' ],
    [ '>=2.0.0', '< 2.5.0' ],
    ...
  ]
  """
  def init_mnesia do
    case Mnesia.start() do
      # start successful
      :ok ->
        Mnesia.wait_for_tables([:dependency], 2500)

        case Mnesia.create_table(:dependency,
               attributes: [:name, :versions],
               disc_copies: [node()]
             ) do
          {:atomic, :ok} ->
            :ok

          {_, {:already_exists, _}} ->
            IO.puts("Nothing to do for table :dependency")
            :ok

          _ ->
            :error
        end

      # start failed
      _ ->
        :error
    end
  end

  @doc ~S"""
  Extract the name part of a reference entry from the advisory file.

      iex> parse_reference("composer://foo/bar")
      "foo/bar"
      iex> parse_reference("bar/baz")
      "bar/baz"
  """
  def parse_reference("composer://" <> reference), do: reference
  def parse_reference(reference), do: reference

  @doc """
  Extract the list of affected versions from the advisory file.

  We are interested the field 'versions' of a structure that looks like this:

  %{
    "branches" => %{
      "4.5.x" => %{"time" => nil, "versions" => [">=4.5.0", "<4.6.0"]},
      ...
    }
  }
  """
  def parse_branches(branches) do
    Enum.map(branches, fn {_version, info} -> info["versions"] end)
  end

  def extract_and_save_info(file) do
    IO.puts("Reading from #{file}")

    case YamlElixir.read_from_file(file) do
      {:ok, contents} ->
        reference = parse_reference(contents["reference"])
        versions = parse_branches(contents["branches"])

        worker = fn ->
          record = Mnesia.read({:dependency, reference})

          # Mnesia.read returns an empty list when no match is found.
          # update_record handles this case by creating a new dependency if the
          # read did not return any result, otherwise it updates the record
          # found with the newly extracted versions.
          Mnesia.write(update_record(record, reference, versions))
        end
        case Mnesia.transaction(worker) do
          {:atomic, :ok} ->
            :ok

          {:aborted, reason} ->
            IO.puts("Transaction aborted:")
            IO.inspect(reason)
            {:error, reason}
        end

      :error ->
        :error
    end
  end

  @doc """
  Main entry point for model population.

  Get the list of YAML files containing vulnerabilities information, extract
  the relevant information then persist it to the database.
  """
  def populate_db do
    for advisory <- Path.wildcard("priv/security-advisories/**/*.yaml") do
      extract_and_save_info(advisory)
    end
  end

  @doc """
  Return the entry in the databse for the given name, if any.
  """
  def get_dep(name) do
    worker = fn -> Mnesia.read({:dependency, name}) end

    case Mnesia.transaction(worker) do
      {:atomic, dep} ->
        {:ok, dep}

      {:aborted, reason} ->
        IO.puts("Transaction aborted.")
        {:error, reason}
    end
  end

  # private functions

  # By pattern matching on the list returned by Mnesia.read() we know if we
  # need to either create a new record or update an existing one
  defp update_record([{:dependency, _, versions}] = _record, name, version) do
    IO.puts("Updating #{name}")

    create_record(name, versions, version)
  end

  defp update_record([], name, version) do
    IO.puts("Creating new record for #{name}")

    create_record(name, nil, version)
  end

  defp create_record(name, versions, version) when is_list(versions) do
    {:dependency, name, versions ++ version}
  end

  defp create_record(name, _, version) do
    {:dependency, name, version}
  end

end
