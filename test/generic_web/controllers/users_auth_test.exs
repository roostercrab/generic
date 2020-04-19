defmodule GenericWeb.UsersAuthTest do
  use GenericWeb.ConnCase, async: true

  alias Generic.Accounts
  alias GenericWeb.UsersAuth
  import Generic.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, GenericWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{users: users_fixture(), conn: conn}
  end

  describe "login_users/3" do
    test "stores the users token in the session", %{conn: conn, users: users} do
      conn = UsersAuth.login_users(conn, users)
      assert token = get_session(conn, :users_token)
      assert redirected_to(conn) == "/"
      assert Accounts.get_users_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, users: users} do
      conn = conn |> put_session(:to_be_removed, "value") |> UsersAuth.login_users(users)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, users: users} do
      conn = conn |> put_session(:users_return_to, "/hello") |> UsersAuth.login_users(users)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, users: users} do
      conn = conn |> fetch_cookies() |> UsersAuth.login_users(users, %{"remember_me" => "true"})
      assert get_session(conn, :users_token) == conn.cookies["users_remember_me"]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies["users_remember_me"]
      assert signed_token != get_session(conn, :users_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_users/1" do
    test "erases session and cookies", %{conn: conn, users: users} do
      users_token = Accounts.generate_session_token(users)

      conn =
        conn
        |> put_session(:users_token, users_token)
        |> put_req_cookie("users_remember_me", users_token)
        |> fetch_cookies()
        |> UsersAuth.logout_users()

      refute get_session(conn, :users_token)
      refute conn.cookies["users_remember_me"]
      assert %{max_age: 0} = conn.resp_cookies["users_remember_me"]
      assert redirected_to(conn) == "/"
      refute Accounts.get_users_by_session_token(users_token)
    end

    test "works even if users is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> UsersAuth.logout_users()
      refute get_session(conn, :users_token)
      assert %{max_age: 0} = conn.resp_cookies["users_remember_me"]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_users/2" do
    test "authenticates users from session", %{conn: conn, users: users} do
      users_token = Accounts.generate_session_token(users)
      conn = conn |> put_session(:users_token, users_token) |> UsersAuth.fetch_current_users([])
      assert conn.assigns.current_users.id == users.id
    end

    test "authenticates users from cookies", %{conn: conn, users: users} do
      logged_in_conn =
        conn |> fetch_cookies() |> UsersAuth.login_users(users, %{"remember_me" => "true"})

      users_token = logged_in_conn.cookies["users_remember_me"]
      %{value: signed_token} = logged_in_conn.resp_cookies["users_remember_me"]

      conn =
        conn
        |> put_req_cookie("users_remember_me", signed_token)
        |> UsersAuth.fetch_current_users([])

      assert get_session(conn, :users_token) == users_token
      assert conn.assigns.current_users.id == users.id
    end

    test "does not authenticate if data is missing", %{conn: conn, users: users} do
      _ = Accounts.generate_session_token(users)
      conn = UsersAuth.fetch_current_users(conn, [])
      refute get_session(conn, :users_token)
      refute conn.assigns.current_users
    end
  end

  describe "redirect_if_users_is_authenticated/2" do
    test "redirects if users is authenticated", %{conn: conn, users: users} do
      conn = conn |> assign(:current_users, users) |> UsersAuth.redirect_if_users_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if users is not authenticated", %{conn: conn} do
      conn = UsersAuth.redirect_if_users_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_users/2" do
    test "redirects if users is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> UsersAuth.require_authenticated_users([])
      assert conn.halted
      assert redirected_to(conn) == "/user/login"
      assert get_flash(conn, :error) == "You must login to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | request_path: "/foo?bar"}
        |> fetch_flash()
        |> UsersAuth.require_authenticated_users([])

      assert halted_conn.halted
      assert get_session(halted_conn, :users_return_to) == "/foo?bar"

      halted_conn =
        %{conn | request_path: "/foo?bar", method: "POST"}
        |> fetch_flash()
        |> UsersAuth.require_authenticated_users([])

      assert halted_conn.halted
      refute get_session(halted_conn, :users_return_to)
    end

    test "does not redirect if users is authenticated", %{conn: conn, users: users} do
      conn = conn |> assign(:current_users, users) |> UsersAuth.require_authenticated_users([])
      refute conn.halted
      refute conn.status
    end
  end
end
