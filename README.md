# CredoDeprecate

Prevents new usage of deprecated functions and macros while allowing existing usage.

Sometimes you have functions or macros in your codebase that you want to deprecate, but you can't
use Elixir's built-in `@deprecated` attribute because there are existing uses
scattered throughout the codebase. This check allows you to prevent new usage while
maintaining an allow list for existing usage.

The check detects all forms of function and macro calls: direct calls, aliased calls, and imported calls.

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
        {CredoDeprecate.Checks.DeprecateFunctionOrMacro, [
          mfa: {MyApp.Foo, :deprecated_function, 2},
          allow_list: [MyApp.Bar, MyApp.Baz]
        ]},
        {CredoDeprecate.Checks.DeprecateFunctionOrMacro, [
          mfa: {MyApp.Foo, :deprecated_macro, 2},
          allow_list: [MyApp.Bar]
        ]}
      ]
    }
  ]
}
```

### 3. Examples of detected function and macro calls

The check detects all forms of function and macro calls in the examples below:

#### Direct calls
```elixir
defmodule MyApp.Qux do
  def quux() do
    MyApp.Foo.deprecated_function(arg1, arg2)
  end
end
```

#### Aliased calls
```elixir
defmodule MyApp.Qux do
  alias MyApp.Foo

  def quux() do
    Foo.deprecated_function(arg1, arg2)
    Foo.deprecated_macro(arg1, arg2)
  end
end
```

#### Aliased with as
```elixir
defmodule MyApp.Qux do
  alias MyApp.Foo, as: MyFoo

  def quux() do
    MyFoo.deprecated_function(arg1, arg2)
    MyFoo.deprecated_macro(arg1, arg2)
  end
end
```

#### Imported calls
```elixir
defmodule MyApp.Qux do
  import MyApp.Foo

  def quux() do
    deprecated_function(arg1, arg2)
    deprecated_macro(arg1, arg2)
  end
end
```

### 4. Run Credo

```bash
mix credo
```
