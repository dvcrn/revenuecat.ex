defmodule RevenueCat.Subscriber.SubscriberAttribute do
  @moduledoc false

  @type t :: %__MODULE__{
          updated_at_ms: integer() | nil,
          value: String.t() | nil
        }

  defstruct [:updated_at_ms, :value]

  @doc """
  Build a subscriber attribute struct from a map.
  """
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      updated_at_ms: map["updated_at_ms"],
      value: map["value"]
    }
  end

  @doc """
  Build a subscriber attribute map keyed by attribute name.
  """
  @spec map_from(map()) :: %{optional(String.t()) => t()}
  def map_from(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} -> {key, from_map(value || %{})} end)
  end

  def map_from(_), do: %{}
end
