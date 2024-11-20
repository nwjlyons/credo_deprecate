defmodule CredoDeprecate.Checks.DeprecateFunctionTest do
  use Credo.Test.Case

  alias CredoDeprecate.Checks.DeprecateFunction

  test "remote function call not allowed" do
    """
    defmodule Foo do
      def answer?(a, b), do: a + b == 42
      def answer?(a), do: a == 42
    end
    defmodule Allowed do
      Foo.answer?(2)
    end
    defmodule NotAllowedOne do
      Foo.answer?(2)
    end
    defmodule NotAllowedTwo do
      Foo.answer?(2, 2)
    end
    """
    |> to_source_file()
    |> run_check(DeprecateFunction, mfa: {Foo, :answer?, 1}, allow_list: [Allowed])
    |> assert_issue()
  end
end
