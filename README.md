# CredoDeprecate

A Credo check to prevent new usage of deprecated functions while allowing existing usage.

## The Problem: Why This Check Exists

Sometimes you have functions in your codebase that you want to deprecate, but you can't use Elixir's built-in `@deprecated` attribute because there are existing legitimate uses scattered throughout the codebase. Using `@deprecated` would immediately flag all existing usage, creating noise and making it harder to prevent *new* usage.

## The Solution: Shitlists

This check implements the concept of a "shitlist" as described by Simon Eskildsen from Shopify in his blog post [Shitlists](https://sirupsen.com/shitlists). The core idea is:

> "A shitlist is a list of things you're not allowed to do. It's a way to prevent bad things from happening, while acknowledging that some bad things have already happened and can't be immediately fixed."

The approach is to:

1. **Acknowledge** that some code is problematic but can't be immediately removed
2. **Prevent** the problem from getting worse by blocking new usage  
3. **Allow** existing usage to continue (via an allow list) while you work on migration
4. **Gradually migrate** existing usage and shrink the allow list over time

## Usage

### 1. Add to your dependencies

```elixir
def deps do
  [
    {:credo_deprecate, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```

### 2. Configure the check in `.credo.exs`

```elixir
%{
  configs: [
    %{
      name: "default",
      checks: [
        # ... other checks ...
        {CredoDeprecate.Checks.DeprecateFunction, [
          mfa: {MyApp.LegacyModule, :problematic_function, 2},
          allow_list: [MyApp.ExistingUser, MyApp.AnotherExistingUser]
        ]}
      ]
    }
  ]
}
```

### 3. Run Credo

```bash
mix credo
```

## Configuration Options

- **`mfa`**: A tuple `{Module, :function, arity}` specifying the deprecated function
- **`allow_list`**: A list of modules that are allowed to continue using the deprecated function

## Examples

### What Gets Flagged

Given the configuration above, this check will flag new usage:

```elixir
defmodule MyApp.NewModule do
  # ❌ This will be flagged - new usage not allowed
  MyApp.LegacyModule.problematic_function(arg1, arg2)
end
```

### What's Allowed

But existing usage in allow-listed modules continues to work:

```elixir
defmodule MyApp.ExistingUser do
  # ✅ This is allowed (module is in allow_list)
  MyApp.LegacyModule.problematic_function(arg1, arg2)
end
```

### All Call Forms Detected

The check detects all forms of function calls:

- **Direct calls**: `MyModule.function(args)`
- **Aliased calls**: `alias MyModule; MyModule.function(args)`  
- **Aliased with as**: `alias MyModule, as: Alias; Alias.function(args)`
- **Imported calls**: `import MyModule; function(args)`

## Real-World Example

Let's say you have a problematic function `MyApp.Utils.unsafe_html_render/1` that you want to deprecate:

### Step 1: Find existing usage
```bash
grep -r "unsafe_html_render" lib/
# Results show it's used in:
# lib/my_app/legacy_view.ex
# lib/my_app/old_controller.ex
```

### Step 2: Configure the check
```elixir
# .credo.exs
{CredoDeprecate.Checks.DeprecateFunction, [
  mfa: {MyApp.Utils, :unsafe_html_render, 1},
  allow_list: [MyApp.LegacyView, MyApp.OldController]
]}
```

### Step 3: Prevent new usage
Now any new code trying to use `unsafe_html_render/1` will be flagged by Credo, but existing usage in `LegacyView` and `OldController` continues to work.

### Step 4: Migrate gradually
As you refactor `LegacyView` and `OldController`, remove them from the allow list. Once the allow list is empty, you can safely delete `unsafe_html_render/1`.

## Workflow Summary

1. **Identify** a problematic function you want to deprecate
2. **Find** all current usage with `grep` or similar tools  
3. **Add** those modules to the `allow_list`
4. **Configure** this check to prevent new usage
5. **Migrate** existing usage gradually and remove modules from the allow list
6. **Remove** the deprecated function once the allow list is empty

This approach prevents technical debt from growing while giving you time to address existing usage systematically.

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/credo_deprecate>.
