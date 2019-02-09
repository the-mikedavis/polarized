defmodule Polarized.ApplicationTest do
  use ExUnit.Case

  alias Polarized.Application

  test "config change is ok" do
    assert :ok = Application.config_change([], [], [])
  end
end
