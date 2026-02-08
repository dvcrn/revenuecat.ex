defmodule RevenueCat do
  @moduledoc """
  Minimal RevenueCat client.

  Exposes `get_customer/1` (cached) and `fetch_customer/1` (remote).
  """

  @type entitlement_map :: map()

  alias RevenueCat.Offerings

  @doc """
  Return the entitlements map from a customer.

  Returns an empty map for non-customer inputs.
  """
  @spec entitlements(RevenueCat.Customer.t()) :: map()
  def entitlements(%RevenueCat.Customer{} = customer) do
    customer.entitlements || %{}
  end

  def entitlements(_), do: %{}

  @doc """
  Return the subscriptions map from a customer.

  Returns an empty map for non-customer inputs.
  """
  @spec subscriptions(RevenueCat.Customer.t()) :: map()
  def subscriptions(%RevenueCat.Customer{} = customer) do
    customer.subscriptions || %{}
  end

  def subscriptions(_), do: %{}

  @doc """
  Return true if the customer has the given entitlement id.
  """
  @spec has_entitlement?(RevenueCat.Customer.t(), String.t() | atom()) :: boolean()
  def has_entitlement?(%RevenueCat.Customer{} = customer, entitlement_id)
      when is_binary(entitlement_id) and entitlement_id != "" do
    Map.has_key?(customer.entitlements || %{}, entitlement_id)
  end

  def has_entitlement?(%RevenueCat.Customer{} = customer, entitlement_id)
      when is_atom(entitlement_id) do
    has_entitlement?(customer, Atom.to_string(entitlement_id))
  end

  def has_entitlement?(_, _), do: false

  @doc """
  Fetch a single entitlement struct by id.
  """
  @spec entitlement(RevenueCat.Customer.t() | map(), String.t() | atom()) ::
          RevenueCat.Customer.Entitlement.t() | nil
  def entitlement(%RevenueCat.Customer{} = customer, entitlement_id) do
    entitlement(customer.entitlements || %{}, entitlement_id)
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
  Fetch a single customer attribute struct by name.
  """
  @spec attribute(RevenueCat.Customer.t(), String.t() | atom()) ::
          RevenueCat.Customer.Attribute.t() | nil
  def attribute(%RevenueCat.Customer{} = customer, name) do
    attribute(customer.attributes || %{}, name)
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
  @spec subscription(RevenueCat.Customer.t(), String.t() | atom()) ::
          RevenueCat.Customer.Subscription.t() | nil
  def subscription(%RevenueCat.Customer{} = customer, subscription_id) do
    subscription(customer.subscriptions || %{}, subscription_id)
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
  Return true if the customer has the given subscription id.
  """
  @spec has_subscription?(RevenueCat.Customer.t(), String.t() | atom()) :: boolean()
  def has_subscription?(%RevenueCat.Customer{} = customer, subscription_id)
      when is_binary(subscription_id) and subscription_id != "" do
    Map.has_key?(customer.subscriptions || %{}, subscription_id)
  end

  def has_subscription?(%RevenueCat.Customer{} = customer, subscription_id)
      when is_atom(subscription_id) do
    has_subscription?(customer, Atom.to_string(subscription_id))
  end

  def has_subscription?(_, _), do: false

  @doc """
  Get a customer by app user id, using the customer cache when possible.
  """
  @spec get_customer(String.t()) ::
          {:ok, RevenueCat.Customer.t()} | {:error, term()}
  def get_customer(app_user_id)
      when is_binary(app_user_id) and byte_size(app_user_id) > 0 do
    case RevenueCat.CustomerCache.get(app_user_id) do
      {:ok, customer} ->
        {:ok, customer}

      :miss ->
        fetch_customer(app_user_id)
    end
  end

  def get_customer(_), do: {:error, :invalid_request}

  @doc """
  Fetch a customer by app user id, bypassing the customer cache.
  """
  @spec fetch_customer(String.t()) ::
          {:ok, RevenueCat.Customer.t()} | {:error, term()}
  def fetch_customer(app_user_id)
      when is_binary(app_user_id) and byte_size(app_user_id) > 0 do
    with {:ok, body} <-
           RevenueCat.Client.do_request(:get, "/v1/subscribers/" <> URI.encode(app_user_id)),
         {:ok, decoded} <- Jason.decode(body),
         {:ok, customer} <- RevenueCat.Customer.from_response(decoded) do
      cache_customer(app_user_id, customer)
      {:ok, customer}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch_customer(_), do: {:error, :invalid_request}

  @doc """
  Update customer attributes and return the updated customer.
  """
  @spec update_customer_attributes(String.t(), map()) ::
          {:ok, RevenueCat.Customer.t()} | {:error, term()}
  def update_customer_attributes(app_user_id, attributes)
      when is_binary(app_user_id) and byte_size(app_user_id) > 0 and is_map(attributes) do
    path = "/v1/subscribers/" <> URI.encode(app_user_id) <> "/attributes"
    payload = %{"attributes" => normalize_attributes(attributes)}

    with {:ok, body} <- RevenueCat.Client.do_request(:post, path, json: payload),
         {:ok, decoded} <- Jason.decode(body) do
      case customer_from_update_response(decoded) do
        {:ok, customer} -> {:ok, customer}
        {:error, _} -> fetch_customer(app_user_id)
      end
    else
      {:error, %Jason.DecodeError{}} -> fetch_customer(app_user_id)
      {:error, reason} -> {:error, reason}
    end
  end

  def update_customer_attributes(_, _), do: {:error, :invalid_request}

  @doc """
  Get Offerings for a given `app_user_id`.

  This endpoint can optionally take a `:platform` (string) which will be sent
  as the `X-Platform` header (lower-cased to `x-platform`), e.g. `"ios"`.
  """
  @spec get_offerings(String.t(), keyword()) :: {:ok, Offerings.t()} | {:error, term()}
  def get_offerings(app_user_id, opts \\ [])

  def get_offerings(app_user_id, opts)
      when is_binary(app_user_id) and byte_size(app_user_id) > 0 and is_list(opts) do
    path = "/v1/subscribers/" <> URI.encode(app_user_id) <> "/offerings"

    with {:ok, headers} <- offerings_headers(opts),
         {:ok, body} <- RevenueCat.Client.do_request(:get, path, headers: headers),
         {:ok, decoded} <- Jason.decode(body),
         {:ok, offerings} <- Offerings.from_response(decoded) do
      {:ok, offerings}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def get_offerings(_, _), do: {:error, :invalid_request}

  defp customer_from_update_response(%{"value" => value}) when is_map(value) do
    RevenueCat.Customer.from_response(value)
  end

  defp customer_from_update_response(value) when is_map(value) do
    RevenueCat.Customer.from_response(value)
  end

  defp customer_from_update_response(_), do: {:error, :missing_customer}

  defp cache_customer(app_user_id, %RevenueCat.Customer{} = customer) do
    ttl_seconds = Application.get_env(:revenuecat, :customer_cache_ttl_seconds, 120)
    RevenueCat.CustomerCache.put(app_user_id, customer, ttl_seconds)
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

  defp offerings_headers(opts) when is_list(opts) do
    case Keyword.fetch(opts, :platform) do
      :error ->
        {:ok, []}

      {:ok, nil} ->
        {:ok, []}

      {:ok, platform} when is_binary(platform) and platform != "" ->
        {:ok, [{"x-platform", platform}]}

      {:ok, _} ->
        {:error, :invalid_request}
    end
  end
end
