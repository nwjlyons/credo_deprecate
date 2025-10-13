defmodule CredoDeprecate.Checks.DeprecateSigil do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [sigil: nil, allow_list: [], message: nil],
    explanations: [
      check: """
      Prevents new usage of deprecated sigils while allowing existing usage via an `allow_list`.
      """,
      params: [
        sigil:
          "An atom specifying the deprecated sigil (e.g., :sigil_F for ~F from Surface).",
        allow_list:
          "List of modules that are allowed to continue using the deprecated sigil.",
        message:
          "Custom error message to display when the deprecated sigil is used."
      ]
    ]

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params \\ []) do
    sigil = Params.get(params, :sigil, __MODULE__)
    allow_list = Params.get(params, :allow_list, __MODULE__)
    message = Params.get(params, :message, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)), %{
      sigil: sigil,
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
        # Track current module
        {ast, %{acc | current_module: current_module}}

      {sigil_function, meta, _args} when is_atom(sigil_function) ->
        if acc.current_module not in acc.allow_list && sigil_function == acc.sigil do
          {ast, add_issue(acc, issue_meta, meta[:line])}
        else
          {ast, acc}
        end

      _ ->
        {ast, acc}
    end
  end

  defp add_issue(acc, issue_meta, line_no) do
    sigil_name = acc.sigil |> Atom.to_string() |> String.replace("sigil_", "~")

    %{
      acc
      | issues: [
          issue_for(
            issue_meta,
            line_no,
            String.trim_trailing(
              "#{sigil_name} sigil is deprecated. #{acc.message}"
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

  defp module_to_atoms(module) when is_atom(module) do
    module |> Module.split() |> Enum.map(&String.to_atom/1)
  end
end
