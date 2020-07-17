defmodule Commanded.Middleware.CommandValidation do
  @moduledoc ~S"""
  ## Examples

    defmodule CreateFakeAccount do
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

  Successfull command validation result will continue pipeline

    iex> cmd = CreateFakeAccount.new(username: "chris", email: "chris@example.com", age: "13")
    iex> pipeline = %Commanded.Middleware.Pipeline{command: cmd}
    iex> Commanded.Middleware.CommandValidation.before_dispatch(pipeline)
    %Commanded.Middleware.Pipeline{halted: false, command: CreateFakeAccount.new(username: "chris", email: "chris@example.com", age: 13)}

  On error validation halt execution with changeset as response

    iex> cmd = CreateFakeAccount.new(username: nil, email: "chrisexample.com", age: 5)
    iex> pipeline = %Commanded.Middleware.Pipeline{command: cmd}
    iex> response = Commanded.Middleware.CommandValidation.before_dispatch(pipeline)
    iex> {:error, resp} = Map.get(response, :response)
    iex> resp
    #Ecto.Changeset<action: nil, changes: %{age: 5, email: "chrisexample.com"}, errors: [age: {"must be greater than %{number}", [validation: :number, kind: :greater_than, number: 12]}, email: {"has invalid format", [validation: :format]}, username: {"can't be blank", [validation: :required]}], data: #CreateFakeAccount<>, valid?: false>
  """

  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline

  def before_dispatch(%Pipeline{command: command} = pipeline) do
    case validate_command(command) do
      %{valid?: true} = changeset ->
        %{pipeline | command: Ecto.Changeset.apply_changes(changeset)}

      %{valid?: false} = changeset ->
        pipeline
        |> Map.put(:halted, true)
        |> Map.put(:response, {:error, changeset})
    end
  end

  def after_dispatch(%Pipeline{} = pipeline) do
    pipeline
  end

  def after_failure(%Pipeline{} = pipeline) do
    pipeline
  end

  defp validate_command(%{__struct__: command} = source) do
    source
    |> Map.from_struct()
    |> command.validate()
  end
end
