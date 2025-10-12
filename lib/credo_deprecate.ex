defmodule CredoDeprecate do
  @readme_filepath Path.join(__DIR__, "../README.md")
  @external_resource @readme_filepath
  @moduledoc File.read!(@readme_filepath)
end
