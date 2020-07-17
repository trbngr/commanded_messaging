defmodule BasicCreateAccount do
  use Commanded.Command,
    username: :string,
    email: :string,
    age: :integer
end

defmodule CreateAccount do
  use Commanded.Command,
    username: :string,
    email: :string,
    age: :integer,
    aliases: {{:array, :string}}

  def handle_validate(changeset) do
    changeset
    |> Changeset.validate_required([:username, :email, :age])
    |> Changeset.validate_format(:email, ~r/@/)
    |> Changeset.validate_number(:age, greater_than: 12)
  end
end

defmodule CreateFakeAccount do
  use Commanded.Command,
    username: :string,
    email: :string,
    age: :integer,
    aliases: {{:array, :string}}

  def handle_validate(changeset) do
    changeset
    |> Changeset.validate_required([:username, :email, :age])
    |> Changeset.validate_format(:email, ~r/@/)
    |> Changeset.validate_number(:age, greater_than: 12)
  end
end

defmodule BasicAccountCreated do
  use Commanded.Event,
    from: CreateAccount
end

defmodule AccountCreatedWithExtraKeys do
  use Commanded.Event,
    from: CreateAccount,
    with: [:date]
end

defmodule AccountCreatedWithDroppedKeys do
  use Commanded.Event,
    from: CreateAccount,
    with: [:date],
    drop: [:email]
end

defmodule AccountCreatedVersioned do
  use Commanded.Event,
    from: CreateAccount,
    with: [:date, :sex, field_with_default_value: "default_value"],
    drop: [:email]

  defimpl Commanded.Event.Upcaster, for: AccountCreatedWithDroppedKeys do
    def upcast(event, _metadata) do
      AccountCreatedVersioned.new(event, sex: "maybe")
    end

    def upcast(event, _metadata), do: event
  end
end

defmodule AccountsRouter do
  use Commanded.Commands.Router
  use Commanded.CommandDispatchValidation
end
