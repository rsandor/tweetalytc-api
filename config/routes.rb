ActionController::Routing::Routes.draw do |map|
  # Query Services
  map.connect ':controller/:action', :format => 'xml'
  map.connect ':controller/:action.:format'
  
  # Chart Services
  #map.connect '/chart/user/:action', :controller => 'user_chart'
  #map.connect '/chart/user/:action.:format', :controller => 'user_chart'
  
  # Feed and Reporting Services
  #map.connect '/report/:action', :format => 'rss'
end
