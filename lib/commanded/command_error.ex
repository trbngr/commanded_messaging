defmodule Commanded.CommandError do
  defexception [:command]

  def message(_), do: "Invalid command"
end
