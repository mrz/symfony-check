# SymfonyVulnChecker

## Description

Ideally, we would like to rely on a third party provider of the checking
functionality, and we would then only have to be concerned with maintenance of a
small client. For the sake of the test, I decided to not rely on existing
checkers (either web or command line based) and instead create something
that is capable of populating a local database of known vulnerable package
versions and of checking that a given composer.lock file contains no vulnerable
packages.

Therefore, this implementation of a Standard Symfony application vulnerabilities checker
is based on top of a database of known vulnerabilities [available on
Github](https://github.com/FriendsOfPHP/security-advisories).

In this database we can find a list of packages and their known vulnerable
versions. After checking how this information is presented to the user (YAML
files with a list of ranges in the form ```[[lower_vulnerable_version_range, upper_vulnerable_version_range_], ...]```)
I implemented a checker using the elixir builtin [`Version` module](https://hexdocs.pm/elixir/Version.html),
which is able to parse versions following the SemVer syntax.
A version is vulnerable if it's contained in any of the known vulnerable version
ranges found in the repository:

    ver = 1.10.0
    v1  = >=1.0.0
    v2  = <1.5.0
    v3  = >=2.5.0
    v4  = <2.7.0

    vuln? = ( match?(ver, v1) ∧ match(ver, v2) ) ∨ ( match?(ver, v3) ∧ match?(ver, v4) )

## Usage

After cloning and downlading the needed dependencies with `mix deps.get`, the
database needs to be initialized and populated using two provided mix tasks:
`create_schema` and `init`.
The `create_schema` task ([found here](lib/tasks/create_schema.ex)) creates a
mnesia disc backed database and the needed table.
The `init` task ([found here](lib/tasks/init.ex)) is used to perform a git clone
of the above-mentioned repository and populates the mnesia database with the
data analyzed from the clone.

The [`analyze`](lib/tasks/analyze.ex) task finally is the intended user exposed interface, and it receives as argument the path to a
composer.lock file to analyze for vulnerabilities:

    ~/P/symfony_vuln_checker (master|✚1) $ mix analyze ../symfony-standard/composer.lock

    ...

    [OK]      Dependency composer/ca-bundle 1.2.4 not found in vulnerability database, you are most likely safe.
    [PROBLEM] Dependency doctrine/annotations 1.2.5 is known to be vulnerable.
    [ERROR]   Could not analyze paragonie/random_compat.

    ...


For sake of brevity, I did not handle non SemVer versions
(`paragonie/random_compat` in the above output is an example of this, since in
the repository the vulnerable version is "<2.0").

## Improvements

As agreed, I did not take this project very far, as complexity is concerned. As
mentioned, I do believe that the ideal solution for this task would be to rely
on a third party to provide this service and interface with them (for example,
[here](https://github.com/sensiolabs/security-checker) we can see a command
line, web-based approach, and Symfony itself should also provide a `symfony
security:check` command to do something like this).

If we were to make this implementatin more robust however I would start with
handling different version syntaxes first, then an easier way to perform the
check (the user should not have to invoke `mix`, should not have to change
directories, etc.), and the database should probably be handled separately from
the checking logic (no database handling code should go in *this* project, but
we should only connect to and query a known endpoint/service/database from
here).
