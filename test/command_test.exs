defmodule CommandTest do
  use ExUnit.Case

  import Ecto.Changeset, only: [apply_changes: 1, traverse_errors: 2]

  def read_errors(changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  test "commands return changesets" do
    %Ecto.Changeset{} = changeset = PlainCommand.new(%{property1: "test", property2: 123})
    assert true == changeset.valid?()

    %PlainCommand{property1: "test", property2: 123} = apply_changes(changeset)
  end

  test "validation failure" do
    changeset = CreateAccount.new(%{})

    assert false == changeset.valid?()

    errors = read_errors(changeset)
    assert %{name: ["can't be blank"], user_id: ["can't be blank"]} = errors
  end
end
