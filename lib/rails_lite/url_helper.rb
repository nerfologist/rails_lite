require 'active_support/inflector'

module UrlHelper
  def method_missing(meth, obj=nil)
    tokens = /^((?<act>\w+)_)?(?<res>[\w_]+)_url$/.match(meth.to_s)
    act = tokens['act']
    res = tokens['res']
    
    id = obj ? (obj.is_a?(Integer) ? obj : obj.id) : nil
    res = res.pluralize if %w(new).include?(act) || id
    
    "http://#{@req.host}:#{@req.port}/#{res}#{id ? "/#{id}" : ""}"
  end
end