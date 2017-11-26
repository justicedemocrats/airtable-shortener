defmodule Shorten.AirtableCache do
  use Agent
  @key Application.get_env(:shorten, :airtable_key)
  @base Application.get_env(:shorten, :airtable_base)
  @table Application.get_env(:shorten, :airtable_table_name)

  def start_link do
    Agent.start_link(
      fn ->
        fetch_all() |> Enum.map(&regexify/1)
      end,
      name: __MODULE__
    )
  end

  def update do
    Agent.update(__MODULE__, fn _current ->
      fetch_all() |> Enum.map(&regexify/1)
    end)
  end

  def get_all do
    Agent.get(__MODULE__, & &1)
  end

  defp fetch_all() do
    %{body: body} = HTTPotion.get("https://api.airtable.com/v0/#{@base}/#{@table}")
    decoded = Poison.decode!(body)

    records =
      Enum.map(decoded["records"], fn %{"fields" => %{"Pattern" => from, "Destination" => to}} ->
        {from, to}
      end)

    if Map.has_key?(decoded, "offset") do
      fetch_all(records, decoded["offset"])
    else
      records
    end
  end

  defp fetch_all(records, offset) do
    HTTPotion.get("https://api.airtable.com/v0/#{@base}/#{@table}")

    decoded = Poison.decode!(body)

    new_records =
      Enum.map(decoded["records"], fn %{"fields" => %{"Pattern" => from, "Destination" => to}} ->
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
