defmodule Commanded.Event do
  @moduledoc ~S"""
  Creates a domain event structure.

  ## Options

    * `from`      - A struct to adapt the keys from.
    * `with`      - A list of keys to add to the event.
    * `drop`      - A list of keys to drop from the keys adapted from a struct.
    * `version`   - An optional version of the event. Defaults to `1`.

  ## Example

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

        iex> changeset = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
        iex> cmd = Ecto.Changeset.apply_changes(changeset)
        iex> event = AccountCreatedWithDroppedKeys.new(cmd)
        iex> Commanded.Event.Upcaster.upcast(event, %{})
        %AccountCreatedVersioned{age: 5, date: nil, sex: "maybe", username: "chris", version: 2}
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      from =
        case Keyword.get(opts, :from) do
          nil ->
            []

          source ->
            unless Code.ensure_compiled(source) do
              raise "#{source} should be a valid struct to use with DomainEvent"
            end

            struct(source)
            |> Map.from_struct()
            |> Map.keys()
        end

      version = Keyword.get(opts, :version, 1)
      keys_to_drop = Keyword.get(opts, :drop, [])
      explicit_keys = Keyword.get(opts, :with, [])

      @derive Jason.Encoder
      defstruct from
                |> Kernel.++(explicit_keys)
                |> Enum.reject(&Enum.member?(keys_to_drop, &1))
                |> Kernel.++([{:version, version}])

      def new(), do: %__MODULE__{}
      def new(source, attrs \\ [])

      def new(%{__struct__: _} = source, attrs) do
        source
        |> Map.from_struct()
        |> new(attrs)
      end

      def new(source, attrs) when is_list(source) do
        source
        |> Enum.into(%{})
        |> new(attrs)
      end

      def new(source, %{__struct__: _} = attrs) when is_map(source) do
        new(source, Map.from_struct(attrs))
      end

      def new(source, attrs) when is_map(source) do
        Map.merge(source, Enum.into(attrs, %{}))
        |> create()
      end

      use ExConstructor, :create
    end
  end
end
