require 'json'

class Hash
  def slice(*keys)
    keys.each_with_object(self.class.new) { |k, hash| hash[k] = self[k] if has_key?(k) }
  end

  def convert_key!
    keys.each do |k|
      self[k.to_s] = self.delete(k)
    end
  end
end

module Configuration
  def params
    unless @params
      set_env
    end
    @params
  end

  def set_env(params_or_path = nil)
    if params_or_path.is_a?(Hash)
      params_or_path.convert_key!
      if params_or_path['config']
        set_env_from_file(params_or_path['config'])
      else
        @params = params_or_path.clone
      end
    elsif params_or_path.is_a?(String)
      set_env_from_file(params_or_path)
    elsif FileTest.exists?(default_config_path)
      set_env_from_file(default_config_path)
    else
      raise ArgumentError, "Only accept Hash or config file path: #{params_or_path}" 
    end
    unless required_params.empty?
      @params = @params.slice(*required_params)
    end
  end

  private

  def default_config_path
    ""
  end

  def required_params
    []
  end

  def set_env_from_file(path)
    unless FileTest.exists?(path)
      raise IOError, "Config File Not Found: #{path}"
    end
    @params = read_config(path) 
  end

  def read_config(path)
    JSON.parse(IO.read(path))
  end
end

