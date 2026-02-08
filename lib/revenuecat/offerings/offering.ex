defmodule RevenueCat.Offerings.Offering do
  @moduledoc false

  alias RevenueCat.Offerings.Package

  @type t :: %__MODULE__{
          description: String.t() | nil,
          identifier: String.t() | nil,
          packages: [Package.t()]
        }

  defstruct [
    :description,
    :identifier,
    packages: []
  ]

  @spec from_map(map()) :: t()
  def from_map(%{} = offering) do
    %__MODULE__{
      description: Map.get(offering, "description"),
      identifier: Map.get(offering, "identifier"),
      packages: Package.list_from(Map.get(offering, "packages", []))
    }
  end

  def from_map(_), do: %__MODULE__{}

  @spec list_from(list()) :: [t()]
  def list_from(offerings) when is_list(offerings) do
    Enum.flat_map(offerings, fn
      %{} = offering -> [from_map(offering)]
      _ -> []
    end)
  end

  def list_from(_), do: []
end
