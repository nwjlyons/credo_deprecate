defmodule CredoDeprecate.Checks.DeprecateModule do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [module: nil, allow_list: [], message: nil],
    explanations: [
      check: """
      Prevents new usage of deprecated modules while allowing existing usage via an `allow_list`.

      The check detects all forms of module usage: direct calls, aliased calls, imported calls, required calls.
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
      aliases: %{},
      imports: [],
      requires: [],
      issues: []
    })
    |> Map.fetch!(:issues)
  end

  defp traverse(ast, acc, issue_meta) do
    case ast do
      {:defmodule, _meta, [{:__aliases__, _, current_module} | _]} ->
        # Reset aliases, imports, and requires for new module
        {ast, %{acc | current_module: current_module, aliases: %{}, imports: [], requires: []}}

      # Handle alias statements
      {:alias, _meta, [{:__aliases__, _, module}]} ->
        # Simple alias: alias Foo.Bar -> Bar maps to Foo.Bar
        alias_name = List.last(module)
        {ast, %{acc | aliases: Map.put(acc.aliases, [alias_name], module)}}

      {:alias, _meta, [{:__aliases__, _, module}, [as: {:__aliases__, _, [alias_name]}]]} ->
        # Alias with as: alias Foo.Bar, as: Baz -> Baz maps to Foo.Bar
        {ast, %{acc | aliases: Map.put(acc.aliases, [alias_name], module)}}

      # Handle import statements
      {:import, _meta, [{:__aliases__, _, module}]} ->
        {ast, %{acc | imports: [module | acc.imports]}}

      # Handle require statements
      {:require, _meta, [{:__aliases__, _, module}]} ->
        {ast, %{acc | requires: [module | acc.requires]}}

      # Handle direct module calls
      {{:., dot_meta, [{:__aliases__, _aliases_meta, module}, _function]}, _args_meta, _args} ->
        cond do
          # Direct call to deprecated module
          acc.current_module not in acc.allow_list && module == acc.deprecated_module ->
            {ast, add_issue(acc, issue_meta, dot_meta[:line])}

          # Call through alias
          acc.current_module not in acc.allow_list && Map.has_key?(acc.aliases, module) &&
            Map.get(acc.aliases, module) == acc.deprecated_module ->
            {ast, add_issue(acc, issue_meta, dot_meta[:line])}

          true ->
            {ast, acc}
        end

      # Handle imported function calls
      {function, meta, args} when is_atom(function) and is_list(args) ->
        # Exclude common language constructs that aren't function calls
        excluded_functions = [:defmodule, :def, :defp, :defmacro, :defmacrop, :alias, :import, :require, :use, :__aliases__]


        if acc.current_module not in acc.allow_list && acc.deprecated_module in acc.imports &&
           function not in excluded_functions do
          {ast, add_issue(acc, issue_meta, meta[:line])}
        else
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
