defmodule SymfonyVulnCheckerTest.Repo do
  use ExUnit.Case

  test "extracts version information from the branches map" do
    expected = [[">=4.5.0", "<4.6.0"], [">=4.6.0", "<4.7.0"]]

    actual =
      SymfonyVulnChecker.Repo.parse_branches(%{
          "4.5.x" => %{"time" => nil, "versions" => [">=4.5.0", "<4.6.0"]},
          "4.6.x" => %{"time" => nil, "versions" => [">=4.6.0", "<4.7.0"]}}
      )

    assert expected == actual
  end
end
