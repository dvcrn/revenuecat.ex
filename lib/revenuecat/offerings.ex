defmodule RevenueCat.Offerings do
  @moduledoc """
  Parsed offerings response from RevenueCat.
  """

  alias RevenueCat.Offerings.Offering

  @type t :: %__MODULE__{
          current_offering_id: String.t() | nil,
          offerings: [Offering.t()]
        }

  defstruct [
    :current_offering_id,
    offerings: []
  ]

  @doc """
  Build an offerings struct from a RevenueCat response map.

  RevenueCat responses are sometimes wrapped in a top-level `"value"` key.
  This function supports both shapes.
  """
  @spec from_response(map()) :: {:ok, t()} | {:error, term()}
  def from_response(%{"value" => value}) when is_map(value), do: from_response(value)

  def from_response(%{"offerings" => offerings} = response) when is_list(offerings) do
    {:ok,
     %__MODULE__{
       current_offering_id: Map.get(response, "current_offering_id"),
       offerings: Offering.list_from(offerings)
     }}
  end

  def from_response(_), do: {:error, :invalid_response}
end
