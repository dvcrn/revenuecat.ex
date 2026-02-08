defmodule RevenueCat.Offerings.Package do
  @moduledoc false

  @type t :: %__MODULE__{
          identifier: String.t() | nil,
          platform_product_identifier: String.t() | nil
        }

  defstruct [
    :identifier,
    :platform_product_identifier
  ]

  @spec from_map(map()) :: t()
  def from_map(%{} = package) do
    %__MODULE__{
      identifier: Map.get(package, "identifier"),
      platform_product_identifier: Map.get(package, "platform_product_identifier")
    }
  end

  def from_map(_), do: %__MODULE__{}

  @spec list_from(list()) :: [t()]
  def list_from(packages) when is_list(packages) do
    Enum.flat_map(packages, fn
      %{} = pkg -> [from_map(pkg)]
      _ -> []
    end)
  end

  def list_from(_), do: []
end
