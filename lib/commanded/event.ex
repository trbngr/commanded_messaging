defmodule Commanded.Event do
  defmodule Helper do
    def add_version_key(list) when is_list(list) do
      has_version =
        Enum.any?(list, fn
          {:version, _} -> true
          _ -> false
        end)

      case has_version do
        false -> [{:version, 1} | list]
        true -> list
      end
    end
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      from =
        case Keyword.get(opts, :from) do
          nil ->
            []

          source ->
            unless Code.ensure_compiled?(source) do
              raise "#{source} should be a valid struct to use with DomainEvent"
            end

            struct(source)
            |> Map.from_struct()
            |> Map.keys()
        end

      explicit_keys =
        Keyword.get(opts, :with, [])
        |> Helper.add_version_key()

      keys_to_drop = Keyword.get(opts, :except, []) -- [:version]

      @derive Jason.Encoder
      defstruct from
                |> Kernel.++(explicit_keys)
                |> Enum.reject(&Enum.member?(keys_to_drop, &1))

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

      def new(source, attrs) when is_map(source) do
        Map.merge(source, Enum.into(attrs, %{}))
        |> create()
      end

      use ExConstructor, :create
    end
  end
end
