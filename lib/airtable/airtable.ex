defmodule Shorten.AirtableCache do
  use Agent

  def key, do: Application.get_env(:shorten, :airtable_key)
  def base, do: Application.get_env(:shorten, :airtable_base)
  def table, do: Application.get_env(:shorten, :airtable_table_name)
  @view "Grid view"

  def start_link do
    Agent.start_link(
      fn ->
        fetch_all() |> Enum.map(&regexify/1)
      end,
      name: __MODULE__
    )
  end

  def update() do
    Agent.update(__MODULE__, fn _current ->
      fetch_all() |> Enum.map(&regexify/1)
    end, 20_000)

    IO.puts("Updated at #{inspect(DateTime.utc_now())}")
  end

  def get_all do
    Agent.get(__MODULE__, & &1)
  end

  defp fetch_all() do
    %{body: body} =
      HTTPotion.get(
        "https://api.airtable.com/v0/#{base()}/#{table()}",
        headers: [
          Authorization: "Bearer #{key()}"
        ],
        query: %{view: @view},
        timeout: :infinity
      )

    decoded = Poison.decode!(body)

    records =
      decoded["records"]
      |> Enum.filter(fn %{"fields" => fields} -> Map.has_key?(fields, "Destination") end)
      |> Enum.map(fn %{"fields" => %{"Pattern" => from, "Destination" => to}} ->
           {from, to}
         end)

    if Map.has_key?(decoded, "offset") do
      fetch_all(records, decoded["offset"])
    else
      records
    end
  end

  defp fetch_all(records, offset) do
    %{body: body} =
      HTTPotion.get(
        "https://api.airtable.com/v0/#{base()}/#{table()}",
        headers: [
          Authorization: "Bearer #{key()}"
        ],
        query: [offset: offset, view: @view],
        timeout: :infinity
      )

    decoded = Poison.decode!(body)

    new_records =
      decoded["records"]
      |> Enum.filter(fn %{"fields" => fields} -> Map.has_key?(fields, "Destination") end)
      |> Enum.map(fn %{"fields" => %{"Pattern" => from, "Destination" => to}} ->
           {from, to}
         end)

    all_records = Enum.concat(records, new_records)

    if Map.has_key?(decoded, "offset") do
      fetch_all(all_records, decoded["offset"])
    else
      all_records
    end
  end

  defp regexify({from, to}) do
    {:ok, as_regex} = from |> String.downcase() |> Regex.compile()
    {as_regex, to}
  end
end
