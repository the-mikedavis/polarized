defmodule PolarizedWeb.Plugs.AuthTest do
  use ExUnit.Case

  alias PolarizedWeb.Plugs.Auth

  test "init just passes opts" do
    assert Auth.init([]) == []
  end
end
