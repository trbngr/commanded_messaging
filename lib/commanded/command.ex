defmodule Commanded.Command do
  @moduledoc ~S"""
  Creates an `Ecto.Schema.embedded_schema` that supplies a command with all the validation power of the `Ecto.Changeset` data structure.

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

      iex> CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
      #Ecto.Changeset<action: nil, changes: %{age: 5, email: "chris@example.com", username: "chris"}, errors: [age: {"must be greater than %{number}", [validation: :number, kind: :greater_than, number: 12]}], data: #CreateAccount<>, valid?: false>

      iex> CreateAccount.new!(username: "chris", email: "chris@example.com", age: 5)
      ** (Commanded.CommandError) Invalid command
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

      @type t :: %Ecto.Changeset{data: %__MODULE__{}}

      @primary_key false
      embedded_schema do
        Enum.map(unquote(schema), fn
          {name, {type, opts}} -> field(name, field_type(type), opts)
          {name, type} -> field(name, field_type(type))
        end)
      end

      def new(attrs \\ [], opts \\ [])

      def new(attrs, []) do
        attrs
        |> Enum.into(%{})
        |> cast()
        |> handle_validate()
      end

      def new(attrs, opts) do
        attrs
        |> Enum.into(%{})
        |> cast()
        |> handle_validate(opts)
      end

      def new!(attrs, opts \\ []) do
        result =
          attrs
          |> new(opts)
          |> apply_action(:create)

        case result do
          {:ok, command} -> command
          {:error, command} -> raise Commanded.CommandError, command: command
        end
      end

      def handle_validate(changeset), do: handle_validate(changeset, [])
      def handle_validate(changeset, _opts), do: changeset

      defoverridable handle_validate: 1, handle_validate: 2

      @cast_keys unquote(schema) |> Enum.into(%{}) |> Map.keys()

      defp cast(attrs) do
        Ecto.Changeset.cast(%__MODULE__{}, attrs, @cast_keys)
      end
    end
  end

  def field_type(:binary_id), do: Ecto.UUID
  def field_type(type), do: type
end
