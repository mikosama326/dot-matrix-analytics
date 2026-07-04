require "test_helper"

class Api::EventsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get api_events_create_url
    assert_response :success
  end
end
