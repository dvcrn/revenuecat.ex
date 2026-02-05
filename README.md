# RevenueCat

Minimal RevenueCat client for Elixir

[docs](https://hexdocs.pm/revenuecat)

## Installation

```elixir
def deps do
  [
    {:revenuecat, "~> 0.2.0"}
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
config :revenuecat, customer_cache_ttl_seconds: 120
```

## Usage

```elixir
# get a customer (cached by customer_cache_ttl_seconds)
{:ok, customer} = RevenueCat.get_customer(app_user_id)

# always fetch a customer independent of cache value
{:ok, customer} = RevenueCat.fetch_customer(app_user_id)

IO.inspect(customer)

# Entitlements
RevenueCat.entitlement(customer, "pro")
|> IO.inspect

RevenueCat.has_entitlement?(customer, "pro")

IO.inspect(customer.entitlements)

# Subscriptions
RevenueCat.subscription(customer, "my_sub")
|> IO.inspect

RevenueCat.has_subscription?(customer, "my_subscription")

IO.inspect(customer.subscriptions)

# Attributes
IO.inspect(customer.attributes)

RevenueCat.attribute(customer, "$email")
|> IO.inspect
```

### Add customer attributes:

```elixir
{:ok, customer} =
  RevenueCat.update_customer_attributes(app_user_id, %{
    "foo" => "bar"
  })
```

## License

MIT
