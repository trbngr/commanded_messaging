# Commanded Messaging

**Common macros for messaging in a Commanded application**

## Installation

This package can be installed
by adding `commanded_messaging` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:commanded_messaging, "~> 0.2.0"}
  ]
end
```

[Documentation](https://hexdocs.pm/commanded_messaging)

## Usage

### Commands

The `Commanded.Command` macro creates an Ecto `embedded_schema` so you can take advantage of the well known `Ecto.Changeset` API.

#### Default

```elixir
defmodule CreateAccount do
  use Commanded.Command,
      username: :string,
      email: :string,
      age: :integer
end

iex> CreateAccount.new() 
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: #CreateAccount<>, valid?: true>
```

#### Validation

```elixir
defmodule CreateAccount do
  use Commanded.Command,
      username: :string,
      email: :string,
      age: :integer

  def handle_validate(changeset) do
    changeset
    |> validate_required([:username, :email, :age])
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than: 12)
  end
end

iex> CreateAccount.new() 
#Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [
    username: {"can't be blank", [validation: :required]},
    email: {"can't be blank", [validation: :required]},
    age: {"can't be blank", [validation: :required]}
  ],
  data: #CreateAccount<>,
  valid?: false
>

iex> changeset = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5) 
#Ecto.Changeset<
  action: nil,
  changes: %{age: 5, email: "chris@example.com", username: "chris"},
  errors: [
    age: {"must be greater than %{number}",
     [validation: :number, kind: :greater_than, number: 12]}
  ],
  data: #CreateAccount<>,
  valid?: false
>
```

To create the actual command struct, use `Ecto.Changeset.apply_changes/1`

```elixir
iex> cmd = Ecto.Changeset.apply_changes(changeset)
%CreateAccount{age: 5, email: "chris@example.com", username: "chris"}
```

> Note that `apply_changes` will not validate values.

### Events

Most events mirror the commands that produce them. So we make it easy to reduce the boilerplate in creating them with the `Commanded.Event` macro.

```elixir
defmodule AccountCreated do
  use Commanded.Event,
    from: CreateAccount
end

iex> AccountCreated.new(cmd)
%AccountCreated{
  age: 5,
  email: "chris@example.com",
  username: "chris",
  version: 1
}
```

#### Extra Keys

There are times when we need keys defined on an event that aren't part of the originating command. We can add these very easily.

```elixir
defmodule AccountCreated do
  use Commanded.Event,
    from: CreateAccount,
    with: [:date]
end

iex> AccountCreated.new(cmd, date: NaiveDateTime.utc_now())
%AccountCreated{
  age: 5,
  date: ~N[2019-07-25 08:03:15.372212],
  email: "chris@example.com",
  username: "chris",
  version: 1
}
```

#### Excluding Keys

And you may also want to drop some keys from your command.

```elixir
defmodule AccountCreated do
  use Commanded.Event,
    from: CreateAccount,
    with: [:date],
    drop: [:email]
end

iex> event = AccountCreated.new(cmd)
%AccountCreated{age: 5, date: nil, username: "chris", version: 1}
```

#### Versioning

You may have noticed that we provide a default version of `1`.

You can change the version of an event at anytime. 

After doing so, you should define an upcast instance that knows how to transform older events into the latest version.

```elixir
defmodule AccountCreated do
  use Commanded.Event,
    version: 2,
    from: CreateAccount,
    with: [:date, :sex],
    drop: [:email]

  defimpl Commanded.Event.Upcaster do
    def upcast(%{version: 1} = event, _metadata) do
      AccountCreated.new(event, sex: "maybe", version: 2)
    end

    def upcast(event, _metadata), do: event
  end
end

iex> Commanded.Event.Upcaster.upcast(event, %{})
%AccountCreated{age: 5, date: nil, sex: "maybe", username: "chris", version: 2}
```

> Note that you won't normally call `upcast` manually. `Commanded` will take care of that for you.

### Command Dispatch Validation

The `Commanded.CommandDispatchValidation` macro will inject the `validate_and_dispatch` into your `Commanded.Commands.Router`.

```elixir
defmodule AccountsRouter do
  use Commanded.Commands.Router
  use Commanded.CommandDispatchValidation
end

iex> AccountsRouter.validate_and_dispatch(changeset)
{:error, {:validation_failure, %{age: ["must be greater than 12"]}}}
```

***

I hope you find this library as useful as my team and I do. -Chris
