defmodule CredoDeprecate.Checks.DeprecateFunctionTest do
  use Credo.Test.Case

  alias CredoDeprecate.Checks.DeprecateFunction

  test "remote function call not allowed" do
    """
    defmodule Foo do
      def foo(a, b), do: nil
      def foo(a), do: nil
    end
    defmodule ModuleOne do
      Foo.foo(2)
    end
    defmodule ModuleTwo do
      Foo.foo(2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "remote function call with different arity allowed" do
    """
    defmodule Foo do
      def foo(a, b), do: nil
      def foo(a), do: nil
    end
    defmodule ModuleOne do
      Foo.foo(2)
    end
    defmodule ModuleTwo do
      # uses different arity
      Foo.foo(2, 2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> refute_issues()
  end
end
