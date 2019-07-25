defmodule Commanded.Command do
  @callback validate(Ecto.Changeset.t()) :: Ecto.Changeset.t()

  defmacro __using__(schema) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import Commanded.Command
      @behaviour Commanded.Command

      @primary_key false
      embedded_schema do
        Enum.map(unquote(schema), fn
          {name, {type, opts}} -> field(name, field_type(type), opts)
          {name, type} -> field(name, field_type(type))
        end)
      end

      def new(attrs \\ []) do
        attrs
        |> Enum.into(%{})
        |> cast()
        |> validate()
      end

      def validate(changeset), do: changeset

      defoverridable validate: 1

      @cast_keys unquote(schema) |> Enum.into(%{}) |> Map.keys()

      defp cast(attrs) do
        Ecto.Changeset.cast(%__MODULE__{}, attrs, @cast_keys)
      end
    end
  end

  def field_type(:binary_id), do: Ecto.UUID
  def field_type(type), do: type
end
