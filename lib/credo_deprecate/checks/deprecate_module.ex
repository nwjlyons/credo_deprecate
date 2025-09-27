defmodule CredoDeprecate.Checks.DeprecateModule do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [module: nil, allow_list: [], message: nil],
    explanations: [
      check: """
      Prevents new usage of deprecated module while allowing existing usage via an `allow_list`.
      """,
      params: [
        module:
          "The deprecated module to check for usage.",
        allow_list:
          "List of modules that are allowed to continue using the deprecated module.",
        message:
          "Custom error message to display when the deprecated module is used."
      ]
    ]

  alias Credo.Check.Params
  alias Credo.IssueMeta
  alias Credo.SourceFile

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params \\ []) do
    module = Params.get(params, :module, __MODULE__)
    allow_list = Params.get(params, :allow_list, __MODULE__)
    message = Params.get(params, :message, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)), %{
      deprecated_module: module_to_atoms(module),
      allow_list: allow_list |> Enum.map(&module_to_atoms/1),
      message: message,
      current_module: nil,
      issues: []
    })
    |> Map.fetch!(:issues)
  end

  defp traverse(ast, acc, issue_meta) do
    case ast do
      {:defmodule, _meta, [{:__aliases__, _, current_module} | _]} ->
        # Set current module for new module
        {ast, %{acc | current_module: current_module}}

      # Handle alias statements
      {:alias, meta, [{:__aliases__, _, module}]} ->
        acc = if acc.current_module not in acc.allow_list && module == acc.deprecated_module do
          add_issue(acc, issue_meta, meta[:line])
        else
          acc
        end
        {ast, acc}

      {:alias, meta, [{:__aliases__, _, module}, [as: {:__aliases__, _, [_alias_name]}]]} ->
        acc = if acc.current_module not in acc.allow_list && module == acc.deprecated_module do
          add_issue(acc, issue_meta, meta[:line])
        else
          acc
        end
        {ast, acc}

      # Handle import statements
      {:import, meta, [{:__aliases__, _, module}]} ->
        acc = if acc.current_module not in acc.allow_list && module == acc.deprecated_module do
          add_issue(acc, issue_meta, meta[:line])
        else
          acc
        end
        {ast, acc}

      # Handle require statements
      {:require, meta, [{:__aliases__, _, module}]} ->
        acc = if acc.current_module not in acc.allow_list && module == acc.deprecated_module do
          add_issue(acc, issue_meta, meta[:line])
        else
          acc
        end
        {ast, acc}


      _ ->
        {ast, acc}
    end
  end

  defp add_issue(acc, issue_meta, line_no) do
    %{
      acc
      | issues: [
          issue_for(
            issue_meta,
            line_no,
            String.trim_trailing(
              "#{module_to_string(acc.deprecated_module)} is deprecated. #{acc.message}"
            )
          )
          | acc.issues
        ]
    }
  end

  defp issue_for({Credo.IssueMeta, %SourceFile{}, _} = issue_meta, line_no, message)
       when (is_integer(line_no) or is_nil(line_no)) and is_binary(message) do
    format_issue(
      issue_meta,
      message: message,
      line_no: line_no
    )
  end

  defp module_to_string(module) when is_list(module) do
    module |> Enum.map(&Atom.to_string/1) |> Enum.join(".")
  end

  defp module_to_atoms(module) when is_atom(module) do
    module |> Module.split() |> Enum.map(&String.to_atom/1)
  end
end
