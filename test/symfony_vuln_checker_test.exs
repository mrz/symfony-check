defmodule SymfonyVulnCheckerTest do
  use ExUnit.Case
  doctest SymfonyVulnChecker

  test "checks a given version against a list of version ranges and verifies it is contained" do
    ranges = [[">=1.0.0", "<1.12.3"], ["<1.20.0"], ["<1.38.0"], [">=2.0.0", "<2.7.0"]]
    version = "1.10.0"

    expected = true
    actual = SymfonyVulnChecker.is_contained(version, ranges)

    assert expected == actual
  end

  test "checks a given version against a list of version ranges and verifies it is not contained" do
    ranges = [[">=1.0.0", "<1.12.3"], ["<1.20.0"], ["<1.38.0"], [">=2.0.0", "<2.7.0"]]
    version = "1.40.0"

    expected = false
    actual = SymfonyVulnChecker.is_contained(version, ranges)

    assert expected == actual
  end
end
