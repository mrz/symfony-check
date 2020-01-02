defmodule SymfonyVulnChecker do
  @moduledoc """
  Documentation for SymfonyVulnChecker.
  """

  @doc """
  Main checking routine.

  Given a list of (lower, upper) vulnerabilities ranges in the form [[v1, v2], [v3, v4], ...],
  and given a target version v, v is vulnerable if it is contained in any of the
  ranges, so our check can be implemented via simple boolean logic:

    isVuln = (match?(v, v1) ∧ match(v, v2)) ∨ (match?(v, v3) ∧ match?(v, v4))
  """
  def do_check({name, version}) do
    case SymfonyVulnChecker.Repo.get_dep(name) do
      {:ok, []} ->
        IO.puts(
          "[OK]      Dependency #{name} #{version} not found in vulnerability database, you are most likely safe."
        )

      {:ok, [dep]} ->
        ranges = elem(dep, 2)

        try do
          if not is_contained(version, ranges) do
            IO.puts(
              "[OK]      Dependency #{name} #{version} is not known to have any vulnerabilities."
            )
          else
            IO.puts("[PROBLEM] Dependency #{name} #{version} is known to be vulnerable.")
          end
        rescue
          # This happens when the Version module fails to parse a version
          # string. Most likely case is that the given version does not follow
          # the semantic version syntax. For a proof of concept, I reckon this
          # is a reasonable compromise, and I would address it in a future
          # development phase by introducing a more robust version parsing
          # routine, still leveraging the Version module but adding the missing
          # handling of different version formats.
          _e in Version.InvalidRequirementError -> IO.puts("[ERROR]   Could not analyze #{name}.")
        end

      {:error, reason} ->
        IO.inspect(reason)
    end
  end

  @doc """
  Return true if the given version is contained in one of the given ranges,
  false otherwise.
  """
  def is_contained(version, ranges) do
    Enum.any?(ranges, fn range ->
      Enum.all?(range, fn r -> Version.match?(version, r) end)
    end)
  end

  @doc """
  Main entry point for the checker.

  Receives the map resulting from parsing a composer.lock file, containing a
  'packages' entry which contains itself another map with 'name' and 'version'
  entries.

  %{
    "_readme": ...,
    "content-hash": ...
    "packages": [
      {"name": "composer/ca-bundle",
       "version": "1.2.4",
       ...},
       {"name": "doctrine/annotations",
        "version": "v1.5.0",
       ...},
      ]},
      ...
   }

  Analyzes each package found and checks its version against a database of known
  vulnerable version ranges.
  """
  def analyze(contents) do
    Map.get(contents, "packages")
    |> Enum.map(fn m -> {m["name"], cleanup_version(m["version"])} end)
    |> Enum.each(&SymfonyVulnChecker.do_check/1)
  end

  # private functions

  defp cleanup_version("v" <> version), do: version
  defp cleanup_version(version), do: version
end
