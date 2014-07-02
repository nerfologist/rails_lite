require 'json'
require 'webrick'
require 'pry-debugger'

class Flash
  def initialize(req)
    @present_content = FlashContent.new
    @future_content = FlashContent.new
    
    req.cookies.each do |cookie|
      if cookie.name == '_rails_lite_app_flash'
        @present_content.merge!(JSON.parse(cookie.value))
        break
      end
    end
  end
  
  def now
    @present_content
  end

  def [](key)
    @present_content[key]
  end

  def []=(key, val)
    @future_content[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_flash(res)
    unless @future_content.empty?
      res.cookies << WEBrick::Cookie.new('_rails_lite_app_flash',
                                         @future_content.to_json)
    end
  end
end

class FlashContent
  def initialize(data = {})
    @content = data
  end
  
  def merge(hash)
    @content.merge!(hash)
  end
  
  def [](key)
    @content[key]
  end
  
  def []=(key, value)
    @content[key] = value
  end
  
  def empty?
    @content.empty?
  end
end