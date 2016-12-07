require 'logger'
require 'awesome_print'

require 'configuration'

class TaskRunner
  include Configuration

  STATUS_RUNNING = 'RUNNING'
  STATUS_NOT_RUNNING = 'NOT RUNNING'

  DEFAULT_CONFIG_PATH = './config/development.json'
  DEFAULT_LOG_LEVEL = 'INFO'

  def initialize(env = nil)
    @task_status = STATUS_NOT_RUNNING
    @mutex = Mutex.new
    set_env(env) if env
  end

  def run(params_or_path = nil, args = {})
    r = nil
    return nil if running?
    @mutex.synchronize do
      return nil if running?
      reset!
      set_env(params_or_path)
      lock
      r = do_task(args)
      unlock
    end
    r
  end

  def running?
    @task_status == STATUS_RUNNING
  end

  def show_env(params_or_path = nil)
    ap params
  end

  def logger
    unless @logger
      @logger = Logger.new(params['log'] || STDOUT)
      set_log_level(params['log_level'])
      @logger.level = get_log_level_value(params['log_level'])
    end
    @logger
  end

  def set_log_level(level = nil)
    logger.level = get_log_level_value(level)
  end

  private

  def get_log_level_value(level = nil)
    level ||= DEFAULT_LOG_LEVEL
    unless Logger::SEV_LABEL.include?(level.upcase)
      level = DEFAULT_LOG_LEVEL
    end
    Logger.const_get(level)
  end

  def default_config_path
    DEFAULT_CONFIG_PATH
  end

  def do_task(args = {})
    raise 'Must Implement do_task'
  end

  def reset!
  end

  def lock
    @task_status = STATUS_RUNNING
  end

  def unlock
    @task_status = STATUS_NOT_RUNNING
  end
end
