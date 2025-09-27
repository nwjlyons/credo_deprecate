defmodule CredoDeprecate.Checks.DeprecateFunction do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [allow_list: []],
    explanations: [
      check: """
      Prevents new usage of deprecated functions while allowing existing usage.

      Sometimes you have functions in your codebase that you want to deprecate, but you can't
      use Elixir's built-in `@deprecated` attribute because there are existing uses
      scattered throughout the codebase. This check allows you to prevent new usage while
      maintaining an allow list for existing usage.

      The check detects all forms of function calls: direct calls, aliased calls, and imported calls.
      """,
      params: [
        mfa: "A tuple `{Module, :function, arity}` specifying the deprecated function.",
        allow_list: "List of modules that are allowed to continue using the deprecated function."
      ]
    ]

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params \\ []) do
    {module, function, arity} = Params.get(params, :mfa, __MODULE__)
    allow_list = Params.get(params, :allow_list, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)), %{
      mfa: %{
        module: module_to_atoms(module),
        function: function,
        arity: arity
      },
      allow_list: allow_list |> Enum.map(&module_to_atoms/1),
      current_module: nil,
      aliases: %{},
      imports: [],
      issues: []
    })
    |> Map.fetch!(:issues)
  end

  defp traverse(ast, acc, issue_meta) do
    case ast do
      {:defmodule, _meta, [{:__aliases__, _, current_module} | _]} ->
        # Reset aliases and imports for new module
        {ast, %{acc | current_module: current_module, aliases: %{}, imports: []}}

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

      # Handle direct module calls (existing functionality)
      {{:., dot_meta, [{:__aliases__, _aliases_meta, module}, function]}, _args_meta, args} ->
        cond do
          # Direct call to deprecated module
          acc.current_module not in acc.allow_list && module == acc.mfa.module &&
            function == acc.mfa.function && length(args) == acc.mfa.arity ->
            {ast, add_issue(acc, issue_meta, dot_meta[:line])}

          # Call through alias
          acc.current_module not in acc.allow_list && Map.has_key?(acc.aliases, module) &&
            Map.get(acc.aliases, module) == acc.mfa.module &&
            function == acc.mfa.function && length(args) == acc.mfa.arity ->
            {ast, add_issue(acc, issue_meta, dot_meta[:line])}

          true ->
            {ast, acc}
        end

      # Handle imported function calls
      {function, meta, args} when is_atom(function) and is_list(args) ->
        if acc.current_module not in acc.allow_list && acc.mfa.module in acc.imports &&
             function == acc.mfa.function && length(args) == acc.mfa.arity do
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
            "#{module_to_string(acc.mfa.module)} is deprecated"
          )
          | acc.issues
        ]
    }
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

  defp module_to_atoms(module) when is_atom(module) do
    module |> Module.split() |> Enum.map(&String.to_atom/1)
  end
end
