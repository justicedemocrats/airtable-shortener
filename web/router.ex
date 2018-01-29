defmodule Shorten.Router do
  use Shorten.Web, :router

  scope "/", Shorten do
    get("/*path", GetController, :get)
  end

  scope "/admin", Shorten do
    get("/", GetController, :admin)
    get("/update", GetController, :update)
  end
end
