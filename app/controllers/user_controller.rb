require 'tweetalytc'
require 'eregex'

# User services controller. Handles the following sub-services:
#   followers, friends, and reports
# Author:: Ryan Sandor Richards (mailto: sandor.richards@gmail.com)
class UserController < ApplicationController
  verify :params => [:id], 
    :only => :followers, 
    :redirect_to => '/500.html'
  
  def followers
    screen_name_regex = Regexp.new('^[a-zA-Z\d]+$')
    number_regex = Regexp.new('^\d+$');
    engine = TweetalytcEngine::Engine.new
      
    begin
      unless screen_name_regex.match(params[:id])
        raise Exception.new("Invalid screen name")
      end
      
      if !params[:cat]
        params[:cat] = 'top'
      elsif !['top', 'bottom'].include? params[:cat]
        raise Exception.new("Invalid category")
      end
      
      if !params[:metric]
        params[:metric] = 'statuses'
      elsif !TweetalytcEngine::Engine::VALID_METRICS.include? params[:metric]
        raise Exception.new("Invalid metric")
      end
      
      if !params[:order]
        params[:order] = 'asc'
      elsif !['asc', 'desc'].include? params[:order]
        raise Exception.new("Invalid ordering")
      end
      
      if !params[:max]
        params[:max] = '10'
      elsif !number_regex.match(params[:max])
        raise Exception.new("Maximum must be a positive integer")
      elsif params[:max].to_i < 1 or params[:max].to_i > 100
        raise Exception.new("Maximum must be between 1 and 100 inclusive")
      end
        
      @users = engine.getFollowers params[:id], 
        params[:metric],
        params[:max].to_i,
        params[:order],
        params[:cat]
        
    rescue Exception
      # TODO Handle the exceptions more elegantly
      redirect_to('/500.html')
    end
  end
  
  
end
