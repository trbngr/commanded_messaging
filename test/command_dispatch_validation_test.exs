defmodule CommandDispatchValidationTest do
  use ExUnit.Case

  # In a Commanded app, you would use this macro in a Router
  use Commanded.CommandDispatchValidation

  # just a dummy dispatch function
  def dispatch(command, _opts) do
    send(self(), {:dispatched, command})
  end

  test "don't dispatch on validation failure" do
    result =
      CreateAccount.new(%{user_id: "abc", name: "chris"})
      |> validate_and_dispatch()

    assert result == {:error, {:validation_failure, %{user_id: ["is invalid"]}}}
  end

  test "dispatch on validation success" do
    PlainCommand.new(%{property1: "test", property2: 123})
    |> validate_and_dispatch()

    assert_receive {:dispatched, %PlainCommand{property1: "test", property2: 123}}
  end
end
