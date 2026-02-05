defmodule RevenueCat.Customer.Subscription.Price do
  @moduledoc false

  @type t :: %__MODULE__{
          amount: number() | nil,
          currency: String.t() | nil
        }

  defstruct [:amount, :currency]

  @doc """
  Build a price struct from a map.
  """
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      amount: map["amount"],
      currency: map["currency"]
    }
  end
end
