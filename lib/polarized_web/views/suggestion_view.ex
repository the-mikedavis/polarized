defmodule PolarizedWeb.SuggestionView do
  use PolarizedWeb, :view

  alias Polarized.Content.Handle

  def wingedness(%Handle{right_wing: true}), do: "right"
  def wingedness(%Handle{right_wing: false}), do: "left"
end
