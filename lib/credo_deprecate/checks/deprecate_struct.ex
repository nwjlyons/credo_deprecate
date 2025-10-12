defmodule CredoDeprecate.Checks.DeprecateStruct do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [struct: nil, allow_list: [], message: nil],
    explanations: [
      check: """
      Prevents new usage of deprecated struct while allowing existing usage via an `allow_list`.
      """,
      params: [
        struct:
          "The deprecated struct to check for usage.",
        allow_list:
          "List of modules that are allowed to continue using the deprecated struct.",
        message:
          "Custom error message to display when the deprecated struct is used."
      ]
    ]

  alias Credo.Check.Params
  alias Credo.IssueMeta
  alias Credo.SourceFile

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params \\ []) do
    struct = Params.get(params, :struct, __MODULE__)
    allow_list = Params.get(params, :allow_list, __MODULE__)
    message = Params.get(params, :message, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)), %{
      deprecated_struct: module_to_atoms(struct),
      allow_list: allow_list |> Enum.map(&module_to_atoms/1),
      message: message,
      current_module: nil,
      aliases: %{},
      issues: []
    })
    |> Map.fetch!(:issues)
  end

  defp traverse(ast, acc, issue_meta) do
    case ast do
      {:defmodule, _meta, [{:__aliases__, _, current_module} | _]} ->
        # Set current module for new module and reset aliases
        {ast, %{acc | current_module: current_module, aliases: %{}}}

      # Handle alias statements
      {:alias, _meta, [{:__aliases__, _, module}]} ->
        # Simple alias: alias Foo.Bar -> Bar maps to Foo.Bar
        alias_name = List.last(module)
        {ast, %{acc | aliases: Map.put(acc.aliases, [alias_name], module)}}

      {:alias, _meta, [{:__aliases__, _, module}, [as: {:__aliases__, _, [alias_name]}]]} ->
        # Alias with as: alias Foo.Bar, as: Baz -> Baz maps to Foo.Bar
        {ast, %{acc | aliases: Map.put(acc.aliases, [alias_name], module)}}

      # Handle struct creation: %StructName{...}
      {:%, meta, [{:__aliases__, _, struct_name}, _fields]} ->
        cond do
          # Direct struct usage
          acc.current_module not in acc.allow_list && struct_name == acc.deprecated_struct ->
            {ast, add_issue(acc, issue_meta, meta[:line])}

          # Struct usage through alias
          acc.current_module not in acc.allow_list && Map.has_key?(acc.aliases, struct_name) &&
            Map.get(acc.aliases, struct_name) == acc.deprecated_struct ->
            {ast, add_issue(acc, issue_meta, meta[:line])}

          true ->
            {ast, acc}
        end

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
              "#{module_to_string(acc.deprecated_struct)} struct is deprecated. #{acc.message}"
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
