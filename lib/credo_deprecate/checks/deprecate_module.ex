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
      aliases: %{},
      imports: [],
      requires: [],
      issues: [],
      flagged_modules: MapSet.new()
    })
    |> Map.fetch!(:issues)
  end

  defp traverse(ast, acc, issue_meta) do
    case ast do
      {:defmodule, _meta, [{:__aliases__, _, current_module} | _]} ->
        # Reset aliases, imports, and requires for new module, but keep flagged_modules
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
            if MapSet.member?(acc.flagged_modules, acc.current_module) do
              {ast, acc}
            else
              {ast, add_issue(acc, issue_meta, dot_meta[:line])}
            end

          # Call through alias
          acc.current_module not in acc.allow_list && Map.has_key?(acc.aliases, module) &&
            Map.get(acc.aliases, module) == acc.deprecated_module ->
            if MapSet.member?(acc.flagged_modules, acc.current_module) do
              {ast, acc}
            else
              {ast, add_issue(acc, issue_meta, dot_meta[:line])}
            end

          # Call through require (full module name)
          acc.current_module not in acc.allow_list && acc.deprecated_module in acc.requires &&
            module == acc.deprecated_module ->
            if MapSet.member?(acc.flagged_modules, acc.current_module) do
              {ast, acc}
            else
              {ast, add_issue(acc, issue_meta, dot_meta[:line])}
            end

          true ->
            {ast, acc}
        end

      # Handle imported function calls - conservative approach
      # Only flag function calls that are very likely to be from the imported deprecated module
      {function, meta, args} when is_atom(function) and is_list(args) and is_list(meta) ->
        # Very conservative: only flag if all conditions are met
        if acc.current_module not in acc.allow_list && 
           acc.deprecated_module in acc.imports &&
           not MapSet.member?(acc.flagged_modules, acc.current_module) &&
           is_integer(meta[:line]) &&
           # Only flag functions that look like regular user-defined functions
           is_likely_user_function(function) do
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
        ],
        flagged_modules: MapSet.put(acc.flagged_modules, acc.current_module)
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

  # Helper function to identify functions that are likely to be user-defined
  # This is a conservative heuristic to only flag function calls that could reasonably be from imported modules
  defp is_likely_user_function(function) do
    function_str = Atom.to_string(function)

    # Exclude obvious built-ins and special forms
    not (function in [
      # Operators and built-ins
      :+, :-, :*, :/, :==, :!=, :<, :>, :<=, :>=, :and, :or, :not,
      :is_atom, :is_binary, :is_boolean, :is_float, :is_function, :is_integer,
      :is_list, :is_map, :is_nil, :is_number, :is_pid, :is_port, :is_reference,
      :is_tuple, :length, :hd, :tl, :elem, :put_elem, :tuple_size,
      # Special forms and keywords
      :import, :alias, :require, :defmodule, :def, :defp, :defmacro, :defstruct,
      :if, :unless, :case, :cond, :with, :for, :try, :receive, :quote, :unquote,
      # Common Kernel functions
      :apply, :send, :spawn, :exit, :throw, :raise, :reraise,
      # Single letter functions (often local variables or very short local functions)
      :a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, :s, :t, :u, :v, :w, :x, :y, :z
    ]) and
    # Must be a reasonable function name (contains letters, not just symbols)
    String.match?(function_str, ~r/^[a-zA-Z][a-zA-Z0-9_]*[?!]?$/) and
    # Not too short (single letter) or too long (likely generated)
    String.length(function_str) > 1 and String.length(function_str) < 50
  end
end
