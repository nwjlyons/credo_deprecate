defmodule CredoDeprecate.Checks.DeprecateStructTest do
  use Credo.Test.Case

  alias CredoDeprecate.Checks.DeprecateStruct

  test "direct struct usage not allowed" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      def create_struct do
        %DeprecatedStruct{field1: "value1", field2: "value2"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "empty struct usage not allowed" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      def create_struct do
        %DeprecatedStruct{}
      end
    end
    defmodule ModuleTwo do
      def create_struct do
        %DeprecatedStruct{}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "struct pattern matching not allowed" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      def match_struct(data) do
        %DeprecatedStruct{field1: value} = data
        value
      end
    end
    defmodule ModuleTwo do
      def match_struct(data) do
        %DeprecatedStruct{field1: value} = data
        value
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "struct update not allowed" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      def update_struct(existing) do
        %DeprecatedStruct{existing | field1: "new_value"}
      end
    end
    defmodule ModuleTwo do
      def update_struct(existing) do
        %DeprecatedStruct{existing | field2: "new_value"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "alias struct usage not allowed" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      alias DeprecatedStruct
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      alias DeprecatedStruct
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "alias with as struct usage not allowed" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      alias DeprecatedStruct, as: DS
      def create_struct do
        %DS{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      alias DeprecatedStruct, as: OldStruct
      def create_struct do
        %OldStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested struct direct usage not allowed" do
    """
    defmodule Foo.DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      def create_struct do
        %Foo.DeprecatedStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      def create_struct do
        %Foo.DeprecatedStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: Foo.DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested struct alias usage not allowed" do
    """
    defmodule Foo.DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      alias Foo.DeprecatedStruct
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      alias Foo.DeprecatedStruct
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: Foo.DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "nested struct alias with as usage not allowed" do
    """
    defmodule Foo.DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      alias Foo.DeprecatedStruct, as: MyStruct
      def create_struct do
        %MyStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      alias Foo.DeprecatedStruct, as: OtherStruct
      def create_struct do
        %OtherStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: Foo.DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue()
  end

  test "allow list works for direct struct usage" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne, ModuleTwo])
    |> refute_issues()
  end

  test "allow list works for alias struct usage" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      alias DeprecatedStruct
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      alias DeprecatedStruct
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne, ModuleTwo])
    |> refute_issues()
  end

  test "different struct usage allowed" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule OtherStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      def create_struct do
        %OtherStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne])
    |> refute_issues()
  end

  test "custom message is displayed" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, 
        struct: DeprecatedStruct, 
        allow_list: [ModuleOne], 
        message: "use NewStruct instead")
    |> assert_issue(fn issue ->
      assert issue.message =~ "DeprecatedStruct struct is deprecated. use NewStruct instead"
    end)
  end

  test "no custom message shows default" do
    """
    defmodule DeprecatedStruct do
      defstruct [:field1, :field2]
    end
    defmodule ModuleOne do
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    defmodule ModuleTwo do
      def create_struct do
        %DeprecatedStruct{field1: "value1"}
      end
    end
    """
    |> to_source_file()
    |> run_check(DeprecateStruct, struct: DeprecatedStruct, allow_list: [ModuleOne])
    |> assert_issue(fn issue ->
      assert issue.message =~ "DeprecatedStruct struct is deprecated."
    end)
  end
end
