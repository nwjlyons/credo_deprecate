# CredoDeprecate

Checks

- [x] `Foo.Bar.foo()`
- [x] `alias Foo.Bar; Bar.foo()`
- [x] `alias Foo.Bar, as: Baz; Baz.foo()`
- [x] `import Foo.Bar; foo()`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `credo_deprecate` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:credo_deprecate, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/credo_deprecate>.
