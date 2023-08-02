defmodule FormulaX.Utils do
  @moduledoc """
  Module for utility functions
  """
  @spec get_image_paths(String.t()) :: list(String.t()) | Error.t()
  def get_image_paths(folder_path) do
    case(File.read(folder_path)) do
      {:ok, available_images} ->
        available_images

      {:error, error} ->
        raise error
    end
  end
end
