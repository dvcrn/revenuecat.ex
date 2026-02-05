defmodule RevenueCat do
  @moduledoc """
  Minimal RevenueCat client.

  Exposes `get_subscriber/1` (cached) and `fetch_subscriber/1` (remote).
  """

  @type entitlement_map :: map()

  @doc """
  Return the entitlements map from a subscriber.

  Returns an empty map for non-subscriber inputs.
  """
  @spec entitlements(RevenueCat.Subscriber.t()) :: map()
  def entitlements(%RevenueCat.Subscriber{} = subscriber) do
    subscriber.entitlements || %{}
  end

  def entitlements(_), do: %{}

  @doc """
  Return the subscriptions map from a subscriber.

  Returns an empty map for non-subscriber inputs.
  """
  @spec subscriptions(RevenueCat.Subscriber.t()) :: map()
  def subscriptions(%RevenueCat.Subscriber{} = subscriber) do
    subscriber.subscriptions || %{}
  end

  def subscriptions(_), do: %{}

  @doc """
  Return true if the subscriber has the given entitlement id.
  """
  @spec has_entitlement?(RevenueCat.Subscriber.t(), String.t() | atom()) :: boolean()
  def has_entitlement?(%RevenueCat.Subscriber{} = subscriber, entitlement_id)
      when is_binary(entitlement_id) and entitlement_id != "" do
    Map.has_key?(subscriber.entitlements || %{}, entitlement_id)
  end

  def has_entitlement?(%RevenueCat.Subscriber{} = subscriber, entitlement_id)
      when is_atom(entitlement_id) do
    has_entitlement?(subscriber, Atom.to_string(entitlement_id))
  end

  def has_entitlement?(_, _), do: false

  @doc """
  Fetch a single entitlement struct by id.
  """
  @spec entitlement(RevenueCat.Subscriber.t() | map(), String.t() | atom()) ::
          RevenueCat.Subscriber.Entitlement.t() | nil
  def entitlement(%RevenueCat.Subscriber{} = subscriber, entitlement_id) do
    entitlement(subscriber.entitlements || %{}, entitlement_id)
  end

  def entitlement(%{} = entitlements, entitlement_id) when is_atom(entitlement_id) do
    entitlement(entitlements, Atom.to_string(entitlement_id))
  end

  def entitlement(%{} = entitlements, entitlement_id)
      when is_binary(entitlement_id) and entitlement_id != "" do
    Map.get(entitlements, entitlement_id)
  end

  def entitlement(_, _), do: nil

  @doc """
  Fetch a single subscriber attribute struct by name.
  """
  @spec attribute(RevenueCat.Subscriber.t(), String.t() | atom()) ::
          RevenueCat.Subscriber.SubscriberAttribute.t() | nil
  def attribute(%RevenueCat.Subscriber{} = subscriber, name) do
    attribute(subscriber.attributes || %{}, name)
  end

  def attribute(%{} = attributes, name) when is_atom(name) do
    attribute(attributes, Atom.to_string(name))
  end

  def attribute(%{} = attributes, name) when is_binary(name) and name != "" do
    Map.get(attributes, name)
  end

  def attribute(_, _), do: nil

  @doc """
  Fetch a single subscription struct by id.
  """
  @spec subscription(RevenueCat.Subscriber.t(), String.t() | atom()) ::
          RevenueCat.Subscriber.Subscription.t() | nil
  def subscription(%RevenueCat.Subscriber{} = subscriber, subscription_id) do
    subscription(subscriber.subscriptions || %{}, subscription_id)
  end

  def subscription(%{} = subscriptions, subscription_id) when is_atom(subscription_id) do
    subscription(subscriptions, Atom.to_string(subscription_id))
  end

  def subscription(%{} = subscriptions, subscription_id)
      when is_binary(subscription_id) and subscription_id != "" do
    Map.get(subscriptions, subscription_id)
  end

  def subscription(_, _), do: nil

  @doc """
  Return true if the subscriber has the given subscription id.
  """
  @spec has_subscription?(RevenueCat.Subscriber.t(), String.t() | atom()) :: boolean()
  def has_subscription?(%RevenueCat.Subscriber{} = subscriber, subscription_id)
      when is_binary(subscription_id) and subscription_id != "" do
    Map.has_key?(subscriber.subscriptions || %{}, subscription_id)
  end

  def has_subscription?(%RevenueCat.Subscriber{} = subscriber, subscription_id)
      when is_atom(subscription_id) do
    has_subscription?(subscriber, Atom.to_string(subscription_id))
  end

  def has_subscription?(_, _), do: false

  @doc """
  Get a subscriber by app user id, using the subscriber cache when possible.
  """
  @spec get_subscriber(String.t()) ::
          {:ok, RevenueCat.Subscriber.t()} | {:error, term()}
  def get_subscriber(app_user_id)
      when is_binary(app_user_id) and byte_size(app_user_id) > 0 do
    case RevenueCat.SubscriberCache.get(app_user_id) do
      {:ok, subscriber} ->
        {:ok, subscriber}

      :miss ->
        fetch_subscriber(app_user_id)
    end
  end

  def get_subscriber(_), do: {:error, :invalid_request}

  @doc """
  Fetch a subscriber by app user id, bypassing the subscriber cache.
  """
  @spec fetch_subscriber(String.t()) ::
          {:ok, RevenueCat.Subscriber.t()} | {:error, term()}
  def fetch_subscriber(app_user_id)
      when is_binary(app_user_id) and byte_size(app_user_id) > 0 do
    with {:ok, body} <-
           RevenueCat.Client.do_request(:get, "/v1/subscribers/" <> URI.encode(app_user_id)),
         {:ok, decoded} <- Jason.decode(body),
         {:ok, subscriber} <- RevenueCat.Subscriber.from_response(decoded) do
      cache_subscriber(app_user_id, subscriber)
      {:ok, subscriber}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_subscriber(_), do: {:error, :invalid_request}

  @doc """
  Update customer attributes and return the updated subscriber.
  """
  @spec update_customer_attributes(String.t(), map()) ::
          {:ok, RevenueCat.Subscriber.t()} | {:error, term()}
  def update_customer_attributes(app_user_id, attributes)
      when is_binary(app_user_id) and byte_size(app_user_id) > 0 and is_map(attributes) do
    path = "/v1/subscribers/" <> URI.encode(app_user_id) <> "/attributes"
    payload = %{"attributes" => normalize_attributes(attributes)}

    with {:ok, body} <- RevenueCat.Client.do_request(:post, path, json: payload),
         {:ok, decoded} <- Jason.decode(body) do
      case subscriber_from_update_response(decoded) do
        {:ok, subscriber} -> {:ok, subscriber}
        {:error, _} -> fetch_subscriber(app_user_id)
      end
    else
      {:error, %Jason.DecodeError{}} -> fetch_subscriber(app_user_id)
      {:error, reason} -> {:error, reason}
    end
  end

  def update_customer_attributes(_, _), do: {:error, :invalid_request}

  defp subscriber_from_update_response(%{"value" => value}) when is_map(value) do
    RevenueCat.Subscriber.from_response(value)
  end

  defp subscriber_from_update_response(value) when is_map(value) do
    RevenueCat.Subscriber.from_response(value)
  end

  defp subscriber_from_update_response(_), do: {:error, :missing_subscriber}

  defp cache_subscriber(app_user_id, %RevenueCat.Subscriber{} = subscriber) do
    ttl_seconds = Application.get_env(:revenuecat, :subscriber_cache_ttl_seconds, 120)
    RevenueCat.SubscriberCache.put(app_user_id, subscriber, ttl_seconds)
  end

  defp normalize_attributes(attributes) when is_map(attributes) do
    Map.new(attributes, fn {key, value} -> {key, normalize_attribute_value(value)} end)
  end

  defp normalize_attribute_value(%{"value" => _} = value), do: value

  defp normalize_attribute_value(%{value: _} = value) do
    Map.new(value, fn {k, v} -> {to_string(k), v} end)
  end

  defp normalize_attribute_value(value) when is_binary(value) or is_nil(value) do
    %{"value" => value}
  end

  defp normalize_attribute_value(value) do
    %{"value" => to_string(value)}
  end
end
