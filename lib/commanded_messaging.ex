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
      #Ecto.Changeset<action: nil, changes: %{}, errors: [], data: #BasicCreateAccount<>, valid?: true>


  ### Validation

      defmodule CreateAccount do
        use Commanded.Command,
          username: :string,
          email: :string,
          age: :integer

        def handle_validate(command) do
          command
          |> validate_required([:username, :email, :age])
          |> validate_format(:email, ~r/@/)
          |> validate_number(:age, greater_than: 12)
        end
      end

      iex> CreateAccount.new()
      #Ecto.Changeset<action: nil, changes: %{}, errors: [username: {"can't be blank", [validation: :required]}, email: {"can't be blank", [validation: :required]}, age: {"can't be blank", [validation: :required]}], data: #CreateAccount<>, valid?: false>

      iex> CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
      #Ecto.Changeset<action: nil, changes: %{age: 5, email: "chris@example.com", username: "chris"}, errors: [age: {"must be greater than %{number}", [validation: :number, kind: :greater_than, number: 12]}], data: #CreateAccount<>, valid?: false>

  To create the actual command struct, use `Ecto.Changeset.apply_changes/1`

      iex> command = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
      iex> Ecto.Changeset.apply_changes(command)
      %CreateAccount{age: 5, email: "chris@example.com", username: "chris"}

  > Note that `apply_changes` will not validate values.

  ## Events

  Most events mirror the commands that produce them. So we make it easy to reduce the boilerplate in creating them with the `Commanded.Event` macro.

      defmodule BasicAccountCreated do
        use Commanded.Event,
          from: CreateAccount
      end

      iex> command = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
      iex> cmd = Ecto.Changeset.apply_changes(command)
      iex> BasicAccountCreated.new(cmd)
      %BasicAccountCreated{
        age: 5,
        email: "chris@example.com",
        username: "chris",
        version: 1
      }


  ### Extra Keys

  There are times when we need keys defined on an event that aren't part of the originating command. We can add these very easily.

      defmodule AccountCreatedWithExtraKeys do
        use Commanded.Event,
          from: CreateAccount,
          with: [:date]
      end

      iex> command = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
      iex> cmd = Ecto.Changeset.apply_changes(command)
      iex> AccountCreatedWithExtraKeys.new(cmd, date: ~D[2019-07-25])
      %AccountCreatedWithExtraKeys{
        age: 5,
        date: ~D[2019-07-25],
        email: "chris@example.com",
        username: "chris",
        version: 1
      }


  ### Excluding Keys

  And you may also want to drop some keys from your command.

      defmodule AccountCreatedWithDroppedKeys do
        use Commanded.Event,
          from: CreateAccount,
          with: [:date],
          drop: [:email]
      end

      iex> command = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
      iex> cmd = Ecto.Changeset.apply_changes(command)
      iex> AccountCreatedWithDroppedKeys.new(cmd)
      %AccountCreatedWithDroppedKeys{
        age: 5,
        date: nil,
        username: "chris",
        version: 1
      }


  ### Versioning

  You may have noticed that we provide a default version of `1`.

  You can change the version of an event at anytime.

  After doing so, you should define an upcast instance that knows how to transform older events into the latest version.

      # This is for demonstration purposes only. You don't need to create a new event to version one.
      defmodule AccountCreatedVersioned do
        use Commanded.Event,
          version: 2,
          from: CreateAccount,
          with: [:date, :sex],
          drop: [:email],

        defimpl Commanded.Event.Upcaster, for: AccountCreatedWithDroppedKeys do
          def upcast(%{version: 1} = event, _metadata) do
            AccountCreatedVersioned.new(event, sex: "maybe", version: 2)
          end

          def upcast(event, _metadata), do: event
        end
      end

      iex> command = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
      iex> cmd = Ecto.Changeset.apply_changes(command)
      iex> event = AccountCreatedWithDroppedKeys.new(cmd)
      iex> Commanded.Event.Upcaster.upcast(event, %{})
      %AccountCreatedVersioned{age: 5, date: nil, sex: "maybe", username: "chris", version: 2}

  > Note that you won't normally call `upcast` manually. `Commanded` will take care of that for you.

  ## Command Dispatch Validation

  The `Commanded.CommandDispatchValidation` macro will inject the `validate_and_dispatch` function into your `Commanded.Application`.
  """
end
