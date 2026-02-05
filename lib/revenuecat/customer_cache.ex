defmodule RevenueCat.CustomerCache do
  @moduledoc false

  use Agent

  @type cache_entry :: {RevenueCat.Customer.t(), integer()}

  def get(app_user_id) when is_binary(app_user_id) and app_user_id != "" do
    if ttl_seconds() <= 0 do
      :miss
    else
      ensure_started()
      now = now_seconds()

      Agent.get_and_update(__MODULE__, fn state ->
        case Map.get(state, app_user_id) do
          {customer, expires_at} = entry when expires_at > now ->
            {{:ok, customer}, Map.put(state, app_user_id, entry)}

          _ ->
            {:miss, Map.delete(state, app_user_id)}
        end
      end)
    end
  end

  def get(_), do: :miss

  def put(app_user_id, %RevenueCat.Customer{} = customer, ttl_seconds)
      when is_binary(app_user_id) and app_user_id != "" and is_integer(ttl_seconds) and
             ttl_seconds > 0 do
    ensure_started()
    expires_at = now_seconds() + ttl_seconds
    entry = {customer, expires_at}
    Agent.update(__MODULE__, &Map.put(&1, app_user_id, entry))
    :ok
  end

  def put(_, _, _), do: :ok

  def clear do
    ensure_started()
    Agent.update(__MODULE__, fn _ -> %{} end)
    :ok
  end

  defp ensure_started do
    case Agent.start_link(fn -> %{} end, name: __MODULE__) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, _} -> :ok
    end
  end

  defp ttl_seconds do
    Application.get_env(:revenuecat, :customer_cache_ttl_seconds, 120)
  end

  defp now_seconds do
    System.monotonic_time(:second)
  end
end
