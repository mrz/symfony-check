defmodule Mix.Tasks.CreateSchema do
  alias :mnesia, as: Mnesia

  @shortdoc """
  First time initialization procedure.
  """
  def run(_) do
    case Mnesia.create_schema([node()]) do
      # create_schema succeded
      :ok ->
        :ok

      # create_schema failed because the schema already exists
      {:error, {node, {:already_exists, node}}} ->
        IO.puts("Nothing to do on #{node}")
        :ok

      # create_schema failed because of other reasons
      _ ->
        :error
    end
  end
end
