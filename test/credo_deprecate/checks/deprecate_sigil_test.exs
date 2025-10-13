defmodule CredoDeprecate.Checks.DeprecateSigilTest do
  use Credo.Test.Case

  alias CredoDeprecate.Checks.DeprecateSigil

  test "sigil usage not allowed" do
    """
    defmodule ModuleOne do
      def foo do
        ~F"hello"
      end
    end
    defmodule ModuleTwo do
      def bar do
        ~F"world"
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateSigil, sigil: :sigil_F, allow_list: [ModuleOne], message: "Use ~H instead")
    |> assert_issue()
  end

  test "sigil usage allowed for modules in allow_list" do
    """
    defmodule ModuleOne do
      def foo do
        ~F"hello"
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateSigil, sigil: :sigil_F, allow_list: [ModuleOne], message: "Use ~H instead")
    |> refute_issues()
  end

  test "different sigil allowed" do
    """
    defmodule ModuleOne do
      def foo do
        ~H"hello"
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateSigil, sigil: :sigil_F, allow_list: [], message: "Use ~H instead")
    |> refute_issues()
  end
end
