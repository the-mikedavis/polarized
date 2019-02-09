defmodule Polarized.Helper do
  @moduledoc """
  Helper macros
  """

  defmacro call(function_name, implementation) do
    quote do
      def unquote(function_name)(arg),
        do: GenServer.call(__MODULE__, {unquote(function_name), arg})

      def handle_call({unquote(function_name), arg}, _from, state) do
        {:reply, unquote(implementation).(arg), state}
      end
    end
  end

  defmacro cast(function_name, implementation) do
    quote do
      def unquote(function_name)(arg),
        do: GenServer.cast(__MODULE__, {unquote(function_name), arg})

      def handle_cast({unquote(function_name), arg}, state) do
        {:noreply, unquote(implementation).(arg), state}
      end
    end
  end
end
