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
          |> validate_required([:username, :email, :age, :aliases])
          |> validate_format(:email, ~r/@/)
          |> validate_number(:age, greater_than: 12)
        end
      end

      iex> CreateAccount.new(username: "chris", email: "chris@example.com", age: 5, aliases: ["christopher", "kris"])
      #Ecto.Changeset<action: nil, changes: %{age: 5, aliases: ["christopher", "kris"], email: "chris@example.com", username: "chris"}, errors: [age: {"must be greater than %{number}", [validation: :number, kind: :greater_than, number: 12]}], data: #CreateAccount<>, valid?: false>
  """

  @doc """
  Optional callback to define validation rules
  """
  @callback handle_validate(Ecto.Changeset.t()) :: Ecto.Changeset.t()

  defmacro __using__(schema) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import Commanded.Command
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

      def new(attrs \\ []) do
        attrs
        |> Enum.into(%{})
        |> cast()
        |> handle_validate()
      end

      def handle_validate(changeset), do: changeset

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
