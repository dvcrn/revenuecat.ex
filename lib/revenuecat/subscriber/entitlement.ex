defmodule RevenueCat.Subscriber.Entitlement do
  @moduledoc false

  @type t :: %__MODULE__{
          expires_date: String.t() | nil,
          grace_period_expires_date: String.t() | nil,
          product_identifier: String.t() | nil,
          purchase_date: String.t() | nil
        }

  defstruct [
    :expires_date,
    :grace_period_expires_date,
    :product_identifier,
    :purchase_date
  ]

  @doc """
  Build an entitlement struct from a map.
  """
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      expires_date: map["expires_date"],
      grace_period_expires_date: map["grace_period_expires_date"],
      product_identifier: map["product_identifier"],
      purchase_date: map["purchase_date"]
    }
  end

  @doc """
  Build an entitlement map keyed by entitlement id.
  """
  @spec map_from(map()) :: %{optional(String.t()) => t()}
  def map_from(entitlements) when is_map(entitlements) do
    Map.new(entitlements, fn {key, value} -> {key, from_map(value || %{})} end)
  end

  def map_from(_), do: %{}
end
