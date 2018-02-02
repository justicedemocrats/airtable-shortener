defmodule Shorten.AirtableCache do
  use AirtableConfig

  def key, do: Application.get_env(:shorten, :airtable_key)
  def base, do: Application.get_env(:shorten, :airtable_base)
  def table, do: Application.get_env(:shorten, :airtable_table_name)
  def view, do: "Grid view"

  def into_what, do: []

  def filter_record(%{"fields" => fields}) do
    Map.has_key?(fields, "Destination")
  end

  def process_record(%{"fields" => fields}) do
    {:ok, pattern} = fields["Pattern"] |> String.downcase() |> Regex.compile()
    {pattern, fields["Destination"]}
  end
end
