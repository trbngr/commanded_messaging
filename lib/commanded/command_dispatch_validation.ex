defmodule Commanded.CommandDispatchValidation do
  @moduledoc ~S"""
  Provides validation before dispatching your commands.

  ## Example

      defmodule AccountsRouter do
        use Commanded.Commands.Router
        use Commanded.CommandDispatchValidation
      end

      iex> changeset = CreateAccount.new(username: "chris", email: "chris@example.com", age: 5)
      iex> AccountsRouter.validate_and_dispatch(changeset)
      {:error, {:validation_failure, %{age: ["must be greater than 12"]}}}
  """

  defmacro __using__(_env) do
    quote do
      alias Ecto.Changeset

      @type validation_failure :: [%{required(atom()) => [String.t()]}]

      @spec validate_and_dispatch(Changeset.t(), Keyword.t()) ::
              :ok
              | {:ok, execution_result :: Commanded.Commands.ExecutionResult.t()}
              | {:ok, aggregate_version :: integer}
              | {:error, :unregistered_command}
              | {:error, :consistency_timeout}
              | {:error, reason :: term}
              | {:error, {:validation_failure, validation_failure}}

      def validate_and_dispatch(%Changeset{} = changeset, opts \\ []) do
        case changeset.valid? do
          true ->
            changeset
            |> Changeset.apply_changes()
            |> __MODULE__.dispatch(opts)

          false ->
            errors =
              Changeset.traverse_errors(changeset, fn {msg, opts} ->
                Enum.reduce(opts, msg, fn {key, value}, acc ->
                  String.replace(acc, "%{#{key}}", to_string(value))
                end)
              end)

            {:error, {:validation_failure, errors}}
        end
      end
    end
  end
end
