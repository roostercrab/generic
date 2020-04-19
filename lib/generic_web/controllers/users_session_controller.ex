defmodule GenericWeb.UsersSessionController do
  use GenericWeb, :controller

  alias Generic.Accounts
  alias GenericWeb.UsersAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"users" => users_params}) do
    %{"email" => email, "password" => password} = users_params

    if users = Accounts.get_users_by_email_and_password(email, password) do
      UsersAuth.login_users(conn, users, users_params)
    else
      render(conn, "new.html", error_message: "Invalid e-mail or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UsersAuth.logout_users()
  end
end
