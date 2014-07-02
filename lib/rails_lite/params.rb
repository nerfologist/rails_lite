require 'uri'
require 'pry-debugger'

class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  def initialize(req, route_params = {})
    @permitted_keys = []
    @params = route_params
    @params.merge!(parse_www_encoded_form(req.query_string))
    @params.merge!(parse_www_encoded_form(req.body))
  end
  
  def auth_token
    @params['authenticity_token']
  end
  
  def delete(key)
    @params.delete(key)
  end

  def [](key)
    @params[key]
  end

  def permit(*keys)
    @permitted_keys += keys
    @params.delete_if { |key, value| ! keys.include?(key) }
    self
  end

  def require(key)
    raise AttributeNotFoundError.new if ! @params.has_key?(key)
    self
  end

  def permitted?(key)
    @permitted_keys.include?(key)
  end

  def to_s
    @params.to_s
  end

  class AttributeNotFoundError < ArgumentError; end;

  private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    result = {}
    return result if www_encoded_form.nil?
    
    items = URI.decode_www_form(www_encoded_form)

    items.each do |name, value|
      keys = parse_key(name)

      current_hash = result
      keys.each do |key|
        if key == keys.last
          current_hash[key] = value
          break
        end

        current_hash[key] ||= {}
        current_hash = current_hash[key]
      end
    end
    
    result
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.scan(/\[?(\w+)\]?/).map(&:first)
  end
end
