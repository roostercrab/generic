defmodule GenericWeb.PageController do
  use GenericWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
