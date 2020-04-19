defmodule GenericWeb.UsersConfirmationController do
  use GenericWeb, :controller

  alias Generic.Accounts

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"users" => %{"email" => email}}) do
    if users = Accounts.get_users_by_email(email) do
      Accounts.deliver_users_confirmation_instructions(
        users,
        &Routes.users_confirmation_url(conn, :confirm, &1)
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      "If your e-mail is in our system and it has not been confirmed yet, " <>
        "you will receive an e-mail with instructions shortly."
    )
    |> redirect(to: "/")
  end

  # Do not login the users after confirmation to avoid a
  # leaked token giving the users access to the account.
  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_users(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Account confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        conn
        |> put_flash(:error, "Confirmation link is invalid or it has expired.")
        |> redirect(to: "/")
    end
  end
end
