defmodule Polarized.Effects.Behaviour do
  @moduledoc "oh what we do for the mox"

  @callback download_file(String.t(), Path.t()) :: :ok
end
