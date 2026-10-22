require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.destroy_all
    @user = User.create!(name: "Tester One", email: "one@example.com", password: "secret123")
    @second = User.create!(name: "Tester Two", email: "two@example.com", password: "secret123")
  end

  test "index lists registered users" do
    get "/users/index"

    assert_response :success
    assert_match @user.email, response.body
    assert_match @second.email, response.body
  end

  test "create persists a user and redirects to show" do
    assert_difference "User.count", 1 do
      post "/users/create", params: { user: { name: "New Guy", email: "new@example.com", password: "secret123" } }
    end

    assert_redirected_to user_path(User.find_by!(email: "new@example.com"))
  end

  test "create with duplicate email re-renders the form" do
    assert_no_difference "User.count" do
      post "/users/create", params: { user: { name: "Dup", email: @user.email } }
    end

    assert_response :success
    assert_match "taken", response.body
  end

  test "create without email is rejected" do
    assert_no_difference "User.count" do
      post "/users/create", params: { user: { name: "No Email" } }
    end

    assert_response :success
    assert_match "be blank", response.body
  end

  test "destroy removes a user and redirects to index" do
    assert_difference "User.count", -1 do
      delete "/users/#{@user.id}"
    end

    assert_redirected_to users_path
  end

  test "destroy unknown user responds not found" do
    delete "/users/999999"

    assert_response :not_found
  end
end
