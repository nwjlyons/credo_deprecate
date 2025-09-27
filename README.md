# CredoDeprecate

Credo check to prevent new usage of deprecated functions and macros while allowing existing usage via an `allow_list` 
which you can't do with the built in [`@deprecated`](https://hexdocs.pm/elixir/Module.html#module-deprecated-since-v1-6-0) attribute.

The check detects all forms of function and macro calls: direct calls, aliased calls, imported calls, required calls.

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
          allow_list: [MyApp.Bar, MyApp.Baz],
          message: "use Abc.bar/2 instead"
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
    MyApp.Foo.deprecated_function(nil, nil)
  end
end
```

#### Aliased calls
```elixir
defmodule MyApp.Qux do
  alias MyApp.Foo

  def quux() do
    Foo.deprecated_function(nil, nil)
  end
end
```

#### Aliased with as
```elixir
defmodule MyApp.Qux do
  alias MyApp.Foo, as: MyFoo

  def quux() do
    MyFoo.deprecated_function(nil, nil)
  end
end
```

#### Imported calls
```elixir
defmodule MyApp.Qux do
  import MyApp.Foo

  def quux() do
    deprecated_function(nil, nil)
    deprecated_macro(nil, nil)
  end
end
```

#### Required calls
```elixir
defmodule MyApp.Qux do
  require MyApp.Foo

  def quux() do
    MyApp.Foo.deprecated_macro(nil, nil)
  end
end
```

### 4. Run Credo

```bash
mix credo
```
