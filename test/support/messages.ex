defmodule PlainCommand do
  use Commanded.Command,
    property1: :string,
    property2: :integer
end

defmodule CreateAccount do
  use Commanded.Command,
    user_id: :binary_id,
    name: :string

  def validate(changeset) do
    changeset
    |> validate_required([:user_id, :name])
  end
end

defmodule CreateAccountWithAutoId do
  use Commanded.Command,
    user_id: :binary_id,
    name: :string

  def validate(changeset) do
    changeset
    |> put_change(:user_id, UUID.uuid4())
    |> validate_required([:user_id, :name])
  end
end

defmodule PlainEvent do
  use Commanded.Event,
    from: PlainCommand
end

defmodule AccountCreatedWithExtras do
  use Commanded.Event,
    from: CreateAccount,
    with: [:source]
end

defmodule AccountCreatedWithDroppedKeys do
  use Commanded.Event,
    from: CreateAccount,
    except: [:user_id]
end

defmodule DefaultVersionEvent do
  use Commanded.Event,
    from: CreateAccount
end

defmodule ExplicitlyVersionedEvent do
  use Commanded.Event, from: CreateAccount, with: [version: 2]
end
