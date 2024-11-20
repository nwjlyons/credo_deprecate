defmodule CredoDeprecate.Checks.DeprecateFunctionTest do
  use Credo.Test.Case

  alias CredoDeprecate.Checks.DeprecateFunction

  test "import not allowed" do
    """
    defmodule Foo do
      def foo(), do: nil
    end
    defmodule CredoSampleModule do
      import Foo
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :foo, 1})
    |> assert_issue()
  end
end
