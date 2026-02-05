# RevenueCat

Minimal RevenueCat client for Elixir

[docs](https://hexdocs.pm/revenuecat)

## Installation

```elixir
def deps do
  [
    {:revenuecat, "~> 0.1.0"}
  ]
end
```

## Configuration

Set your API key in config or environment:

```elixir
config :revenuecat, api_key: System.get_env("REVENUECAT_API_KEY")
```

Optional:

```elixir
config :revenuecat,
  base_url: "https://api.revenuecat.com",
  client_adapter: RevenueCat.Client.Req
```

Optional cache:

```elixir
config :revenuecat, subscriber_cache_ttl_seconds: 120
```

## Usage

```elixir
# get a subscriber (cached by subscriber_cache_ttl_seconds)
{:ok, subscriber} = RevenueCat.get_subscriber(app_user_id)

# always fetch a subscriber independent of cache value
{:ok, subscriber} = RevenueCat.fetch_subscriber(app_user_id)


IO.inspect(subscriber)

# Entitlements
RevenueCat.entitlement(subscriber, "pro")
|> IO.inspect

RevenueCat.has_entitlement?(subscriber, "pro")

IO.inspect(subscriber.entitlements)

# Subscriptions
RevenueCat.subscription(subscriber, "my_sub")
|> IO.inspect

RevenueCat.has_subscription?(subscriber, "my_subscription")

IO.inspect(subscriber.subscriptions)

# Attributes
IO.inspect(subscriber.attributes)

RevenueCat.attribute(subscriber, "$email")
|> IO.inspect
```

### Add customer attributes:

```elixir
{:ok, subscriber} =
  RevenueCat.update_customer_attributes(app_user_id, %{
    "foo" => "bar"
  })
```

## License

MIT
