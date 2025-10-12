defmodule CredoDeprecate.Checks.DeprecateModuleTest do
  use Credo.Test.Case

  alias CredoDeprecate.Checks.DeprecateModule

  test "direct module call allowed (not detected by this check)" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      DeprecatedModule.some_function(1)
    end
    defmodule ModuleTwo do
      DeprecatedModule.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "direct module call with zero arity allowed (not detected by this check)" do
    """
    defmodule DeprecatedModule do
      def some_function(), do: nil
    end
    defmodule ModuleOne do
      DeprecatedModule.some_function()
    end
    defmodule ModuleTwo do
      DeprecatedModule.some_function()
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "direct module call with multiple functions allowed (not detected by this check)" do
    """
    defmodule DeprecatedModule do
      def func_a(a), do: nil
      def func_b(a, b), do: nil
    end
    defmodule ModuleOne do
      DeprecatedModule.func_a(1)
    end
    defmodule ModuleTwo do
      DeprecatedModule.func_b(1, 2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "alias module call not allowed" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      alias DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    defmodule ModuleTwo do
      alias DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "alias with as module call not allowed" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      alias DeprecatedModule, as: Dep
      Dep.some_function(1)
    end
    defmodule ModuleTwo do
      alias DeprecatedModule, as: OldMod
      OldMod.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "import module not allowed" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      import DeprecatedModule
      some_function(1)
    end
    defmodule ModuleTwo do
      import DeprecatedModule
      some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "require module not allowed" do
    """
    defmodule DeprecatedModule do
      defmacro some_macro(a), do: nil
    end
    defmodule ModuleOne do
      require DeprecatedModule
      DeprecatedModule.some_macro(1)
    end
    defmodule ModuleTwo do
      require DeprecatedModule
      DeprecatedModule.some_macro(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested module direct call allowed (not detected by this check)" do
    """
    defmodule Foo.DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      Foo.DeprecatedModule.some_function(1)
    end
    defmodule ModuleTwo do
      Foo.DeprecatedModule.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: Foo.DeprecatedModule, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "nested module alias call not allowed" do
    """
    defmodule Foo.DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      alias Foo.DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    defmodule ModuleTwo do
      alias Foo.DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: Foo.DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested module alias with as call not allowed" do
    """
    defmodule Foo.DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      alias Foo.DeprecatedModule, as: MyDep
      MyDep.some_function(1)
    end
    defmodule ModuleTwo do
      alias Foo.DeprecatedModule, as: OtherDep
      OtherDep.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: Foo.DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested module import call not allowed" do
    """
    defmodule Foo.DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      import Foo.DeprecatedModule
      some_function(1)
    end
    defmodule ModuleTwo do
      import Foo.DeprecatedModule
      some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: Foo.DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "allow list works for direct calls" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      DeprecatedModule.some_function(1)
    end
    defmodule ModuleTwo do
      DeprecatedModule.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne, ModuleTwo])
    |> refute_issues()
  end

  test "allow list works for alias calls" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      alias DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    defmodule ModuleTwo do
      alias DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne, ModuleTwo])
    |> refute_issues()
  end

  test "allow list works for import calls" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      import DeprecatedModule
      some_function(1)
    end
    defmodule ModuleTwo do
      import DeprecatedModule
      some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne, ModuleTwo])
    |> refute_issues()
  end

  test "different module usage allowed" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule OtherModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      DeprecatedModule.some_function(1)
    end
    defmodule ModuleTwo do
      OtherModule.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "custom message is displayed" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      alias DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    defmodule ModuleTwo do
      alias DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, 
        module: DeprecatedModule, 
        allow_list: [ModuleOne], 
        message: "use NewModule instead")
    |> assert_issue(fn issue ->
      assert issue.message =~ "DeprecatedModule is deprecated. use NewModule instead"
    end)
  end

  test "no custom message shows default" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      alias DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    defmodule ModuleTwo do
      alias DeprecatedModule
      DeprecatedModule.some_function(1)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue(fn issue ->
      assert issue.message == "DeprecatedModule is deprecated."
    end)
  end

  test "alias statement without usage not allowed" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      alias DeprecatedModule
    end
    defmodule ModuleTwo do
      alias DeprecatedModule
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "alias with as statement without usage not allowed" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      alias DeprecatedModule, as: Dep
    end
    defmodule ModuleTwo do
      alias DeprecatedModule, as: OldMod
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "import statement without usage not allowed" do
    """
    defmodule DeprecatedModule do
      def some_function(a), do: nil
    end
    defmodule ModuleOne do
      import DeprecatedModule
    end
    defmodule ModuleTwo do
      import DeprecatedModule
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "require statement without usage not allowed" do
    """
    defmodule DeprecatedModule do
      defmacro some_macro(a), do: nil
    end
    defmodule ModuleOne do
      require DeprecatedModule
    end
    defmodule ModuleTwo do
      require DeprecatedModule
    end
    """
    |> to_source_file()
    |> run_check(DeprecateModule, module: DeprecatedModule, allow_list: [ModuleOne])
    |> assert_issue()
  end
end
