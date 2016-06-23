require 'cgi'
require 'net/http'
require 'rest-client'
require 'json'
require 'awesome_print'

class CoreClient
  DEFAULT_SCHEME = 'http'
  DEFAULT_HOST = 'localhost'
  DEFAULT_PORT = '3000'

  attr_accessor :scheme, :host, :port, :api_key
  attr_reader :error, :response

  def initialize(opt = {})
    @error = nil
    set_env(opt)
  end

  def set_env(params_or_path = {})
    opt = params_or_path
    if opt.is_a? String
      opt = read_config(opt)
    elsif opt.is_a? Hash
      if opt[:config]
        opt = read_config(opt[:config])
      end
    end
    @scheme = opt['api_scheme'] || DEFAULT_SCHEME
    @host = opt['api_host'] || DEFAULT_HOST
    @port = opt['api_port'] ||  DEFAULT_PORT
    @api_key = opt['api_key']
  end

  def read_config(params_or_path)
    unless FileTest.exists?(params_or_path)
      raise IOError, "CoreClient Config File Not Found: #{path}"
    end
    JSON.parse(IO.read(params_or_path))
  end

  def show_env
    ap({ scheme: @scheme, host: @host, port: @port, api_key: @api_key })
  end

  def base_url
    "#{@scheme}://#{@host}:#{@port}/api/v1"
  end

  def url(resource, params = {})
    r = "#{base_url}/#{resource}" 
    if params[:id]
      r += "/#{params[:id]}"
    end
    params = params.reject { |k, v| k == :id }
    unless params.empty?
      query = params.map { |k, v| "#{k}=#{v.respond_to?(:encoding) ? CGI.escape(v) : v}" }.join('&')
      r += '?' + query
    end
    r
  end

  def check_status
    begin
      r = RestClient.get(url(:users, id: 'xxxxxxxx'), auth_key) { |body, req, res| res }
      if r.is_a? Net::HTTPResponse
        { code: r.code.to_i, msg: r.msg, type: r.class.to_s }
      else
        { code: -1, msg: 'Unexpected Response', type: r.class.to_s }
      end
    rescue => e
      { code: -2, msg: e.to_s, type: e.class.to_s, backtrace: e.backtrace }
    end
  end

  def get_users
    get :users, limit: '1000000'
  end

  def get_user_by_id(user_id)
    get :users, id: user_id
  end

  def get_user(query)
    get :users, q: query
  end

  def add_user(user)
    post :users, user
  end

  def update_user(user_id, user)
    put :users, { id: user_id }, user
  end

  def delete_user(user_id)
    delete :users, id: user_id
  end

  def success?
    @response && @response.code.start_with?('2')
  end

  def failure?
    !success?
  end

  def error?
    !!@error
  end

  def show_error(out = STDOUT)
    if error?
      show_fatal_error(out)
    elsif failure?
      show_error_response(out)
    end
  end

  def show_fatal_error(out = STDOUT)
    out.error "FATAL: #{@error.to_s}"
    out.error @error.backtrace.join(";")
  end

  def show_error_response(out = STDOUT)
    out.error "ERROR [#{@response.code}] #{@response.msg} #{@response.body}"
  end

  def record_error(r)
    h = r[:error] = {}
    if error?
      h[:type] = 'fatal'
      h[:message] = @error.to_s
      h[:backtrace] = @error.backtrace.join("\n")
    elsif failure?
      h[:type] = 'error'
      h[:http_code] = @response.code
      h[:message] = @response.msg
      h[:details] = JSON.parse(@response.body)['errors'] 
    end
    r
  end

  private

  def get(resource, params = {})
    rest_wrapper do |callback|
      RestClient.get(url(resource, params), auth_key, &callback)
    end
  end

  def post(resource, data)
    rest_wrapper do |callback|
      RestClient.post url(resource), data, auth_key, &callback
    end
  end

  def put(resource, params = {}, data)
    rest_wrapper do |callback|
      RestClient.put url(resource, params), data, auth_key, &callback
    end
  end

  def delete(resource, params = {})
    rest_wrapper do |callback|
      RestClient.delete url(resource, params), auth_key, &callback
    end
  end

  def save_response
    unless @proc
      @proc = Proc.new { |response, request, result|
        @request = request
        @response = result
        response
      }
    end
    @proc
  end

  # Returns JSON if successful and has body, nil otherwise
  def rest_wrapper
    begin
      @error = nil
      r = yield(save_response)
      if success?
        if r && !r.empty?
          return JSON.parse(r)
        end
      end
    rescue => e
      @error = e
    end
    nil
  end

  def auth_key
    { Authorization: "Bearer #{@api_key}" }
  end
end
