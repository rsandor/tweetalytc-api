require 'test_helper'
require 'cgi'

# Unit tests for the user controller.
#
# Note: Thinking of refactoring this test class to make it more elegant
#   but something about the each test is explicit has got me feeling
#   all warm and fuzzy inside...
#
# Author:: Ryan Sandor Richards (mailto: Ryan Sandor Richards)
class UserControllerTest < ActionController::TestCase   
  test "followers and friends should fail without an id" do
    get :followers, {:format => 'xml'}
    assert_redirected_to '/500.html'
    get :friends, {:format => 'xml'}
    assert_redirected_to '/500.html'
  end
  
  test "followers and friends should fail with an invalid id" do
    get :followers, {:id => CGI::escape('#$%^&*'), :format => 'xml'}
    assert_redirected_to '/500.html'
    get :friends, {:id => CGI::escape('#$%^&*'), :format => 'xml'}
    assert_redirected_to '/500.html'
  end
  
  test "followers should fail with an id that doesn't exist" do
    # Watch someone go and register *that* name ;)
    get :followers, {:id => 'nOtAsCrEeNnAmEoMg', :format => 'xml'}
    assert_redirected_to '/500.html'
    get :friends, {:id => 'nOtAsCrEeNnAmEoMg', :format => 'xml'}
    assert_redirected_to '/500.html'
  end
  
  test "followers and friends should succeed with a valid id parameter" do
    get :followers, {:id => 'rsandor', :format => 'xml'}
    assert_response :success
    get :friends, {:id => 'rsandor', :format => 'xml'}
    assert_response :success
  end
  
  test "followers and friends should fail with invalid cat parameter" do
    get :followers, {:id => 'rsandor', :cat => 'notarealcategory', :format => 'xml'}
    assert_redirected_to '/500.html'
    get :friends, {:id => 'rsandor', :cat => 'notarealcategory', :format => 'xml'}
    assert_redirected_to '/500.html'
  end
  
  test "followers and friends should succeed with cat set as 'top'" do
    get :followers, {:id => 'rsandor', :cat => 'top', :format => 'xml'}
    assert_response :success
    get :friends, {:id => 'rsandor', :cat => 'top', :format => 'xml'}
    assert_response :success
  end
  
  test "followers and friends should succeed with cat set as 'bottom'" do
    get :followers, {:id => 'rsandor', :cat => 'bottom', :format => 'xml'}
    assert_response :success
    get :friends, {:id => 'rsandor', :cat => 'bottom', :format => 'xml'}
    assert_response :success
  end
  
  test "followers and friends should fail with invalid metric parameter" do
    get :followers, {:id => 'rsandor', :metric => 'supertweetsthatdonotexist', :format => 'xml'}
    assert_redirected_to '/500.html'
    get :friends, {:id => 'rsandor', :metric => 'supertweetsthatdonotexist', :format => 'xml'}
    assert_redirected_to '/500.html'
  end
  
  test "followers and friends should succeed with metric set as 'followers'" do
    get :followers, {:id => 'rsandor', :metric => 'followers', :format => 'xml'}
    assert_response :success
    get :friends, {:id => 'rsandor', :metric => 'followers', :format => 'xml'}
    assert_response :success
  end
  
  test "followers and friends should succeed with metric set as 'friends'" do
    get :followers, {:id => 'rsandor', :metric => 'friends', :format => 'xml'}
    assert_response :success
    get :friends, {:id => 'rsandor', :metric => 'friends', :format => 'xml'}
    assert_response :success
  end
  
  test "followers and friends should succeed with metric set as 'statuses'" do
    get :followers, {:id => 'rsandor',:metric => 'statuses', :format => 'xml'}
    assert_response :success
    get :friends, {:id => 'rsandor',:metric => 'statuses', :format => 'xml'}
    assert_response :success
  end
  
  test "followers and friends should fail with non-numeric limit parameter" do
    get :followers, {:id => 'rsandor',:limit => 'five', :format => 'xml'}
    assert_redirected_to '/500.html'
    get :friends, {:id => 'rsandor',:limit => 'five', :format => 'xml'}
    assert_redirected_to '/500.html'
  end
  
  test "followers and friends should fail with limit parameter less than 1" do
    get :followers, {:id => 'rsandor',:limit => '-42', :format => 'xml'}
    assert_redirected_to '/500.html'
    get :friends, {:id => 'rsandor',:limit => '-42', :format => 'xml'}
    assert_redirected_to '/500.html'
  end
  
  test "followers and friends should fail with limit parameter greater than 100" do
    get :followers, {:id => 'rsandor',:limit => '142', :format => 'xml'}
    assert_redirected_to '/500.html'
    get :friends, {:id => 'rsandor',:limit => '142', :format => 'xml'}
    assert_redirected_to '/500.html'
  end
  
  test "followers and friends should succeed with limit parameter between 1 and 100" do
    get :followers, {:id => 'rsandor',:limit => '5', :format => 'xml'}
    assert_response :success
    get :friends, {:id => 'rsandor',:limit => '5', :format => 'xml'}
    assert_response :success
  end
  
  test "Given a valid request a users array should be set in the controller" do
    get :followers, {:id => 'rsandor', :format => 'xml'}
    assert assigns(:users)
    get :friends, {:id => 'rsandor', :format => 'xml'}
    assert assigns(:users)
  end
  
  test "Given a valid request a query information array should be set in the controller" do
    get :followers, {:id => 'rsandor', :format => 'xml'}
    assert assigns(:query)
    get :friends, {:id => 'rsandor', :format => 'xml'}
    assert assigns(:query)
  end
end
