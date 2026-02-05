defmodule RevenueCat.Subscriber do
  @moduledoc """
  Parsed subscriber response from RevenueCat.
  """

  alias RevenueCat.Subscriber.Entitlement
  alias RevenueCat.Subscriber.SubscriberAttribute
  alias RevenueCat.Subscriber.Subscription

  @type t :: %__MODULE__{
          request_date: String.t() | nil,
          request_date_ms: integer() | nil,
          entitlements: %{optional(String.t()) => Entitlement.t()},
          first_seen: String.t() | nil,
          last_seen: String.t() | nil,
          management_url: String.t() | nil,
          non_subscriptions: map(),
          original_app_user_id: String.t() | nil,
          original_application_version: String.t() | nil,
          original_purchase_date: String.t() | nil,
          other_purchases: map(),
          attributes: %{optional(String.t()) => SubscriberAttribute.t()},
          subscriptions: %{optional(String.t()) => Subscription.t()}
        }

  defstruct [
    :request_date,
    :request_date_ms,
    :first_seen,
    :last_seen,
    :management_url,
    :original_app_user_id,
    :original_application_version,
    :original_purchase_date,
    entitlements: %{},
    non_subscriptions: %{},
    other_purchases: %{},
    attributes: %{},
    subscriptions: %{}
  ]

  @doc """
  Build a subscriber struct from a RevenueCat response map.
  """
  @spec from_response(map()) :: {:ok, t()} | {:error, term()}
  def from_response(%{"subscriber" => subscriber} = response) when is_map(subscriber) do
    {:ok,
     %__MODULE__{
       request_date: response["request_date"],
       request_date_ms: response["request_date_ms"],
       entitlements: Entitlement.map_from(Map.get(subscriber, "entitlements", %{})),
       first_seen: subscriber["first_seen"],
       last_seen: subscriber["last_seen"],
       management_url: subscriber["management_url"],
       non_subscriptions: Map.get(subscriber, "non_subscriptions", %{}),
       original_app_user_id: subscriber["original_app_user_id"],
       original_application_version: subscriber["original_application_version"],
       original_purchase_date: subscriber["original_purchase_date"],
       other_purchases: Map.get(subscriber, "other_purchases", %{}),
       attributes:
         SubscriberAttribute.map_from(Map.get(subscriber, "subscriber_attributes", %{})),
       subscriptions: Subscription.map_from(Map.get(subscriber, "subscriptions", %{}))
     }}
  end

  def from_response(_), do: {:error, :invalid_response}
end
