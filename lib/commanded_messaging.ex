defmodule CommandedMessaging do
  @moduledoc ~S"""
  # Commanded Messaging

  **Common macros for messaging in a Commanded application**

  ## Commands

  The `Commanded.Command` macro creates an Ecto `embedded_schema` so you can take advantage of the well known `Ecto.Changeset` API.

    defmodule BasicCreateAccount do
      use Commanded.Command,
        username: :string,
        email: :string,
        age: :integer
    end

    iex> BasicCreateAccount.new()
    %BasicCreateAccount{age: nil, email: nil, username: nil}

  ### Validation

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

    iex> CreateAccount.validate(%{age: nil, aliases: nil, email: nil, username: nil})
    #Ecto.Changeset<action: nil, changes: %{}, errors: [username: {"can't be blank", [validation: :required]}, email: {"can't be blank", [validation: :required]}, age: {"can't be blank", [validation: :required]}], data: #CreateAccount<>, valid?: false>

    iex> CreateAccount.validate(%{username: "chris", email: "chris@example.com", age: 5})
    #Ecto.Changeset<action: nil, changes: %{age: 5, email: "chris@example.com", username: "chris"}, errors: [age: {"must be greater than %{number}", [validation: :number, kind: :greater_than, number: 12]}], data: #CreateAccount<>, valid?: false>

  To create the actual command struct, use `Ecto.Changeset.apply_changes/1`

    iex> command = CreateAccount.validate(%{username: "chris", email: "chris@example.com", age: 5})
    iex> Ecto.Changeset.apply_changes(command)
    %CreateAccount{age: 5, email: "chris@example.com", username: "chris"}

  > Note that `apply_changes` will not validate values.

  ## Events

  Most events mirror the commands that produce them. So we make it easy to reduce the boilerplate in creating them with the `Commanded.Event` macro.

    defmodule BasicAccountCreated do
      use Commanded.Event,
        from: CreateAccount
    end

    iex> cmd = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
    iex> BasicAccountCreated.new(cmd)
    %BasicAccountCreated{age: 5, email: "chris@example.com", username: "chris"}


  ### Extra Keys

  There are times when we need keys defined on an event that aren't part of the originating command. We can add these very easily.

    defmodule AccountCreatedWithExtraKeys do
      use Commanded.Event,
        from: CreateAccount,
        with: [:date]
    end

    iex> cmd = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
    iex> AccountCreatedWithExtraKeys.new(cmd, date: ~D[2019-07-25])
    %AccountCreatedWithExtraKeys{age: 5, date: ~D[2019-07-25], email: "chris@example.com", username: "chris"}

  ### Excluding Keys

  And you may also want to drop some keys from your command.

    defmodule AccountCreatedWithDroppedKeys do
      use Commanded.Event,
        from: CreateAccount,
        with: [:date],
        drop: [:email]
    end

    iex> cmd = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
    iex> AccountCreatedWithDroppedKeys.new(cmd)
    %AccountCreatedWithDroppedKeys{age: 5, date: nil, username: "chris"}

  ### Versioning

  You should define an upcast instance that knows how to transform older events into the latest version.

    # This is for demonstration purposes only. You don't need to create a new event to version one.
    defmodule AccountCreatedVersioned do
      use Commanded.Event,
        from: CreateAccount,
        with: [:date, :sex, field_with_default_value: "default_value"],
        drop: [:email]

      defimpl Commanded.Event.Upcaster, for: AccountCreatedWithDroppedKeys do
        def upcast(%AccountCreatedWithDroppedKeys{} = event, _metadata) do
          AccountCreatedVersioned.new(event, sex: "maybe")
        end

        def upcast(event, _metadata), do: event
      end
    end

    iex> cmd = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
    iex> event = AccountCreatedWithDroppedKeys.new(cmd)
    iex> Commanded.Event.Upcaster.upcast(event, %{})
    %AccountCreatedVersioned{age: 5, date: nil, sex: "maybe", username: "chris", field_with_default_value: "default_value"}

  > Note that you won't normally call `upcast` manually. `Commanded` will take care of that for you.

  ## Command Dispatch Validation

  The `Commanded.CommandDispatchValidation` macro will inject the `validate_and_dispatch` function into your `Commanded.Application`.
  """
end
