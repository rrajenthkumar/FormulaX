defmodule FormulaX.Utils do
  @moduledoc """
  Module for utility functions.
  """
  @spec get_filenames_of_images(String.t()) :: list(String.t()) | {:error, any()}
  def get_filenames_of_images(folder_name) do
    folder_path = "#{Application.app_dir(:formula_x)}/priv/static/images/#{folder_name}"

    case File.ls(folder_path) do
      {:ok, filenames_of_available_images} ->
        filenames_of_available_images

      error ->
        error
    end
  end
end
