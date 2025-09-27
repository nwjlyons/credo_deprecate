# CredoDeprecate

Credo check to prevent new usage of deprecated functions and macros while allowing existing usage via an `allow_list` 
which you can't do with the built in [`@deprecated`](https://hexdocs.pm/elixir/Module.html#module-deprecated-since-v1-6-0) attribute.

The check detects all forms of function and macro calls: direct calls, aliased calls, imported calls, required calls.

> #### Sigils {: .warning}
> 
> Sigils appear as strings to the compiler so are not supported except for inside interpolation.
> 
> ❌ `~H"<hr :if={MyApp.Foo.deprecated_function(nil, nil)}/>"`
> 
> ✅ `~s"Foo #{MyApp.Foo.deprecated_function(nil, nil)}"`

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
        {CredoDeprecate.Checks.DeprecateModule, [
          module: MyApp.Foo,
          allow_list: [MyApp.Bar, MyApp.Baz],
          message: "use Abc.bar/2 instead"
        ]},
        {CredoDeprecate.Checks.DeprecateFunctionOrMacro, [
          mfa: {MyApp.Foo, :deprecated_function, 2},
          allow_list: [MyApp.Bar],
          message: "use Abc.bar/2 instead"
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


### 4. Error

```bash
  Warnings - please take a look                                                                                                                                                                                                                      
┃ 
┃ [W] ↗ MyApp.Foo.deprecated_function/2 is deprecated. use Abc.bar/2 instead
┃       lib/my_app/qux.ex

Please report incorrect results: https://github.com/rrrene/credo/issues
```
