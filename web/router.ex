defmodule Shorten.Router do
  use Shorten.Web, :router

  scope "/", Shorten do
    get("/*path", GetController, :get)
  end
end
