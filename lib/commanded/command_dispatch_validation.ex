defmodule Commanded.CommandDispatchValidation do
  @moduledoc ~S"""
  Provides validation before dispatching your commands.
  """

  defmacro __using__(_env) do
    quote do
      alias Ecto.Changeset, as: Command

      @type validation_failure :: [%{required(atom()) => [String.t()]}]

      @spec validate_and_dispatch(Command.t(), Keyword.t()) ::
              :ok
              | {:ok, aggregate_state :: struct}
              | {:ok, aggregate_version :: non_neg_integer()}
              | {:ok, execution_result :: Commanded.Commands.ExecutionResult.t()}
              | {:error, :unregistered_command}
              | {:error, :consistency_timeout}
              | {:error, reason :: term}
              | {:error, {:validation_failure, Command.t()}}

      def validate_and_dispatch(command, opts \\ [])

      def validate_and_dispatch(%Command{valid?: true} = command, opts) do
        command
        |> Command.apply_changes()
        |> __MODULE__.dispatch(opts)
      end

      def validate_and_dispatch(%Command{} = command, _opts) do
        {:error, {:validation_failure, command}}
      end
    end
  end
end
