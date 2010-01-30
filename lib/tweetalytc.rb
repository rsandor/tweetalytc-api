require 'rest_adapters'
require 'date'
require 'eregex'

# The core querying and reporting modules for tweetaly.tc
# Author:: Ryan Sandor Richards (mailto:sandor.richards@gmail.com)
module Tweetalytc
  class UserResultSet < Array
    attr_reader :metric

    def initialize(users, metric)
      super(users) # tee hee hee...
      @metric = metric
    end
  end

  class DataSet < Array
    attr_reader :labels
    def initialize(data, labels=nil)
      super(data)
      @labels = labels
    end
  end

  class Engine
    VALID_METRICS = ['followers', 'friends', 'statuses']
    VALID_CATEGORIES = ['top', 'bottom']
    VALID_ORDERS = ['asc', 'desc']
    
    def initialize
      @twitter = RESTAdapters::Twitter.new
    end

    def getSortedUserResult(users, metric, limit, order, category)
      # Ensure the metric is valid
      if !Engine::VALID_METRICS.include? metric
        raise Exception.new('Invalid metric: ' + metric)
      else
        metric += '_count'
      end

      # Sort by metric
      users = users.sort_by { |user| user[metric].to_i }

      # Determine the query category
      if !Engine::VALID_CATEGORIES.include? category 
        raise Exception.new('Invalid category: ' + category)
      elsif category == 'top'
        users.reverse!
      end

      # Cut the set down by the limit
      users = users.slice(0, limit)

      # Apply the ordering
      if !Engine::VALID_ORDERS.include? order
        raise Exception.new('Invalid category: ' + category)
      elsif (order == 'acs' and category == 'top') or (order == 'desc' and category == 'bottom')
        users.reverse!
      end

      # Return the result set
      UserResultSet.new(users, metric)
    end

    # Followers and Friends queries
    def getFollowers(id, metric, limit, order, category)
      self.getSortedUserResult(@twitter.getFollowers(id), metric, limit, order, category)
    end

    def getFriends(id, metric, limit, order, category)
      self.getSortedUserResult(@twitter.getFriends(id), metric, limit, order, category)
    end

    # Tweet/Timeline queries
    def dailyTweetCounts(id, days=7)
      day = 0 
      counts = [0] * days
      last = Date.today - 1
      page = 1
      done = false

      while !done do
        @twitter.userTimeline(id, page).each do |status|
          current = Date.parse( status['created_at'] )
          day += last - current
          last = current
          if day >= counts.length
            done = true
            break
          end
          counts[day] += 1;
        end
        page += 1
      end

      labels = []
      days.times do |i|
        labels << (Date.today - i - 1).to_s.split('-').slice(1,2).join('/')
      end

      DataSet.new(counts.reverse, labels.reverse)
    end
  end

  # Charting and reporting engine
  class Reports
    GOOGLE_CHART_MAP = {
      'bar' => 'bvg',
      'pie' => 'p',
      'pie3d' => 'p3'
    }
    VALID_CHARTS = ['bar', 'pie', 'pie3d']
    
    def initialize
      @chart = RESTAdapters::GoogleChart.new
      @bitly = RESTAdapters::BitLy.new
    end
    
    def barChart(dataSet, size="300x200")
      @chart.type 'bvg'
      @chart.size size
      @chart.data dataSet
      @chart.dataScaling [0, dataSet.max]
      unless dataSet.labels == nil
        @chart.axisLabels ['x', 'y'], [dataSet.labels, [0, dataSet.max / 2, dataSet.max]]
      end
      @bitly.shorten @chart.buildQuery
    end

    def userChart(resultSet, type='bar', size="300x300")
      # Ensure valid chart type
      if !Engine::VALID_CHARTS.include?(type)
        # TODO Need something better... Exceptions?
        return nil
      end

      # Make sure the size is valid for google charts
      # TODO Use exceptions! 
      # TODO Split into two types of exceptions (formatting & invalid size)
      dims = size.split('x').map { |c| c.to_i }
      if dims.length != 2 or dims[0] * dims[1] > RESTAdapters::GoogleChart::MAX_PIXELS
        return nil
      end

      # Calculate max for chart size and ratios of total for each user for labels
      max = 0
      total = 0
      resultSet.each do |user| 
        count = user[resultSet.metric].to_i
        max = [max, count].max 
        total += count
      end

      # Construct the chart
      @chart.type Engine::GOOGLE_CHART_MAP[type]
      @chart.size size
      @chart.data resultSet.map { |user| user[resultSet.metric] }
      @chart.dataScaling [0, max]
      @chart.legend resultSet.map { |user| user['screen_name'] + ' (' + user[resultSet.metric] + ')'}

      # Build, shorten, and return the chart url
      @bitly.shorten @chart.buildQuery
    end
  end
end