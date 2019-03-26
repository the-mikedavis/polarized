defmodule Polarized.Content.Server.Behaviour do
  @moduledoc "A behaviour for the content server"

  alias Polarized.Content.Embed

  @callback request(:_ | boolean(), :_ | [String.t()]) :: [%Embed{}]
  @callback list_hashtags() :: [String.t()]
  @callback get(integer()) :: %Embed{} | nil
  @callback refresh() :: :ok
  @callback add(String.t()) :: :ok
  @callback remove(String.t()) :: :ok
end
