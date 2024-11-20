defmodule CredoDeprecate.Checks.DeprecateFunction do
  use Credo.Check

  def run(%SourceFile{} = source_file, params \\ []) do
    params = Keyword.validate!(params, [:mfa])
    {module, function, arity} = Keyword.fetch!(params, :mfa)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)), %{
      mfa: %{
        module: module |> Module.split() |> Enum.map(&String.to_atom/1),
        function: function,
        arity: arity
      },
      issues: []
    })
    |> Map.fetch!(:issues)
  end

  defp traverse(ast, acc, issue_meta) do
    case ast do
      {:import, import_meta, [{:__aliases__, _aliases_meta, module}]} ->
        if module == acc.mfa.module do
          {ast,
           %{
             acc
             | issues: [
                 issue_for(
                   issue_meta,
                   import_meta[:line],
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
end
