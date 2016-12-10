require 'logger'
require 'awesome_print'

require 'configuration'
require 'kim_users_sql'

class KimUsersBase
  include Configuration
  include KimUsersSql

  DEFAULT_LOG_LEVEL = 'WARN'
  DEFAULT_HOST = 'localhost'
  DEFAULT_PORT = 1521

  attr_reader :status, :errors
  attr_accessor :params, :logger

  def initialize(args = {})
    @errors = []
    @status = 'Not Connected'
    set_env(args)
    set_log_level(args[:log_level])
  end

  def set_env(params_or_path = nil)
    super
    if params
      params['db_host'] = DEFAULT_HOST unless params['db_host']
      params['db_port'] = DEFAULT_PORT unless params['db_port']
    end
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def set_log_level(level = nil)
    level ||= DEFAULT_LOG_LEVEL
    if Logger::SEV_LABEL.include?(level.upcase)
      logger.level = Logger.const_get(level)
    end
  end

  def show_env
    ap params
  end

  def find_user(username, groups = nil)
    select_one(select_kim_user_by_name_sql(username, groups))
  end

  def find_user_by_id(school_id, groups = nil)
    select_one(select_kim_user_by_id_sql(school_id, groups))
  end

  def find_all_by_name(username, groups = nil)
    select_all(select_kim_user_by_name_sql(username, groups))
  end

  def find_all_by_email(email, groups = nil)
    select_all(select_kim_user_by_email_sql(email, groups))
  end

  def find_all_by_id(school_id, groups = nil)
    select_all(select_kim_user_by_id_sql(school_id, groups))
  end

  #Returns users that were recently inserted into KC/COI user groups
  def find_new_group_members(groups, days = 1)
    select_all(select_new_group_members_sql(groups, days))
  end

  def top_user
    nil if has_error?
    select_one(select_kim_users_sql)
  end

  def all_users
    nil if has_error?
    select_all(all_users_sql)
  end

  def users(groups = nil)
    nil if has_error?
    #unless @users
    #  @users = select_all(select_kim_users_sql(groups))
    #end
    #@users
    select_all(select_kim_users_sql(groups))
  end

  def admin_users
    return nil unless permission_assignees
    permission_assignees.select { |r|
      r['MBR_TYP_CD'] == 'P' || r['MBR_TYP_CD'] == 'G'
    }.map { |r| r['MBR_ID'] }.uniq
  end

  def groups
    unless @groups
      @groups = select_all(select_groups_sql)
    end
    @groups
  end

  def group_names
    groups.map { |r| r['name'] }
  end

  def permission_assignees
    nil if has_error?
    unless @permission_assignees
      @permission_assignees = select_all(select_permission_assignees_sql)
    end
    @permission_assignees
  end

  def role_ids
    nil if has_error?
    unless @role_ids
      @role_ids = select_all(select_role_ids_sql).map { |r| r['ROLE_ID']}
    end
    @role_ids
  end

  def show_errors
    @errors.each do |h|
      puts '=' * 80
      puts h[:message]
      puts '-' * 80
      puts h[:stacktrace]
    end
    puts '-' * 80 unless @errors.empty?
  end

  def has_error?
    !@errors.empty?
  end

  def reset_errors
    @errors = []
  end

  def ping
    raise 'Must Override ping'
  end

  private

  def select_one(sql)
    raise 'Must Override select_one'
  end

  def select_all(sql)
    raise 'Must Override select_all'
  end

  def record_error(e)
    @errors << {
      message:  e.to_s,
      stacktrace: e.backtrace.join("\n"),
    }
  end

  def required_params
    %w(db_user db_pass db_host db_port db_sid log_level)
  end
end
