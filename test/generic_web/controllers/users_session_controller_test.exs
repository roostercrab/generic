defmodule GenericWeb.UsersSessionControllerTest do
  use GenericWeb.ConnCase, async: true

  import Generic.AccountsFixtures

  setup do
    %{users: users_fixture()}
  end

  describe "GET /user/login" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, Routes.users_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Login</h1>"
      assert response =~ "Login</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn, users: users} do
      conn = conn |> login_users(users) |> get(Routes.users_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /user/login" do
    test "logs the users in", %{conn: conn, users: users} do
      conn =
        post(conn, Routes.users_session_path(conn, :create), %{
          "users" => %{"email" => users.email, "password" => valid_users_password()}
        })

      assert get_session(conn, :users_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ users.email
      assert response =~ "Settings</a>"
      assert response =~ "Logout</a>"
    end

    test "logs the users in with remember me", %{conn: conn, users: users} do
      conn =
        post(conn, Routes.users_session_path(conn, :create), %{
          "users" => %{
            "email" => users.email,
            "password" => valid_users_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["users_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "emits error message with invalid credentials", %{conn: conn, users: users} do
      conn =
        post(conn, Routes.users_session_path(conn, :create), %{
          "users" => %{"email" => users.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Login</h1>"
      assert response =~ "Invalid e-mail or password"
    end
  end

  describe "DELETE /user/logout" do
    test "redirects if not logged in", %{conn: conn} do
      conn = delete(conn, Routes.users_session_path(conn, :delete))
      assert redirected_to(conn) == "/user/login"
    end

    test "logs the users out", %{conn: conn, users: users} do
      conn = conn |> login_users(users) |> delete(Routes.users_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :users_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
