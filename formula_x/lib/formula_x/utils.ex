defmodule FormulaX.Utils do
  @moduledoc """
  Module for utility functions
  """
  @spec get_images(String.t()) :: list(String.t()) | Error.t()
  def get_images(folder_name) do
    folder_path = "#{Application.app_dir(:formula_x)}/priv/static/images/#{folder_name}"

    case File.ls(folder_path) do
      {:ok, available_images} ->
        available_images

      {:error, error} ->
        raise error
    end
  end
end
