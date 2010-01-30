require 'net/http'
require 'cgi'
require 'uri'
require 'rexml/document'

# Contains classes useful for interacting with the various REST APIs utilized
# by the Tweetaly.tc engine. An 'adapter' is a class that contains various 
# helper methods that can be used to request information from a web service
# in a fashion that makes sense programmatically.
#
# Author:: Ryan Sandor Richards (mailto:sandor.richards@gmail.com)
module RESTAdapters
  
  # Base class for all adapters contains helper methods for programmatically
  # formulating service requests to REST APIs
  class RequestAdapter
    attr_accessor :baseurl

    def initialize(baseurl)
      @baseurl = baseurl
      @params = {}
    end

    def setParam(name, val)
      @params[name] = val.to_s
    end

    def setEncodedParam(name, val)
      @params[name] = CGI::escape(val.to_s)
    end

    def getParam(name)
      @params[name]
    end

    def getEncodedParam(name)
      CGI::unescape(@params[name])
    end

    def buildQuery
      query = @baseurl
      params = []
      @params.each do |k, v|
        params.push k + '=' + v
      end
      query + params.join("&")
    end

    def request
      response = Net::HTTP.get_response(URI.parse(self.buildQuery))
      response.value
      response.read_body
    end

    def requestXML
      REXML::Document.new(self.request)
    end

    def clearParams
      @params = {}
    end
  end

  # A request adatpter specifically designed for common requests to the Twitter API 
  # by the tweetaly.tc engine. 
  class Twitter < RequestAdapter
    def initialize
      super('')
    end

    def getElementsFromRequest(path)
      elements = []
      self.requestXML.elements.each(path) do |element|
        element_hash = {}
        element.elements.each do |property|
          element_hash[property.name] = property.text
        end
        elements << element_hash
      end
      elements
    end

    def getFollowers(id)
      self.baseurl = 'http://twitter.com/statuses/followers.xml?'
      self.clearParams
      self.setParam 'id', id
      self.getElementsFromRequest('users/user')
    end

    def getFriends(id)
      self.baseurl = 'http://twitter.com/statuses/friends.xml?'
      self.clearParams
      self.setParam 'id', id
      self.getElementsFromRequest('users/user')
    end

    def userTimeline(id, page=1)
      self.baseurl = 'http://twitter.com/statuses/user_timeline/' + id + '.xml?'
      self.clearParams
      self.setParam 'page', page
      self.getElementsFromRequest('statuses/status')
    end
  end

  # Adapter for handling common google charts requests by the tweetaly.tc engine.
  class GoogleChart < RequestAdapter
    MAX_PIXELS = 300000

    def initialize
      super('http://chart.apis.google.com/chart?')
    end

    def type(type)
      self.setParam 'cht', type
    end

    def size(size)
      self.setParam 'chs', size
    end

    def data(list)
      self.setParam 'chd', 't:' + list.join(',')
    end

    def dataScaling(list)
      self.setParam 'chds', list.join(',')
    end

    def legend(list)
      self.setParam 'chdl', list.map {|name| CGI::escape(name)}.join('|')
    end

    def pieChartLabels(list)
      self.setParam 'chl', list.map {|name| CGI::escape(name)}.join('|')
    end

    def axisLabels(axes, labels)  
      self.setParam 'chxt', axes.join(',')
      self.setParam 'chxl', labels.length.times.map { |i| i.to_s + ":|" + labels[i].map {|value| CGI::escape(value.to_s)}.join('|') }.join('|')
    end
  end

  # Simple adapter for handling automatic bit.ly URL shortening (mainly used for charts)
  class BitLy < RequestAdapter
    API_LOGIN = 'rsandor'
    API_KEY = 'R_42fc49aea4e1ca8d7b119c9a10fb48c3'
    API_BASE = 'http://api.bit.ly/'
    API_VERSION = '2.0.1'

    def service(name)
      @baseurl = BitLy::API_BASE + name + '?'
      self.setParam 'version', BitLy::API_VERSION
      self.setParam 'login', BitLy::API_LOGIN
      self.setParam 'apiKey', BitLy::API_KEY
      self.setParam 'format', 'xml'
      self.requestXML
    end

    def initialize
      super('')
    end

    def shorten(url)
      self.clearParams
      self.setEncodedParam 'longUrl', url
      doc = self.service('shorten')
      errorCode = doc.elements['bitly'].elements['errorCode'].text.to_i
      if errorCode != 0
        # TODO Handle errors appropriately! (Use Exceptions and annotate them based off the code)
        nil
      else
        doc.elements.each('bitly/results/nodeKeyVal/shortUrl') do |element|
          return element.text
        end
      end
    end
  end
  
end