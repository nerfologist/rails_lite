require 'json'
require 'webrick'
require 'pry-debugger'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @content = {}
    
    req.cookies.each do |cookie|
      if cookie.name == '_rails_lite_app'
        @content = JSON.parse(cookie.value)
        break
      end
    end
  end

  def [](key)
    @content[key]
  end

  def []=(key, val)
    @content[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.cookies << WEBrick::Cookie.new('_rails_lite_app', @content.to_json)
  end
end
