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

  test "remote function call with zero arity not allowed" do
    """
    defmodule Foo do
      def foo(), do: nil
    end
    defmodule ModuleOne do
      Foo.foo()
    end
    defmodule ModuleTwo do
      Foo.foo()
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :foo, 0}, allow_list: [ModuleOne])
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

  test "alias function call not allowed" do
    """
    defmodule Foo do
      def foo(a), do: nil
    end
    defmodule ModuleOne do
      alias Foo
      Foo.foo(2)
    end
    defmodule ModuleTwo do
      alias Foo
      Foo.foo(2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "alias with as function call not allowed" do
    """
    defmodule Foo do
      def foo(a), do: nil
    end
    defmodule ModuleOne do
      alias Foo, as: Bar
      Bar.foo(2)
    end
    defmodule ModuleTwo do
      alias Foo, as: Baz
      Baz.foo(2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "import function call not allowed" do
    """
    defmodule Foo do
      def foo(a), do: nil
    end
    defmodule ModuleOne do
      import Foo
      foo(2)
    end
    defmodule ModuleTwo do
      import Foo
      foo(2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested module alias function call not allowed" do
    """
    defmodule Foo.Bar do
      def baz(a), do: nil
    end
    defmodule ModuleOne do
      alias Foo.Bar
      Bar.baz(2)
    end
    defmodule ModuleTwo do
      alias Foo.Bar
      Bar.baz(2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo.Bar, :baz, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested module alias with as function call not allowed" do
    """
    defmodule Foo.Bar do
      def baz(a), do: nil
    end
    defmodule ModuleOne do
      alias Foo.Bar, as: MyBar
      MyBar.baz(2)
    end
    defmodule ModuleTwo do
      alias Foo.Bar, as: OtherBar
      OtherBar.baz(2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo.Bar, :baz, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested module import function call not allowed" do
    """
    defmodule Foo.Bar do
      def baz(a), do: nil
    end
    defmodule ModuleOne do
      import Foo.Bar
      baz(2)
    end
    defmodule ModuleTwo do
      import Foo.Bar
      baz(2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo.Bar, :baz, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "alias function call with different arity allowed" do
    """
    defmodule Foo do
      def foo(a, b), do: nil
      def foo(a), do: nil
    end
    defmodule ModuleOne do
      alias Foo
      Foo.foo(2)
    end
    defmodule ModuleTwo do
      alias Foo
      # uses different arity
      Foo.foo(2, 2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "import function call with different arity allowed" do
    """
    defmodule Foo do
      def foo(a, b), do: nil
      def foo(a), do: nil
    end
    defmodule ModuleOne do
      import Foo
      foo(2)
    end
    defmodule ModuleTwo do
      import Foo
      # uses different arity
      foo(2, 2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> refute_issues()
  end
end
