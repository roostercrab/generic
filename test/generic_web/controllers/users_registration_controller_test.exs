defmodule GenericWeb.UsersRegistrationControllerTest do
  use GenericWeb.ConnCase, async: true

  import Generic.AccountsFixtures

  describe "GET /user/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.users_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "Login</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> login_users(users_fixture()) |> get(Routes.users_registration_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /user/register" do
    @tag :capture_log
    test "creates account and logs the users in", %{conn: conn} do
      email = unique_users_email()

      conn =
        post(conn, Routes.users_registration_path(conn, :create), %{
          "users" => %{"email" => email, "password" => valid_users_password()}
        })

      assert get_session(conn, :users_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ "Settings</a>"
      assert response =~ "Logout</a>"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.users_registration_path(conn, :create), %{
          "users" => %{"email" => "with spaces", "password" => "too short"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
    end
  end
end
