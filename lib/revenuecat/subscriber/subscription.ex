defmodule RevenueCat.Subscriber.Subscription do
  @moduledoc false

  alias RevenueCat.Subscriber.Subscription.Price

  @type t :: %__MODULE__{
          auto_resume_date: String.t() | nil,
          billing_issues_detected_at: String.t() | nil,
          display_name: String.t() | nil,
          expires_date: String.t() | nil,
          grace_period_expires_date: String.t() | nil,
          is_sandbox: boolean() | nil,
          management_url: String.t() | nil,
          original_purchase_date: String.t() | nil,
          period_type: String.t() | nil,
          price: Price.t() | nil,
          purchase_date: String.t() | nil,
          refunded_at: String.t() | nil,
          store: String.t() | nil,
          store_transaction_id: String.t() | nil,
          unsubscribe_detected_at: String.t() | nil
        }

  defstruct [
    :auto_resume_date,
    :billing_issues_detected_at,
    :display_name,
    :expires_date,
    :grace_period_expires_date,
    :is_sandbox,
    :management_url,
    :original_purchase_date,
    :period_type,
    :price,
    :purchase_date,
    :refunded_at,
    :store,
    :store_transaction_id,
    :unsubscribe_detected_at
  ]

  @doc """
  Build a subscription struct from a map.
  """
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      auto_resume_date: map["auto_resume_date"],
      billing_issues_detected_at: map["billing_issues_detected_at"],
      display_name: map["display_name"],
      expires_date: map["expires_date"],
      grace_period_expires_date: map["grace_period_expires_date"],
      is_sandbox: map["is_sandbox"],
      management_url: map["management_url"],
      original_purchase_date: map["original_purchase_date"],
      period_type: map["period_type"],
      price: map["price"] && Price.from_map(map["price"]),
      purchase_date: map["purchase_date"],
      refunded_at: map["refunded_at"],
      store: map["store"],
      store_transaction_id: map["store_transaction_id"],
      unsubscribe_detected_at: map["unsubscribe_detected_at"]
    }
  end

  @doc """
  Build a subscription map keyed by product id.
  """
  @spec map_from(map()) :: %{optional(String.t()) => t()}
  def map_from(subs) when is_map(subs) do
    Map.new(subs, fn {key, value} -> {key, from_map(value || %{})} end)
  end

  def map_from(_), do: %{}
end
