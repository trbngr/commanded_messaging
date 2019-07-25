defmodule EventTest do
  use ExUnit.Case

  import Ecto.Changeset, only: [apply_changes: 1]

  test "defined via commands" do
    %PlainEvent{property1: "test", property2: 123} =
      PlainCommand.new(property1: "test", property2: 123)
      |> apply_changes()
      |> PlainEvent.new()
  end

  test "defined via commands -- with extra keys" do
    command =
      CreateAccountWithAutoId.new(name: "chris")
      |> apply_changes()

    %{user_id: user_id, name: "chris", source: "ex_unit"} =
      AccountCreatedWithExtras.new(command, source: "ex_unit")

    {result, _} = UUID.info(user_id)

    assert result == :ok
  end

  test "defined via commands -- with dropped keys" do
    event =
      CreateAccountWithAutoId.new(name: "chris")
      |> apply_changes()
      |> AccountCreatedWithDroppedKeys.new()

    assert Map.has_key?(event, :user_id) == false
  end

  test "has a default version" do
    %{version: 1} = DefaultVersionEvent.create([])
  end

  test "can be explicitly versioned" do
    %{version: 2} = ExplicitlyVersionedEvent.create([])
  end
end
