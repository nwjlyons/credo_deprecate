defmodule CredoDeprecate.Checks.DeprecateFunction do
  use Credo.Check

  def run(%SourceFile{} = source_file, params \\ []) do
    params = Keyword.validate!(params, [:mfa, allow_list: []])
    {module, function, arity} = Keyword.fetch!(params, :mfa)
    allow_list = Keyword.fetch!(params, :allow_list)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)), %{
      mfa: %{
        module: module_to_atoms(module),
        function: function,
        arity: arity
      },
      allow_list: allow_list |> Enum.map(&module_to_atoms/1),
      current_module: nil,
      issues: []
    })
    |> Map.fetch!(:issues)
  end

  defp traverse(ast, acc, issue_meta) do
    case ast do
      {:defmodule, _meta, [{:__aliases__, _, current_module} | _]} ->
        {ast, %{acc | current_module: current_module}}

      {{:., dot_meta, [{:__aliases__, _aliases_meta, module}, function]}, _args_meta, args} ->
        if acc.current_module not in acc.allow_list && module == acc.mfa.module &&
             function == acc.mfa.function && length(args) == acc.mfa.arity do
          {ast,
           %{
             acc
             | issues: [
                 issue_for(
                   issue_meta,
                   dot_meta[:line],
                   "#{module_to_string(acc.mfa.module)} is deprecated"
                 )
                 | acc.issues
               ]
           }}
        else
          {ast, acc}
        end

      _ ->
        {ast, acc}
    end
  end

  defp issue_for({Credo.IssueMeta, %SourceFile{}, _} = issue_meta, line_no, message)
       when is_integer(line_no) and is_binary(message) do
    format_issue(
      issue_meta,
      message: message,
      line_no: line_no
    )
  end

  defp module_to_string(module) when is_list(module) do
    module |> Enum.map(&Atom.to_string/1) |> Enum.join(".")
  end

  def module_to_atoms(module) when is_atom(module) do
      module |> Module.split() |> Enum.map(&String.to_atom/1)
  end
end
