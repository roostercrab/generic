defmodule GenericWeb.UsersConfirmationControllerTest do
  use GenericWeb.ConnCase, async: true

  alias Generic.Accounts
  alias Generic.Repo
  import Generic.AccountsFixtures

  setup do
    %{users: users_fixture()}
  end

  describe "GET /userss/confirm" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.users_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /userss/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, users: users} do
      conn =
        post(conn, Routes.users_confirmation_path(conn, :create), %{
          "users" => %{"email" => users.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your e-mail is in our system"
      assert Repo.get_by!(Accounts.UsersToken, users_id: users.id).context == "confirm"
    end

    test "does not send confirmation token if account is confirmed", %{conn: conn, users: users} do
      Repo.update!(Accounts.Users.confirm_changeset(users))

      conn =
        post(conn, Routes.users_confirmation_path(conn, :create), %{
          "users" => %{"email" => users.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your e-mail is in our system"
      refute Repo.get_by(Accounts.UsersToken, users_id: users.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.users_confirmation_path(conn, :create), %{
          "users" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your e-mail is in our system"
      assert Repo.all(Accounts.UsersToken) == []
    end
  end

  describe "GET /userss/confirm/:token" do
    test "confirms the given token once", %{conn: conn, users: users} do
      token =
        extract_users_token(fn url ->
          Accounts.deliver_users_confirmation_instructions(users, url)
        end)

      conn = get(conn, Routes.users_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Account confirmed successfully"
      assert Accounts.get_users!(users.id).confirmed_at
      refute get_session(conn, :users_token)
      assert Repo.all(Accounts.UsersToken) == []

      conn = get(conn, Routes.users_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Confirmation link is invalid or it has expired"
    end

    test "does not confirm email with invalid token", %{conn: conn, users: users} do
      conn = get(conn, Routes.users_confirmation_path(conn, :confirm, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Confirmation link is invalid or it has expired"
      refute Accounts.get_users!(users.id).confirmed_at
    end
  end
end
