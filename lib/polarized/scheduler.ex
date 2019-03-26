defmodule Polarized.Scheduler do
  use Quantum.Scheduler,
    otp_app: :polarized

  @moduledoc "Quantum scheduler for refresh job"
end
