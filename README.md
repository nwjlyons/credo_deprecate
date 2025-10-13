Credo checks to prevent new usage of deprecated modules, functions, macros, structs, and sigils while allowing existing usage via an `allow_list`.

- [`CredoDeprecate.Checks.DeprecateModule`](https://hexdocs.pm/credo_deprecate/CredoDeprecate.Checks.DeprecateModule.html)
- [`CredoDeprecate.Checks.DeprecateFunctionOrMacro`](https://hexdocs.pm/credo_deprecate/CredoDeprecate.Checks.DeprecateFunctionOrMacro.html)
- [`CredoDeprecate.Checks.DeprecateStruct`](https://hexdocs.pm/credo_deprecate/CredoDeprecate.Checks.DeprecateStruct.html)
- [`CredoDeprecate.Checks.DeprecateSigil`](https://hexdocs.pm/credo_deprecate/CredoDeprecate.Checks.DeprecateSigil.html)

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
          mfa: {MyApp.Foo, :deprecated_function, 0},
          allow_list: [MyApp.Bar],
          message: "use Abc.bar/2 instead"
        ]},
        {CredoDeprecate.Checks.DeprecateStruct, [
          struct: MyApp.DeprecatedStruct,
          allow_list: [MyApp.LegacyModule],
          message: "use MyApp.NewStruct instead"
        ]},
        {CredoDeprecate.Checks.DeprecateSigil, [
          sigil: :sigil_F,
          allow_list: [],
          message: "Use ~H instead"
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
┃ [W] ↗ MyApp.Foo.deprecated_function/0 is deprecated. use Abc.bar/2 instead
┃       lib/my_app/qux.ex
┃ 
┃ [W] ↗ MyApp.DeprecatedStruct struct is deprecated. use MyApp.NewStruct instead
┃       lib/my_app/baz.ex
┃ 
┃ [W] ↗ ~F sigil is deprecated. Use ~H instead
┃       lib/my_app/qux.ex

Please report incorrect results: https://github.com/rrrene/credo/issues
```
