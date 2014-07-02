require 'erb'
require 'active_support/inflector'
require 'securerandom'
require 'yaml'
require 'nokogiri'
require 'pry-debugger'
require_relative 'params'
require_relative 'session'
require_relative 'flash'

class ControllerBase
  attr_reader :params, :req, :res

  # require CSRF tokens for following request methods
  CSRF_METHODS = ['POST', 'PUT', 'PATCH', 'DELETE']

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @already_built_response = false
    @params = Params.new(req, route_params)
    
    # CSRF token verification
    begin
      @issued_tokens = YAML.load_file('issued_auth_tokens.yml')
    rescue SystemCallError # basically, 'file not found'
      @issued_tokens = []
    end
    
    check_csrf # cross-site request forgery
  end
  
  def check_csrf
    # only check 'dangerous' methods (i.e. allow 'GET')
    return unless CSRF_METHODS.include?(@req.request_method)
    
    client_token = @params.auth_token || (raise CsrfAuthenticityError.new(
                                          'form authenticity token not found'))
    
    matching_server_token = @issued_tokens.find do
      |h| h[:hash] == client_token
    end
    
    unless matching_server_token
      raise CsrfAuthenticityError.new
    end
      
    # consume server-side token; clean up client params
    @issued_tokens.delete(matching_server_token)
    @params.delete('authenticity_token')
  end

  # helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(content, type)
    raise StandardError.new('Already built response') if @already_built_response
    
    @res.content_type = type
    @res.body = inject_csrf_fields(content)
    @already_built_response = true
    do_chores
  end

  # set the response status code and header
  def redirect_to(url)
    raise StandardError.new('Already built response') if @already_built_response
    
    do_chores
    @res.status = 302 #Found
    @res['Location'] = "#{url}"
    @already_built_response = true
  end
  
  def do_chores
    serialize_auth_tokens # CSRF tokens issued are stored server-side
    session.store_session(@res)
    flash.store_flash(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    t_path = "views/#{self.class.to_s.underscore}/#{template_name}.html.erb"
    t_content = File.read(t_path)
    
    erb = ERB.new(t_content)
    render_content(erb.result(binding), 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end
  
  # method exposing a `Flash` object
  def flash
    @flash ||= Flash.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    self.send(:render) unless @already_built_response
  end
  
  def forum_authenticity_token
    token = {
      hash: SecureRandom::urlsafe_base64(24),
      issued_date: Time::now.utc.to_s,
      remote_ip: @req.remote_ip
    }
    
    @issued_tokens << token
    token[:hash]
  end
  
  def serialize_auth_tokens
    File.open('issued_auth_tokens.yml', 'w') { |f| YAML.dump(@issued_tokens, f)}
  end
  
  def inject_csrf_fields(html)
    noko_page = Nokogiri::HTML(html)
    injected = false
    
    forms = noko_page.css('form')
    forms.each do |form|
      csrf_input = Nokogiri::XML::Node.new("input", noko_page).tap do |node|
        node['type'] = 'hidden'
        node['name'] = 'authenticity_token'
        node['value'] = forum_authenticity_token
      end
      # add forum authenticity input fields
      form.children.first.before(csrf_input)
      injected = true
    end
    
    # return noko_page with injected tokens
    injected ? noko_page.to_html : html
  end
end

class CsrfAuthenticityError < ArgumentError
  def initialize(msg = 'unable to authenticate form')
    super('CSRF protection error: ' + msg)
  end
end