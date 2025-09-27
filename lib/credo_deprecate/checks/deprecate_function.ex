defmodule CredoDeprecate.Checks.DeprecateFunction do
  @moduledoc """
  A Credo check to prevent new usage of deprecated functions while allowing existing usage.

  ## The Problem: Why This Check Exists

  Sometimes you have functions in your codebase that you want to deprecate, but you can't
  use Elixir's built-in `@deprecated` attribute because there are existing legitimate uses
  scattered throughout the codebase. Using `@deprecated` would immediately flag all existing
  usage, creating noise and making it harder to prevent *new* usage.

  This check implements the concept of a "shitlist" as described by Simon Eskildsen from
  Shopify (https://sirupsen.com/shitlists). The idea is to:

  1. Acknowledge that some code is problematic but can't be immediately removed
  2. Prevent the problem from getting worse by blocking new usage
  3. Allow existing usage to continue (via an allow list) while you work on migration

  ## Configuration

  The check requires two parameters:

  - `mfa`: A tuple `{Module, :function, arity}` specifying the deprecated function
  - `allow_list`: A list of modules that are allowed to continue using the deprecated function

  ## Usage

  Add this check to your `.credo.exs` configuration:

  ```elixir
  {CredoDeprecate.Checks.DeprecateFunction, [
    mfa: {MyApp.LegacyModule, :problematic_function, 2},
    allow_list: [MyApp.ExistingUser, MyApp.AnotherExistingUser]
  ]}
  ```

  ## Examples

  Given the configuration above, this check will flag new usage:

  ```elixir
  defmodule MyApp.NewModule do
    # ❌ This will be flagged
    MyApp.LegacyModule.problematic_function(arg1, arg2)
  end
  ```

  But allow existing usage:

  ```elixir
  defmodule MyApp.ExistingUser do
    # ✅ This is allowed (module is in allow_list)
    MyApp.LegacyModule.problematic_function(arg1, arg2)
  end
  ```

  The check detects all forms of function calls:

  - Direct calls: `MyModule.function(args)`
  - Aliased calls: `alias MyModule; MyModule.function(args)`
  - Aliased with as: `alias MyModule, as: Alias; Alias.function(args)`
  - Imported calls: `import MyModule; function(args)`

  ## Workflow

  1. Identify a problematic function you want to deprecate
  2. Find all current usage with `grep` or similar tools
  3. Add those modules to the `allow_list`
  4. Configure this check to prevent new usage
  5. Gradually migrate existing usage and remove modules from the allow list
  6. Once the allow list is empty, you can safely remove the deprecated function

  This approach lets you prevent technical debt from growing while giving you time to
  address existing usage systematically.
  """
  use Credo.Check, param_defaults: [allow_list: []]

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

  def module_to_atoms(module) when is_atom(module) do
    module |> Module.split() |> Enum.map(&String.to_atom/1)
  end
end
