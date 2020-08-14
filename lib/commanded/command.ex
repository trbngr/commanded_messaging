defmodule Commanded.Command do
  @moduledoc ~S"""
  Creates an `Ecto.Schema.embedded_schema` that supplies a command with all the validation power of the `Ecto.Changeset` data structure.

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

      iex> CreateAccount.new(username: "chris", email: "chris@example.com", age: 5, aliases: ["christopher", "kris"])
      %CreateAccount{username: "chris", email: "chris@example.com", age: 5, aliases: ["christopher", "kris"]}

      iex> CreateAccount.validate(%{username: "chris", email: "chris@example.com", age: 5, aliases: ["christopher", "kris"]})
      #Ecto.Changeset<action: nil, changes: %{age: 5, aliases: ["christopher", "kris"], email: "chris@example.com", username: "chris"}, errors: [age: {"must be greater than %{number}", [validation: :number, kind: :greater_than, number: 12]}], data: #CreateAccount<>, valid?: false>

      iex> CreateAccount.validate(%{email: "emailson", age: 5})
      #Ecto.Changeset<action: nil, changes: %{age: 5, email: "emailson"}, errors: [age: {"must be greater than %{number}", [validation: :number, kind: :greater_than, number: 12]}, email: {"has invalid format", [validation: :format]}, username: {"can't be blank", [validation: :required]}], data: #CreateAccount<>, valid?: false>
  """

  @doc """
  Optional callback to define validation rules
  """
  @callback handle_validate(Ecto.Changeset.t()) :: Ecto.Changeset.t()

  defmacro __using__(schema) do
    quote do
      use Ecto.Schema
      import Ecto.Schema, only: [embedded_schema: 1, field: 2, field: 3]
      import Commanded.Command

      alias Ecto.Changeset
      @behaviour Commanded.Command

      @primary_key false
      embedded_schema do
        Enum.map(unquote(schema), fn
          {name, {{_, _} = composite_type, opts}} -> field(name, field_type(composite_type), opts)
          {name, {{_, _} = composite_type}} -> field(name, field_type(composite_type))
          {name, {type, opts}} -> field(name, field_type(type), opts)
          {name, type} -> field(name, field_type(type))
        end)
      end

      def new(), do: %__MODULE__{}
      def new(source)

      def new(%{__struct__: _} = source) do
        source
        |> Map.from_struct()
        |> new()
      end

      def new(source) when is_list(source) do
        source
        |> Enum.into(%{})
        |> new()
      end

      def new(source) when is_map(source) do
        source |> create()
      end

      use ExConstructor, :create

      def validate(command) when is_map(command) do
        command
        |> cast()
        |> handle_validate()
      end

      def handle_validate(%Ecto.Changeset{} = changeset), do: changeset

      defoverridable handle_validate: 1

      @cast_keys unquote(schema) |> Enum.into(%{}) |> Map.keys()

      defp cast(attrs) do
        Ecto.Changeset.cast(%__MODULE__{}, attrs, @cast_keys)
      end
    end
  end

  def field_type(:binary_id), do: Ecto.UUID

  def field_type(:array) do
    raise "`:array` is not a valid Ecto.Type\nIf you are using a composite data type, wrap the type definition like this `{{:array, :string}}`"
  end

  def field_type(type), do: type
end
