defmodule CredoDeprecate.Checks.DeprecateFunctionOrMacroTest do
  use Credo.Test.Case

  alias CredoDeprecate.Checks.DeprecateFunctionOrMacro

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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 0}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo.Bar, :baz, 1}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo.Bar, :baz, 1}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo.Bar, :baz, 1}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> refute_issues()
  end

  # Macro deprecation tests
  test "remote macro call not allowed" do
    """
    defmodule Foo do
      defmacro foo(a, b), do: nil
      defmacro foo(a), do: nil
    end
    defmodule ModuleOne do
      Foo.foo(2)
    end
    defmodule ModuleTwo do
      Foo.foo(2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "remote macro call with zero arity not allowed" do
    """
    defmodule Foo do
      defmacro foo(), do: nil
    end
    defmodule ModuleOne do
      Foo.foo()
    end
    defmodule ModuleTwo do
      Foo.foo()
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 0}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "remote macro call with different arity allowed" do
    """
    defmodule Foo do
      defmacro foo(a, b), do: nil
      defmacro foo(a), do: nil
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "alias macro call not allowed" do
    """
    defmodule Foo do
      defmacro foo(a), do: nil
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "alias with as macro call not allowed" do
    """
    defmodule Foo do
      defmacro foo(a), do: nil
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "import macro call not allowed" do
    """
    defmodule Foo do
      defmacro foo(a), do: nil
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested module alias macro call not allowed" do
    """
    defmodule Foo.Bar do
      defmacro baz(a), do: nil
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo.Bar, :baz, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested module alias with as macro call not allowed" do
    """
    defmodule Foo.Bar do
      defmacro baz(a), do: nil
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo.Bar, :baz, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested module import macro call not allowed" do
    """
    defmodule Foo.Bar do
      defmacro baz(a), do: nil
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo.Bar, :baz, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "alias macro call with different arity allowed" do
    """
    defmodule Foo do
      defmacro foo(a, b), do: nil
      defmacro foo(a), do: nil
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "import macro call with different arity allowed" do
    """
    defmodule Foo do
      defmacro foo(a, b), do: nil
      defmacro foo(a), do: nil
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "mixed function and macro deprecation" do
    """
    defmodule Foo do
      def bar(a), do: nil
      defmacro baz(a), do: nil
    end
    defmodule ModuleOne do
      Foo.bar(1)
      Foo.baz(1)
    end
    defmodule ModuleTwo do
      Foo.bar(1)
      Foo.baz(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :baz, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "function call within sigil_s interpolation not allowed" do
    """
    defmodule Foo do
      def deprecated_function(a), do: nil
    end
    defmodule ModuleOne do
      def test_function do
        ~s"String with \#{Foo.deprecated_function(1)} interpolation"
      end
    end
    defmodule ModuleTwo do
      def test_function do
        ~s"String with \#{Foo.deprecated_function(1)} interpolation"
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :deprecated_function, 1}, allow_list: [ModuleOne])
    |> assert_issue()
  end

  # Custom message tests
  test "uses default message when no custom message provided" do
    """
    defmodule Foo do
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne])
    |> assert_issue(fn issue ->
      assert issue.message == "Foo is deprecated"
    end)
  end

  test "uses custom message when provided" do
    """
    defmodule Foo do
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne], message: "This function is no longer supported")
    |> assert_issue(fn issue ->
      assert issue.message == "This function is no longer supported"
    end)
  end

  test "custom message works with alias calls" do
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne], message: "Please use the new API instead")
    |> assert_issue(fn issue ->
      assert issue.message == "Please use the new API instead"
    end)
  end

  test "custom message works with import calls" do
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
    |> run_check(DeprecateFunctionOrMacro, mfa: {Foo, :foo, 1}, allow_list: [ModuleOne], message: "Use Bar.foo/1 instead")
    |> assert_issue(fn issue ->
      assert issue.message == "Use Bar.foo/1 instead"
    end)
  end
end
