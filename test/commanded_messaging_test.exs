defmodule CommandTest do
  use ExUnit.Case
  doctest Commanded.Event
  doctest Commanded.Command
  doctest CommandedMessaging
  doctest Commanded.Middleware.CommandValidation
end
