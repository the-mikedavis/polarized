defmodule PolarizedWeb.Plugs.UserTest do
  use ExUnit.Case

  alias PolarizedWeb.Plugs.User

  test "init just passes opts" do
    assert User.init([]) == []
  end
end
