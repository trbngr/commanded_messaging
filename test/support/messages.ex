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
    |> validate_required([:username, :email, :age])
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than: 12)
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
    with: [:date, :sex, version: 2],
    drop: [:email]

  defimpl Commanded.Event.Upcaster, for: AccountCreatedWithDroppedKeys do
    def upcast(%{version: 1} = event, _metadata) do
      AccountCreatedVersioned.new(event, sex: "maybe", version: 2)
    end

    def upcast(event, _metadata), do: event
  end
end

defmodule AccountsRouter do
  use Commanded.Commands.Router
  use Commanded.CommandDispatchValidation
end
