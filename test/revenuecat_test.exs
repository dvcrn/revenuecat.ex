defmodule RevenueCatTest do
  use ExUnit.Case
  import Mox

  setup do
    Mox.set_mox_global()
    Application.put_env(:revenuecat, :client_adapter, RevenueCat.ClientMock)
    Application.put_env(:revenuecat, :api_key, "test_key")
    Application.put_env(:revenuecat, :subscriber_cache_ttl_seconds, 120)
    RevenueCat.SubscriberCache.clear()
    :ok
  end

  test "fetches entitlements via mocked client" do
    stub(RevenueCat.ClientMock, :do_request, fn _opts -> {:ok, production_body()} end)

    assert {:ok, subscriber} =
             RevenueCat.get_subscriber("c5389bab-e858-44d0-826e-c64ee14d9730")

    entitlements = RevenueCat.entitlements(subscriber)
    assert Map.has_key?(entitlements, "pro")
    assert RevenueCat.entitlement(subscriber, "pro") != nil
    assert RevenueCat.entitlement(subscriber, "missing") == nil

    assert RevenueCat.has_entitlement?(subscriber, "pro")
    assert RevenueCat.has_entitlement?(subscriber, :pro)
    refute RevenueCat.has_entitlement?(subscriber, "missing")
  end

  test "has_entitlement? supports subscriber and atom" do
    stub(RevenueCat.ClientMock, :do_request, fn _opts -> {:ok, production_body()} end)

    assert {:ok, subscriber} =
             RevenueCat.get_subscriber("c5389bab-e858-44d0-826e-c64ee14d9730")

    assert RevenueCat.has_entitlement?(subscriber, "pro")
    assert RevenueCat.has_entitlement?(subscriber, :pro)
  end

  test "subscriptions and attribute helpers" do
    stub(RevenueCat.ClientMock, :do_request, fn _opts -> {:ok, production_body()} end)

    assert {:ok, subscriber} =
             RevenueCat.get_subscriber("c5389bab-e858-44d0-826e-c64ee14d9730")

    subs = RevenueCat.subscriptions(subscriber)
    assert Map.has_key?(subs, "example.product.web")

    assert %RevenueCat.Subscriber.Subscription{} =
             RevenueCat.subscription(subscriber, "example.product.web")

    assert %RevenueCat.Subscriber.Subscription{} =
             RevenueCat.subscription(subscriber, :"example.product.web")

    assert RevenueCat.subscription(subscriber, "missing") == nil
    assert RevenueCat.has_subscription?(subscriber, "example.product.web")
    assert RevenueCat.has_subscription?(subscriber, :"example.product.web")
    refute RevenueCat.has_subscription?(subscriber, "missing")

    assert %RevenueCat.Subscriber.SubscriberAttribute{} =
             RevenueCat.attribute(subscriber, "$email")

    assert RevenueCat.attribute(subscriber, "missing") == nil
  end

  test "update_customer_attributes posts attributes payload" do
    attrs = %{
      "plan" => %{"value" => "pro", "updated_at_ms" => 1_700_000_000_000},
      "note" => "test"
    }

    expect(RevenueCat.ClientMock, :do_request, fn opts ->
      assert opts[:method] == :post
      assert String.ends_with?(opts[:url], "/v1/subscribers/test_user/attributes")

      assert opts[:json] == %{
               "attributes" => %{
                 "plan" => %{"value" => "pro", "updated_at_ms" => 1_700_000_000_000},
                 "note" => %{"value" => "test"}
               }
             }

      {:ok, update_response_body()}
    end)

    assert {:ok, subscriber} =
             RevenueCat.update_customer_attributes("test_user", attrs)

    assert %RevenueCat.Subscriber{} = subscriber
    assert RevenueCat.has_entitlement?(subscriber, "pro_cat")
    assert RevenueCat.has_subscription?(subscriber, "annual")
  end

  test "update_customer_attributes falls back to fetch_subscriber on empty response" do
    attrs = %{"foo" => ""}

    expect(RevenueCat.ClientMock, :do_request, fn opts ->
      assert opts[:method] == :post
      assert String.ends_with?(opts[:url], "/v1/subscribers/test_user/attributes")
      assert opts[:json] == %{"attributes" => %{"foo" => %{"value" => ""}}}
      {:ok, "{}"}
    end)

    expect(RevenueCat.ClientMock, :do_request, fn opts ->
      assert opts[:method] == :get
      assert String.ends_with?(opts[:url], "/v1/subscribers/test_user")
      {:ok, production_body()}
    end)

    assert {:ok, %RevenueCat.Subscriber{}} =
             RevenueCat.update_customer_attributes("test_user", attrs)
  end

  test "get_subscriber caches by ttl and fetch_subscriber bypasses cache" do
    Application.put_env(:revenuecat, :subscriber_cache_ttl_seconds, 300)

    expect(RevenueCat.ClientMock, :do_request, fn opts ->
      assert opts[:method] == :get
      assert String.ends_with?(opts[:url], "/v1/subscribers/test_user")
      {:ok, production_body()}
    end)

    assert {:ok, subscriber} = RevenueCat.get_subscriber("test_user")
    assert {:ok, ^subscriber} = RevenueCat.get_subscriber("test_user")

    expect(RevenueCat.ClientMock, :do_request, fn opts ->
      assert opts[:method] == :get
      assert String.ends_with?(opts[:url], "/v1/subscribers/test_user")
      {:ok, production_body()}
    end)

    assert {:ok, _subscriber} = RevenueCat.fetch_subscriber("test_user")
  end

  defp production_body do
    """
    {
      "request_date": "2026-01-01T00:00:00Z",
      "request_date_ms": 1767225600000,
      "subscriber": {
        "entitlements": {
          "pro": {
            "expires_date": "2026-12-31T23:59:59Z",
            "grace_period_expires_date": null,
            "product_identifier": "example.product.web",
            "purchase_date": "2026-01-01T00:00:00Z"
          }
        },
        "first_seen": "2025-01-01T00:00:00Z",
        "last_seen": "2026-01-01T00:00:00Z",
        "management_url": "https://example.com/rc/portal",
        "non_subscriptions": {},
        "original_app_user_id": "test_user_id",
        "original_application_version": null,
        "original_purchase_date": null,
        "other_purchases": {},
        "subscriber_attributes": {
          "$email": {
            "updated_at_ms": 1735689600000,
            "value": "test@example.com"
          }
        },
        "subscriptions": {
          "example.product.web": {
            "auto_resume_date": null,
            "billing_issues_detected_at": null,
            "display_name": "Example Product (Web)",
            "expires_date": "2026-12-31T23:59:59Z",
            "grace_period_expires_date": null,
            "is_sandbox": false,
            "management_url": "https://example.com/rc/portal",
            "original_purchase_date": "2025-01-01T00:00:00Z",
            "period_type": "normal",
            "price": {
              "amount": 9.99,
              "currency": "USD"
            },
            "purchase_date": "2026-01-01T00:00:00Z",
            "refunded_at": null,
            "store": "rc_billing",
            "store_transaction_id": "test_transaction_id",
            "unsubscribe_detected_at": null
          }
        }
      }
    }
    """
  end

  defp update_response_body do
    """
    {
      "value": {
        "request_date": "2019-07-26T17:40:10Z",
        "request_date_ms": 1564162810884,
        "subscriber": {
          "entitlements": {
            "pro_cat": {
              "expires_date": null,
              "grace_period_expires_date": null,
              "product_identifier": "onetime",
              "purchase_date": "2019-04-05T21:52:45Z"
            }
          },
          "first_seen": "2019-02-21T00:08:41Z",
          "management_url": "https://apps.apple.com/account/subscriptions",
          "non_subscriptions": {
            "onetime": [
              {
                "id": "cadba0c81b",
                "is_sandbox": true,
                "purchase_date": "2019-04-05T21:52:45Z",
                "store": "app_store"
              }
            ]
          },
          "original_app_user_id": "XXX-XXXXX-XXXXX-XX",
          "original_application_version": "1.0",
          "original_purchase_date": "2019-01-30T23:54:10Z",
          "other_purchases": {},
          "subscriptions": {
            "annual": {
              "auto_resume_date": null,
              "billing_issues_detected_at": null,
              "expires_date": "2019-08-14T21:07:40Z",
              "grace_period_expires_date": null,
              "is_sandbox": true,
              "original_purchase_date": "2019-02-21T00:42:05Z",
              "ownership_type": "PURCHASED",
              "period_type": "normal",
              "purchase_date": "2019-07-14T20:07:40Z",
              "refunded_at": null,
              "store": "play_store",
              "store_transaction_id": "GPA.6801-7988-0152-76034..5",
              "unsubscribe_detected_at": "2019-07-17T22:48:38Z"
            },
            "onemonth": {
              "auto_resume_date": null,
              "billing_issues_detected_at": null,
              "expires_date": "2019-06-17T22:47:55Z",
              "grace_period_expires_date": null,
              "is_sandbox": true,
              "original_purchase_date": "2019-02-21T00:42:05Z",
              "ownership_type": "PURCHASED",
              "period_type": "normal",
              "purchase_date": "2019-06-17T22:42:55Z",
              "refunded_at": null,
              "store": "app_store",
              "store_transaction_id": 1000000652379790,
              "unsubscribe_detected_at": "2019-06-17T22:48:38Z"
            },
            "rc_promo_pro_cat_monthly": {
              "auto_resume_date": null,
              "billing_issues_detected_at": null,
              "expires_date": "2019-08-26T01:02:16Z",
              "grace_period_expires_date": null,
              "is_sandbox": false,
              "original_purchase_date": "2019-07-26T01:02:16Z",
              "ownership_type": "FAMILY_SHARED",
              "period_type": "normal",
              "purchase_date": "2019-07-26T01:02:16Z",
              "refunded_at": null,
              "store": "promotional",
              "store_transaction_id": "a42db3af39530cb82b17eaf9c6576393",
              "unsubscribe_detected_at": null
            }
          }
        }
      }
    }
    """
  end
end
