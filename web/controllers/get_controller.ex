defmodule Shorten.GetController do
  use Shorten.Web, :controller
  def secret, do: Application.get_env(:shorten, :secret)

  def get(conn = %{request_path: path}, _params) do
    path = String.downcase(path)
    routes = Shorten.AirtableCache.get_all()

    tuple_or_nil =
      routes
      |> Enum.filter(&matches(&1, path))
      |> List.first()

    destination =
      case tuple_or_nil do
        nil -> "https://justicedemocrats.com"
        {_, destination} -> destination
      end

    redirect(conn, external: destination)
  end

  defp matches({regex, destination}, path) do
    Regex.run(regex, path) != nil
  end

  def admin(conn, %{"secret" => input_secret}) do
    if input_secret == secret() do
      resp =
        Shorten.AirtableCache.get_all()
        |> Enum.map(routes, fn {regex, destination} ->
          "\t\t\t#{regex} -> #{destination}"
        end)
        |> Enum.join("\n")

      text conn, ~s(
        hello shortlink user! here are the current routes.

        to force an update, visit jdems.us/admin/update?secret=#{secret}.

        #{resp}
      )
    else
      text conn, ~s(
        wrong secret – contact ben.
      )
    end
  end

  def admin(conn, _) do
    text conn, ~s(
      missing secret – proper usage is jdems.us/admin?secret=secretfromben
    )
  end

  def force_update(conn, %{"secret" => input_secret}) do
    if input_secret == secret() do
      Shorten.AirtableCache.update()

      text conn, ~s(
        hello shortlink user! we just updated. to verify that your update
        has completed or to further diagnose issues, visit

        -> jdems.us/admin?secret=#{secret}.
      )
    else
      text conn, ~s(
        wrong secret – contact ben.
      )
    end
  end

  def force_update(conn, _) do
    text conn, ~s(
      missing secret – proper usage is jdems.us/admin/update?secret=secretfromben
    )
  end
end
